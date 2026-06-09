# =============================================================================
# Phase 13: Add TreeMap (FIA-structure imputation) as an independent 4th method,
# build a CONSENSUS confidence map, and break disagreement down by owner class.
#
# Methods on the 100 m AOI grid:
#   M1 Hagan (airborne-LiDAR canopy RF)         -> C_hagan_class_100m.tif
#   M2 v5.1-GEDI (FIA class ~ Potapov height)   -> M2_v51gedi_pLSOG_100m.tif
#   M3 Potapov-direct (RH95 >= 18 m)            -> derived from pLSOG threshold
#   M4 TreeMap (FIA v5.1 class imputed per pixel)-> TreeMap2022 + hybrid lookup
#
# M4 is the genuinely independent axis: it carries the full 6-dimension FIA field
# structure to every pixel by nearest-plot imputation, NOT canopy height. If M4
# agrees with M2 (also FIA-targeted) more than with M1 (canopy), the disagreement
# is definitional (structure vs canopy), not noise.
#
# Outputs: ~/LSOG/output_phase13/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table); library(foreign); library(sf) })
terraOptions(memfrac=0.7)
LSOG <- "/users/PUOM0008/crsfaaron/LSOG"
P10R <- file.path(LSOG,"output_phase10/C_hagan_class_100m.tif")
PLR  <- file.path(LSOG,"output_phase12/M2_v51gedi_pLSOG_100m.tif")
TM   <- "/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif"
VAT  <- "/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif.vat.dbf"
LUT  <- file.path(LSOG,"output_treemap/hybrid_v5_v4_lookup.csv")
OWN  <- "/users/PUOM0008/crsfaaron/landowner/US_forest_ownership.tif"
PLOTS<- file.path(LSOG,"output_unified/lsog_ne_plot_table.csv")
OUT  <- file.path(LSOG,"output_phase13"); dir.create(file.path(OUT,"fig"),showWarnings=FALSE,recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
kappa_bin <- function(v,h){n<-length(v);a<-sum(v&h);b<-sum(v&!h);c<-sum(!v&h);d<-sum(!v&!h)
  po<-(a+d)/n;pe<-((a+b)/n)*((a+c)/n)+((c+d)/n)*((b+d)/n);(po-pe)/(1-pe)}
B0<- -3.0204; B_RH<-0.10815                       # Phase 12 M2 fit
THR2 <- 0.2553                                    # M2 calibrated (FIA share 14.1%)
THR3 <- 1/(1+exp(-(B0+B_RH*18)))                  # M3 == RH95>=18 m
CODE <- c("Not LSOG"=1L,"Transitioning LS"=2L,"LS"=3L,"OG"=4L)

tmpl <- rast(P10R); names(tmpl)<-"M1code"
pL   <- rast(PLR);  names(pL)<-"pLSOG"

# ---- M4 TreeMap: TM_ID -> PLT_CN -> hybrid class, over AOI ----
log("Building TreeMap class raster ...")
vat <- as.data.table(read.dbf(VAT, as.is=TRUE))
setnames(vat, names(vat), toupper(names(vat)))
log("VAT columns: %s", paste(names(vat), collapse=","))
val_col <- intersect(c("VALUE","TM_ID"), names(vat))[1]
cn_col  <- intersect(c("CN","PLT_CN"), names(vat))[1]
log("Using raster-value column '%s' and plot column '%s'", val_col, cn_col)
vat <- data.table(TM_ID=as.integer(vat[[val_col]]),
                  PLT_CN=sprintf("%.0f", as.numeric(vat[[cn_col]])))
lut <- fread(LUT, colClasses=list(character="PLT_CN"))
lut[, code := CODE[hybrid_class]]
vat <- merge(vat, lut[, .(PLT_CN, code)], by="PLT_CN", all.x=TRUE)
vat <- vat[!is.na(TM_ID)]
log("TreeMap VAT: %d ids, %d with class (rest = Unknown PLT_CN)", nrow(vat), sum(!is.na(vat$code)))

tm <- rast(TM)
tmpl_tm <- project(rast(ext(tmpl), resolution=250, crs=crs(tmpl)), crs(tm))
tmc <- crop(tm, ext(tmpl_tm), snap="out")
levels(tmc) <- NULL   # CRITICAL (Phase 8 note): get raw integer VALUE codes, not RAT labels
log("TreeMap cropped to AOI: %d x %d (30 m); value range %s",
    nrow(tmc), ncol(tmc), paste(as.vector(minmax(tmc)), collapse="-"))
m4_30 <- subst(tmc, from=vat$TM_ID, to=ifelse(is.na(vat$code),0L,vat$code), others=NA)
m4_30[m4_30==0] <- NA
m4 <- project(m4_30, tmpl, method="mode"); names(m4)<-"M4code"
writeRaster(m4, file.path(OUT,"M4_treemap_class_100m.tif"), overwrite=TRUE, datatype="INT1U")

# ---- assemble 4-method table on AOI ----
dt <- as.data.table(c(tmpl, pL, m4)); setnames(dt, c("M1code","pLSOG","M4code"))
dt <- dt[!is.na(M1code)]
dt[, M1 := M1code %in% 2:4]
dt[, M2 := !is.na(pLSOG) & pLSOG >= THR2]
dt[, M3 := !is.na(pLSOG) & pLSOG >= THR3]
dt[, M4known := !is.na(M4code)]
dt[, M4 := M4code %in% 2:4]
log("AOI cells: %d | TreeMap known: %d (%.1f%%)", nrow(dt), sum(dt$M4known), 100*mean(dt$M4known))

# area by method (M4 among known cells)
area <- data.table(
  method=c("M1 Hagan","M2 v5.1-GEDI","M3 Potapov-direct","M4 TreeMap (FIA imputed)"),
  any_LSOG_pct=c(100*mean(dt$M1),100*mean(dt$M2),100*mean(dt$M3),100*mean(dt[M4known==TRUE]$M4)),
  basis=c("all AOI","all AOI","all AOI","TreeMap-known cells"))
fwrite(area, file.path(OUT,"T1_area_4method.csv")); print(area)

# pairwise kappa on cells where all four defined (M4 known)
q <- dt[M4known==TRUE]
pairs <- list(c("M1","M2"),c("M1","M3"),c("M1","M4"),c("M2","M3"),c("M2","M4"),c("M3","M4"))
pk <- rbindlist(lapply(pairs, function(p){
  data.table(pair=paste(p[1],"vs",p[2]),
    kappa=kappa_bin(q[[p[1]]], q[[p[2]]]),
    jaccard=sum(q[[p[1]]]&q[[p[2]]])/sum(q[[p[1]]]|q[[p[2]]]))}))
fwrite(pk, file.path(OUT,"T2_pairwise_kappa_4method.csv")); print(pk)

# ---- CONSENSUS confidence: number of methods flagging LSOG (0-4) ----
q[, nflag := as.integer(M1)+as.integer(M2)+as.integer(M4)]   # M2==M3 nearly; use M1,M2,M4 as 3 distinct views
# (M3 is the naive height rule; M2 is its calibrated form. Use 3 conceptual methods: Hagan, GEDI-calibrated, TreeMap.)
cons <- q[, .(ha=.N), by=nflag][order(nflag)]
cons[, label := c("0 none","1 method","2 methods","3 methods (consensus)")[nflag+1]]
cons[, pct_of_union := 100*ha/sum(q$nflag>0)]
fwrite(cons, file.path(OUT,"T3_consensus_levels.csv")); print(cons)
allagree <- q[nflag==3,.N]; union3 <- q[nflag>0,.N]
log("High-confidence core (all 3 conceptual methods agree LSOG): %d ha (%.1f%% of union)",
    allagree, 100*allagree/union3)
# write consensus raster
con_r <- tmpl; con_r[] <- NA
idx <- which(!is.na(values(tmpl)))
# rebuild nflag on full grid via lookup of cell order: recompute on raster directly
m1r <- tmpl %in% c(2,3,4)
m2r <- pL >= THR2
m4r <- (m4 %in% c(2,3,4))
m4known_r <- !is.na(m4)
consensus <- m1r + m2r + ifel(is.na(m4r),0,m4r)
consensus <- mask(consensus, tmpl)
writeRaster(consensus, file.path(OUT,"CONSENSUS_nmethods_100m.tif"), overwrite=TRUE, datatype="INT1U")

# ---- Ownership breakdown of consensus ----
ok <- tryCatch({
  own <- rast(OWN)
  ownp <- project(crop(own, ext(project(rast(ext(tmpl),res=250,crs=crs(tmpl)),crs(own))),snap="out"),
                  tmpl, method="near"); names(ownp)<-"owner"
  ovat <- tryCatch(as.data.table(read.dbf(paste0(OWN,".vat.dbf"), as.is=TRUE)), error=function(e) NULL)
  dto <- as.data.table(c(consensus, ownp)); setnames(dto, c("nflag","owner"))
  dto <- dto[!is.na(nflag)]
  obreak <- dto[, .(ha=.N,
                    consensus_ha=sum(nflag==3), contested_ha=sum(nflag>0 & nflag<3),
                    any_flag_ha=sum(nflag>0)), by=owner][order(-any_flag_ha)]
  obreak[, pct_contested_of_flagged := round(100*contested_ha/any_flag_ha,1)]
  fwrite(obreak, file.path(OUT,"T4_ownership_consensus.csv"))
  if(!is.null(ovat)) fwrite(ovat, file.path(OUT,"T4b_owner_vat.csv"))
  log("Ownership breakdown written (%d owner classes)", nrow(obreak)); print(head(obreak,12)); TRUE
}, error=function(e){ log("Ownership step skipped: %s", conditionMessage(e)); FALSE })

# ---- FIA validation: M4 at plots ----
pl <- fread(PLOTS, colClasses=list(character="CN"))[state=="ME" & eval_period=="2019-2023"]
pts <- vect(st_transform(st_as_sf(pl, coords=c("LON","LAT"), crs=4326), crs(tmpl)))
ex <- data.table(v5=pl$v5_class,
                 M1=terra::extract(tmpl,pts)[,2] %in% 2:4,
                 M2=terra::extract(pL,pts)[,2] >= THR2,
                 M4=terra::extract(m4,pts)[,2] %in% 2:4)
ex <- ex[!is.na(M1)]
val <- data.table(method=c("M1 Hagan","M2 v5.1-GEDI","M4 TreeMap"),
  kappa_vs_v51=c(kappa_bin(ex$v5!="Not LSOG",ex$M1),
                 kappa_bin(ex$v5!="Not LSOG",ex$M2 %in% TRUE),
                 kappa_bin(ex[!is.na(M4)]$v5!="Not LSOG", ex[!is.na(M4)]$M4)))
fwrite(val, file.path(OUT,"T5_fia_validation_4method.csv")); print(val)

# ---- maps: 4-panel + consensus ----
e<-ext(tmpl); cx<-mean(e[1:2]); cy<-mean(e[3:4]); win<-ext(cx-12000,cx+12000,cy-12000,cy+12000)
mk <- function(file,w,h,fn){png(file.path(OUT,"fig",file),w,h,res=130);fn();dev.off()
  png(file.path(OUT,"fig",sub("\\.png$","_thumb.png",file)),round(w*0.6),round(h*0.6),res=80);fn();dev.off()}
mk("M_four_maps.png",1600,460,function(){par(mfrow=c(1,4),mar=c(1,1,2.2,1))
  plot(crop(m1r,win),col=c("grey90","#1A3D28"),legend=FALSE,axes=FALSE,main="Hagan (canopy)")
  plot(crop(m2r,win),col=c("grey90","#2c7fb8"),legend=FALSE,axes=FALSE,main="v5.1-GEDI (height)")
  plot(crop(m4r,win),col=c("grey90","#6AAE3D"),legend=FALSE,axes=FALSE,main="TreeMap (FIA structure)")
  plot(crop(consensus,win),col=c("grey92","#fee08b","#fc8d59","#1A3D28"),legend=TRUE,axes=FALSE,main="Consensus (n methods)")})
mk("M_consensus.png",900,820,function(){par(mar=c(1,1,2.5,3))
  plot(consensus,col=c("grey92","#fee08b","#fc8d59","#1A3D28"),
       main="Consensus confidence: number of methods flagging LSOG",axes=FALSE)})
log("DONE Phase 13.")
