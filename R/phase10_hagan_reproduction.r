# =============================================================================
# Phase 10: Reproduce Hagan et al. (2026, Ecosphere) LSOG classification from the
# published Zenodo deposit (10.5281/zenodo.19696494) and run a TRUE plot-by-plot
# cross-validation of the v5.1 FIA proxy against Hagan's actual wall-to-wall
# LiDAR classification over the full Maine unorganized townships (UT) AOI.
#
# This replaces:
#   - Phase 6 (hagan_extract), which was scaffolded but blocked on Hagan's raster
#   - Phase 9, which only had the privately shared Seven Islands / Pingree subset
#     (~290 K ha, n = 125 in-extent plots)
#
# Inputs (staged on Cardinal):
#   - Training data:  ~/LSOG/data/zenodo_hagan/Maine_training_data.csv  (463 plots)
#   - AOI grid (8 LiDAR metrics for every hectare in the 4.2 M ha AOI):
#       ~/LSOG/data/zenodo_hagan/AOI_unzipped/AOI_LiDAR_stats.shp  (4,282,675 polys)
#   - v5.1 per-plot table: ~/LSOG/output_unified/lsog_ne_plot_table.csv
#
# Outputs: ~/LSOG/output_phase10/
# =============================================================================
suppressPackageStartupMessages({
  library(randomForest); library(terra); library(sf); library(data.table)
})
set.seed(20260609)  # RF is stochastic; fix seed for reproducibility

ZEN  <- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan"
SHP  <- file.path(ZEN, "AOI_unzipped/AOI_LiDAR_stats.shp")
TD   <- file.path(ZEN, "Maine_training_data.csv")
PLOTS<- "/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv"
OUT  <- "/users/PUOM0008/crsfaaron/LSOG/output_phase10"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
dir.create(file.path(OUT, "fig"), showWarnings = FALSE, recursive = TRUE)

