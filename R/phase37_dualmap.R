# =============================================================================
# Phase 37: independent assessment at precise locations.
# (1) Does HAGAN's own map flag the ecological reserves (incl. Big Reed) as LSOG?
#     Sample the reproduced Hagan 100 m classification at the precise ERM reserve
#     plot coordinates and compare to our four-axis call from the reserve trees.
# (2) Does using TRUE FIA coordinates (vs fuzzed) change the v5.1-vs-Hagan
#     cross-map agreement? Sample Hagan at true and fuzzed FIA coords.
# Output: ~/LSOG/output_phase37/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table) })
RES <- "/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
HAG <- "/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif"
UNI <- "/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase37"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...), "\n")
hag <- rast(HAG)   # 1=NotLSOG 2=TransLS 3=LS 4=OGL

## ---- (1) our four-axis call at reserve plots + Hagan's call there ----
allt <- fread(file.path(RES,"ERM_ME_AllTrees.csv"), encoding="Latin-1")
plots<- fread(file.path(RES,"ERM_ME_Plots.csv"), encoding="Latin-1")
IN<-2.54; TPAC<-0.404686
allt[, DBH:=as.numeric(DBH)][, EXPF:=as.numeric(EXPF)][, Round:=as.numeric(Round)]
allt <- allt[!is.na(DBH)&!is.na(EXPF)]
allt[, mr:=max(Round,na.rm=TRUE), by=Plot_ID]; allt<-allt[Round==mr]
LATE<-c("TSUCAN","PICRUB","PICMAR","PICGLA","THUOCC","ACESAC","FAGGRA","BETALL","PINSTR","QUERUB")
grp<-function(code){c<-suppressWarnings(as.integer(code)); ifelse(is.na(c),"other",
  fifelse(c>=120&c<=169,"spruce-fir",fifelse(c>=800&c<=809,"maple-beech-birch",
  fifelse(c>=900&c<=969,"aspen-birch",fifelse(c>=400&c<=409,"oak-pine",
  fifelse((c>=100&c<=140)|(c>=380&c<=399),"pine-softwood",fifelse(c>=500&c<=599,"oak-hickory",
  fifelse(c>=700&c<=722,"elm-ash-cottonwood","other"))))))))}
ft<-plots[, .(Plot_ID, g=grp(ForestType), Lat=as.numeric(Latitude), Lon=as.numeric(Longitude), res=EcoRName)]
PELZ<-c('spruce-fir'=5,'maple-beech-birch'=8,'aspen-birch'=5,'oak-pine'=7,'pine-softwood'=7,'oak-hickory'=8,'elm-ash-cottonwood'=5,'other'=5)
allt[, live:=Condition %in% c("1","2")]
sc <- allt[, .(
  liveBA=sum(ifelse(live, pi/4*(DBH/100)^2*EXPF,0)),
  largeBA16=sum(ifelse(live & DBH>=16*IN, pi/4*(DBH/100)^2*EXPF,0)),
  n12=sum(ifelse(live & DBH>=12*IN, EXPF*TPAC,0)),
  snagBA=sum(ifelse(!live & DBH>=5*IN, pi/4*(DBH/100)^2*EXPF,0)),
  lateBA=sum(ifelse(live & Species %in% LATE, pi/4*(DBH/100)^2*EXPF,0))), by=Plot_ID]
