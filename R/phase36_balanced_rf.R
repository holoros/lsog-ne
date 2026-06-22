# =============================================================================
# Phase 36: does class balancing change Hagan's classifier? A random forest on
# imbalanced data attenuates the rare class (here, old growth). We refit the
# reproduced Hagan RF with balanced bootstrap sampling and compare (a) rare-class
# operating accuracy and (b) the wall-to-wall LSOG/OG area against the unbalanced
# original. Framed as a sensitivity to the algorithm, not an accusation.
# Output: ~/LSOG/output_phase36/
# =============================================================================
suppressPackageStartupMessages({ library(randomForest); library(terra); library(data.table) })
set.seed(20260613)
ZEN <- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan"
TD  <- file.path(ZEN, "Maine_training_data.csv")
SHP <- file.path(ZEN, "AOI_unzipped/AOI_LiDAR_stats.shp")
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase36"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...), "\n")
LID <- c("mean_cano_ht","max_cano_ht","percentile_95th","rumple","top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
DBF <- c("mn_cn_h","mx_cn_h","prcn_95","rumple","tp_rgst","cn_cv_2","cn_cv_6","cn_c_15")

td <- read.csv(TD); td <- td[, c("LSOG_class", LID)]; td$LSOG_class <- as.factor(td$LSOG_class)
log("class counts:"); print(table(td$LSOG_class))
nmin <- min(table(td$LSOG_class))

## unbalanced (as published) vs balanced (per-tree downsample to rare class)
rf_unb <- randomForest(LSOG_class ~ ., data=td, mtry=2, ntree=500)
rf_bal <- randomForest(LSOG_class ~ ., data=td, mtry=2, ntree=500,
                       sampsize=rep(nmin, nlevels(td$LSOG_class)), strata=td$LSOG_class)
## also a class-weighted variant (inverse frequency)
w <- max(table(td$LSOG_class))/table(td$LSOG_class)
rf_wt <- randomForest(LSOG_class ~ ., data=td, mtry=2, ntree=500, classwt=as.numeric(w))

og_lab <- levels(td$LSOG_class)[grep("rowth|OG", levels(td$LSOG_class))][1]
opacc <- function(rf, lab){ cm<-rf$confusion[,1:4]; cm[lab,lab]/sum(cm[lab,]) }
res <- data.table(
  model=c("unbalanced","balanced (downsample)","class-weighted"),
  oob_overall=round(c(1-rf_unb$err.rate[500,1],1-rf_bal$err.rate[500,1],1-rf_wt$err.rate[500,1]),3),
  OG_operating_acc=round(c(opacc(rf_unb,og_lab),opacc(rf_bal,og_lab),opacc(rf_wt,og_lab)),3))
log("OG operating accuracy (sensitivity to the rare class):"); print(res)
fwrite(res, file.path(OUT,"P1_operating_accuracy.csv"))  # write headline first

## wall-to-wall area under each model (unzip AOI grid if needed; guard so P1 is safe)
area_dt <- NULL
tryCatch({
  if (!file.exists(SHP)) {
    z <- file.path(ZEN, "AOI_LiDAR_stats.zip")
    ud <- file.path(ZEN, "AOI_unzipped"); dir.create(ud, showWarnings=FALSE)
    system2("unzip", c("-o", shQuote(z), "-d", shQuote(ud)), stdout=FALSE)
    cand <- list.files(ud, pattern="\\.shp$", recursive=TRUE, full.names=TRUE)
    if (length(cand)) SHP <- cand[1]
  }
v <- terra::vect(SHP); att <- as.data.table(as.data.frame(v))
setnames(att, DBF, LID)
cc <- complete.cases(att[, ..LID]) & is.finite(rowSums(as.matrix(att[, ..LID])))
AC <- 2.4710538
area_of <- function(rf){
  p <- factor(rep(NA,nrow(att)), levels=levels(td$LSOG_class))
  p[cc] <- predict(rf, att[cc, ..LID])
  tab <- table(p); tot <- sum(tab)
  lsog <- 100*sum(tab[names(tab)!="Not LS"])/tot
  lsogl<- 100*sum(tab[names(tab) %in% c("LS",og_lab)])/tot
  og   <- 100*tab[og_lab]/tot
  c(any_lsog_pct=lsog, ls_og_pct=lsogl, og_pct=og, og_acres=as.numeric(tab[og_lab])*AC)
}
A <- rbind(unbalanced=area_of(rf_unb), balanced=area_of(rf_bal), weighted=area_of(rf_wt))
area_dt <- data.table(model=rownames(A), as.data.table(round(A,3)))
log("Wall-to-wall area under each model (published any-LSOG ~19.7%%, LS+OGL 3.9%%, OG 0.9%%):")
print(area_dt)
fwrite(area_dt, file.path(OUT,"P2_walltowall_area_by_model.csv"))
}, error=function(e) log("wall-to-wall skipped: %s", conditionMessage(e)))
cat("PHASE 36 DONE\n")
