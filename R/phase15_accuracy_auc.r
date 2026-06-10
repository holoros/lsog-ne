# =============================================================================
# Phase 15: Accuracy assessment on Hagan et al.'s OWN training data.
# Tests how well competing predictor sets recover the field-assigned LSOG class,
# with cross-validated AUC and bootstrap/CV confidence intervals.
#
# Data: Maine_training_data.csv (463 plots) from the Hagan Zenodo deposit:
#   field class (Not LS / Trans LS / LS / Old-growth) +
#   8 LiDAR canopy metrics (Hagan's approach) +
#   ground structural metrics (live/dead BA, BA>=40cm, QMD, CWD, CV dbh).
#
# Predictor sets:
#   LIDAR8  : Hagan's 8 canopy metrics (their published approach)
#   HEIGHT  : the 3 canopy-height metrics only (spaceborne GEDI/Potapov analog)
#   STRUCT  : ground structural metrics (what actually defines old growth)
#
# Targets (binary): any-LSOG, LS+OG (policy class), OG (the high-value class)
#
# Also: can the 8 LiDAR metrics even predict the structural variables that
# define old growth (large-tree BA, coarse woody debris)? If not, canopy LiDAR
# is structurally blind to the defining features of OG.
#
# Outputs: ~/LSOG/output_phase15/
# =============================================================================
suppressPackageStartupMessages({ library(randomForest); library(data.table) })
ZEN <- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan/Maine_training_data.csv"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase15"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")

d <- as.data.table(read.csv(ZEN))
log("plots: %d", nrow(d)); print(table(d$LSOG_class))
LIDAR8 <- c("mean_cano_ht","max_cano_ht","percentile_95th","rumple","top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
HEIGHT <- c("mean_cano_ht","max_cano_ht","percentile_95th")
STRUCT <- c("sum_live_basalarea","sum_dead_basalarea","basal_GE_40cmDBH","prop_basal_GE_40cmDBH","No_treesGE_40cmdbh","QMD_live","CWD_vol","CV_livedbh")
# median-impute predictor columns (di); keep raw d for targets / R2 responses
di <- copy(d)
for(cc in unique(c(LIDAR8,STRUCT))){ di[[cc]] <- as.numeric(di[[cc]]); m<-median(di[[cc]],na.rm=TRUE); di[[cc]][is.na(di[[cc]])]<-m
  log("  %-20s NA imputed: %d", cc, sum(is.na(d[[cc]]))) }

auc <- function(y, p){ # y logical, p numeric score
  n1<-sum(y); n0<-sum(!y); if(n1==0||n0==0) return(NA_real_)
  r<-rank(p); (sum(r[y]) - n1*(n1+1)/2)/(n1*n0) }

# repeated stratified k-fold CV AUC
cv_auc <- function(X, y, reps=40, k=5, seed=1){
  set.seed(seed); out<-numeric(0)
  yf<-factor(ifelse(y,"pos","neg"))
  for(r in 1:reps){
    # stratified folds
    fold<-integer(length(y))
    for(lv in c(TRUE,FALSE)){ idx<-which(y==lv); fold[idx]<-sample(rep(1:k,length.out=length(idx))) }
    oof<-rep(NA_real_,length(y))
    for(f in 1:k){
      tr<-fold!=f; te<-fold==f
      if(length(unique(y[tr]))<2) next
      m<-randomForest(x=X[tr,,drop=FALSE], y=yf[tr], ntree=300)
      oof[te]<-predict(m, X[te,,drop=FALSE], type="prob")[,"pos"]
    }
    ok<-!is.na(oof); out<-c(out, auc(y[ok], oof[ok]))
  }
  out
}

targets <- list(
  "any-LSOG"=function(d) d$LSOG_class!="Not LS",
  "LS+OG"   =function(d) d$LSOG_class %in% c("LS","Old-growth"),
  "OG"      =function(d) d$LSOG_class=="Old-growth")
sets <- list(LIDAR8=LIDAR8, HEIGHT=HEIGHT, STRUCT=STRUCT)

res <- list(); i<-1
for(tn in names(targets)){ y<-targets[[tn]](d)
  for(sn in names(sets)){
    X<-as.data.frame(di[, sets[[sn]], with=FALSE])
    a<-cv_auc(X, y, reps=40, k=5, seed=42)
    res[[i]]<-data.table(target=tn, predictors=sn, prevalence=round(mean(y),3),
      auc_mean=round(mean(a,na.rm=TRUE),3), auc_lo=round(quantile(a,.025,na.rm=TRUE),3),
      auc_hi=round(quantile(a,.975,na.rm=TRUE),3)); i<-i+1
    log("[%s | %-7s] AUC %.3f [%.3f, %.3f]", tn, sn, mean(a,na.rm=TRUE), quantile(a,.025,na.rm=TRUE), quantile(a,.975,na.rm=TRUE))
  }}
restab<-rbindlist(res); fwrite(restab, file.path(OUT,"T1_cv_auc_by_approach.csv"))

# Can canopy LiDAR predict the structural OG-defining variables? (CV R2)
cv_r2 <- function(X,y,reps=20,k=5,seed=7){ set.seed(seed); o<-numeric(0)
  for(r in 1:reps){ fold<-sample(rep(1:k,length.out=length(y))); pred<-rep(NA_real_,length(y))
    for(f in 1:k){ tr<-fold!=f; m<-randomForest(x=X[tr,,drop=FALSE], y=y[tr], ntree=300); pred[fold==f]<-predict(m,X[fold==f,,drop=FALSE]) }
    o<-c(o, 1 - sum((y-pred)^2)/sum((y-mean(y))^2)) }; o }
Xl_full<-as.data.frame(di[,LIDAR8,with=FALSE])
struct_pred <- rbindlist(lapply(c("basal_GE_40cmDBH","No_treesGE_40cmdbh","CWD_vol","sum_dead_basalarea","CV_livedbh"), function(v){
  yv<-as.numeric(d[[v]]); keep<-!is.na(yv)
  r2<-cv_r2(Xl_full[keep,,drop=FALSE], yv[keep]); data.table(structural_var=v, n=sum(keep), cv_R2_from_LiDAR=round(mean(r2),3),
    lo=round(quantile(r2,.1),3), hi=round(quantile(r2,.9),3)) }))
fwrite(struct_pred, file.path(OUT,"T2_lidar_predicts_structure_R2.csv"))
log("== Can 8 LiDAR metrics predict OG-defining structure? (CV R2) =="); print(struct_pred)

# Variable importance for OG using ALL variables (which features actually flag OG)
set.seed(1); Xall<-as.data.frame(d[, c(LIDAR8,STRUCT), with=FALSE])
rf_og<-randomForest(x=Xall, y=factor(ifelse(d$LSOG_class=="Old-growth","OG","not")), ntree=1000, importance=TRUE)
imp<-as.data.table(importance(rf_og), keep.rownames="variable")[order(-MeanDecreaseAccuracy)]
imp[, set := ifelse(variable %in% LIDAR8, "LiDAR canopy","ground structure")]
fwrite(imp[,.(variable,set,MeanDecreaseAccuracy=round(MeanDecreaseAccuracy,2))], file.path(OUT,"T3_OG_variable_importance.csv"))
log("== Top OG discriminators =="); print(head(imp[,.(variable,set,MeanDecreaseAccuracy=round(MeanDecreaseAccuracy,2))],8))
log("DONE Phase 15.")
