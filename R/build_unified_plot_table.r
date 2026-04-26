# =============================================================================
# Unified per-plot analytical table for Northeast LSOG project
# Produces one row per FIA plot per panel per state, joining all proxy
# classifications, ORNL 2498 probabilities, and Potapov canopy height.
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse); library(sf); library(terra)
})

STATE_CODES   <- c("ME","NH","VT","NY")
data_root     <- "~/LSOG/data/fia"
ornl_raster   <- "~/LSOG/data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m_lzw.tif"
potapov_raster <- "~/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif"
out_path      <- "~/LSOG/output_unified/lsog_ne_plot_table.csv"

EVAL_BREAKS <- tribble(
  ~eval_period, ~yr_lo, ~yr_hi, ~eval_year,
  "2014-2018",   2014,   2018,   2016,
  "2019-2023",   2019,   2023,   2021
)

source("~/LSOG/R/phase4_helpers.r")

score_state <- function(st) {
  cat(sprintf("scoring %s...\n", st))
  pf <- read_csv(file.path(path.expand(data_root), paste0(st, "_PLOT.csv")),
                 show_col_types = FALSE)
  cf <- read_csv(file.path(path.expand(data_root), paste0(st, "_COND.csv")),
                 show_col_types = FALSE)
  tf <- read_csv(file.path(path.expand(data_root), paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_types = cols(.default = col_guess()))

  pc <- pf %>% inner_join(cf, by = c("CN" = "PLT_CN")) %>%
    filter(COND_STATUS_CD == 1) %>%
    mutate(INVYR = as.integer(INVYR.x %||% INVYR)) %>%
    inner_join(EVAL_BREAKS, by = character()) %>%
    filter(INVYR >= yr_lo, INVYR <= yr_hi) %>%
    group_by(CN, eval_period) %>%
    slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>% ungroup()

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
  ts <- live %>% left_join(snag, by = c("PLT_CN","eval_period")) %>%
    mutate(snag_tpa = replace_na(snag_tpa, 0))
  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  s1 <- if (length(snz) > 10) round(quantile(snz, 0.75)) else 10
  s2 <- if (length(snz) > 10) round(quantile(snz, 0.90)) else 20

  pc %>% left_join(ts, by = c("CN" = "PLT_CN", "eval_period")) %>%
    mutate(across(c(ba_total, ba_large, sd_dia, max_dia, snag_tpa),
                  ~replace_na(.x, 0))) %>%
    transmute(state = st, eval_period, eval_year, CN, INVYR, LAT, LON,
              STDAGE, ba_total, ba_large, sd_dia, max_dia, snag_tpa,
              snag_thresh_1 = s1, snag_thresh_2 = s2,
              # v4 default (relaxed dims)
              s_ba_large_v4 = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
              s_maturity_v4 = case_when(
                !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
                !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
                (is.na(STDAGE) | STDAGE == 0) & max_dia >= 20 ~ 1L,
                TRUE ~ 0L),
              s_structure_v4 = case_when(sd_dia >= 6 ~ 2L, sd_dia >= 3 ~ 1L, TRUE ~ 0L),
              s_canopy_v4    = case_when(ba_total >= 120 ~ 2L, ba_total >= 80 ~ 1L, TRUE ~ 0L),
              s_deadwood_v4  = case_when(snag_tpa >= s2 ~ 2L, snag_tpa >= s1 ~ 1L, TRUE ~ 0L),
              v4_total = s_ba_large_v4 + s_maturity_v4 + s_structure_v4 +
                         s_canopy_v4 + s_deadwood_v4,
              v4_class = factor(case_when(
                v4_total >= 8 ~ "OG", v4_total >= 6 ~ "LS",
                v4_total >= 4 ~ "Transitioning LS", TRUE ~ "Not LSOG"),
                levels = c("Not LSOG","Transitioning LS","LS","OG")))
}

cat("=== scoring all states ===\n")
all_scored <- map_dfr(STATE_CODES, score_state)
cat(sprintf("\ntotal: %d plot-period rows\n", nrow(all_scored)))

# ---- Extract Potapov RH95 (WGS84) ------------------------------------------

cat("\nExtracting Potapov RH95...\n")
sf_pot <- all_scored %>% filter(!is.na(LAT), !is.na(LON)) %>%
  st_as_sf(coords = c("LON","LAT"), crs = 4326, remove = FALSE)
rh95 <- terra::extract(terra::rast(path.expand(potapov_raster)),
                       terra::vect(sf_pot), method = "simple", ID = FALSE)
all_scored$potapov_rh95 <- ifelse(rh95[[1]] > 60, NA_real_, rh95[[1]])

# ---- Extract ORNL probabilities (EPSG:6933) --------------------------------

cat("Extracting ORNL probabilities...\n")
sf_ornl <- all_scored %>% filter(!is.na(LAT), !is.na(LON)) %>%
  st_as_sf(coords = c("LON","LAT"), crs = 4326, remove = FALSE) %>%
  st_transform(6933)
ornl_v <- terra::extract(terra::rast(path.expand(ornl_raster)),
                         terra::vect(sf_ornl), method = "simple", ID = FALSE)
names(ornl_v) <- c("ornl_p_nonforest","ornl_p_allforest","ornl_p_other",
                   "ornl_p_mature","ornl_p_oldgrowth")
all_scored <- bind_cols(all_scored, ornl_v)

# ---- Add v5 score (with Potapov), v5b class, score_canopy_height ----------

all_scored <- all_scored %>% mutate(
  s_canopy_height = case_when(
    !is.na(potapov_rh95) & potapov_rh95 >= 25 ~ 2L,
    !is.na(potapov_rh95) & potapov_rh95 >= 18 ~ 1L,
    TRUE ~ 0L),
  v5_total = v4_total + s_canopy_height,
  v5_class = factor(case_when(
    v5_total >= 9 ~ "OG", v5_total >= 7 ~ "LS",
    v5_total >= 5 ~ "Transitioning LS", TRUE ~ "Not LSOG"),
    levels = c("Not LSOG","Transitioning LS","LS","OG")),
  v5b_class = factor(case_when(
    v5_total >= 8 ~ "OG", v5_total >= 6 ~ "LS",
    v5_total >= 4 ~ "Transitioning LS", TRUE ~ "Not LSOG"),
    levels = c("Not LSOG","Transitioning LS","LS","OG"))
)

# ---- Write output -----------------------------------------------------------

write_csv(all_scored, path.expand(out_path))
cat(sprintf("\nwrote %s (%d rows, %d columns)\n",
            out_path, nrow(all_scored), ncol(all_scored)))

cat("\nState x panel x v5b class counts:\n")
all_scored %>% count(state, eval_period, v5b_class) %>%
  pivot_wider(names_from = v5b_class, values_from = n, values_fill = 0) %>%
  print(n = Inf)

cat("\nDone.\n")
