# =============================================================================
# Phase 6 Seven Islands: wall-to-wall v5.1-spatial probability raster (Cardinal).
#
# Approach
#   - Stage two 100m rasters over the Pingree AOI (already done by gdalwarp):
#       Potapov_RH95_seven_islands_100m.tif   (continuous canopy height, m)
#       ORNL_strata_seven_islands_100m.tif    (categorical strata, 1..4 from ORNL DAAC 2498)
#   - At every FIA plot in the Maine training set, extract the strata raster value
#     and look up the mean continuous ornl_p_mature / ornl_p_oldgrowth for plots
#     in that strata class.  This produces a cell-level surrogate for the
#     continuous probability bands when only the strata raster is staged.
#   - Refit a logit:    y ~ potapov_rh95 + ornl_p_mature + ornl_p_oldgrowth
#     using the actual continuous probabilities at the plots, where y =
#     v5_class %in% c("Transitioning LS","LS","OG").
#   - For wall-to-wall prediction, replace the continuous bands with the
#     strata-class means and apply the fitted model.
#   - Mask to the Hagan footprint (NoData = 15).  Classify into 4 classes
#     using thresholds anchored on FIA training prevalence.
#
# Outputs (in ~/LSOG/output_phase6/):
#   SevenIslands_pLSOG_v51spatial_100m.tif   continuous p_LSOG, 0..1
#   SevenIslands_class_v51spatial_100m.tif   4-class (Not LSOG / Trans LS / LS / OG)
#   spatial_logit_coefs.csv                  glm coefficients
#   spatial_logit_metrics.csv                AUC, n_train, prevalence, strata table
#   strata_class_means.csv                   mean p_mature, p_oldgrowth per strata
#
# Author: A. Weiskittel + Cowork agent, May 2026
# =============================================================================
suppressPackageStartupMessages({
  library(terra)
  library(data.table)
  library(pROC)
  library(broom)
})

# ---- CONFIG ------------------------------------------------------------------
LSOG  <- "/users/PUOM0008/crsfaaron/LSOG"
HAGAN <- "/users/PUOM0008/crsfaaron/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
PLOTS <- file.path(LSOG, "output_unified/lsog_ne_plot_table.csv")
OUT   <- file.path(LSOG, "output_phase6")
POT   <- file.path(OUT,  "Potapov_RH95_seven_islands_100m.tif")
STR   <- file.path(OUT,  "ORNL_strata_seven_islands_100m.tif")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Train spatial logit at FIA plots -------------------------------------
plt <- fread(PLOTS, colClasses = list(character = "CN"))
plt <- plt[state == "ME" & !is.na(potapov_rh95) & !is.na(ornl_p_mature)]
plt[, y := as.integer(v5_class %in% c("Transitioning LS","LS","OG"))]

fit <- glm(y ~ potapov_rh95 + ornl_p_mature + ornl_p_oldgrowth,
           data = plt, family = binomial())
cat("\n==== Spatial logit summary ====\n")
print(summary(fit))

roc1 <- pROC::roc(plt$y, predict(fit, type = "response"), quiet = TRUE)
metrics <- data.table(auc = round(as.numeric(roc1$auc), 4),
                      n_train = nobs(fit),
                      prevalence_y = round(mean(plt$y), 4))
fwrite(metrics, file.path(OUT, "spatial_logit_metrics.csv"))
fwrite(broom::tidy(fit), file.path(OUT, "spatial_logit_coefs.csv"))

cat(sprintf("\nAUC: %.3f  (n = %d, prevalence = %.3f)\n",
            metrics$auc, metrics$n_train, metrics$prevalence_y))

# ---- 2. Build raster stack and a strata-keyed lookup -------------------------
hagan <- rast(HAGAN); levels(hagan) <- NULL
pot   <- rast(POT)
str_r <- rast(STR)

# Sanity: align stack
if (!compareGeom(hagan, pot, stopOnError = FALSE)) {
  pot <- project(pot, hagan, method = "bilinear")
}
if (!compareGeom(hagan, str_r, stopOnError = FALSE)) {
  str_r <- project(str_r, hagan, method = "near")
}

