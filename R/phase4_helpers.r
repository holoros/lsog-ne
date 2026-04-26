# =============================================================================
# Phase 4 helpers: shared scoring + raster utilities
# =============================================================================
# These are factored out of fia_lsog_analysis_v3.r so the v3 classifier and the
# Phase 4 ORNL comparison can both use the same scoring rules.

suppressPackageStartupMessages({
  library(tidyverse)
})

# Weighted SD (TPA-weighted DBH dispersion)
wt_sd <- function(x, w) {
  if (length(x) < 2 || sum(w, na.rm = TRUE) == 0) return(0)
  mu <- weighted.mean(x, w, na.rm = TRUE)
  sqrt(sum(w * (x - mu)^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
}

# Score one plot's tree summary against the v3 5-dimension rubric.
# Inputs: a one-row tibble or list with ba_total, ba_large, sd_dia, max_dia,
# snag_tpa, and an STDAGE value (may be NA). Plus state-level snag thresholds.
score_lsog_plot <- function(row,
                            stdage,
                            snag_thresh_1 = 10,
                            snag_thresh_2 = 20,
                            thresh_og = 8,
                            thresh_ls = 6,
                            thresh_trans = 4) {

  ba_total <- row$ba_total %||% 0
  ba_large <- row$ba_large %||% 0
  sd_dia   <- row$sd_dia   %||% 0
  max_dia  <- row$max_dia  %||% 0
  snag_tpa <- row$snag_tpa %||% 0

  s_ba_large <- if (ba_large >= 80) 2L else if (ba_large >= 40) 1L else 0L

  s_maturity <- if (!is.na(stdage) && stdage >= 120) 2L
           else if (!is.na(stdage) && stdage >= 80)  1L
           else if ((is.na(stdage) || stdage == 0) && max_dia >= 24) 1L
           else 0L

  s_structure <- if (sd_dia >= 8) 2L else if (sd_dia >= 5) 1L else 0L
  s_canopy    <- if (ba_total >= 150) 2L else if (ba_total >= 100) 1L else 0L
  s_deadwood  <- if (snag_tpa >= snag_thresh_2) 2L
            else if (snag_tpa >= snag_thresh_1) 1L
            else 0L

  total <- s_ba_large + s_maturity + s_structure + s_canopy + s_deadwood
  cls   <- if (total >= thresh_og) "OG"
       else if (total >= thresh_ls) "LS"
       else if (total >= thresh_trans) "Transitioning LS"
       else "Not LSOG"

  list(
    score_ba_large = s_ba_large,
    score_maturity = s_maturity,
    score_structure = s_structure,
    score_canopy = s_canopy,
    score_deadwood = s_deadwood,
    total_score = total,
    lsog_class = cls
  )
}

# null-coalesce
`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

# Project lat/lon to EPSG:6933 (NSIDC EASE-Grid 2.0)
# Returns sf points in 6933.
to_ease_grid_2 <- function(plot_df, lon = "LON", lat = "LAT") {
  suppressPackageStartupMessages(library(sf))
  pts <- plot_df %>%
    filter(!is.na(.data[[lat]]), !is.na(.data[[lon]])) %>%
    st_as_sf(coords = c(lon, lat), crs = 4326, remove = FALSE) %>%
    st_transform(6933)
  pts
}

# Extract all 5 bands of the ORNL probability raster at point locations.
# Returns the original df with new columns:
#   ornl_p_nonforest, ornl_p_allforest, ornl_p_other, ornl_p_mature, ornl_p_oldgrowth
extract_ornl_probabilities <- function(plot_sf, raster_path) {
  suppressPackageStartupMessages(library(terra))
  r <- terra::rast(raster_path)
  if (terra::nlyr(r) != 5) {
    stop(sprintf("Expected 5-band raster, got %d bands.", terra::nlyr(r)))
  }
  v <- terra::extract(r, terra::vect(plot_sf), method = "simple", ID = FALSE)
  names(v) <- c("ornl_p_nonforest", "ornl_p_allforest",
                "ornl_p_other", "ornl_p_mature", "ornl_p_oldgrowth")
  cbind(as.data.frame(plot_sf), v)
}
