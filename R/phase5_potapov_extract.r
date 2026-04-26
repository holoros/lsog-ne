# =============================================================================
# Phase 5: integrate Potapov et al. 2021 GEDI/Landsat canopy height
# =============================================================================
# Adds a sixth dimension to the v3 score system based on plot-level extraction
# of canopy top height (RH95) from the Potapov 30m global forest canopy height
# product. Trained on GEDI L2A footprints between 52N/52S, extrapolated to
# boreal regions. North America continental mosaic covers all of New England.
#
# The new dimension is score_canopy_height, with thresholds:
#   2 pts if RH95 >= 25 m (super-emergent / OG-like canopy)
#   1 pt  if RH95 >= 18 m (closed mature canopy)
#   0 pts if RH95  < 18 m (regenerating / young)
#
# Total score now /12 (was /10). LSOG class thresholds adjust:
#   THRESH_OG    = 9  (was 8)
#   THRESH_LS    = 7  (was 6)
#   THRESH_TRANS = 5  (was 4)
#
# Output:
#   - phase5_plot_classified_<ST>.csv: per-plot scores incl. RH95 + new class
#   - phase5_state_compare.csv: v4 vs v5 vs ORNL share comparison
#   - phase5_logit_coefficients.csv: logistic fit with 6 dim scores
#   - phase5_three_way_bar.png
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
potapov_raster <- "~/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif"
out_dir       <- "~/LSOG/output_phase5"
EVAL_PERIOD   <- list(name = "2019-2023", yr_lo = 2019, yr_hi = 2023)

# v5 thresholds (extended /12 system)
T_TRANS_5 <- 5
T_LS_5    <- 7
T_OG_5    <- 9

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

source("~/LSOG/R/phase4_helpers.r")

# ---- Score plots with v4 dim thresholds (relaxed canopy/structure/maturity) -

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
    filter(INVYR >= EVAL_PERIOD$yr_lo, INVYR <= EVAL_PERIOD$yr_hi) %>%
    group_by(CN) %>% slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>% ungroup()

  td <- tf %>% inner_join(pc %>% select(CN, CONDID), by = c("PLT_CN" = "CN", "CONDID"))
  snag <- td %>% filter(STATUSCD == 2, DIA >= 5.0) %>%
    group_by(PLT_CN) %>% summarise(snag_tpa = sum(TPA_UNADJ, na.rm = TRUE), .groups = "drop")
  live <- td %>% filter(STATUSCD == 1, DIA >= 1.0) %>%
    group_by(PLT_CN) %>% summarise(
      ba_total = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
      ba_large = sum(0.005454 * DIA^2 * TPA_UNADJ * (DIA >= 20), na.rm = TRUE),
      sd_dia   = wt_sd(DIA, TPA_UNADJ),
      max_dia  = max(DIA, na.rm = TRUE),
      .groups = "drop"
    )
  ts <- live %>% left_join(snag, by = "PLT_CN") %>%
    mutate(snag_tpa = replace_na(snag_tpa, 0))
  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  s1 <- if (length(snz) > 10) round(quantile(snz, 0.75)) else 10
  s2 <- if (length(snz) > 10) round(quantile(snz, 0.90)) else 20

  pc %>% left_join(ts, by = c("CN" = "PLT_CN")) %>%
    mutate(across(c(ba_total, ba_large, sd_dia, max_dia, snag_tpa),
                  ~replace_na(.x, 0))) %>%
    mutate(
      # v4 relaxed-dim scoring (the operational v3R baseline)
      score_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
      score_maturity = case_when(
        !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
        !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
        (is.na(STDAGE) | STDAGE == 0) & max_dia >= 20 ~ 1L,   # 24 -> 20
        TRUE ~ 0L),
      score_structure = case_when(sd_dia >= 6 ~ 2L, sd_dia >= 3 ~ 1L, TRUE ~ 0L),  # 8/5 -> 6/3
      score_canopy    = case_when(ba_total >= 120 ~ 2L, ba_total >= 80 ~ 1L, TRUE ~ 0L),  # 150/100 -> 120/80
      score_deadwood  = case_when(snag_tpa >= s2 ~ 2L, snag_tpa >= s1 ~ 1L, TRUE ~ 0L),
      v4_total = score_ba_large + score_maturity + score_structure +
                 score_canopy + score_deadwood,
      state = st, snag_thresh_1 = s1, snag_thresh_2 = s2
    ) %>%
    select(state, CN, INVYR, LAT, LON, STDAGE,
           ba_total, ba_large, sd_dia, max_dia, snag_tpa,
           score_ba_large, score_maturity, score_structure, score_canopy,
           score_deadwood, v4_total, snag_thresh_1, snag_thresh_2)
}

