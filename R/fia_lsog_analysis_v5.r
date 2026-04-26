# =============================================================================
# Title: FIA LSOG Analysis for New England (v5)
# Author: A. Weiskittel
# Date: 2026-04-26
# Description:
#   Operational successor to v4. Adds a 6th dimension based on Potapov et al.
#   2021 GEDI/Landsat 30m canopy height; uses 4/6/8 score thresholds within
#   a /12 system (the v5b configuration that scored best in Phase 5b).
#
#   Because Potapov height is a single 2019 raster, v5 is scoped to FIA
#   panels overlapping that year. For historical time series back to 1999,
#   use v4 (no GEDI dimension, comparable across panels).
#
# Score breakdown (/12):
#   1. score_ba_large    : 0/1/2 from BA in trees DBH >= 20 in
#   2. score_maturity    : 0/1/2 from STDAGE or max_dia fallback (>= 20 in)
#   3. score_structure   : 0/1/2 from TPA-weighted SD of DBH (>= 3 / >= 6 in)
#   4. score_canopy      : 0/1/2 from total BA (>= 80 / >= 120 ft^2/ac)
#   5. score_deadwood    : 0/1/2 from snag TPA, data-driven percentiles
#   6. score_canopy_height : 0/1/2 from Potapov RH95 (>= 18 / >= 25 m)
# Class thresholds:
#   OG    >= 8
#   LS    >= 6
#   TLS   >= 4
#
# Inputs:
#   <ST>_PLOT.csv, <ST>_COND.csv, <ST>_TREE.csv per state in data/fia/
#   data/rasters/potapov_2019/Forest_height_2019_NAM.tif
# Outputs in output_v5/:
#   fia_lsog_v5_all_states.csv  : per-state per-panel summary with bootstrap CIs
#   lsog_pct_combined_<ST>_v5.png
#   lsog_acres_facet_<ST>_v5.png
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(sf)
  library(terra)
  library(scales)
})

# ---- CONFIG -----------------------------------------------------------------

STATE_CODES   <- c("ME", "NH", "VT", "NY")
data_root     <- "~/LSOG/data/fia"
potapov_raster <- "~/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif"
out_dir       <- "~/LSOG/output_v5"
N_BOOT        <- 2000

# Recent-panel scope (Potapov 2019 baseline)
EVAL_BREAKS <- tribble(
  ~eval_period, ~yr_lo, ~yr_hi, ~eval_year,
  "2014-2018",   2014,   2018,   2016,
  "2019-2023",   2019,   2023,   2021
)

# Score thresholds (v5b: 4/6/8 within /12)
T_OG    <- 8
T_LS    <- 6
T_TRANS <- 4

# Forest acres fallback (used only when EXPNS missing)
FOREST_ACRES <- tribble(
  ~state, ~forest_acres,
  "ME",   17600000,
  "NH",    4800000,
  "VT",    4600000,
  "MA",    3000000,
  "CT",    1700000,
  "RI",     360000,
  "NY",   18900000
)

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)
source("~/LSOG/R/phase4_helpers.r")
set.seed(42)

# ---- Plot scoring with Potapov canopy height -------------------------------