sc<-merge(sc, ft, by="Plot_ID")
sc[, a1_orig:=as.integer(largeBA16>=30*0.2296)]
sc[, a1_pelz:=as.integer(n12>=PELZ[g])]
sc[, a2:=as.integer(snagBA>=5*0.2296)]
sc[, a3:=as.integer(liveBA>0 & lateBA/liveBA>=0.5)]
sc[, ours_orig:=as.integer(a1_orig+a2+a3>=2)]   # our LSOG call (original large-tree BA)
sc[, ours_pelz:=as.integer(a1_pelz+a2+a3>=2)]   # our LSOG call (Pelz type-specific)
# sample Hagan at reserve coords
pv<-project(vect(sc[!is.na(Lat)&!is.na(Lon)], geom=c("Lon","Lat"), crs="EPSG:4269"), crs(hag))
sc2<-sc[!is.na(Lat)&!is.na(Lon)]
sc2[, hag_code:=terra::extract(hag, pv)[,2]]
sc2[, hag_lsog:=as.integer(hag_code %in% c(2,3,4))]
sc2[, in_hag:=as.integer(!is.na(hag_code))]
inAOI<-sc2[in_hag==1]
log("Reserve plots inside Hagan's AOI: %d of %d", nrow(inAOI), nrow(sc2))
summ<-function(nm,d){ if(nrow(d)==0){return(invisible())}
  log("%-26s n=%3d | Hagan flags LSOG %3.0f%% | ours(orig) %3.0f%% | ours(Pelz) %3.0f%%",
      nm, nrow(d), 100*mean(d$hag_lsog), 100*mean(d$ours_orig), 100*mean(d$ours_pelz)) }
summ("ALL reserves in AOI", inAOI)
summ("Big Reed", inAOI[res=="Big Reed Forest Reserve"])
fwrite(sc2[, .(Plot_ID,res,g,ours_orig,ours_pelz,hag_code,hag_lsog,in_hag)], file.path(OUT,"Q1_reserve_dualmap.csv"))
# per-reserve table
pr<-inAOI[, .(n=.N, hagan=round(100*mean(hag_lsog)), ours_pelz=round(100*mean(ours_pelz))), by=res][order(-n)]
fwrite(pr, file.path(OUT,"Q2_per_reserve.csv")); print(pr[n>=8])

## ---- (2) true vs fuzzed FIA coords: cross-map kappa v5.1 vs Hagan ----
xy<-fread(file.path(RES,"FIA.xy.csv"), colClasses=list(character="PLT_CN"))
xy<-unique(xy[, .(PLT_CN, FUZZ.LAT, FUZZ.LON, TRUE.LAT, TRUE.LON)])
uni<-fread(UNI, colClasses=list(character="CN"))[state=="ME", .(PLT_CN=CN, v5_class, eval_period)]
m<-merge(xy, uni, by="PLT_CN")
kap<-function(a,b){t<-table(a,b); n<-sum(t); po<-sum(diag(t))/n; pe<-sum(rowSums(t)*colSums(t))/n^2; (po-pe)/(1-pe)}
samp<-function(la,lo){ pv<-project(vect(data.table(la,lo)[!is.na(la)], geom=c("lo","la"), crs="EPSG:4269"), crs(hag))
  terra::extract(hag, pv)[,2] }
mm<-m[!is.na(TRUE.LAT)&!is.na(FUZZ.LAT)]
mm[, h_true:=samp(TRUE.LAT, TRUE.LON)]; mm[, h_fuzz:=samp(FUZZ.LAT, FUZZ.LON)]
mm[, v5_lsog:=as.integer(v5_class!="Not LSOG")]
fz<-mm[!is.na(h_fuzz)]; tr<-mm[!is.na(h_true)]
k_fuzz<-kap(fz$v5_lsog, as.integer(fz$h_fuzz %in% c(2,3,4)))
k_true<-kap(tr$v5_lsog, as.integer(tr$h_true %in% c(2,3,4)))
log("Cross-map kappa v5.1-any vs Hagan-any: FUZZED %.3f (n=%d) -> TRUE %.3f (n=%d)", k_fuzz, nrow(fz), k_true, nrow(tr))
fwrite(data.table(coord=c("fuzzed","true"), n=c(nrow(fz),nrow(tr)), kappa_any=round(c(k_fuzz,k_true),3)),
       file.path(OUT,"Q3_truecoord_kappa.csv"))
cat("PHASE 37 DONE\n")
