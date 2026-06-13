# =============================================================================
# Phase 39: cutpoint analysis for the refined LSOG probability model.
# Instead of an arbitrary 0.5 class threshold, we (a) treat P(LSOG) as the
# primary product and (b) compare principled cutpoints:
#   - Youden's J (accuracy-optimal: max sensitivity+specificity-1)
#   - area-matched (threshold so predicted prevalence == design-based FIA
#     any-LSOG prevalence; structurally guards against over-prediction)
#   - 0.5 default (for reference)
# Report sensitivity, specificity, predicted prevalence, and independent-reserve
# detection at each. Output: ~/LSOG/output_phase39/
# =============================================================================
suppressPackageStartupMessages({ library(randomForest); library(terra); library(data.table) })
set.seed(20260613)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase39"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
log<-function(...) cat(sprintf(...),"\n")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")

uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
me[, lcms_yod:=terra::extract(yod, pv)[,2]]
me[, lcms_tsd:=ifelse(is.na(lcms_yod)|lcms_yod==0, 40, 2023-lcms_yod)]
me[, y:=factor(ifelse(v5_class!="Not LSOG","LSOG","Not"), levels=c("Not","LSOG"))]
prev_design<-0.141   # design-based ME any-LSOG prevalence (target for area-matching)

## out-of-fold CV probabilities (balanced RF)
folds<-sample(rep(1:5, length.out=nrow(me))); me[, ph:=NA_real_]
nmin<-min(table(me$y))
for(k in 1:5){ tr<-me[folds!=k]; te<-which(folds==k)
  rf<-randomForest(y~potapov_rh95+lcms_tsd, data=tr, ntree=400,
                   sampsize=rep(min(nmin,min(table(tr$y))),2), strata=tr$y)
  me$ph[te]<-predict(rf, me[te], type="prob")[,"LSOG"] }
yv<-as.integer(me$y=="LSOG"); p<-me$ph

## ROC over a grid of cutpoints
thr<-seq(0.01,0.99,0.01)
roc<-rbindlist(lapply(thr, function(t){ pred<-as.integer(p>=t)
  tp<-sum(pred==1&yv==1); fn<-sum(pred==0&yv==1); tn<-sum(pred==0&yv==0); fp<-sum(pred==1&yv==0)
  data.table(thr=t, sens=tp/(tp+fn), spec=tn/(tn+fp), prev_pred=mean(pred)) }))
roc[, J:=sens+spec-1]
thr_youden<-roc[which.max(J), thr]
thr_area<-roc[which.min(abs(prev_pred-prev_design)), thr]
auc<-{pos<-p[yv==1]; neg<-p[yv==0]; mean(outer(pos,neg,">")+0.5*outer(pos,neg,"=="))}
log("CV AUC %.3f | Youden thr %.2f | area-matched thr %.2f (target prev %.3f)", auc, thr_youden, thr_area, prev_design)

## reserve P(LSOG) using a final balanced model
rf_f<-randomForest(y~potapov_rh95+lcms_tsd, data=me, ntree=600, sampsize=rep(nmin,2), strata=me$y)
plots<-fread(file.path(RES,"ERM_ME_Plots.csv"), encoding="Latin-1")[!is.na(as.numeric(Latitude))]
rp<-vect(plots, geom=c("Longitude","Latitude"), crs="EPSG:4269")
rd<-data.table(res=plots$EcoRName,
  potapov_rh95=terra::extract(pot, project(rp,crs(pot)))[,2],
  lcms_yod=terra::extract(yod, project(rp,crs(yod)))[,2])
rd[, lcms_tsd:=ifelse(is.na(lcms_yod)|lcms_yod==0,40,2023-lcms_yod)]
rd<-rd[!is.na(potapov_rh95)]; rd[, p_lsog:=predict(rf_f, rd, type="prob")[,"LSOG"]]

tab<-function(nm,t){ data.table(cutpoint=nm, threshold=round(t,2),
  sensitivity=round(roc[which.min(abs(thr-t)),sens],3),
  specificity=round(roc[which.min(abs(thr-t)),spec],3),
  map_prevalence=round(roc[which.min(abs(thr-t)),prev_pred],3),
  reserve_detect=round(mean(rd$p_lsog>=t),3),
  bigreed_detect=round(mean(rd[res=="Big Reed Forest Reserve"]$p_lsog>=t),3)) }
res<-rbindlist(list(tab("0.5 default",0.5), tab("Youden J",thr_youden), tab("area-matched",thr_area)))
print(res); fwrite(res, file.path(OUT,"C1_cutpoint_comparison.csv"))
fwrite(roc, file.path(OUT,"C2_roc.csv"))
fwrite(rd[, .(res, p_lsog=round(p_lsog,3))], file.path(OUT,"C3_reserve_prob.csv"))
log("reserve mean P(LSOG) %.2f | Big Reed mean P(LSOG) %.2f", mean(rd$p_lsog), mean(rd[res=="Big Reed Forest Reserve"]$p_lsog))
cat("PHASE 39 DONE\n")