# Sample strata at each Maine FIA plot, then compute strata-class means
pts <- vect(plt[, .(LON, LAT)], geom = c("LON","LAT"), crs = "EPSG:4326")
pts <- project(pts, crs(str_r))
plt[, strata := terra::extract(str_r, pts)[, 2]]

class_means <- plt[!is.na(strata),
                   .(p_mature = mean(ornl_p_mature, na.rm = TRUE),
                     p_oldgrowth = mean(ornl_p_oldgrowth, na.rm = TRUE),
                     n = .N),
                   by = strata][order(strata)]
cat("\n==== Strata class means (FIA training, n=", nrow(plt), ") ====\n", sep = "")
print(class_means)
fwrite(class_means, file.path(OUT, "strata_class_means.csv"))

# Build cell-level surrogate p_mature and p_oldgrowth from the strata raster
mat_r <- classify(str_r, rcl = cbind(class_means$strata, class_means$p_mature))
og_r  <- classify(str_r, rcl = cbind(class_means$strata, class_means$p_oldgrowth))
names(pot) <- "potapov_rh95"
names(mat_r) <- "ornl_p_mature"
names(og_r)  <- "ornl_p_oldgrowth"
stk <- c(pot, mat_r, og_r)

# ---- 3. Predict probability raster -------------------------------------------
pred <- predict(stk, fit, type = "response", na.rm = TRUE)
mask_layer <- hagan; mask_layer[mask_layer == 15] <- NA
pred_masked <- mask(pred, mask_layer)
writeRaster(pred_masked, file.path(OUT, "SevenIslands_pLSOG_v51spatial_100m.tif"),
            datatype = "FLT4S", overwrite = TRUE,
            gdal = c("COMPRESS=LZW","TILED=YES","BIGTIFF=IF_SAFER"))

# ---- 4. Classify into v5.1 classes -------------------------------------------
# Anchor breaks on FIA training prevalence: ME ~14% any LSOG, 2% LS+OG, 0.2% OG.
qbreaks <- quantile(values(pred_masked, na.rm = TRUE),
                    probs = c(0, 0.86, 0.98, 0.998, 1.0))
class_r <- classify(pred_masked,
                    rcl = matrix(c(qbreaks[1], qbreaks[2], 1L,
                                   qbreaks[2], qbreaks[3], 2L,
                                   qbreaks[3], qbreaks[4], 3L,
                                   qbreaks[4], qbreaks[5], 4L), ncol = 3, byrow = TRUE),
                    include.lowest = TRUE)
levels(class_r) <- data.frame(value = 1:4,
                              class = c("Not LSOG","Transitioning LS","LS","OG"))
writeRaster(class_r, file.path(OUT, "SevenIslands_class_v51spatial_100m.tif"),
            datatype = "INT1U", overwrite = TRUE,
            gdal = c("COMPRESS=LZW","TILED=YES"))

# ---- 5. Acreage tally vs Hagan ------------------------------------------------
res_ac <- prod(res(class_r)) / 4046.8564224
v51_freq <- as.data.table(freq(class_r))[, .(class = factor(value, levels = 1:4,
                                                labels = c("Not LSOG","Trans LS","LS","OG")),
                                              v51_n = count, v51_ac = round(count * res_ac, 0))]
hag_freq <- as.data.table(freq(hagan))[value %in% 1:4,
   .(class = factor(value, levels = 1:4,
                    labels = c("Not LS","Trans LS","LS","OG-like")),
     hagan_n = count, hagan_ac = round(count * res_ac, 0))]
fwrite(v51_freq, file.path(OUT, "v51_class_acres.csv"))
fwrite(hag_freq, file.path(OUT, "hagan_class_acres.csv"))

cat("\n==== Wall-to-wall acreage Hagan vs v5.1-spatial ====\n")
print(hag_freq); print(v51_freq)

cat("\nWall-to-wall complete. Outputs in", OUT, "\n")
