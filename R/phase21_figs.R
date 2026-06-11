# =============================================================================
# Phase 21: expansion figures for the Ecosphere Comment.
#  (1) per-pixel multi-method ENSEMBLE LSOG probability + UNCERTAINTY rasters
#  (2) hex maps: ensemble probability, uncertainty (two-panel) + bivariate
#  (3) RF out-of-bag CONFUSION MATRIX (4-class) heatmap
#  (4) probability-threshold SENSITIVITY (mapped area + accuracy vs cutoff)
#  (5) TEMPORAL panel: FIA age>=120, FIA large-tree BA, TreeMap LSOG over time
# R-first, GSEA palette, save full-res + small thumbnails. Outputs: output_phase21/
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(sf); library(data.table)
  library(ggplot2); library(ggsci); library(patchwork); library(scales); library(randomForest)
})
PAY <- "/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/zenodo_upload/payload"
NEW <- "/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/v1_2_newfiles"
TRAIN <- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan/Maine_training_data.csv"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase21"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
gsea <- pal_gsea()(12)
th <- theme_minimal(base_size=11) + theme(
  panel.grid=element_blank(), axis.text=element_blank(), axis.title=element_blank(),
  plot.title=element_text(face="bold", size=11), legend.position="right",
  legend.key.width=unit(0.35,"cm"), plot.background=element_rect(fill="white",color=NA))
thumb <- function(p, file, w=4.2, h=4.2){ ggsave(file.path(OUT,file), p, width=w, height=h, dpi=300)
  ggsave(file.path(OUT, sub("\\.png$","_thumb.jpg",file)), p, width=w, height=h, dpi=70) }

# ---- (1) per-pixel ensemble probability + uncertainty -----------------------
m1 <- rast(file.path(PAY,"M1_hagan_class_100m.tif"))
m2 <- rast(file.path(PAY,"M2_v51gedi_pLSOG_100m.tif"))
m4 <- rast(file.path(PAY,"M4_treemap_class_100m.tif"))
m2 <- resample(m2, m1, method="bilinear"); m4 <- resample(m4, m1, method="near")
b1 <- (m1 >= 2);  b4 <- (m4 >= 2)               # any-LSOG membership (class 2,3,4)
memb <- c(b1, m2, b4)                            # three membership scores in [0,1]
ens_prob <- app(memb, mean, na.rm=TRUE)
ens_unc  <- app(memb, sd,   na.rm=TRUE)          # cross-method SD = per-pixel uncertainty
names(ens_prob)<-"ensemble_prob"; names(ens_unc)<-"ensemble_uncertainty"
writeRaster(ens_prob, file.path(OUT,"ENSEMBLE_prob_100m.tif"), overwrite=TRUE)
writeRaster(ens_unc,  file.path(OUT,"ENSEMBLE_uncertainty_100m.tif"), overwrite=TRUE)
# summary: share of flagged area by uncertainty tercile
pv <- values(ens_prob); uv <- values(ens_unc); ok <- !is.na(pv) & !is.na(uv)
flag <- ok & pv>0
es <- data.table(prob=pv[flag], unc=uv[flag])
es[, ut := cut(unc, quantile(unc, c(0,1/3,2/3,1)), include.lowest=TRUE, labels=c("low","med","high"))]
fwrite(es[, .(n=.N, mean_prob=round(mean(prob),3)), by=ut][order(ut)], file.path(OUT,"E1_ensemble_uncertainty_terciles.csv"))

# ---- (2) hex maps from existing hex fractions -------------------------------
hx <- st_read(file.path(NEW,"hex_lsog_by_method.gpkg"), quiet=TRUE)
hx$ens  <- rowMeans(st_drop_geometry(hx)[,c("hagan","gedi","treemap")], na.rm=TRUE)
hx$unc  <- apply(st_drop_geometry(hx)[,c("hagan","gedi","treemap")], 1, sd, na.rm=TRUE)
fwrite(data.table(metric=c("hex ensemble agreement score","hex uncertainty (SD across methods)","hex disagreement (max-min)"),
  mean=round(c(mean(hx$ens,na.rm=TRUE),mean(hx$unc,na.rm=TRUE),mean(hx$disagree,na.rm=TRUE)),3),
  median=round(c(median(hx$ens,na.rm=TRUE),median(hx$unc,na.rm=TRUE),median(hx$disagree,na.rm=TRUE)),3),
  iqr=round(c(IQR(hx$ens,na.rm=TRUE),IQR(hx$unc,na.rm=TRUE),IQR(hx$disagree,na.rm=TRUE)),3),
  p90=round(c(quantile(hx$ens,.9,na.rm=TRUE),quantile(hx$unc,.9,na.rm=TRUE),quantile(hx$disagree,.9,na.rm=TRUE)),3)),
  file.path(OUT,"E5_hex_variation.csv"))
