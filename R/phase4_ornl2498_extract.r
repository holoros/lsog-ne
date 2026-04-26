# =============================================================================
# Phase 4: cross-validate v3 LSOG proxy against ORNL DAAC dataset 2498
# Author: A. Weiskittel (with Cowork agent assist)
# Date: 2026-04-25
#
# What this does:
#   1. Run v3 process_state for each state in STATE_CODES, capturing per-plot
#      classification (not just summary CSV).
#   2. Reproject FIA plot lat/lon (from ME_PLOT.csv etc.) to EPSG:6933.
#   3. Extract the 5 ORNL 2498 probability bands at each plot.
#   4. Produce a confusion matrix / cross-tabulation comparing v3 lsog_class
#      with binned ORNL old-growth probability.
#
# Inputs:
#   - data/fia/<ST>_PLOT.csv, <ST>_COND.csv, <ST>_TREE.csv per state
#       (a symlink data/fia -> ~/fia_data is recommended on Cardinal)
#   - data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m_lzw.tif
#       (downloaded by scripts/download_ornl2498.sh)
#
# Outputs (in output_phase4/):
#   - phase4_plot_classified_<ST>.csv       per-plot v3 class + ORNL probs
#   - phase4_confusion_<ST>.csv             confusion matrix table
#   - phase4_summary.csv                    cross-state summary
#   - phase4_confusion_<ST>.png             heatmap figure
#   - phase4_pct_lsog_compare.png           bar chart of v3 vs ORNL by state
#
# Note on coordinates:
#   FIA public PLOT.LAT and PLOT.LON are fuzzed (typically <1 km offset for
#   forested plots). True coordinates are available under the FIA DUA. For
#   1-ha pixel comparisons the fuzzing is acceptable; if true coords are
#   later provided, set OPTION_TRUE_LATLON_CSV in the config block.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
})

# ---- CONFIG -----------------------------------------------------------------

STATE_CODES <- c("ME")    # extend to c("ME","NH","VT","NY") later
data_root   <- "~/LSOG/data/fia"
ornl_raster <- "~/LSOG/data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m_lzw.tif"
out_dir     <- "~/LSOG/output_phase4"
v3_script   <- "~/LSOG/R/fia_lsog_analysis_v3.r"

OPTION_TRUE_LATLON_CSV <- NULL   # e.g. "~/LSOG/data/fia/FIA_TRUE_LATLON.csv"
                                  # with columns CN, LAT, LON

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

source("~/LSOG/R/phase4_helpers.r")

# ---- SOURCE V3 SCORING (factored into phase4_helpers) -----------------------
# We do NOT source v3 directly because it has a top-level execution block.
# Instead phase4 reproduces the v3 plot-level scoring inline using the same
# rules from phase4_helpers::score_lsog_plot.

# ---- Per-state plot-level scoring -------------------------------------------