cat(strrep("=", 70), "\n")
cat(" Phase 5: add Potapov canopy height as 6th proxy dimension\n")
cat(strrep("=", 70), "\n")

scored <- map_dfr(STATE_CODES, score_state)
cat(sprintf("\n  scored %d plots total\n", nrow(scored)))

# Reproject for Potapov (WGS84 / EPSG:4326 - it's already in geographic)
cat("\n  extracting Potapov canopy height...\n")
plot_sf_4326 <- scored %>% filter(!is.na(LAT), !is.na(LON)) %>%
  st_as_sf(coords = c("LON", "LAT"), crs = 4326, remove = FALSE)

r_pot <- terra::rast(path.expand(potapov_raster))
v_pot <- terra::extract(r_pot, terra::vect(plot_sf_4326), method = "simple", ID = FALSE)
names(v_pot) <- "potapov_rh95"

# Mask non-data values (101=water, 102=snow, 103=nodata; values <=60 are heights)
v_pot <- v_pot %>% mutate(potapov_rh95 = ifelse(potapov_rh95 > 60, NA_real_, potapov_rh95))

scored_pot <- bind_cols(as_tibble(plot_sf_4326), v_pot) %>%
  select(-any_of("geometry"))

# ---- Score new dimension + extended /12 total -------------------------------