p_prob <- ggplot(hx) + geom_sf(aes(fill=ens), color=NA) +
  scale_fill_gsea(name="agreement\nscore (0-1)", limits=c(0,1), oob=squish) +
  labs(title="(a) Multi-method ensemble LSOG agreement score") + th
p_unc <- ggplot(hx) + geom_sf(aes(fill=unc), color=NA) +
  scale_fill_gsea(name="uncertainty\n(SD across\nmethods)") +
  labs(title="(b) Ensemble uncertainty layer") + th
thumb(p_prob/p_unc + plot_layout(ncol=1), "Fig_ensemble_hex.png", w=4.6, h=8)
# bivariate (manual 3x3): probability x uncertainty
q3 <- function(x) cut(x, quantile(x, c(0,1/3,2/3,1), na.rm=TRUE), include.lowest=TRUE, labels=1:3)
hx$bx <- q3(hx$ens); hx$by <- q3(hx$unc)
hx$bi <- paste0(hx$bx,"-",hx$by)
bipal <- c("1-1"="#e8e8e8","2-1"="#ace4e4","3-1"="#5ac8c8",
           "1-2"="#dfb0d6","2-2"="#a5add3","3-2"="#5698b9",
           "1-3"="#be64ac","2-3"="#8c62aa","3-3"="#3b4994")
p_bi <- ggplot(hx[!is.na(hx$bi),]) + geom_sf(aes(fill=bi), color=NA) +
  scale_fill_manual(values=bipal, guide="none") +
  labs(title="(c) Bivariate: agreement (x) by uncertainty (y); tercile breaks") + th
leg <- expand.grid(x=1:3,y=1:3); leg$bi<-paste0(leg$x,"-",leg$y)
p_leg <- ggplot(leg, aes(x,y,fill=bi)) + geom_tile() + scale_fill_manual(values=bipal,guide="none") +
  labs(x="agreement score →", y="uncertainty →") +
  theme_minimal(base_size=8) + theme(axis.text=element_blank(), panel.grid=element_blank(),
  axis.title=element_text(size=7), aspect.ratio=1, plot.background=element_rect(fill="white",color=NA))
thumb(p_bi + inset_element(p_leg, left=0.0, bottom=0.0, right=0.34, top=0.34), "Fig_ensemble_bivariate.png", w=4.6, h=4.6)