score_state <- function(st) {
  cat(sprintf("\n--- Phase 4 scoring: %s ---\n", st))

  plot_file <- file.path(path.expand(data_root), paste0(st, "_PLOT.csv"))
  cond_file <- file.path(path.expand(data_root), paste0(st, "_COND.csv"))
  tree_file <- file.path(path.expand(data_root), paste0(st, "_TREE.csv"))

  for (f in c(plot_file, cond_file, tree_file)) {
    if (!file.exists(f)) {
      cat(sprintf("  missing: %s; skipping %s.\n", f, st))
      return(NULL)
    }
  }

  plot_df <- read_csv(plot_file, show_col_types = FALSE)
  cond_df <- read_csv(cond_file, show_col_types = FALSE)
  tree_df <- read_csv(tree_file, show_col_types = FALSE,
                      col_types = cols(.default = col_guess()))

  # Match v3: dominant condition per plot, latest measurement per CN
  pc <- plot_df %>%
    inner_join(cond_df, by = c("CN" = "PLT_CN")) %>%
    filter(COND_STATUS_CD == 1) %>%
    group_by(CN) %>%
    slice_max(order_by = CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup()

  # Tree summary on dominant condition
  td <- tree_df %>%
    inner_join(pc %>% select(CN, CONDID), by = c("PLT_CN" = "CN", "CONDID"))

  snag <- td %>%
    filter(STATUSCD == 2, DIA >= 5.0) %>%
    group_by(PLT_CN) %>%
    summarise(snag_tpa = sum(TPA_UNADJ, na.rm = TRUE), .groups = "drop")

  live <- td %>%
    filter(STATUSCD == 1, DIA >= 1.0) %>%
    group_by(PLT_CN) %>%
    summarise(
      ba_total = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
      ba_large = sum(0.005454 * DIA^2 * TPA_UNADJ * (DIA >= 20), na.rm = TRUE),
      sd_dia   = wt_sd(DIA, TPA_UNADJ),
      max_dia  = max(DIA, na.rm = TRUE),
      .groups  = "drop"
    )

  ts <- live %>% left_join(snag, by = "PLT_CN") %>%
    mutate(snag_tpa = replace_na(snag_tpa, 0))

  # Data-driven snag thresholds (same rule as v3)
  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  if (length(snz) > 10) {
    qq <- quantile(snz, probs = c(0.75, 0.90))
    s1 <- round(qq[["75%"]]); s2 <- round(qq[["90%"]])
  } else {
    s1 <- 10; s2 <- 20
  }

  scored <- pc %>%
    left_join(ts, by = c("CN" = "PLT_CN")) %>%
    mutate(across(c(ba_total, ba_large, sd_dia, max_dia, snag_tpa),
                  ~replace_na(.x, 0)))

  # Vectorized scoring (mirrors phase4_helpers::score_lsog_plot)
  scored <- scored %>% mutate(
    score_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
    score_maturity = case_when(
      !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
      !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
      (is.na(STDAGE) | STDAGE == 0) & max_dia >= 24 ~ 1L,
      TRUE ~ 0L),
    score_structure = case_when(sd_dia >= 8 ~ 2L, sd_dia >= 5 ~ 1L, TRUE ~ 0L),
    score_canopy    = case_when(ba_total >= 150 ~ 2L, ba_total >= 100 ~ 1L, TRUE ~ 0L),
    score_deadwood  = case_when(snag_tpa >= s2 ~ 2L, snag_tpa >= s1 ~ 1L, TRUE ~ 0L),
    total_score     = score_ba_large + score_maturity + score_structure +
                      score_canopy + score_deadwood,
    lsog_class      = factor(case_when(
                        total_score >= 8 ~ "OG",
                        total_score >= 6 ~ "LS",
                        total_score >= 4 ~ "Transitioning LS",
                        TRUE             ~ "Not LSOG"),
                       levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
  )

  # Keep just what Phase 4 needs
  out <- scored %>%
    transmute(state = st, CN, INVYR = INVYR.x %||% INVYR,
              LAT, LON, STDAGE, ba_total, ba_large, sd_dia, max_dia, snag_tpa,
              score_ba_large, score_maturity, score_structure, score_canopy,
              score_deadwood, total_score, lsog_class,
              snag_thresh_1 = s1, snag_thresh_2 = s2)

  cat(sprintf("  scored %d plots, snag thresholds %d / %d TPA\n",
              nrow(out), s1, s2))
  out
}

# ---- Run scoring for all states ---------------------------------------------

cat(strrep("=", 70), "\n")
cat(" Phase 4: ORNL DAAC 2498 vs FIA proxy (v3) plot-level comparison\n")
cat(strrep("=", 70), "\n")
cat(sprintf(" States: %s\n", paste(STATE_CODES, collapse = ", ")))
cat(sprintf(" ORNL raster: %s\n", ornl_raster))

all_scored <- map_dfr(STATE_CODES, score_state)
if (nrow(all_scored) == 0) stop("No plots scored. Check data_root.")

# ---- Optional override with true lat/lon from a DUA file --------------------

if (!is.null(OPTION_TRUE_LATLON_CSV) && file.exists(path.expand(OPTION_TRUE_LATLON_CSV))) {
  cat(sprintf("\n  Using true lat/lon from %s\n", OPTION_TRUE_LATLON_CSV))
  true_ll <- read_csv(path.expand(OPTION_TRUE_LATLON_CSV), show_col_types = FALSE)
  all_scored <- all_scored %>%
    select(-LAT, -LON) %>%
    inner_join(true_ll %>% select(CN, LAT, LON), by = "CN")
} else {
  cat("\n  Using public (fuzzed) FIA lat/lon. <1 km offset is fine for 1-ha pixels.\n")
}

# ---- Reproject to EPSG:6933 and extract ORNL probabilities ------------------

if (!file.exists(path.expand(ornl_raster))) {
  stop(sprintf("ORNL raster not found at %s.\n  Run: bash scripts/download_ornl2498.sh", ornl_raster))
}

cat("\n  Reprojecting plot lat/lon to EPSG:6933...\n")
plot_sf <- to_ease_grid_2(all_scored, lon = "LON", lat = "LAT")

cat(sprintf("  Extracting ORNL probabilities for %d plots...\n", nrow(plot_sf)))
extracted <- extract_ornl_probabilities(plot_sf, path.expand(ornl_raster))

# Drop the geometry column for the CSV write
joined <- as_tibble(extracted) %>% select(-any_of("geometry"))

# ---- Save per-state and global outputs --------------------------------------

for (st in STATE_CODES) {
  st_data <- joined %>% filter(state == st)
  if (nrow(st_data) == 0) next
  fp <- file.path(path.expand(out_dir), sprintf("phase4_plot_classified_%s.csv", st))
  write_csv(st_data, fp)
  cat(sprintf("  saved %s (%d rows)\n", basename(fp), nrow(st_data)))
}

# ---- Confusion matrix per state --------------------------------------------

confusion_summary <- joined %>%
  mutate(
    ornl_og_bin = cut(ornl_p_oldgrowth,
                      breaks = c(-Inf, 5, 25, 50, 75, Inf),
                      labels = c("<=5%", "6-25%", "26-50%", "51-75%", ">75%"),
                      include.lowest = TRUE)
  ) %>%
  count(state, lsog_class, ornl_og_bin, name = "n_plots") %>%
  arrange(state, lsog_class, ornl_og_bin)

write_csv(confusion_summary, file.path(path.expand(out_dir), "phase4_summary.csv"))

# ---- Per-state confusion CSV + heatmap --------------------------------------

for (st in STATE_CODES) {
  st_conf <- confusion_summary %>% filter(state == st)
  if (nrow(st_conf) == 0) next

  fp <- file.path(path.expand(out_dir), sprintf("phase4_confusion_%s.csv", st))
  write_csv(st_conf, fp)

  p <- ggplot(st_conf, aes(x = ornl_og_bin, y = lsog_class, fill = n_plots)) +
    geom_tile(color = "white") +
    geom_text(aes(label = n_plots), size = 3.5) +
    scale_fill_gradient(low = "#F0F7F2", high = "#1B4332", name = "Plots") +
    labs(
      title = sprintf("v3 LSOG class vs ORNL 2498 old-growth probability: %s", st),
      x = "ORNL old-growth probability bin",
      y = "v3 LSOG class",
      caption = "Bruening et al. 2026 (ORNL DAAC ds_id 2498) compared with FIA proxy v3."
    ) +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank())

  ggsave(file.path(path.expand(out_dir), sprintf("phase4_confusion_%s.png", st)),
         p, width = 8, height = 5, dpi = 200, bg = "white")
}

# ---- Cross-state percent comparison: v3 LSOG vs ORNL >50% OG prob -----------

state_compare <- joined %>%
  group_by(state) %>%
  summarise(
    n_plots             = n(),
    pct_v3_any_lsog     = 100 * mean(lsog_class != "Not LSOG"),
    pct_v3_ls_og        = 100 * mean(lsog_class %in% c("LS", "OG")),
    pct_v3_og           = 100 * mean(lsog_class == "OG"),
    pct_ornl_og_gt50    = 100 * mean(ornl_p_oldgrowth > 50, na.rm = TRUE),
    pct_ornl_mature_gt50 = 100 * mean(ornl_p_mature > 50, na.rm = TRUE),
    pct_ornl_mog_gt50   = 100 * mean(pmax(ornl_p_oldgrowth, ornl_p_mature) > 50,
                                     na.rm = TRUE),
    .groups = "drop"
  )

write_csv(state_compare, file.path(path.expand(out_dir), "phase4_state_compare.csv"))
print(state_compare)

cat("\nDone.\n")
