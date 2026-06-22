# =============================================================================
# Phase 38: a refined LSOG map that fuses remote-sensing structure (Potapov RH95,
# ORNL mature/OG probability) with our LCMS Landsat disturbance/continuity layer,
# trained with class BALANCING (practicing what we fault in Hagan), and validated
# against the independent MNAP/TNC reserves. Tests whether adding the Landsat
# disturbance layer improves detection of independent old growth.
# Output: ~/LSOG/output_phase38/
# =============================================================================
suppressPackageStartupMessages({ library(randomForest); library(terra); library(data.table) })
set.seed(20260613)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase38"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
log<-function(...) cat(sprintf(...),"\n")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")

## ---- training data: ME FIA plots, RS covariates already in unified table + LCMS ----
uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
me[, lcms_yod:=terra::extract(yod, pv)[,2]]
me[, lcms_tsd:=ifelse(is.na(lcms_yod)|lcms_yod==0, 40, 2023-lcms_yod)]   # years since disturbance (40=none in record)
me[, y:=factor(ifelse(v5_class!="Not LSOG","LSOG","Not"), levels=c("Not","LSOG"))]
log("training plots: %d  (LSOG prevalence %.2f)", nrow(me), mean(me$y=="LSOG"))

cv_auc<-function(dat, preds){
  set.seed(1); folds<-sample(rep(1:5, length.out=nrow(dat)))
  ph<-numeric(nrow(dat)); nmin<-min(table(dat$y))
  for(k in 1:5){ tr<-dat[folds!=k]; te<-dat[folds==k]
    rf<-randomForest(reformulate(preds,"y"), data=tr, ntree=400,
                     sampsize=rep(min(nmin,min(table(tr$y))),2), strata=tr$y)
    ph[folds==k]<-predict(rf, te, type="prob")[,"LSOG"] }
  # AUC
  pos<-ph[dat$y=="LSOG"]; neg<-ph[dat$y=="Not"]
  mean(outer(pos,neg,">")+0.5*outer(pos,neg,"=="))
}
base_preds<-c("potapov_rh95")
auc_rs <-cv_auc(me, base_preds)
auc_rsl<-cv_auc(me, c(base_preds,"lcms_tsd"))
log("Balanced 5-fold CV AUC:  canopy height only %.3f   + LCMS disturbance %.3f   (delta %+.3f)", auc_rs, auc_rsl, auc_rsl-auc_rs)
fwrite(data.table(model=c("canopy height","canopy + LCMS"), cv_auc=round(c(auc_rs,auc_rsl),3)), file.path(OUT,"R1_cv_auc.csv"))

## ---- fit final refined (balanced) model on all ME plots ----
nmin<-min(table(me$y))
rf_ref<-randomForest(reformulate(c(base_preds,"lcms_tsd"),"y"), data=me, ntree=500,
                     sampsize=rep(nmin,2), strata=me$y)
saveRDS(rf_ref, file.path(OUT,"refined_rf.rds"))

## ---- validate at independent MNAP/TNC reserve plots ----
plots<-fread(file.path(RES,"ERM_ME_Plots.csv"), encoding="Latin-1")[!is.na(as.numeric(Latitude))]
rp<-vect(plots, geom=c("Longitude","Latitude"), crs="EPSG:4269")
ex<-data.table(res=plots$EcoRName,
  potapov_rh95=terra::extract(pot, project(rp, crs(pot)))[,2],
  lcms_yod=terra::extract(yod, project(rp, crs(yod)))[,2])
ex[, lcms_tsd:=ifelse(is.na(lcms_yod)|lcms_yod==0, 40, 2023-lcms_yod)]
ok<-ex[!is.na(potapov_rh95)]
ok[, p_lsog:=predict(rf_ref, ok, type="prob")[,"LSOG"]]
ok[, refined_lsog:=as.integer(p_lsog>=0.5)]
log("Refined map (RS+LCMS, balanced) detection at reserves:")
log("  ALL reserves: %.0f%%  (n=%d)", 100*mean(ok$refined_lsog), nrow(ok))
br<-ok[res=="Big Reed Forest Reserve"]
log("  Big Reed: %.0f%%  (n=%d)", 100*mean(br$refined_lsog), nrow(br))
fwrite(ok[, .(res, p_lsog=round(p_lsog,3), refined_lsog)], file.path(OUT,"R2_reserve_refined_pred.csv"))
pr<-ok[, .(n=.N, refined_pct=round(100*mean(refined_lsog))), by=res][order(-n)]
fwrite(pr, file.path(OUT,"R3_per_reserve_refined.csv")); print(pr[n>=10])
cat("PHASE 38 DONE\n")