# ---- (3) RF OOB confusion matrix (4-class) ----------------------------------
d <- fread(TRAIN); setDF(d)
lidar <- c("mean_cano_ht","max_cano_ht","percentile_95th","rumple","top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
d$LSOG_class <- factor(d$LSOG_class)
set.seed(1); rf <- randomForest(x=d[,lidar], y=d$LSOG_class, ntree=500, mtry=2)
cm <- rf$confusion[, levels(d$LSOG_class), drop=FALSE]
cmn <- sweep(cm, 1, rowSums(cm), "/")            # row-normalized (producer)
cdt <- as.data.table(as.table(as.matrix(cmn))); setnames(cdt, c("True","Predicted","prop"))
cnt <- as.data.table(as.table(as.matrix(cm)));  setnames(cnt, c("True","Predicted","n"))
cdt <- merge(cdt, cnt, by=c("True","Predicted"))
ord <- levels(d$LSOG_class)
cdt[, True:=factor(True, levels=rev(ord))]; cdt[, Predicted:=factor(Predicted, levels=ord)]
p_cm <- ggplot(cdt, aes(Predicted, True, fill=prop)) + geom_tile(color="white") +
  geom_text(aes(label=ifelse(n>0, sprintf("%.0f%%\n(%d)", 100*prop, n), "")), size=3) +
  scale_fill_gsea(name="row %", limits=c(0,1), labels=percent) +
  labs(title="Out-of-bag confusion matrix (LiDAR random forest)", x="Predicted class", y="True (field) class") +
  theme_minimal(base_size=11) + theme(panel.grid=element_blank(), plot.background=element_rect(fill="white",color=NA),
  axis.text.x=element_text(angle=20,hjust=1))
thumb(p_cm, "Fig_confusion.png", w=6, h=4.8)
fwrite(cbind(True=rownames(cm), as.data.table(cm)), file.path(OUT,"E2_confusion_counts.csv"))

# ---- (4) probability-threshold sensitivity ---------------------------------
d$bin <- factor(ifelse(d$LSOG_class=="Not LSOG" | d$LSOG_class=="NotLSOG" | d$LSOG_class=="Not_LSOG","No","Yes"))
if(length(levels(d$bin))<2){ d$bin <- factor(ifelse(as.integer(d$LSOG_class)==1,"No","Yes")) }
set.seed(1); rfb <- randomForest(x=d[,lidar], y=d$bin, ntree=500, mtry=2)
pv2 <- predict(rfb, type="prob")[,"Yes"]; truth <- d$bin=="Yes"
cut <- seq(0.1,0.9,0.05)
sens <- rbindlist(lapply(cut, function(k){ pp<-pv2>=k
  data.table(cutoff=k, mapped_pos_rate=mean(pp),
    sensitivity=sum(pp&truth)/sum(truth), specificity=sum(!pp&!truth)/sum(!truth),
    accuracy=mean(pp==truth)) }))
sens[, TSS := sensitivity+specificity-1]
fwrite(sens, file.path(OUT,"E3_threshold_sensitivity.csv"))
# threshold-independent rank ability: ROC AUC (Mann-Whitney) with bootstrap 95% CI
auc_fun <- function(p, y){ r<-rank(p); (sum(r[y]) - sum(y)*(sum(y)+1)/2)/(sum(y)*sum(!y)) }
auc <- auc_fun(pv2, truth)
set.seed(7); bsa <- replicate(2000, { i<-sample(length(truth), replace=TRUE); auc_fun(pv2[i], truth[i]) })
auc_lo <- quantile(bsa, .025); auc_hi <- quantile(bsa, .975)
fwrite(data.table(metric="OOB ROC AUC (any-LSOG)", auc=round(auc,3), lo=round(auc_lo,3), hi=round(auc_hi,3)),
       file.path(OUT,"E4_binary_auc.csv"))
sl <- melt(sens, id.vars="cutoff", measure.vars=c("mapped_pos_rate","accuracy","TSS"))
p_thr <- ggplot(sl, aes(cutoff, value, color=variable)) + geom_line(linewidth=0.9) + geom_point(size=1.6) +
  scale_color_npg(name=NULL, labels=c("mapped LSOG fraction","overall accuracy","TSS")) +
  scale_x_continuous(breaks=seq(0.1,0.9,0.2)) + ylim(0,1) +
  labs(title="Sensitivity of mapped LSOG to the probability cutoff",
       subtitle=sprintf("Threshold-independent rank ability is high (ROC AUC = %.3f [%.3f, %.3f]); accuracy, TSS and mapped extent still depend on the cutoff", auc, auc_lo, auc_hi),
       x="random forest probability cutoff for calling LSOG", y="value (on labelled plots)") +
  theme_minimal(base_size=11) + theme(plot.background=element_rect(fill="white",color=NA), legend.position="top",
    plot.subtitle=element_text(size=8.5,color="grey35"))
thumb(p_thr, "Fig_threshold.png", w=6.2, h=4.4)
cat(sprintf("OOB ROC AUC any-LSOG = %.3f [%.3f, %.3f]\n", auc, auc_lo, auc_hi))

# ---- (5) temporal panel: FIA age120 + large-tree BA + TreeMap over time -----
tr <- fread(file.path(NEW,"T1_designbased_oldforest_trend.csv"))
trs <- tr[region=="statewide" & domain %in% c("Stand age >= 120 yr","Large-tree BA >= 30 ft2/ac (>=16in)")]
trs[, dom := ifelse(grepl("age", domain), "FIA stand age ≥ 120 yr", "FIA large-tree basal area")]
tm <- fread(file.path(PAY,"T1_treemap_lsog_timeseries.csv"))
pA <- ggplot(trs[grepl("age",domain)], aes(YEAR, area_perc)) +
  geom_ribbon(aes(ymin=perc_lo,ymax=perc_hi), fill="#3b4994", alpha=0.18) +
  geom_line(color="#3b4994",linewidth=0.9) + geom_point(color="#3b4994",size=1.3) +
  labs(title="(a) FIA design-based: stand age ≥ 120 yr", subtitle="age is modeled in FIADB; shown for comparison",
       x="inventory year", y="% of forestland") + theme_minimal(base_size=10) +
  theme(plot.background=element_rect(fill="white",color=NA), plot.subtitle=element_text(size=8,color="grey40"))
pB <- ggplot(trs[grepl("BA",domain)], aes(YEAR, area_perc)) +
  geom_ribbon(aes(ymin=perc_lo,ymax=perc_hi), fill="#1B9E9E", alpha=0.18) +
  geom_line(color="#1B9E9E",linewidth=0.9) + geom_point(color="#1B9E9E",size=1.3) +
  labs(title="(b) FIA design-based: large-tree basal area (≥16 in)", subtitle="structural, directly measured",
       x="inventory year", y="% of forestland") + theme_minimal(base_size=10) +
  theme(plot.background=element_rect(fill="white",color=NA), plot.subtitle=element_text(size=8,color="grey40"))
pC <- ggplot(tm, aes(year, any_LSOG_pct)) + geom_line(color="#E15554",linewidth=0.9) +
  geom_point(color="#E15554",size=2) +
  labs(title="(c) TreeMap-imputed LSOG classification", subtitle="reproducible LSOG-class map over time (proxy for the mapped class)",
       x="TreeMap year", y="any-LSOG % (known cells)") + theme_minimal(base_size=10) +
  theme(plot.background=element_rect(fill="white",color=NA), plot.subtitle=element_text(size=8,color="grey40"))
thumb(pA/pB/pC, "Fig_temporal_panel.png", w=5.2, h=8.4)

# ---- (6) LSOG/older-forest over time under different definitions and thresholds ----
trd <- fread(file.path(NEW,"T1_designbased_oldforest_trend.csv"))[region=="statewide"]
trd[, dl := fcase(grepl("100",domain),"age >= 100 yr", grepl("120",domain),"age >= 120 yr",
                  grepl("150",domain),"age >= 150 yr", grepl("BA",domain),"large-tree BA >= 30 ft2/ac",
                  default=domain)]
trd[, dl := factor(dl, levels=c("age >= 100 yr","large-tree BA >= 30 ft2/ac","age >= 120 yr","age >= 150 yr"))]
p_tt <- ggplot(trd, aes(YEAR, area_perc, color=dl, fill=dl)) +
  geom_ribbon(aes(ymin=perc_lo,ymax=perc_hi), alpha=0.10, color=NA) +
  geom_line(linewidth=0.9) +
  scale_color_d3(name=NULL) + scale_fill_d3(name=NULL) +
  labs(title="Older forest over time under different definitions and thresholds",
       subtitle="Maine, FIA design-based. The level depends on the criterion; the increasing direction does not.",
       x="inventory year", y="% of forestland") +
  theme_minimal(base_size=10) + theme(legend.position="top",
    plot.background=element_rect(fill="white",color=NA), plot.subtitle=element_text(size=8.5,color="grey35"))
thumb(p_tt, "Fig_temporal_thresholds.png", w=6.6, h=4.4)

cat("PHASE 21 DONE\n"); cat("ensemble flagged px terciles written; confusion + threshold + temporal done\n")
print(sens[, .(cutoff, mapped_pos_rate=round(mapped_pos_rate,3), accuracy=round(accuracy,3), TSS=round(TSS,3))])
cat("OOB binary err:", round(100*mean(predict(rfb)!=d$bin),2), "%\n")