scored_pot <- scored_pot %>%
  mutate(
    score_canopy_height = case_when(
      potapov_rh95 >= 25 ~ 2L,
      potapov_rh95 >= 18 ~ 1L,
      !is.na(potapov_rh95) ~ 0L,
      TRUE ~ 0L                       # missing height treated as 0pts
    ),
    v5_total = v4_total + score_canopy_height,
    v4_class = factor(case_when(
      v4_total >= 8 ~ "OG", v4_total >= 6 ~ "LS",
      v4_total >= 4 ~ "Transitioning LS", TRUE ~ "Not LSOG"),
      levels = c("Not LSOG", "Transitioning LS", "LS", "OG")),
    v5_class = factor(case_when(
      v5_total >= T_OG_5    ~ "OG",
      v5_total >= T_LS_5    ~ "LS",
      v5_total >= T_TRANS_5 ~ "Transitioning LS",
      TRUE                  ~ "Not LSOG"),
      levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
  )

# ---- Now extract ORNL probabilities for the same plots ----------------------

cat("\n  extracting ORNL 2498 probabilities...\n")
plot_sf_ease <- scored_pot %>% filter(!is.na(LAT), !is.na(LON)) %>%
  st_as_sf(coords = c("LON", "LAT"), crs = 4326, remove = FALSE) %>%
  st_transform(6933)
ornl_v <- terra::extract(terra::rast(path.expand(ornl_raster)),
                         terra::vect(plot_sf_ease), method = "simple", ID = FALSE)
names(ornl_v) <- c("ornl_p_nonforest","ornl_p_allforest","ornl_p_other",
                   "ornl_p_mature","ornl_p_oldgrowth")

joined <- bind_cols(scored_pot, ornl_v) %>%
  mutate(
    ornl_mat_50 = if_else(ornl_p_mature   > 50, 1L, 0L),
    ornl_og_50  = if_else(ornl_p_oldgrowth > 50, 1L, 0L),
    ornl_mog_50 = if_else(pmax(ornl_p_oldgrowth, ornl_p_mature, na.rm = TRUE) > 50, 1L, 0L)
  )

write_csv(joined, file.path(path.expand(out_dir), "phase5_plot_classified_ME.csv"))
cat(sprintf("  wrote phase5_plot_classified_ME.csv (%d rows)\n", nrow(joined)))

# ---- Three-way share comparison ---------------------------------------------

three_way <- tibble(
  variant = c("v4 default (4/6/8, /10 score)",
              "v5 with Potapov RH95 (5/7/9, /12 score)",
              "ORNL mature_prob > 50 (target)",
              "ORNL OG_prob > 50 (target)"),
  pct_any_lsog = c(
    100 * mean(joined$v4_class != "Not LSOG"),
    100 * mean(joined$v5_class != "Not LSOG"),
    100 * mean(joined$ornl_mat_50, na.rm = TRUE),
    NA_real_
  ),
  pct_ls_og = c(
    100 * mean(joined$v4_class %in% c("LS","OG")),
    100 * mean(joined$v5_class %in% c("LS","OG")),
    NA_real_,
    NA_real_
  ),
  pct_og = c(
    100 * mean(joined$v4_class == "OG"),
    100 * mean(joined$v5_class == "OG"),
    NA_real_,
    100 * mean(joined$ornl_og_50, na.rm = TRUE)
  )
)

write_csv(three_way, file.path(path.expand(out_dir), "phase5_three_way_compare.csv"))
print(three_way)

# ---- Logistic fit with 6 dim scores -----------------------------------------

cat("\n--- Logit fit P(ORNL mature > 50) ~ 6 dimension scores ---\n")
fit_data <- joined %>% filter(!is.na(ornl_mat_50), !is.na(potapov_rh95)) %>%
  select(ornl_mat_50, score_ba_large, score_maturity, score_structure,
         score_canopy, score_deadwood, score_canopy_height)

set.seed(42)
n <- nrow(fit_data)
ti <- sample.int(n, floor(0.8 * n))
tr <- fit_data[ti, ]; te <- fit_data[-ti, ]

m <- glm(ornl_mat_50 ~ score_ba_large + score_maturity + score_structure +
                       score_canopy + score_deadwood + score_canopy_height,
         data = tr, family = binomial)
print(summary(m)$coefficients)

auc_fn <- function(y, p) {
  pos <- p[y == 1]; neg <- p[y == 0]
  if (length(pos) == 0 || length(neg) == 0) return(NA_real_)
  (sum(outer(pos, neg, ">")) + 0.5 * sum(outer(pos, neg, "=="))) /
    (length(pos) * length(neg))
}

tr$pred <- predict(m, tr, type = "response")
te$pred <- predict(m, te, type = "response")
auc_tr <- auc_fn(tr$ornl_mat_50, tr$pred)
auc_te <- auc_fn(te$ornl_mat_50, te$pred)
cat(sprintf("\nAUC train=%.3f, test=%.3f  (n_train=%d, n_test=%d)\n",
            auc_tr, auc_te, nrow(tr), nrow(te)))

coef_tab <- broom::tidy(m) %>%
  rename(dimension = term) %>% mutate(odds_ratio = exp(estimate))
write_csv(coef_tab, file.path(path.expand(out_dir), "phase5_logit_coefficients.csv"))
print(coef_tab)

write_csv(tibble(auc_train = auc_tr, auc_test = auc_te,
                  n_train = nrow(tr), n_test = nrow(te)),
          file.path(path.expand(out_dir), "phase5_logit_metrics.csv"))

# ---- Bar chart ---------------------------------------------------------------

bar_data <- three_way %>% filter(!is.na(pct_any_lsog)) %>%
  mutate(variant = fct_inorder(variant))

p <- ggplot(bar_data, aes(x = variant, y = pct_any_lsog, fill = variant)) +
  geom_col(alpha = 0.85, color = "white", width = 0.65) +
  geom_text(aes(label = sprintf("%.1f%%", pct_any_lsog)),
            vjust = -0.3, size = 4, fontface = "bold") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, NA), expand = expansion(mult = c(0, 0.12))) +
  scale_fill_brewer(type = "qual", palette = "Set2", guide = "none") +
  labs(
    title = "v5 (with Potapov canopy height) vs v4 vs ORNL mature target",
    subtitle = sprintf("ME, panel %s, n=%d plots", EVAL_PERIOD$name, nrow(joined)),
    x = NULL, y = "Percent of plots flagged any-LSOG / mature",
    caption = "Potapov et al. 2021 30m forest height (GLAD/UMD) added as 6th dim. AUC reported from logit fit."
  ) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1, size = 9))

ggsave(file.path(path.expand(out_dir), "phase5_three_way_bar.png"),
       p, width = 11, height = 5.5, dpi = 200, bg = "white")

cat("\nDone.\n")
