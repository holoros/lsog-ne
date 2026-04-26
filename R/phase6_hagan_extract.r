# =============================================================================
# Phase 6 (scaffold): cross-validate v5 against Hagan et al. 2024 LiDAR LSOG
# =============================================================================
# Drop-in pipeline for when the Hagan 100m LSOG raster lands.
# Input expected: ~/LSOG/data/rasters/hagan_lsog/hagan_lsog_100m.tif
#   - 1-band raster, 100 m resolution
#   - Class codes (per Hagan/Thompson 2026 Table 3.1):
#       0 = Not LSOG
#       1 = Transitioning LS
#       2 = LS
#       3 = OG
# (If the raster uses different codes, set HAGAN_CLASS_MAP below.)
#
# Outputs in output_phase6/:
#   - phase6_plot_classified.csv: per-plot v5 class + Hagan class
#   - phase6_confusion.csv: 4x4 cell counts, all permutations
#   - phase6_kappa.csv: Cohen's kappa for v5 vs Hagan
#     - kappa for any-LSOG (binary)
#     - kappa for ordinal (Transitioning LS / LS / OG)
#   - phase6_confusion.png: heatmap
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
})

# ---- CONFIG -----------------------------------------------------------------

STATE_CODES <- c("ME")
data_root   <- "~/LSOG/data/fia"
hagan_raster <- "~/LSOG/data/rasters/hagan_lsog/hagan_lsog_100m.tif"
out_dir     <- "~/LSOG/output_phase6"
PANEL       <- list(name = "2014-2018", yr_lo = 2014, yr_hi = 2018)

# Map raster pixel values to Hagan class names. Update if codes differ.
HAGAN_CLASS_MAP <- c("0" = "Not LSOG",
                     "1" = "Transitioning LS",
                     "2" = "LS",
                     "3" = "OG")

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)
source("~/LSOG/R/phase4_helpers.r")

if (!file.exists(path.expand(hagan_raster))) {
  cat(sprintf("Hagan raster not found at %s\n", hagan_raster))
  cat("Stage the file there, then re-run.\n")
  quit(status = 1)
}

# ---- Score plots with v5 (matches fia_lsog_analysis_v5.r) -------------------

source("~/LSOG/R/fia_lsog_analysis_v5.r", local = TRUE)

# fia_lsog_analysis_v5.r populates `all_scored` and `results`. Filter to PANEL.
plot_data <- all_scored %>% filter(eval_period == PANEL$name) %>%
  filter(!is.na(LAT), !is.na(LON))

# ---- Extract Hagan class at plot centroid (transform to raster CRS) ---------

cat(sprintf("\nExtracting Hagan class for %d plots...\n", nrow(plot_data)))
hr <- terra::rast(path.expand(hagan_raster))

plot_sf <- plot_data %>% st_as_sf(coords = c("LON", "LAT"), crs = 4326, remove = FALSE)
plot_proj <- st_transform(plot_sf, terra::crs(hr))

hagan_v <- terra::extract(hr, terra::vect(plot_proj), method = "simple", ID = FALSE)
plot_data$hagan_code  <- hagan_v[[1]]
plot_data$hagan_class <- HAGAN_CLASS_MAP[as.character(plot_data$hagan_code)]
plot_data$hagan_class <- factor(plot_data$hagan_class,
                                 levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))

# ---- Save per-plot --------------------------------------------------------

write_csv(plot_data %>% select(state, eval_period, CN, INVYR, LAT, LON,
                                 lsog_class, hagan_class, hagan_code,
                                 starts_with("score_"), total_score,
                                 potapov_rh95),
          file.path(path.expand(out_dir), "phase6_plot_classified.csv"))

# ---- 4x4 confusion ---------------------------------------------------------

confusion <- plot_data %>%
  filter(!is.na(hagan_class)) %>%
  count(state, lsog_class, hagan_class, name = "n_plots") %>%
  arrange(state, lsog_class, hagan_class)
write_csv(confusion, file.path(path.expand(out_dir), "phase6_confusion.csv"))

# ---- Cohen's kappa ---------------------------------------------------------

kappa_binary <- function(y_true, y_pred) {
  ct <- table(y_true, y_pred)
  if (any(dim(ct) < 2)) return(NA_real_)
  n <- sum(ct); po <- sum(diag(ct)) / n
  pe <- sum(rowSums(ct) * colSums(ct)) / n^2
  (po - pe) / (1 - pe)
}

# Weighted (linear) kappa for ordinal classes
kappa_weighted <- function(y_true, y_pred, levels) {
  yt <- factor(y_true, levels = levels); yp <- factor(y_pred, levels = levels)
  k <- length(levels)
  ct <- table(yt, yp); n <- sum(ct)
  w <- matrix(NA, k, k)
  for (i in 1:k) for (j in 1:k) w[i,j] <- 1 - abs(i-j)/(k-1)
  po <- sum(w * ct) / n
  rs <- rowSums(ct); cs <- colSums(ct)
  pe <- sum(w * outer(rs, cs)) / n^2
  (po - pe) / (1 - pe)
}

bin <- function(x) as.integer(x != "Not LSOG")
levs <- c("Not LSOG", "Transitioning LS", "LS", "OG")

kapps <- tibble(
  metric = c("any-LSOG kappa (binary)",
             "ordinal kappa (linear weights, 4 classes)",
             "OG-only kappa (binary)"),
  value = c(
    kappa_binary(bin(plot_data$hagan_class), bin(plot_data$lsog_class)),
    kappa_weighted(plot_data$hagan_class, plot_data$lsog_class, levs),
    kappa_binary(as.integer(plot_data$hagan_class == "OG"),
                  as.integer(plot_data$lsog_class == "OG"))
  )
)
write_csv(kapps, file.path(path.expand(out_dir), "phase6_kappa.csv"))
cat("\nKappa vs Hagan:\n"); print(kapps)

# ---- Heatmap ---------------------------------------------------------------

p <- ggplot(confusion, aes(x = hagan_class, y = lsog_class, fill = n_plots)) +
  geom_tile(color = "white") +
  geom_text(aes(label = n_plots), size = 4) +
  scale_fill_gradient(low = "#F0F7F2", high = "#1B4332", name = "Plots") +
  labs(
    title = sprintf("v5 LSOG class vs Hagan et al. 2024 LiDAR class: %s panel", PANEL$name),
    x = "Hagan class (LiDAR)", y = "v5 class (FIA proxy)",
    caption = sprintf("n = %d FIA plots; cells show plot counts.", sum(confusion$n_plots))
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(file.path(path.expand(out_dir), "phase6_confusion.png"),
       p, width = 9, height = 5.5, dpi = 200, bg = "white")

cat("\nDone.\n")
