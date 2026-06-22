# Phase 49: menu of rare-class remedies for the reproduced Hagan random forest,
# with old growth (OG) as the rare event. Compares (0) default, (1) class
# weighting (classwt; = sklearn class_weight='balanced'), (2) balanced sub-
# sampling (sampsize/strata; = imblearn BalancedRandomForestClassifier), and
# (3) voting-threshold adjustment (lower the OG vote fraction needed to call OG).
# Reports OG recall with bootstrap 95% CIs, overall accuracy, and wall-to-wall
# OG area under each, showing the headline area is a modeling choice.
suppressPackageStartupMessages({ library(randomForest); library(terra); library(data.table) })
set.seed(20260613)
ZEN<-"/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan"; OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase49"; dir.create(OUT,showWarnings=FALSE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
LID<-c("mean_cano_ht","max_cano_ht","percentile_95th","rumple","top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
DBF<-c("mn_cn_h","mx_cn_h","prcn_95","rumple","tp_rgst","cn_cv_2","cn_cv_6","cn_c_15")
td<-read.csv(file.path(ZEN,"Maine_training_data.csv")); td<-td[,c("LSOG_class",LID)]; td$LSOG_class<-as.factor(td$LSOG_class)
print(table(td$LSOG_class)); nmin<-min(table(td$LSOG_class)); K<-nlevels(td$LSOG_class)
og<-levels(td$LSOG_class)[grep("rowth|OG|^OG",levels(td$LSOG_class))][1]; log("OG label: %s", og)
ntr<-500

## ---- fit the three model-based strategies ----
fit_unb<-function(d) randomForest(LSOG_class~.,data=d,mtry=2,ntree=ntr)
fit_wt <-function(d){w<-max(table(d$LSOG_class))/table(d$LSOG_class); randomForest(LSOG_class~.,data=d,mtry=2,ntree=ntr,classwt=as.numeric(w))}
fit_bal<-function(d) randomForest(LSOG_class~.,data=d,mtry=2,ntree=ntr,sampsize=rep(min(table(d$LSOG_class)),nlevels(d$LSOG_class)),strata=d$LSOG_class)
rf_unb<-fit_unb(td); rf_wt<-fit_wt(td); rf_bal<-fit_bal(td)
ogrecall<-function(rf){cm<-rf$confusion[,1:K]; cm[og,og]/sum(cm[og,])}
overall<-function(rf) 1-rf$err.rate[ntr,1]

## ---- bootstrap 95% CI on OG recall for each strategy (refit on resamples, OOB recall) ----
B<-300
boot_recall<-function(fitfun){ out<-numeric(B)
  for(b in 1:B){ idx<-sample(nrow(td),replace=TRUE); d<-td[idx,]
    if(length(unique(d$LSOG_class))<K || sum(d$LSOG_class==og)<2){ out[b]<-NA; next }
    rf<-tryCatch(fitfun(d),error=function(e)NULL); out[b]<-if(is.null(rf)) NA else ogrecall(rf) }
  q<-quantile(out,c(.025,.975),na.rm=TRUE); c(lo=q[1],hi=q[2]) }
ci_unb<-boot_recall(fit_unb); ci_wt<-boot_recall(fit_wt); ci_bal<-boot_recall(fit_bal)
log("bootstrap done")

## ---- voting-threshold strategy: default RF, lower OG vote threshold ----
votes_og<-rf_unb$votes[,og]                       # OOB OG vote fraction
trueOG<-td$LSOG_class==og
thr_sweep<-rbindlist(lapply(c(0.5,0.3,0.2,0.1), function(t)
  data.table(og_threshold=t, OG_recall=round(mean(votes_og[trueOG]>=t),3),
             commission=round(mean(votes_og[!trueOG]>=t),3))))
log("OG vote-threshold sweep (default RF):"); print(thr_sweep)

## ---- wall-to-wall area under each strategy ----
SHP<-file.path(ZEN,"AOI_unzipped/AOI_LiDAR_stats.shp"); AC<-2.4710538
area_dt<-NULL
tryCatch({
  v<-terra::vect(SHP); att<-as.data.table(as.data.frame(v)); setnames(att,DBF,LID)
  cc<-complete.cases(att[,..LID]) & is.finite(rowSums(as.matrix(att[,..LID])))
  og_area<-function(rf){ p<-factor(rep(NA,nrow(att)),levels=levels(td$LSOG_class)); p[cc]<-predict(rf,att[cc,..LID]); 100*sum(p==og,na.rm=TRUE)/sum(!is.na(p)) }
  # threshold-based OG area from default RF probs at t
  pr<-matrix(NA,nrow(att),1); pr[cc,1]<-predict(rf_unb,att[cc,..LID],type="prob")[,og]
  og_area_t<-function(t) 100*sum(pr[,1]>=t,na.rm=TRUE)/sum(!is.na(pr[,1]))
  area_dt<-data.table(
    strategy=c("default","class-weighted","balanced subsample","threshold OG>=0.2","threshold OG>=0.1"),
    OG_area_pct=round(c(og_area(rf_unb),og_area(rf_wt),og_area(rf_bal),og_area_t(0.2),og_area_t(0.1)),2))
  log("wall-to-wall OG area %% by strategy:"); print(area_dt)
}, error=function(e) log("wall-to-wall skipped: %s", conditionMessage(e)))

## ---- headline table ----
res<-data.table(
  strategy=c("default (unbalanced)","class weighting (classwt)","balanced subsample (sampsize/strata)","threshold-adjusted (OG vote >= 0.2)"),
  OG_recall=round(c(ogrecall(rf_unb),ogrecall(rf_wt),ogrecall(rf_bal),mean(votes_og[trueOG]>=0.2)),3),
  OG_recall_lo=round(c(ci_unb[1],ci_wt[1],ci_bal[1],NA),3),
  OG_recall_hi=round(c(ci_unb[2],ci_wt[2],ci_bal[2],NA),3),
  overall_acc=round(c(overall(rf_unb),overall(rf_wt),overall(rf_bal),overall(rf_unb)),3))
if(!is.null(area_dt)) res[, OG_area_pct:=c(area_dt$OG_area_pct[1:3], area_dt$OG_area_pct[4])]
fwrite(res, file.path(OUT,"R1_rareclass_menu.csv")); fwrite(thr_sweep, file.path(OUT,"R2_threshold_sweep.csv"))
log("=== rare-class remedy menu (OG = rare event) ==="); print(res)
cat("PHASE 49 DONE\n")
