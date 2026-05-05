# =============================================================================
# Phase 9 Seven Islands cross-validation (Hagan M2V2b, Pingree, 2024-05-09)
#
# Compares v5.1 plot-based class against Hagan LiDAR LSOG class at FIA plots
# whose fuzzed coordinates fall on the Seven Islands / Pingree raster footprint.
#
# Inputs (all available locally; runnable on Cardinal as-is):
#   - SevenIslands raster: /sessions/.../SevenISL_M2V2b_GFW23.tif
#   - Unified plot table:  ~/LSOG/output_unified/lsog_ne_plot_table.csv
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(data.table); library(sf)
})

RASTER <- "/users/PUOM0008/crsfaaron/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
PLOTS  <- "/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv"
OUT    <- "/users/PUOM0008/crsfaaron/LSOG/output_phase9"

dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

# ---- Load ----
r <- terra::rast(RASTER)
levels(r) <- NULL  # ensure raw integer values (Phase 8 v3 fix)
cat(sprintf("Hagan raster: %d x %d  CRS: %s\n",
            ncol(r), nrow(r), terra::crs(r, describe = TRUE)$name))

dt <- fread(PLOTS, colClasses = list(character = "CN"))
me <- dt[state == "ME"]
cat(sprintf("ME plots: %d (both panels)\n", nrow(me)))

# ---- Project plot fuzzed centroids to raster CRS, then sample ----
pts_wgs84 <- sf::st_as_sf(me, coords = c("LON","LAT"), crs = 4326)
pts_proj  <- sf::st_transform(pts_wgs84, terra::crs(r))
hagan_val <- terra::extract(r, terra::vect(pts_proj))[,2]
me[, hagan_value := hagan_val]
me[is.na(hagan_value), hagan_value := -1L]

cat("Hagan value distribution at ME plots:\n")
print(me[, .N, by = hagan_value][order(hagan_value)])

fwrite(me[, .(CN, eval_period, LAT, LON, STDAGE, v4_class, v5_class,
              v5_total, potapov_rh95, hagan_value)],
       file.path(OUT, "me_plots_hagan_sampled_full.csv"))

# ---- Cross-validation on in-extent latest-panel plots ----
inext <- me[hagan_value %in% 1:4 & eval_period == "2019-2023"]
cat(sprintf("\nIn-extent latest panel: %d plots\n", nrow(inext)))

# Confusion matrices
hagan_label <- c("1" = "Not LS", "2" = "Trans LS", "3" = "LS", "4" = "OG-like")
v5_levels   <- c("Not LSOG","Transitioning LS","LS","OG")

cm_v5 <- table(factor(inext$v5_class, levels = v5_levels),
               factor(inext$hagan_value, levels = 1:4,
                       labels = hagan_label))
cat("\n==== Confusion: v5.1 (rows) x Hagan (cols), latest panel ====\n")
print(addmargins(cm_v5))
fwrite(as.data.table(as.table(cm_v5)), file.path(OUT, "phase9_confusion_v5.csv"))

cm_v4 <- table(factor(inext$v4_class, levels = v5_levels),
               factor(inext$hagan_value, levels = 1:4,
                       labels = hagan_label))
fwrite(as.data.table(as.table(cm_v4)), file.path(OUT, "phase9_confusion_v4.csv"))

# Cohen kappa
kappa_bin <- function(d, vfn, hfn) {
  v <- vfn(d); h <- hfn(d); n <- length(v)
  a <- sum(v & h); b <- sum(v & !h); c <- sum(!v & h); d_ <- sum(!v & !h)
  po <- (a + d_) / n
  pe <- ((a+b)/n)*((a+c)/n) + ((c+d_)/n)*((b+d_)/n)
  list(n = n, po = po, pe = pe, kappa = (po - pe) / (1 - pe), tp = a, fp = b, fn = c, tn = d_)
}

cmps <- list(
  list("v5.1 any-LSOG vs Hagan any-LS",
       function(d) d$v5_class %in% c("Transitioning LS","LS","OG"),
       function(d) d$hagan_value %in% 2:4),
  list("v5.1 LS+OG vs Hagan LS+OG-like",
       function(d) d$v5_class %in% c("LS","OG"),
       function(d) d$hagan_value %in% 3:4),
  list("v5.1 OG vs Hagan OG-like",
       function(d) d$v5_class == "OG",
       function(d) d$hagan_value == 4),
  list("v4 any-LSOG vs Hagan any-LS",
       function(d) d$v4_class %in% c("Transitioning LS","LS","OG"),
       function(d) d$hagan_value %in% 2:4),
  list("v4 LS+OG vs Hagan LS+OG-like",
       function(d) d$v4_class %in% c("LS","OG"),
       function(d) d$hagan_value %in% 3:4)
)
ksumm <- rbindlist(lapply(cmps, function(x) {
  k <- kappa_bin(inext, x[[2]], x[[3]])
  data.table(comparison = x[[1]], n = k$n, po = round(k$po, 4),
             pe = round(k$pe, 4), kappa = round(k$kappa, 4))
}))
cat("\n==== Cohen kappa summary ====\n"); print(ksumm)
fwrite(ksumm, file.path(OUT, "phase9_kappa_summary.csv"))

# Share-level comparison
share <- data.table(
  comparison = c("v5.1 (FIA proxy)", "v4 (FIA proxy no GEDI)",
                  "Hagan (LiDAR canopy)", "Hagan landscape Pingree (Table 2)"),
  n = c(rep(nrow(inext), 3), NA_integer_),
  any_LSOG_pct = c(
    round(100 * mean(inext$v5_class %in% c("Transitioning LS","LS","OG")), 1),
    round(100 * mean(inext$v4_class %in% c("Transitioning LS","LS","OG")), 1),
    round(100 * mean(inext$hagan_value %in% 2:4), 1),
    18.8
  ),
  LS_OG_pct = c(
    round(100 * mean(inext$v5_class %in% c("LS","OG")), 1),
    round(100 * mean(inext$v4_class %in% c("LS","OG")), 1),
    round(100 * mean(inext$hagan_value %in% 3:4), 1),
    2.4
  ),
  OG_only_pct = c(
    round(100 * mean(inext$v5_class == "OG"), 1),
    round(100 * mean(inext$v4_class == "OG"), 1),
    round(100 * mean(inext$hagan_value == 4), 1),
    0.6
  )
)
cat("\n==== Share-level comparison ====\n"); print(share)
fwrite(share, file.path(OUT, "phase9_share_table.csv"))

cat("\nPhase 9 complete. Outputs in", OUT, "\n")
