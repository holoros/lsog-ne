# =============================================================================
# Phase 4 v2: panel filter + ORNL mature/MOG bins + threshold grid search
# =============================================================================
# Improvements over v1:
#   1. Filter FIA plots to the 2019-2023 panel only, matching the ORNL c.2022
#      temporal window.
#   2. Confusion table includes ORNL mature_bin and mog_bin alongside og_bin.
#   3. Grid-search v3 score thresholds (THRESH_TRANS, THRESH_LS, THRESH_OG) to
#      find the combination that best calibrates to ORNL "mature" and "OG"
#      class shares.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
})

# ---- CONFIG -----------------------------------------------------------------

STATE_CODES   <- c("ME")
data_root     <- "~/LSOG/data/fia"
ornl_raster   <- "~/LSOG/data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m_lzw.tif"
out_dir       <- "~/LSOG/output_phase4/v2"
EVAL_PERIODS  <- list(
  list(name = "2019-2023", yr_lo = 2019, yr_hi = 2023),
  list(name = "2020-2024", yr_lo = 2020, yr_hi = 2024)
)
EVAL_PERIOD_PRIMARY <- "2019-2023"  # used for state_compare and grid search

# Grid search over score thresholds. Each must satisfy trans <= ls <= og.
GRID_TRANS <- c(3, 4, 5)
GRID_LS    <- c(5, 6, 7)
GRID_OG    <- c(7, 8, 9)

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

source("~/LSOG/R/phase4_helpers.r")

# ---- Score plots, panel-aware -----------------------------------------------

