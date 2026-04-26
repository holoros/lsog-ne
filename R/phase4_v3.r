# =============================================================================
# Phase 4 v3: relaxed dimensional thresholds + logistic recalibration
# =============================================================================
# Improvements over v2:
#   1. Add a "v3R" score variant with relaxed dimensional thresholds:
#      - score_canopy:    BA  >=100 -> >=80 for 1pt;  >=150 -> >=120 for 2pt
#      - score_structure: sd  >=5   -> >=3 for 1pt;   >=8   -> >=6 for 2pt
#      - score_maturity:  max_dia fallback 24 -> 20 for 1pt
#      Keep score_ba_large (large-tree-specific) and score_deadwood unchanged.
#   2. Fit a logistic regression: P(ORNL mature_prob > 50) ~ 5 dimension scores.
#      Report coefficients, AUC, and balanced accuracy at the 0.5 threshold.
#   3. Compare three classifications side-by-side:
#      v3       : default 4/6/8 score thresholds, default dim thresholds
#      v3R      : default 4/6/8 score thresholds, RELAXED dim thresholds
#      v3logit  : logistic predicted probability, threshold 0.5
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
out_dir       <- "~/LSOG/output_phase4/v3"
EVAL_PERIOD   <- list(name = "2019-2023", yr_lo = 2019, yr_hi = 2023)

if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

source("~/LSOG/R/phase4_helpers.r")

# ---- Score with both default and relaxed dimensional thresholds -------------

score_state <- function(st, eval_period) {
  cat(sprintf("\n--- v3 scoring %s panel %s ---\n", st, eval_period$name))

  plot_file <- file.path(path.expand(data_root), paste0(st, "_PLOT.csv"))
  cond_file <- file.path(path.expand(data_root), paste0(st, "_COND.csv"))
  tree_file <- file.path(path.expand(data_root), paste0(st, "_TREE.csv"))

  plot_df <- read_csv(plot_file, show_col_types = FALSE)
  cond_df <- read_csv(cond_file, show_col_types = FALSE)
  tree_df <- read_csv(tree_file, show_col_types = FALSE,
                      col_types = cols(.default = col_guess()))

  pc <- plot_df %>%
    inner_join(cond_df, by = c("CN" = "PLT_CN")) %>%
    filter(COND_STATUS_CD == 1) %>%
    mutate(INVYR = as.integer(INVYR.x %||% INVYR)) %>%
    filter(INVYR >= eval_period$yr_lo, INVYR <= eval_period$yr_hi) %>%
    group_by(CN) %>%
    slice_max(order_by = CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup()

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
      # v3 default scoring
      d_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
      d_maturity = case_when(
        !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
        !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
        (is.na(STDAGE) | STDAGE == 0) & max_dia >= 24 ~ 1L,
        TRUE ~ 0L),
      d_structure = case_when(sd_dia >= 8 ~ 2L, sd_dia >= 5 ~ 1L, TRUE ~ 0L),
      d_canopy    = case_when(ba_total >= 150 ~ 2L, ba_total >= 100 ~ 1L, TRUE ~ 0L),
      d_deadwood  = case_when(snag_tpa >= s2 ~ 2L, snag_tpa >= s1 ~ 1L, TRUE ~ 0L),
      d_total     = d_ba_large + d_maturity + d_structure + d_canopy + d_deadwood,

      # v3R relaxed dimensional thresholds (3 dims relaxed: maturity, structure, canopy)
      r_ba_large = d_ba_large,                          # unchanged
      r_maturity = case_when(
        !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
        !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
        (is.na(STDAGE) | STDAGE == 0) & max_dia >= 20 ~ 1L,    # 24 -> 20
        TRUE ~ 0L),
      r_structure = case_when(sd_dia >= 6 ~ 2L, sd_dia >= 3 ~ 1L, TRUE ~ 0L),  # 8/5 -> 6/3
      r_canopy    = case_when(ba_total >= 120 ~ 2L, ba_total >= 80 ~ 1L, TRUE ~ 0L), # 150/100 -> 120/80
      r_deadwood  = d_deadwood,                          # unchanged
      r_total     = r_ba_large + r_maturity + r_structure + r_canopy + r_deadwood
    )

  out <- scored %>%
    transmute(state = st, eval_period = eval_period$name,
              CN, INVYR, LAT, LON, STDAGE,
              ba_total, ba_large, sd_dia, max_dia, snag_tpa,
              d_ba_large, d_maturity, d_structure, d_canopy, d_deadwood, d_total,
              r_ba_large, r_maturity, r_structure, r_canopy, r_deadwood, r_total,
              snag_thresh_1 = s1, snag_thresh_2 = s2)

  cat(sprintf("  %d plots in %s, snag thresh %d/%d TPA\n",
              nrow(out), eval_period$name, s1, s2))
  out
}