score_state <- function(st) {
  cat(sprintf("\n--- v5 scoring %s ---\n", st))

  pf <- read_csv(file.path(path.expand(data_root), paste0(st, "_PLOT.csv")),
                 show_col_types = FALSE)
  cf <- read_csv(file.path(path.expand(data_root), paste0(st, "_COND.csv")),
                 show_col_types = FALSE)
  tf <- read_csv(file.path(path.expand(data_root), paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_types = cols(.default = col_guess()))

  pc <- pf %>%
    inner_join(cf, by = c("CN" = "PLT_CN")) %>%
    filter(COND_STATUS_CD == 1) %>%
    mutate(INVYR = as.integer(INVYR.x %||% INVYR)) %>%
    inner_join(EVAL_BREAKS, by = character()) %>%
    filter(INVYR >= yr_lo, INVYR <= yr_hi) %>%
    group_by(CN, eval_period) %>% slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup()

  td <- tf %>% inner_join(pc %>% select(CN, CONDID, eval_period),
                          by = c("PLT_CN" = "CN", "CONDID"),
                          relationship = "many-to-many")

  snag <- td %>% filter(STATUSCD == 2, DIA >= 5.0) %>%
    group_by(PLT_CN, eval_period) %>%
    summarise(snag_tpa = sum(TPA_UNADJ, na.rm = TRUE), .groups = "drop")
  live <- td %>% filter(STATUSCD == 1, DIA >= 1.0) %>%
    group_by(PLT_CN, eval_period) %>%
    summarise(
      ba_total = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
      ba_large = sum(0.005454 * DIA^2 * TPA_UNADJ * (DIA >= 20), na.rm = TRUE),
      sd_dia   = wt_sd(DIA, TPA_UNADJ),
      max_dia  = max(DIA, na.rm = TRUE),
      .groups = "drop"
    )
  ts <- live %>% left_join(snag, by = c("PLT_CN", "eval_period")) %>%
    mutate(snag_tpa = replace_na(snag_tpa, 0))

  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  s1 <- if (length(snz) > 10) round(quantile(snz, 0.75)) else 10
  s2 <- if (length(snz) > 10) round(quantile(snz, 0.90)) else 20

  scored <- pc %>%
    left_join(ts, by = c("CN" = "PLT_CN", "eval_period")) %>%
    mutate(across(c(ba_total, ba_large, sd_dia, max_dia, snag_tpa),
                  ~replace_na(.x, 0))) %>%
    mutate(state = st, snag_thresh_1 = s1, snag_thresh_2 = s2)

  # Extract Potapov canopy height at plot LAT/LON (already in WGS84)
  cat("   extracting Potapov canopy height...\n")
  scored_sf <- scored %>% filter(!is.na(LAT), !is.na(LON)) %>%
    st_as_sf(coords = c("LON", "LAT"), crs = 4326, remove = FALSE)
  rh95 <- terra::extract(terra::rast(path.expand(potapov_raster)),
                         terra::vect(scored_sf), method = "simple", ID = FALSE)
  scored$potapov_rh95 <- ifelse(rh95[[1]] > 60, NA_real_, rh95[[1]])

  scored %>% mutate(
    score_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
    score_maturity = case_when(
      !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
      !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
      (is.na(STDAGE) | STDAGE == 0) & max_dia >= 24 ~ 1L,
      TRUE ~ 0L),
    score_structure = case_when(sd_dia >= 8 ~ 2L, sd_dia >= 5 ~ 1L, TRUE ~ 0L),
    score_canopy    = case_when(ba_total >= 150 ~ 2L, ba_total >= 100 ~ 1L, TRUE ~ 0L),
    score_deadwood  = case_when(snag_tpa >= snag_thresh_2 ~ 2L,
                                 snag_tpa >= snag_thresh_1 ~ 1L,
                                 TRUE ~ 0L),
    score_canopy_height = case_when(
      !is.na(potapov_rh95) & potapov_rh95 >= 25 ~ 2L,
      !is.na(potapov_rh95) & potapov_rh95 >= 18 ~ 1L,
      TRUE ~ 0L),
    total_score = score_ba_large + score_maturity + score_structure +
                  score_canopy + score_deadwood + score_canopy_height,
    lsog_class = factor(case_when(
      total_score >= T_OG    ~ "OG",
      total_score >= T_LS    ~ "LS",
      total_score >= T_TRANS ~ "Transitioning LS",
      TRUE                   ~ "Not LSOG"),
      levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
  )
}

# ---- Bootstrap CIs ----------------------------------------------------------

bootstrap_one <- function(grp) {
  n <- nrow(grp)
  has_expns <- "EXPNS" %in% names(grp) && any(!is.na(grp$EXPNS))
  st_acres <- FOREST_ACRES %>% filter(state == grp$state[1]) %>% pull(forest_acres)
  if (length(st_acres) == 0) st_acres <- NA_real_

  if (has_expns) {
    grp$plot_acres <- grp$EXPNS
  } else if (!is.na(st_acres)) {
    grp$plot_acres <- (st_acres / n) * grp$CONDPROP_UNADJ
  } else {
    grp$plot_acres <- 1
  }

  bm <- replicate(N_BOOT, {
    idx <- sample.int(n, replace = TRUE)
    cls <- grp$lsog_class[idx]; ac <- grp$plot_acres[idx]
    c(pct_trans   = 100 * mean(cls == "Transitioning LS"),
      pct_ls      = 100 * mean(cls == "LS"),
      pct_og      = 100 * mean(cls == "OG"),
      pct_all     = 100 * mean(cls != "Not LSOG"),
      ac_trans    = sum(ac[cls == "Transitioning LS"], na.rm = TRUE),
      ac_ls       = sum(ac[cls == "LS"], na.rm = TRUE),
      ac_og       = sum(ac[cls == "OG"], na.rm = TRUE),
      ac_all      = sum(ac[cls != "Not LSOG"], na.rm = TRUE))
  })
  ci <- apply(bm, 1, quantile, probs = c(0.025, 0.975))

  tibble(
    state = grp$state[1], eval_period = grp$eval_period[1],
    eval_year = grp$eval_year[1], n_plots = n,
    pct_trans = 100 * mean(grp$lsog_class == "Transitioning LS"),
    pct_ls    = 100 * mean(grp$lsog_class == "LS"),
    pct_og    = 100 * mean(grp$lsog_class == "OG"),
    pct_all   = 100 * mean(grp$lsog_class != "Not LSOG"),
    pct_trans_lo = ci["2.5%","pct_trans"], pct_trans_hi = ci["97.5%","pct_trans"],
    pct_ls_lo    = ci["2.5%","pct_ls"],    pct_ls_hi    = ci["97.5%","pct_ls"],
    pct_og_lo    = ci["2.5%","pct_og"],    pct_og_hi    = ci["97.5%","pct_og"],
    pct_all_lo   = ci["2.5%","pct_all"],   pct_all_hi   = ci["97.5%","pct_all"],
    acres_trans = sum(grp$plot_acres[grp$lsog_class == "Transitioning LS"], na.rm=TRUE),
    acres_ls    = sum(grp$plot_acres[grp$lsog_class == "LS"], na.rm=TRUE),
    acres_og    = sum(grp$plot_acres[grp$lsog_class == "OG"], na.rm=TRUE),
    acres_all   = sum(grp$plot_acres[grp$lsog_class != "Not LSOG"], na.rm=TRUE),
    ac_all_lo   = ci["2.5%","ac_all"],   ac_all_hi   = ci["97.5%","ac_all"],
    snag_thresh_1 = grp$snag_thresh_1[1], snag_thresh_2 = grp$snag_thresh_2[1]
  )
}

# ---- Run --------------------------------------------------------------------

cat(strrep("=", 70), "\n")
cat(" FIA LSOG Analysis v5 (operational): adds Potapov canopy height\n")
cat(strrep("=", 70), "\n")

all_scored <- map_dfr(STATE_CODES, score_state)

cat("\n  Score and class distributions (latest panel):\n")
latest <- all_scored %>% filter(eval_period == "2019-2023")
print(table(latest$total_score))
print(table(latest$lsog_class))

cat("\n  Bootstrapping...\n")
results <- all_scored %>%
  group_by(state, eval_period, eval_year) %>%
  group_split() %>%
  map_dfr(bootstrap_one)

write_csv(results, file.path(path.expand(out_dir), "fia_lsog_v5_all_states.csv"))
print(results)

# ---- Comparison to Hagan/Thompson 2014-2018 unorganized only ---------------

me_data <- results %>% filter(state == "ME", eval_period == "2014-2018")
if (nrow(me_data) > 0) {
  cat("\n", strrep("=", 70), "\n", sep="")
  cat(" COMPARISON: FIA Proxy v5 vs Hagan/Thompson LiDAR (UT only)\n")
  cat(strrep("=", 70), "\n", sep="")
  cat("\n  Hagan/Thompson 2014-2018 (unorganized townships, 9.5M ac):\n")
  cat(sprintf("    Transitioning LS: 1,637,522 ac  (17.2%%)\n"))
  cat(sprintf("    LS + OG:            400,008 ac   (4.2%%)\n"))
  cat(sprintf("    All LSOG:         2,037,530 ac  (21.4%%)\n"))
  cat("\n  v5 statewide ME 2014-2018:\n")
  cat(sprintf("    Transitioning LS: %s ac  (%.1f%%)\n",
              format(round(me_data$acres_trans), big.mark=","), me_data$pct_trans))
  cat(sprintf("    LS:               %s ac  (%.2f%%)\n",
              format(round(me_data$acres_ls), big.mark=","), me_data$pct_ls))
  cat(sprintf("    OG:               %s ac  (%.3f%%)\n",
              format(round(me_data$acres_og), big.mark=","), me_data$pct_og))
  cat(sprintf("    LS + OG:          %s ac  (%.2f%%)\n",
              format(round(me_data$acres_ls + me_data$acres_og), big.mark=","),
              me_data$pct_ls + me_data$pct_og))
  cat(sprintf("    All LSOG:         %s ac  (%.1f%%)\n",
              format(round(me_data$acres_all), big.mark=","), me_data$pct_all))
}

# ---- Figures ---------------------------------------------------------------

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12),
        axis.text  = element_text(size = 10),
        legend.position = "bottom",
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption  = element_text(size = 8, color = "gray50", hjust = 0))

