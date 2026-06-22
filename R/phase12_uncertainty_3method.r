# =============================================================================
# Phase 12: How hard is it to map LSOG? A three-method uncertainty comparison
# over the Hagan AOI (Maine unorganized townships), and a policy-fragility test.
#
# Methods (all on the same 100 m AOI grid):
#   M1  Hagan (airborne-LiDAR canopy random forest)  -> reproduced Phase 10 raster
#   M2  v5.1-GEDI (FIA-structure-calibrated spatial logit on Potapov RH95 canopy
#       height + ORNL strata proportions) -> the defensible, mappable product
#   M3  Potapov-direct (GEDI-derived canopy height >= 18 m), a naive "tall canopy"
#
# Outputs quantify (a) how much they disagree on AREA, (b) how much on WHERE
# (kappa, 3-way concordance), and (c) how fragile patch-level conservation
# prioritization is across methods (Jaccard of the protected sets) -- the direct
# relevance to reports (Thompson et al. 2026) that price the "top 50%" of a
# single map for LD 1529.
#
# Outputs: ~/LSOG/output_phase12/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table); library(sf) })
terraOptions(memfrac=0.7)

LSOG <- "/users/PUOM0008/crsfaaron/LSOG"
P10R <- file.path(LSOG,"output_phase10/C_hagan_class_100m.tif")   # 1=NotLSOG 2=TLS 3=LS 4=OGL
POT  <- file.path(LSOG,"data/rasters/potapov_2019/Forest_height_2019_NAM.tif")
PLOTS<- file.path(LSOG,"output_unified/lsog_ne_plot_table.csv")
OUT  <- file.path(LSOG,"output_phase12"); dir.create(file.path(OUT,"fig"),showWarnings=FALSE,recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
kappa_bin <- function(v,h){n<-length(v);a<-sum(v&h);b<-sum(v&!h);c<-sum(!v&h);d<-sum(!v&!h)
  po<-(a+d)/n;pe<-((a+b)/n)*((a+c)/n)+((c+d)/n)*((b+d)/n);(po-pe)/(1-pe)}

# ---- M2 model: FIA-calibrated logistic of any-LSOG ~ Potapov RH95 (GEDI) ----
fit_dt <- fread(PLOTS, colClasses=list(character="CN"))
fit_dt <- fit_dt[!is.na(potapov_rh95)]
fit_dt[, y := as.integer(v5_class != "Not LSOG")]
m2fit <- glm(y ~ potapov_rh95, data=fit_dt, family=binomial)
B0 <- coef(m2fit)[1]; B_RH <- coef(m2fit)[2]
pr <- predict(m2fit, type="response")
auc <- { o<-order(pr); r<-rank(pr); n1<-sum(fit_dt$y); n0<-sum(!fit_dt$y)
  (sum(r[fit_dt$y==1]) - n1*(n1+1)/2)/(n1*n0) }
log("M2 logit fit: n=%d  B0=%.3f  B_RH=%.4f  AUC=%.3f  prevalence=%.3f",
    nrow(fit_dt), B0, B_RH, auc, mean(fit_dt$y))
fwrite(data.table(term=c("(Intercept)","potapov_rh95"), estimate=coef(m2fit),
       auc=auc, n=nrow(fit_dt)), file.path(OUT,"T0_M2_logit_fit.csv"))

# ---- template = Hagan 100 m AOI raster ----
tmpl <- rast(P10R); names(tmpl)<-"hagan_code"
log("Template: %d x %d cells, crs=%s", nrow(tmpl), ncol(tmpl), crs(tmpl,describe=TRUE)$name)

# ---- Potapov RH95 -> template (windowed crop in 4326, then project) ----
tmpl_ll <- project(rast(ext(tmpl),resolution=500,crs=crs(tmpl)), "EPSG:4326")
pot <- crop(rast(POT), ext(tmpl_ll), snap="out")
log("Potapov cropped: %d x %d", nrow(pot), ncol(pot))
rh95 <- project(pot, tmpl, method="bilinear"); names(rh95)<-"rh95"
rh95[rh95>60 | rh95<0] <- NA

# ---- M2: v5.1-GEDI FIA-calibrated logit P(LSOG) from Potapov RH95 ----
lin <- B0 + B_RH*rh95
pLSOG <- 1/(1+exp(-lin)); names(pLSOG)<-"pLSOG"
writeRaster(pLSOG, file.path(OUT,"M2_v51gedi_pLSOG_100m.tif"), overwrite=TRUE)

# ---- assemble cell table on forested AOI (Hagan present) ----
dt <- as.data.table(c(tmpl, rh95, pLSOG)); setnames(dt, c("hagan_code","rh95","pLSOG"))
dt <- dt[!is.na(hagan_code)]
log("AOI cells with Hagan class: %d", nrow(dt))

# M1 Hagan any-LSOG
dt[, M1 := hagan_code %in% 2:4]
# M3 Potapov-direct any-LSOG (tall canopy >= 18 m)
dt[, M3 := !is.na(rh95) & rh95 >= 18]
# M2 threshold calibrated so AOI any-LSOG share matches FIA plot-based ME (~14.1%);
#    also report a range of thresholds for sensitivity
fia_share <- 0.141
thr <- as.numeric(quantile(dt$pLSOG, 1-fia_share, na.rm=TRUE))
dt[, M2 := !is.na(pLSOG) & pLSOG >= thr]
log("M2 calibrated threshold pLSOG>=%.3f to match FIA share %.1f%%", thr, 100*fia_share)

HA <- 1.0
area_tab <- data.table(
  method=c("M1 Hagan (LiDAR canopy)","M2 v5.1-GEDI (FIA+Potapov)","M3 Potapov-direct (RH95>=18m)"),
  any_LSOG_pct=c(100*mean(dt$M1),100*mean(dt$M2),100*mean(dt$M3, na.rm=TRUE)),
  any_LSOG_ha =c(sum(dt$M1),sum(dt$M2),sum(dt$M3,na.rm=TRUE)))
fwrite(area_tab, file.path(OUT,"T1_area_by_method.csv")); print(area_tab)

# threshold sensitivity for M2
sens <- rbindlist(lapply(c(0.10,0.125,0.141,0.16,0.20,0.25), function(s){
  t<-as.numeric(quantile(dt$pLSOG,1-s,na.rm=TRUE)); data.table(target_share=s, threshold=t,
    ha=sum(dt$pLSOG>=t,na.rm=TRUE))}))
fwrite(sens, file.path(OUT,"T2_M2_threshold_sensitivity.csv"))

# ---- WHERE: pairwise kappa + 3-way concordance ----
pk <- data.table(
  pair=c("M1 vs M2","M1 vs M3","M2 vs M3"),
  kappa=c(kappa_bin(dt$M1,dt$M2), kappa_bin(dt$M1,dt$M3 %in% TRUE), kappa_bin(dt$M2,dt$M3 %in% TRUE)),
  jaccard=c(
    sum(dt$M1&dt$M2)/sum(dt$M1|dt$M2),
    sum(dt$M1&dt$M3,na.rm=TRUE)/sum(dt$M1|dt$M3,na.rm=TRUE),
    sum(dt$M2&dt$M3,na.rm=TRUE)/sum(dt$M2|dt$M3,na.rm=TRUE)))
fwrite(pk, file.path(OUT,"T3_pairwise_agreement.csv")); print(pk)

dt[, nmeth := as.integer(M1)+as.integer(M2)+as.integer(M3 %in% TRUE)]
conc <- dt[, .(ha=.N), by=nmeth][order(nmeth)]
conc[, pct_of_anyLSOG := 100*ha/sum(dt$nmeth>0)]
fwrite(conc, file.path(OUT,"T4_concordance_counts.csv")); print(conc)
allthree <- dt[nmeth==3, .N]; anyLSOG_union <- dt[nmeth>0, .N]
log("Hectares all 3 methods agree LSOG: %d (%.1f%% of the union flagged by any method)",
    allthree, 100*allthree/anyLSOG_union)

# ---- Hagan over-call: LSOG where canopy isn't even tall ----
hag <- dt[M1==TRUE]
oc <- data.table(
  metric=c("Hagan-LSOG hectares","... with Potapov RH95 < 18 m","... with low v5.1-GEDI P (below M2 thresh)"),
  ha=c(nrow(hag), hag[rh95<18 | is.na(rh95), .N], hag[pLSOG<thr, .N]))
oc[, pct := 100*ha/nrow(hag)]
fwrite(oc, file.path(OUT,"T5_hagan_overcall.csv")); print(oc)

# ---- POLICY FRAGILITY: if you protect the top-K hectares, do methods pick the same ground? ----
# Rank by each method's LSOG signal; Hagan ordinal class, M2 continuous P, M3 rh95.
N <- nrow(dt)
frag <- rbindlist(lapply(c(0.05,0.10,0.20), function(frac){
  k <- round(frac*N)
  s1 <- order(-dt$hagan_code, -dt$pLSOG)[1:k]      # Hagan class then P as tiebreak
  s2 <- order(-dt$pLSOG)[1:k]                        # v5.1-GEDI
  s3 <- order(-ifelse(is.na(dt$rh95),-1,dt$rh95))[1:k]
  jac <- function(a,b) length(intersect(a,b))/length(union(a,b))
  data.table(top_frac=frac, k=k,
    J_M1_M2=jac(s1,s2), J_M1_M3=jac(s1,s3), J_M2_M3=jac(s2,s3))
}))
fwrite(frag, file.path(OUT,"T6_prioritization_jaccard.csv")); print(frag)

# ---- FIA validation: each method's any-LSOG at the 1760 UT plots vs v5.1 plot class ----
pl <- fread(PLOTS, colClasses=list(character="CN"))[state=="ME" & eval_period=="2019-2023"]
pts <- vect(st_transform(st_as_sf(pl, coords=c("LON","LAT"), crs=4326), crs(tmpl)))
ex <- data.table(v5=pl$v5_class,
                 M1=terra::extract(tmpl,pts)[,2] %in% 2:4,
                 M2=terra::extract(pLSOG,pts)[,2] >= thr,
                 M3=terra::extract(rh95,pts)[,2] >= 18)
ex <- ex[!is.na(M1)]
val <- data.table(method=c("M1 Hagan","M2 v5.1-GEDI","M3 Potapov-direct"),
  n=nrow(ex),
  any_pct=c(100*mean(ex$M1),100*mean(ex$M2,na.rm=TRUE),100*mean(ex$M3,na.rm=TRUE)),
  kappa_vs_v51=c(kappa_bin(ex$v5!="Not LSOG",ex$M1),
                 kappa_bin(ex$v5!="Not LSOG",ex$M2 %in% TRUE),
                 kappa_bin(ex$v5!="Not LSOG",ex$M3 %in% TRUE)))
fwrite(val, file.path(OUT,"T7_fia_validation.csv")); print(val)

# ---- 3-panel map over a sample window (Borestone-ish: center of AOI) ----
 e <- ext(tmpl); cx<-mean(e[1:2]); cy<-mean(e[3:4]); win<-ext(cx-12000,cx+12000,cy-12000,cy+12000)
m1r <- crop(tmpl>=2, win); m2r <- crop(pLSOG>=thr, win); m3r <- crop(rh95>=18, win)
png(file.path(OUT,"fig","M_three_maps.png"), 1500, 560, res=130)
par(mfrow=c(1,3), mar=c(1,1,2.5,1))
plot(m1r, col=c("grey90","#1A3D28"), legend=FALSE, axes=FALSE, main="Hagan (LiDAR canopy)")
plot(m2r, col=c("grey90","#2c7fb8"), legend=FALSE, axes=FALSE, main="v5.1-GEDI (FIA+Potapov)")
plot(m3r, col=c("grey90","#C5A55A"), legend=FALSE, axes=FALSE, main="Potapov-direct (RH95>=18m)")
dev.off()
png(file.path(OUT,"fig","M_three_maps_thumb.png"), 900, 336, res=80)
par(mfrow=c(1,3), mar=c(1,1,2,1))
plot(m1r,col=c("grey90","#1A3D28"),legend=FALSE,axes=FALSE,main="Hagan")
plot(m2r,col=c("grey90","#2c7fb8"),legend=FALSE,axes=FALSE,main="v5.1-GEDI")
plot(m3r,col=c("grey90","#C5A55A"),legend=FALSE,axes=FALSE,main="Potapov")
dev.off()
log("DONE Phase 12.")