score_state <- function(st, eval_period) {
  cat(sprintf("\n--- v2 scoring %s panel %s ---\n", st, eval_period$name))

  plot_file <- file.path(path.expand(data_root), paste0(st, "_PLOT.csv"))
  cond_file <- file.path(path.expand(data_root), paste0(st, "_COND.csv"))
  tree_file <- file.path(path.expand(data_root), paste0(st, "_TREE.csv"))
  for (f in c(plot_file, cond_file, tree_file)) {
    if (!file.exists(f)) {
      cat(sprintf("  missing: %s; skipping.\n", f))
      return(NULL)
    }
  }

  plot_df <- read_csv(plot_file, show_col_types = FALSE)
  cond_df <- read_csv(cond_file, show_col_types = FALSE)
  tree_df <- read_csv(tree_file, show_col_types = FALSE,
                      col_types = cols(.default = col_guess()))

  # Filter to panel
  pc <- plot_df %>%
    inner_join(cond_df, by = c("CN" = "PLT_CN")) %>%
    filter(COND_STATUS_CD == 1) %>%
    mutate(INVYR = as.integer(INVYR.x %||% INVYR)) %>%
    filter(INVYR >= eval_period$yr_lo, INVYR <= eval_period$yr_hi) %>%
    group_by(CN) %>%
    slice_max(order_by = CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup()

  if (nrow(pc) == 0) {
    cat("  no plots in panel.\n")
    return(NULL)
  }

  td <- tree_df %>%
    inner_join(pc %>% select(CN, CONDID), by = c("PLT_CN" = "CN", "CONDID"))

  snag <- td %>% filter(STATUSCD == 2, DIA >= 5.0) %>%
    group_by(PLT_CN) %>%
    summarise(snag_tpa = sum(TPA_UNADJ, na.rm = TRUE), .groups = "drop")

  live <- td %>% filter(STATUSCD == 1, DIA >= 1.0) %>%
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

  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  if (length(snz) > 10) {
    qq <- quantile(snz, probs = c(0.75, 0.90))
    s1 <- round(qq[["75%"]]); s2 <- round(qq[["90%"]])
  } else { s1 <- 10; s2 <- 20 }

  scored <- pc %>%
    left_join(ts, by = c("CN" = "PLT_CN")) %>%
    mutate(across(c(ba_total, ba_large, sd_dia, max_dia, snag_tpa),
                  ~replace_na(.x, 0))) %>%
    mutate(
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
                        score_canopy + score_deadwood
    )

  out <- scored %>%
    transmute(state = st,
              eval_period = eval_period$name,
              CN, INVYR, LAT, LON, STDAGE, ba_total, ba_large, sd_dia,
              max_dia, snag_tpa,
              score_ba_large, score_maturity, score_structure,
              score_canopy, score_deadwood, total_score,
              snag_thresh_1 = s1, snag_thresh_2 = s2)

  cat(sprintf("  %d plots in %s, snag thresh %d/%d TPA\n",
              nrow(out), eval_period$name, s1, s2))
  out
}

# Classify with given thresholds
classify <- function(scored, t_trans, t_ls, t_og) {
  scored %>% mutate(
    lsog_class = factor(case_when(
      total_score >= t_og    ~ "OG",
      total_score >= t_ls    ~ "LS",
      total_score >= t_trans ~ "Transitioning LS",
      TRUE                   ~ "Not LSOG"),
      levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
  )
}

# ---- Run scoring across states and panels -----------------------------------

cat(strrep("=", 70), "\n")
cat(" Phase 4 v2: panel-filtered comparison vs ORNL DAAC 2498\n")
cat(strrep("=", 70), "\n")

all_scored <- map_dfr(STATE_CODES, function(st) {
  map_dfr(EVAL_PERIODS, function(ep) score_state(st, ep))
})

if (nrow(all_scored) == 0) stop("No plots scored. Check data_root.")

# ---- Reproject + extract ORNL probabilities ---------------------------------

if (!file.exists(path.expand(ornl_raster))) {
  stop(sprintf("ORNL raster not found: %s", ornl_raster))
}

cat("\n  Reprojecting plot lat/lon to EPSG:6933...\n")
plot_sf <- to_ease_grid_2(all_scored, lon = "LON", lat = "LAT")
cat(sprintf("  Extracting ORNL probabilities for %d rows...\n", nrow(plot_sf)))
extracted <- extract_ornl_probabilities(plot_sf, path.expand(ornl_raster))
joined <- as_tibble(extracted) %>% select(-any_of("geometry"))

# ---- Apply default thresholds (4/6/8) and bin ORNL probabilities ------------

bin_prob <- function(p) {
  cut(p,
      breaks = c(-Inf, 5, 25, 50, 75, Inf),
      labels = c("<=5%", "6-25%", "26-50%", "51-75%", ">75%"),
      include.lowest = TRUE)
}

joined_default <- classify(joined, 4, 6, 8) %>%
  mutate(
    ornl_og_bin     = bin_prob(ornl_p_oldgrowth),
    ornl_mature_bin = bin_prob(ornl_p_mature),
    ornl_mog_bin    = bin_prob(pmax(ornl_p_oldgrowth, ornl_p_mature, na.rm = TRUE))
  )

# Save per-state per-panel detail
for (st in STATE_CODES) for (ep in EVAL_PERIODS) {
  d <- joined_default %>% filter(state == st, eval_period == ep$name)
  if (nrow(d) == 0) next
  fp <- file.path(path.expand(out_dir),
                  sprintf("phase4_v2_plot_classified_%s_%s.csv", st, ep$name))
  write_csv(d, fp)
  cat(sprintf("  saved %s (%d rows)\n", basename(fp), nrow(d)))
}

# ---- Multi-bin confusion (OG, mature, MOG) ----------------------------------

build_confusion <- function(d, bin_col, label) {
  d %>%
    filter(eval_period == EVAL_PERIOD_PRIMARY) %>%
    count(state, lsog_class, .data[[bin_col]], name = "n_plots") %>%
    rename(ornl_bin = .data[[bin_col]]) %>%
    mutate(ornl_class = label) %>%
    arrange(state, lsog_class, ornl_bin)
}

confusion_long <- bind_rows(
  build_confusion(joined_default, "ornl_og_bin",     "old-growth"),
  build_confusion(joined_default, "ornl_mature_bin", "mature"),
  build_confusion(joined_default, "ornl_mog_bin",    "MOG (mature OR OG)")
) %>%
  select(state, ornl_class, lsog_class, ornl_bin, n_plots)

write_csv(confusion_long,
          file.path(path.expand(out_dir), "phase4_v2_confusion.csv"))

# ---- Faceted heatmap ---------------------------------------------------------

p <- ggplot(confusion_long,
       aes(x = ornl_bin, y = lsog_class, fill = n_plots)) +
  geom_tile(color = "white") +
  geom_text(aes(label = n_plots), size = 3) +
  facet_grid(state ~ ornl_class) +
  scale_fill_gradient(low = "#F0F7F2", high = "#1B4332", name = "Plots",
                      trans = "log10") +
  labs(
    title = sprintf("v3 LSOG class vs ORNL 2498 probability bins (%s panel)",
                    EVAL_PERIOD_PRIMARY),
    x = "ORNL probability bin", y = "v3 LSOG class",
    caption = "log10 color scale. Bruening et al. 2026 (ds_id 2498) c.2022."
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 30, hjust = 1))

ggsave(file.path(path.expand(out_dir), "phase4_v2_confusion_facet.png"),
       p, width = 12, height = 5, dpi = 200, bg = "white")

# ---- Per-state, per-panel comparison shares ---------------------------------

state_compare <- joined_default %>%
  group_by(state, eval_period) %>%
  summarise(
    n_plots             = n(),
    pct_v3_any_lsog     = 100 * mean(lsog_class != "Not LSOG"),
    pct_v3_ls_og        = 100 * mean(lsog_class %in% c("LS", "OG")),
    pct_v3_og           = 100 * mean(lsog_class == "OG"),
    pct_ornl_og_gt50    = 100 * mean(ornl_p_oldgrowth > 50, na.rm = TRUE),
    pct_ornl_mature_gt50 = 100 * mean(ornl_p_mature > 50, na.rm = TRUE),
    pct_ornl_mog_gt50   = 100 * mean(pmax(ornl_p_oldgrowth, ornl_p_mature, na.rm=TRUE) > 50,
                                     na.rm = TRUE),
    .groups = "drop"
  )

write_csv(state_compare,
          file.path(path.expand(out_dir), "phase4_v2_state_compare.csv"))
print(state_compare)

# ---- Grid search over score thresholds --------------------------------------

cat("\n--- Threshold grid search ---\n")

panel_only <- joined %>% filter(eval_period == EVAL_PERIOD_PRIMARY)

ornl_pct_mog_gt50 <- 100 * mean(
  pmax(panel_only$ornl_p_oldgrowth,
       panel_only$ornl_p_mature, na.rm = TRUE) > 50, na.rm = TRUE)

ornl_pct_og_gt50 <- 100 * mean(panel_only$ornl_p_oldgrowth > 50, na.rm = TRUE)

cat(sprintf("  ORNL targets: any-MOG=%5.2f%%   OG=%5.2f%%\n",
            ornl_pct_mog_gt50, ornl_pct_og_gt50))

grid <- expand_grid(t_trans = GRID_TRANS, t_ls = GRID_LS, t_og = GRID_OG) %>%
  filter(t_trans <= t_ls, t_ls <= t_og)

grid_results <- pmap_dfr(grid, function(t_trans, t_ls, t_og) {
  cls <- classify(panel_only, t_trans, t_ls, t_og)
  pct_any  <- 100 * mean(cls$lsog_class != "Not LSOG")
  pct_og_v <- 100 * mean(cls$lsog_class == "OG")
  tibble(
    t_trans = t_trans, t_ls = t_ls, t_og = t_og,
    pct_any_lsog = pct_any,
    pct_og       = pct_og_v,
    diff_any     = pct_any  - ornl_pct_mog_gt50,
    diff_og      = pct_og_v - ornl_pct_og_gt50,
    abs_loss     = abs(diff_any) + abs(diff_og)
  )
}) %>% arrange(abs_loss)

write_csv(grid_results,
          file.path(path.expand(out_dir), "phase4_v2_threshold_grid.csv"))

cat("\nTop 5 threshold combinations (smallest absolute calibration loss):\n")
print(head(grid_results, 5))

cat(sprintf("\nDefault v3 (4/6/8): any-LSOG=%5.2f%%, OG=%5.2f%%; ORNL: %5.2f%%, %5.2f%%\n",
            grid_results %>% filter(t_trans==4, t_ls==6, t_og==8) %>% pull(pct_any_lsog),
            grid_results %>% filter(t_trans==4, t_ls==6, t_og==8) %>% pull(pct_og),
            ornl_pct_mog_gt50, ornl_pct_og_gt50))

cat("\nDone.\n")