acre_label <- function(x) ifelse(x >= 1e6,
  paste0(format(round(x / 1e6, 1), nsmall = 1), "M"),
  paste0(format(round(x / 1e3), big.mark = ","), "K"))

for (st in unique(results$state)) {
  rs <- results %>% filter(state == st)
  if (nrow(rs) == 0) next

  pl <- rs %>% select(eval_period, eval_year, pct_trans, pct_ls, pct_og,
                       pct_trans_lo, pct_trans_hi, pct_ls_lo, pct_ls_hi,
                       pct_og_lo, pct_og_hi) %>%
    pivot_longer(cols = c(pct_trans, pct_ls, pct_og),
                 names_to = "cr", values_to = "pct") %>%
    mutate(
      lo = case_when(cr == "pct_trans" ~ pct_trans_lo,
                     cr == "pct_ls"    ~ pct_ls_lo,
                     cr == "pct_og"    ~ pct_og_lo),
      hi = case_when(cr == "pct_trans" ~ pct_trans_hi,
                     cr == "pct_ls"    ~ pct_ls_hi,
                     cr == "pct_og"    ~ pct_og_hi),
      class = factor(case_when(
        cr == "pct_trans" ~ "Transitioning LS",
        cr == "pct_ls"    ~ "LS (Late Successional)",
        cr == "pct_og"    ~ "OG (Old Growth)"),
        levels = c("Transitioning LS","LS (Late Successional)","OG (Old Growth)"))
    )

  p <- ggplot(pl, aes(x = eval_year, y = pct, color = class, fill = class)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.15, color = NA) +
    geom_line(linewidth = 1) + geom_point(size = 2.5) +
    scale_color_manual(values = c("Transitioning LS"="#8FBC8F",
                                   "LS (Late Successional)"="#2E8B57",
                                   "OG (Old Growth)"="#1B4332"),
                        name = "LSOG Class") +
    scale_fill_manual(values = c("Transitioning LS"="#8FBC8F",
                                  "LS (Late Successional)"="#2E8B57",
                                  "OG (Old Growth)"="#1B4332"),
                        name = "LSOG Class") +
    scale_x_continuous(breaks = rs$eval_year, labels = rs$eval_period) +
    scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, NA)) +
    labs(
      title    = paste0("LSOG percent by class (v5): ", st),
      subtitle = "v5 (4/6/8 in /12 score, includes Potapov canopy height) with 95% bootstrap CIs",
      x = "Evaluation Period", y = "Percent of Plots",
      caption = paste0("v5 = v3R relaxed dims + Potapov 2021 RH95 (GLAD/UMD). ",
                       "Bootstrap n = ", format(N_BOOT, big.mark = ","), ".")
    ) + theme_pub
  ggsave(file.path(path.expand(out_dir), paste0("lsog_pct_combined_", st, "_v5.png")),
         p, width = 10, height = 6, dpi = 200, bg = "white")
}

cat("\nDone.\n")