# Helper: classify a score column with given thresholds
classify_col <- function(scored, score_col, t_trans = 4, t_ls = 6, t_og = 8) {
  s <- scored[[score_col]]
  factor(case_when(
    s >= t_og    ~ "OG",
    s >= t_ls    ~ "LS",
    s >= t_trans ~ "Transitioning LS",
    TRUE         ~ "Not LSOG"),
    levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
}

# ---- Run + extract ORNL ------------------------------------------------------

cat(strrep("=", 70), "\n")
cat(" Phase 4 v3: relaxed dimensional thresholds + logistic recalibration\n")
cat(strrep("=", 70), "\n")

all_scored <- map_dfr(STATE_CODES, function(st) score_state(st, EVAL_PERIOD))
if (nrow(all_scored) == 0) stop("No plots scored.")

if (!file.exists(path.expand(ornl_raster))) {
  stop(sprintf("ORNL raster not found: %s", ornl_raster))
}

cat("\n  Reprojecting + extracting ORNL probabilities...\n")
plot_sf  <- to_ease_grid_2(all_scored, lon = "LON", lat = "LAT")
extracted <- extract_ornl_probabilities(plot_sf, path.expand(ornl_raster))
joined <- as_tibble(extracted) %>% select(-any_of("geometry"))

# ---- Apply default-threshold (4/6/8) classifications to BOTH dim variants ----

joined <- joined %>%
  mutate(
    class_default = classify_col(., "d_total"),   # v3 default + default dims
    class_relaxed = classify_col(., "r_total"),   # v3 default + relaxed dims (= v3R)
    ornl_og_50    = if_else(ornl_p_oldgrowth > 50, 1L, 0L),
    ornl_mat_50   = if_else(ornl_p_mature   > 50, 1L, 0L),
    ornl_mog_50   = if_else(pmax(ornl_p_oldgrowth, ornl_p_mature, na.rm = TRUE) > 50, 1L, 0L)
  )

# ---- Logistic fit: predict ORNL mature > 50 from 5 default-dim scores --------

cat("\n--- Logistic fit: P(ORNL mature_prob > 50) ~ 5 dim scores (default thresholds) ---\n")

fit_data <- joined %>%
  filter(!is.na(ornl_mat_50)) %>%
  select(ornl_mat_50, d_ba_large, d_maturity, d_structure, d_canopy, d_deadwood)

# Train/test 80/20
set.seed(42)
n <- nrow(fit_data)
train_idx <- sample.int(n, floor(0.8 * n))
train <- fit_data[train_idx, ]; test <- fit_data[-train_idx, ]

m <- glm(ornl_mat_50 ~ d_ba_large + d_maturity + d_structure + d_canopy + d_deadwood,
         data = train, family = binomial)
print(summary(m)$coefficients)

# AUC (Mann-Whitney form)
auc <- function(y, p) {
  y <- as.integer(y); pos <- p[y == 1]; neg <- p[y == 0]
  if (length(pos) == 0 || length(neg) == 0) return(NA_real_)
  comp <- outer(pos, neg, FUN = ">")
  ties <- outer(pos, neg, FUN = "==")
  (sum(comp) + 0.5 * sum(ties)) / (length(pos) * length(neg))
}

train$pred <- predict(m, train, type = "response")
test$pred  <- predict(m, test,  type = "response")

auc_train <- auc(train$ornl_mat_50, train$pred)
auc_test  <- auc(test$ornl_mat_50,  test$pred)

cat(sprintf("\nAUC train=%.3f, test=%.3f  (n_train=%d, n_test=%d)\n",
            auc_train, auc_test, nrow(train), nrow(test)))

# Balanced accuracy at 0.5
ba_at_thresh <- function(y, p, thr = 0.5) {
  y_hat <- as.integer(p > thr); y <- as.integer(y)
  tp <- sum(y_hat == 1 & y == 1); tn <- sum(y_hat == 0 & y == 0)
  fp <- sum(y_hat == 1 & y == 0); fn <- sum(y_hat == 0 & y == 1)
  tpr <- if (tp + fn > 0) tp / (tp + fn) else NA_real_
  tnr <- if (tn + fp > 0) tn / (tn + fp) else NA_real_
  list(tpr = tpr, tnr = tnr, balanced = (tpr + tnr) / 2,
       confusion = matrix(c(tn, fp, fn, tp), 2, 2,
                          dimnames = list(c("pred_0","pred_1"),
                                          c("ornl_0","ornl_1"))))
}

ba_train <- ba_at_thresh(train$ornl_mat_50, train$pred)
ba_test  <- ba_at_thresh(test$ornl_mat_50,  test$pred)

cat(sprintf("Balanced accuracy at 0.5: train=%.3f, test=%.3f\n",
            ba_train$balanced, ba_test$balanced))
cat("Test confusion at 0.5:\n"); print(ba_test$confusion)

# Apply logit prediction back to whole panel
joined$logit_pred <- predict(m, joined, type = "response")
joined$class_logit <- factor(if_else(joined$logit_pred > 0.5,
                                      "any-LSOG (logit>0.5)", "Not LSOG"),
                              levels = c("Not LSOG", "any-LSOG (logit>0.5)"))

# ---- Three-way comparison summary --------------------------------------------

ornl_pct_mog_gt50  <- 100 * mean(joined$ornl_mog_50,  na.rm = TRUE)
ornl_pct_mat_gt50  <- 100 * mean(joined$ornl_mat_50,  na.rm = TRUE)
ornl_pct_og_gt50   <- 100 * mean(joined$ornl_og_50,   na.rm = TRUE)

three_way <- tibble(
  variant = c("v3 default (4/6/8, default dims)",
              "v3R relaxed dims (4/6/8, BA/sd/max relaxed)",
              "v3 logit (P_mature>50 | scores) > 0.5",
              "ORNL mature_prob > 50 (target)",
              "ORNL MOG_prob > 50 (target)",
              "ORNL OG_prob > 50 (target)"),
  pct_any_lsog = c(
    100 * mean(joined$class_default != "Not LSOG"),
    100 * mean(joined$class_relaxed != "Not LSOG"),
    100 * mean(joined$class_logit  == "any-LSOG (logit>0.5)"),
    ornl_pct_mat_gt50,
    ornl_pct_mog_gt50,
    NA_real_
  ),
  pct_og = c(
    100 * mean(joined$class_default == "OG"),
    100 * mean(joined$class_relaxed == "OG"),
    NA_real_,
    NA_real_,
    NA_real_,
    ornl_pct_og_gt50
  )
)

write_csv(three_way, file.path(path.expand(out_dir), "phase4_v3_three_way_compare.csv"))
print(three_way)

# ---- Coefficient table -------------------------------------------------------

coef_tab <- broom::tidy(m) %>%
  rename(dimension = term) %>%
  mutate(odds_ratio = exp(estimate))
write_csv(coef_tab, file.path(path.expand(out_dir), "phase4_v3_logit_coefficients.csv"))
print(coef_tab)

# Save metric summary
metrics <- tibble(
  auc_train = auc_train, auc_test = auc_test,
  bal_acc_train = ba_train$balanced, bal_acc_test = ba_test$balanced,
  tpr_test = ba_test$tpr, tnr_test = ba_test$tnr,
  n_train = nrow(train), n_test = nrow(test)
)
write_csv(metrics, file.path(path.expand(out_dir), "phase4_v3_logit_metrics.csv"))

# Save full per-plot data including all 3 classifications and ORNL vals
write_csv(joined, file.path(path.expand(out_dir), "phase4_v3_plot_classified_ME_2019-2023.csv"))

# ---- Per-dimension confusion (default vs relaxed scores) ---------------------

dim_compare <- joined %>%
  count(d_total, r_total) %>%
  arrange(desc(n))
write_csv(dim_compare, file.path(path.expand(out_dir), "phase4_v3_score_shift.csv"))

# ---- Quick visualization -----------------------------------------------------

# Bar chart of the three-way comparison (pct any LSOG/MOG only)
plot_data <- three_way %>%
  filter(!is.na(pct_any_lsog)) %>%
  mutate(variant = fct_inorder(variant))

p <- ggplot(plot_data, aes(x = variant, y = pct_any_lsog, fill = variant)) +
  geom_col(alpha = 0.85, color = "white", width = 0.65) +
  geom_text(aes(label = sprintf("%.1f%%", pct_any_lsog)),
            vjust = -0.3, size = 3.5, fontface = "bold") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, NA), expand = expansion(mult = c(0, 0.12))) +
  scale_fill_brewer(type = "qual", palette = "Set2", guide = "none") +
  labs(
    title = "v3 default vs v3R relaxed dims vs logit fit, against ORNL mature/MOG",
    subtitle = sprintf("ME, panel %s, n=%d plots", EVAL_PERIOD$name, nrow(joined)),
    x = NULL, y = "Percent of plots flagged any-LSOG / mature / MOG",
    caption = "ORNL targets are the reference; v3 variants are the proxy classifications."
  ) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1, size = 8.5))

ggsave(file.path(path.expand(out_dir), "phase4_v3_three_way_bar.png"),
       p, width = 11, height = 5.5, dpi = 200, bg = "white")

cat("\nDone.\n")