LIDAR_COLS <- c("mean_cano_ht","max_cano_ht","percentile_95th","rumple",
                "top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
# dbf field order (truncated names) maps positionally to LIDAR_COLS after FID:
DBF_COLS   <- c("mn_cn_h","mx_cn_h","prcn_95","rumple",
                "tp_rgst","cn_cv_2","cn_cv_6","cn_c_15")

log <- function(...) cat(sprintf(...), "\n")

# -----------------------------------------------------------------------------
# PART A: Reproduce Hagan's randomForest classifier (faithful to Ecosphere_code.Rmd)
# -----------------------------------------------------------------------------
log("== PART A: reproduce randomForest ==")
td_full <- read.csv(TD)
td <- td_full[, c("LSOG_class", LIDAR_COLS)]
td$LSOG_class <- as.factor(td$LSOG_class)
log("Training records: %d   class counts:", nrow(td))
print(table(td$LSOG_class))

rf <- randomForest(LSOG_class ~ ., data = td, mtry = 2, ntree = 500,
                   proximity = FALSE, importance = TRUE)
print(rf)
saveRDS(rf, file.path(OUT, "hagan_rf_reproduced.rds"))

# OOB 4-class confusion + per-class accuracy
oob <- rf$confusion[, 1:4]
fwrite(data.table(class = rownames(oob), as.data.frame(oob)),
       file.path(OUT, "A_oob_confusion_4class.csv"))
oob_acc4 <- sum(diag(oob)) / sum(oob)
log("OOB overall 4-class accuracy: %.1f%%", 100 * oob_acc4)

# Binary Not-LSOG vs LSOG OOB accuracy (paper reports 94.1%)
is_lsog_true <- td$LSOG_class != "Not LS"
is_lsog_pred <- rf$predicted != "Not LS"
bin_acc <- mean(is_lsog_true == is_lsog_pred)
log("OOB binary Not-LSOG vs LSOG accuracy: %.1f%%  (paper: 94.1%%)", 100 * bin_acc)
bin_cm <- table(actual = ifelse(is_lsog_true, "LSOG", "Not LSOG"),
                predicted = ifelse(is_lsog_pred, "LSOG", "Not LSOG"))
fwrite(as.data.table(as.table(bin_cm)), file.path(OUT, "A_oob_confusion_binary.csv"))

# Variable importance (paper: cano_cover_15 highest MDA ~21.4%)
imp <- as.data.frame(importance(rf))
imp$metric <- rownames(imp)
imp <- imp[order(-imp$MeanDecreaseAccuracy), ]
fwrite(imp, file.path(OUT, "A_variable_importance.csv"))
log("Top metric by MeanDecreaseAccuracy: %s", imp$metric[1])

# -----------------------------------------------------------------------------
# PART B: Wall-to-wall prediction over the real 4.2 M ha AOI grid
# -----------------------------------------------------------------------------
log("== PART B: wall-to-wall prediction ==")
v <- terra::vect(SHP)
log("AOI polygons read: %d", nrow(v))
att <- as.data.frame(v)
# rename dbf metric cols -> training names (positional, FID is col 1)
stopifnot(all(DBF_COLS %in% names(att)))
setnames(att <- as.data.table(att), DBF_COLS, LIDAR_COLS)

complete <- complete.cases(att[, ..LIDAR_COLS]) &
            is.finite(rowSums(as.matrix(att[, ..LIDAR_COLS])))
log("Hectares with complete metrics: %d   incomplete/NA: %d",
    sum(complete), sum(!complete))

pred <- factor(rep(NA, nrow(att)), levels = levels(td$LSOG_class))
pred[complete] <- predict(rf, att[complete, ..LIDAR_COLS])
att[, hagan_pred := pred]

# Map to 4-level scheme consistent with v5.1
relabel <- c("Not LS" = "Not LSOG", "Trans LS" = "Transitioning LS",
             "LS" = "LS", "Old-growth" = "OGL")
att[, hagan_class := relabel[as.character(hagan_pred)]]

HA_PER_CELL <- 1.0  # each polygon = 1 hectare
AC_PER_HA   <- 2.4710538
area_tab <- att[!is.na(hagan_class), .(ha = .N * HA_PER_CELL), by = hagan_class]
area_tab[, acres := ha * AC_PER_HA]
tot_class <- sum(area_tab$ha)
area_tab[, pct := 100 * ha / tot_class]

# Published Table 7 (whole study area) for side-by-side
pub <- data.table(
  hagan_class = c("Not LSOG","Transitioning LS","LS","OGL"),
  pub_ha  = c(3361292, 662696, 124821, 37060),
  pub_pct = c(80.3, 15.8, 3.0, 0.9))
cmp <- merge(area_tab, pub, by = "hagan_class", all = TRUE)
setcolorder(cmp, c("hagan_class","ha","pct","pub_ha","pub_pct","acres"))
cmp <- cmp[match(c("Not LSOG","Transitioning LS","LS","OGL"), hagan_class)]
log("Reproduced wall-to-wall areas vs published Table 7:")
print(cmp)
lsog_ha  <- sum(area_tab[hagan_class != "Not LSOG", ha])
lsogl_ha <- sum(area_tab[hagan_class %in% c("LS","OGL"), ha])
log("Reproduced LS+OGL: %.0f ha (%.2f%%)   published: 161,881 ha (3.9%%)",
    lsogl_ha, 100 * lsogl_ha / tot_class)
fwrite(cmp, file.path(OUT, "B_walltowall_area_vs_published.csv"))
saveRDS(att[, .(FID = as.data.frame(v)[[1]], hagan_class)],
        file.path(OUT, "B_aoi_predicted_class_by_FID.rds"))

# -----------------------------------------------------------------------------
# PART C: True plot-by-plot cross-validation (v5.1 vs Hagan over full UT AOI)
# -----------------------------------------------------------------------------
log("== PART C: cross-validation v5.1 vs Hagan over full UT AOI ==")
# rasterize predicted class to 100 m, extract at FIA plot points
code_map <- c("Not LSOG" = 1L, "Transitioning LS" = 2L, "LS" = 3L, "OGL" = 4L)
v$hagan_code <- code_map[att$hagan_class]
templ <- terra::rast(v, resolution = 100)
rcl   <- terra::rasterize(v, templ, field = "hagan_code")
terra::writeRaster(rcl, file.path(OUT, "C_hagan_class_100m.tif"),
                   overwrite = TRUE, datatype = "INT1U")

dt <- fread(PLOTS, colClasses = list(character = "CN"))
me <- dt[state == "ME"]
pts <- sf::st_as_sf(me, coords = c("LON","LAT"), crs = 4326)
pts <- sf::st_transform(pts, terra::crs(v))
me[, hagan_code := terra::extract(rcl, terra::vect(pts))[, 2]]
hagan_lab <- c("1"="Not LSOG","2"="Transitioning LS","3"="LS","4"="OGL")
me[, hagan_class := hagan_lab[as.character(hagan_code)]]
me[, in_aoi := !is.na(hagan_code)]
log("ME plots total: %d   inside Hagan AOI (UT): %d", nrow(me), sum(me$in_aoi))

fwrite(me[, .(CN, eval_period, LAT, LON, STDAGE, v4_class, v5_class,
              v5_total, potapov_rh95, hagan_code, hagan_class, in_aoi)],
       file.path(OUT, "C_me_plots_hagan_full_AOI.csv"))

v5_levels <- c("Not LSOG","Transitioning LS","LS","OG")
hg_levels <- c("Not LSOG","Transitioning LS","LS","OGL")

cohen_kappa <- function(tab){
  tab <- as.matrix(tab); n <- sum(tab)
  po <- sum(diag(tab)) / n
  pe <- sum(rowSums(tab) * colSums(tab)) / n^2
  (po - pe) / (1 - pe)
}

run_panel <- function(panel_lab, sub){
  sub <- sub[in_aoi == TRUE]
  n <- nrow(sub)
  cm <- table(factor(sub$v5_class, levels = v5_levels),
              factor(sub$hagan_class, levels = hg_levels))
  fwrite(as.data.table(as.table(cm)),
         file.path(OUT, sprintf("C_confusion_v5_%s.csv", panel_lab)))
  # collapsed binaries
  k_any <- cohen_kappa(table(sub$v5_class != "Not LSOG",
                             sub$hagan_class != "Not LSOG"))
  k_lsog<- cohen_kappa(table(sub$v5_class %in% c("LS","OG"),
                             sub$hagan_class %in% c("LS","OGL")))
  shares <- data.table(
    panel = panel_lab, n = n,
    v51_any = 100*mean(sub$v5_class != "Not LSOG"),
    hagan_any = 100*mean(sub$hagan_class != "Not LSOG"),
    v51_lsog = 100*mean(sub$v5_class %in% c("LS","OG")),
    hagan_lsog = 100*mean(sub$hagan_class %in% c("LS","OGL")),
    v51_og = 100*mean(sub$v5_class == "OG"),
    hagan_og = 100*mean(sub$hagan_class == "OGL"),
    kappa_any = k_any, kappa_lsog = k_lsog)
  log("[%s] n=%d  v5.1 any=%.1f%% Hagan any=%.1f%%  kappa_any=%.3f kappa_LSOG=%.3f",
      panel_lab, n, shares$v51_any, shares$hagan_any, k_any, k_lsog)
  print(addmargins(cm))
  shares
}

sh_latest <- run_panel("2019-2023", me[eval_period == "2019-2023"])
sh_all    <- run_panel("all_panels", me)
fwrite(rbindlist(list(sh_latest, sh_all)),
       file.path(OUT, "C_share_and_kappa_summary.csv"))

# -----------------------------------------------------------------------------
# Figures (full-res + thumbnail)
# -----------------------------------------------------------------------------
log("== figures ==")
mk <- function(file, w, h, fn){
  png(file.path(OUT, "fig", file), width=w, height=h, res=150); fn(); dev.off()
  png(file.path(OUT, "fig", sub("\\.png$","_thumb.png",file)),
      width=round(w*0.5), height=round(h*0.5), res=72); fn(); dev.off()
}
# B: reproduced vs published areas
mk("B_area_compare.png", 1500, 1000, function(){
  m <- t(as.matrix(cmp[, .(ha, pub_ha)]))/1000
  colnames(m) <- cmp$hagan_class
  barplot(m, beside=TRUE, col=c("#2c7fb8","#a6bddb"), las=1,
          ylab="Thousand hectares", main="Wall-to-wall area: reproduced vs published (Hagan Table 7)")
  legend("topright", c("Reproduced (Phase 10)","Published"), fill=c("#2c7fb8","#a6bddb"), bty="n")
})
# A: variable importance
mk("A_varimp.png", 1200, 1000, function(){
  ii <- imp[order(imp$MeanDecreaseAccuracy), ]
  par(mar=c(5,9,3,2))
  barplot(ii$MeanDecreaseAccuracy, names.arg=ii$metric, horiz=TRUE, las=1,
          col="#41ab5d", xlab="Mean decrease in accuracy",
          main="Hagan RF variable importance (reproduced)")
})
log("DONE Phase 10.")
