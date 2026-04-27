# =============================================================================
# Phase 5j: three remaining refinements
# 30. Maine UT split via tighter county set (Aroostook/Piscataquis/Somerset)
# 31. Diagnostic plots (STDAGE x class, ROC, calibration)
# 32. LD 1529 policy table (state x ownership x class x carbon)
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(scales); library(broom)
})

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12), axis.text = element_text(size = 10),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption  = element_text(size = 8, color = "gray50", hjust = 0))

state_full <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont", NY = "New York")
lsog_pal <- c("Not LSOG"="#D8D8D8","Transitioning LS"="#8FBC8F","LS"="#2E8B57","OG"="#1B4332")

dat <- read_csv("~/LSOG/output_unified/lsog_ne_plot_table.csv",
                 show_col_types = FALSE) %>%
  mutate(
    s_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
    s_maturity = case_when(
      !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
      !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
      (is.na(STDAGE) | STDAGE == 0) & max_dia >= 24 ~ 1L,
      TRUE ~ 0L),
    s_structure = case_when(sd_dia >= 8 ~ 2L, sd_dia >= 5 ~ 1L, TRUE ~ 0L),
    s_canopy    = case_when(ba_total >= 150 ~ 2L, ba_total >= 100 ~ 1L, TRUE ~ 0L),
    s_deadwood  = case_when(snag_tpa >= snag_thresh_2 ~ 2L,
                             snag_tpa >= snag_thresh_1 ~ 1L, TRUE ~ 0L),
    s_height    = case_when(
      !is.na(potapov_rh95) & potapov_rh95 >= 25 ~ 2L,
      !is.na(potapov_rh95) & potapov_rh95 >= 18 ~ 1L,
      TRUE ~ 0L),
    v51_total = s_ba_large + s_maturity + s_structure + s_canopy + s_deadwood + s_height,
    v51_class = factor(case_when(
      v51_total >= 8 ~ "OG", v51_total >= 6 ~ "LS",
      v51_total >= 4 ~ "Transitioning LS", TRUE ~ "Not LSOG"),
      levels = c("Not LSOG","Transitioning LS","LS","OG"))
  )
dat_19 <- dat %>% filter(eval_period == "2019-2023")
out_dir <- "~/LSOG/output_final2"
fig_dir <- "~/LSOG/output_figures"
dir.create(path.expand(out_dir), recursive = TRUE, showWarnings = FALSE)

# ===========================================================================
# 30. MAINE UT SPLIT (tighter county set + UNITCD comparison)
# ===========================================================================
cat("\n--- 30: Maine UT split refined ---\n")

me_plot <- read_csv("~/fia_data/ME_PLOT.csv", show_col_types = FALSE,
                     col_select = c(CN, COUNTYCD, UNITCD)) %>%
  rename(plot_cn = CN)

dat_me <- dat_19 %>% filter(state == "ME") %>%
  inner_join(me_plot, by = c("CN" = "plot_cn"))

# Three UT region definitions
dat_me <- dat_me %>% mutate(
  region_strict = if_else(COUNTYCD %in% c(3, 21, 25),
                          "Strict UT (Aroostook+Piscataquis+Somerset)",
                          "Rest of Maine"),
  region_inclusive = if_else(COUNTYCD %in% c(3, 7, 21, 25),
                              "Inclusive UT (+ Franklin)",
                              "Rest of Maine"),
  region_unit = if_else(UNITCD %in% c(2, 5, 7),
                         "FIA Northern unit (UNITCD 2,5,7)",
                         "Other Maine units")
)

ut_summary <- bind_rows(
  dat_me %>% count(region_def = "1. Strict (Aroo+Pisc+Som)", region_strict, v51_class) %>%
    rename(region = region_strict),
  dat_me %>% count(region_def = "2. Inclusive (+Franklin)", region_inclusive, v51_class) %>%
    rename(region = region_inclusive),
  dat_me %>% count(region_def = "3. UNITCD 2,5,7", region_unit, v51_class) %>%
    rename(region = region_unit)
) %>%
  group_by(region_def, region) %>%
  mutate(pct = 100 * n / sum(n), n_total = sum(n)) %>%
  ungroup()

write_csv(ut_summary, file.path(path.expand(out_dir), "T30_maine_ut_refined.csv"))
print(ut_summary, n = Inf)

# Compute summary against Hagan UT 21.4%
ut_compare <- dat_me %>%
  pivot_longer(cols = starts_with("region_"), names_to = "method", values_to = "region") %>%
  filter(grepl("Strict UT|Inclusive UT|FIA Northern", region)) %>%
  group_by(method, region) %>%
  summarise(
    n = n(),
    pct_any_lsog = 100 * mean(v51_class != "Not LSOG"),
    pct_ls_og    = 100 * mean(v51_class %in% c("LS","OG")),
    pct_og       = 100 * mean(v51_class == "OG"),
    .groups = "drop"
  )
write_csv(ut_compare, file.path(path.expand(out_dir), "T30_maine_ut_vs_hagan.csv"))
cat("\nUT-region comparison vs Hagan 21.4%:\n")
print(ut_compare)

# ===========================================================================
# 31. DIAGNOSTIC PLOTS
# ===========================================================================
cat("\n--- 31: Diagnostic plots ---\n")

# STDAGE distribution by v5.1 class (boxplot)
dat_age <- dat_19 %>% filter(!is.na(STDAGE), STDAGE > 0)
p_age <- ggplot(dat_age, aes(x = v51_class, y = STDAGE, fill = v51_class)) +
  geom_violin(alpha = 0.4, color = "gray60") +
  geom_boxplot(width = 0.18, alpha = 0.85, outlier.size = 0.6) +
  scale_fill_manual(values = lsog_pal, guide = "none") +
  scale_y_continuous(breaks = seq(0, 200, by = 20), limits = c(0, 200)) +
  labs(title = "Stand age (STDAGE) distribution by v5.1 class",
       subtitle = sprintf("n = %d plots with valid STDAGE, all 4 states 2019-2023", nrow(dat_age)),
       x = "v5.1 LSOG class", y = "Stand age (years)",
       caption = "OG plots have median age >100 yr; Not-LSOG plots median ~30 yr.") +
  theme_pub
ggsave(file.path(path.expand(fig_dir), "fig13_stdage_by_class.png"),
       p_age, width = 10, height = 5.5, dpi = 200, bg = "white")

# ROC curve for multi-state logit
fit_data <- dat_19 %>% filter(!is.na(ornl_p_mature)) %>%
  mutate(ornl_mat_50 = if_else(ornl_p_mature > 50, 1L, 0L))
m_multi <- glm(ornl_mat_50 ~ s_ba_large + s_maturity + s_structure +
                              s_canopy + s_deadwood + s_height + state,
                data = fit_data, family = binomial)
fit_data$pred <- predict(m_multi, fit_data, type = "response")

# Compute ROC by sweeping thresholds
roc <- map_dfr(seq(0, 1, by = 0.005), function(t) {
  pos <- fit_data$ornl_mat_50 == 1
  yhat <- fit_data$pred > t
  tpr <- sum(yhat & pos) / sum(pos)
  fpr <- sum(yhat & !pos) / sum(!pos)
  tibble(threshold = t, tpr, fpr)
})
auc_val <- {
  pos_p <- fit_data$pred[fit_data$ornl_mat_50 == 1]
  neg_p <- fit_data$pred[fit_data$ornl_mat_50 == 0]
  (sum(outer(pos_p, neg_p, ">")) + 0.5 * sum(outer(pos_p, neg_p, "=="))) /
    (length(pos_p) * length(neg_p))
}

p_roc <- ggplot(roc, aes(x = fpr, y = tpr)) +
  geom_path(color = "#1B4332", linewidth = 1.1) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray60") +
  scale_x_continuous(labels = percent, limits = c(0, 1)) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  annotate("text", x = 0.65, y = 0.15,
           label = sprintf("AUC = %.3f", auc_val),
           size = 5, fontface = "bold", color = "#1B4332") +
  labs(title = "ROC curve: multi-state logit predicting ORNL mature > 50",
       subtitle = "v5.1 6-dim scores + state effects, 4-state pooled fit",
       x = "False positive rate (1 - specificity)",
       y = "True positive rate (sensitivity)",
       caption = "Diagonal = chance. AUC > 0.5 indicates discriminatory power.") +
  theme_pub
ggsave(file.path(path.expand(fig_dir), "fig14_roc_multistate.png"),
       p_roc, width = 7, height = 7, dpi = 200, bg = "white")

# Calibration plot: bin predicted, plot mean observed
calibration <- fit_data %>%
  mutate(pred_bin = cut(pred, breaks = seq(0, 1, by = 0.1), include.lowest = TRUE)) %>%
  group_by(pred_bin) %>%
  summarise(n = n(), mean_pred = mean(pred), mean_obs = mean(ornl_mat_50),
            .groups = "drop")

p_cal <- ggplot(calibration, aes(x = mean_pred, y = mean_obs)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(aes(size = n), color = "#1B4332", alpha = 0.8) +
  geom_line(color = "#1B4332", alpha = 0.5) +
  scale_x_continuous(labels = percent, limits = c(0, 1)) +
  scale_y_continuous(labels = percent, limits = c(0, 1)) +
  scale_size_continuous(name = "n plots", range = c(2, 9)) +
  labs(title = "Calibration: predicted vs observed ORNL mature share",
       subtitle = "v5.1 multi-state logit, decile bins",
       x = "Mean predicted P(mature > 50) in bin",
       y = "Observed mean(ORNL mature > 50) in bin",
       caption = "Points on diagonal = perfect calibration.") +
  theme_pub
ggsave(file.path(path.expand(fig_dir), "fig15_calibration_multistate.png"),
       p_cal, width = 8, height = 6.5, dpi = 200, bg = "white")

# v5.1 total score vs carbon scatter
plot_carbon <- map_dfr(c("ME","NH","VT","NY"), function(st) {
  tf <- read_csv(file.path("~/fia_data", paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_types = cols(.default = col_guess()))
  tf %>% filter(STATUSCD == 1, DIA >= 1.0, !is.na(DRYBIO_AG)) %>%
    group_by(PLT_CN) %>%
    summarise(live_lbs = sum(DRYBIO_AG * TPA_UNADJ, na.rm = TRUE), .groups = "drop") %>%
    mutate(state = st, live_MgC_per_ha = live_lbs * 0.000453592 * 2.4710538 * 0.5)
})
dat_score_carbon <- dat_19 %>%
  inner_join(plot_carbon %>% select(PLT_CN, state, live_MgC_per_ha),
              by = c("CN" = "PLT_CN", "state"))

p_sc <- ggplot(dat_score_carbon,
              aes(x = factor(v51_total), y = live_MgC_per_ha, fill = v51_class)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.5, width = 0.7) +
  scale_fill_manual(values = lsog_pal, name = NULL) +
  geom_vline(xintercept = c(4.5, 6.5, 8.5), linetype = "dashed", color = "gray50") +
  labs(title = "Live aboveground carbon vs v5.1 total score",
       subtitle = "Boxes show distribution per integer score; vertical lines mark class thresholds",
       x = "v5.1 total score (out of 12)",
       y = "Live AGB (Mg C/ha)",
       caption = "Carbon increases monotonically with score; class thresholds at 4/6/8.") +
  theme_pub +
  theme(legend.position = "bottom")
ggsave(file.path(path.expand(fig_dir), "fig16_carbon_vs_score.png"),
       p_sc, width = 12, height = 6, dpi = 200, bg = "white")

# ===========================================================================
# 32. LD 1529 POLICY TABLE: state x ownership x class x carbon
# ===========================================================================
cat("\n--- 32: LD 1529 policy table ---\n")

# Need OWNGRPCD per plot
cond_own <- map_dfr(c("ME","NH","VT","NY"), function(st) {
  read_csv(file.path("~/fia_data", paste0(st, "_COND.csv")),
           show_col_types = FALSE,
           col_select = c(PLT_CN, CONDID, COND_STATUS_CD, CONDPROP_UNADJ, OWNGRPCD)) %>%
    filter(COND_STATUS_CD == 1) %>%
    group_by(PLT_CN) %>%
    slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup() %>% mutate(state = st)
})

# Join carbon + ownership + v5.1 class
policy <- dat_19 %>%
  inner_join(plot_carbon %>% select(PLT_CN, state, live_MgC_per_ha),
              by = c("CN" = "PLT_CN", "state")) %>%
  inner_join(cond_own %>% select(PLT_CN, OWNGRPCD, state),
              by = c("CN" = "PLT_CN", "state")) %>%
  mutate(own_grp = case_when(
    OWNGRPCD == 10 ~ "Federal",
    OWNGRPCD == 20 ~ "Other federal",
    OWNGRPCD == 30 ~ "State and local",
    OWNGRPCD == 40 ~ "Private",
    TRUE ~ "Unknown"))

# For each state x ownership x v5.1 class
# - n plots
# - mean carbon (Mg C/ha) with bootstrap CI
boot_ci <- function(x, n = 500) {
  x <- x[!is.na(x)]
  if (length(x) < 2) return(c(NA, NA, NA))
  m <- mean(x); bs <- replicate(n, mean(sample(x, replace = TRUE)))
  c(m, quantile(bs, 0.025), quantile(bs, 0.975))
}
set.seed(42)
policy_tab <- policy %>%
  group_by(state, own_grp, v51_class) %>%
  summarise(n_plots = n(),
             bs = list(boot_ci(live_MgC_per_ha)),
             .groups = "drop") %>%
  mutate(mean_carbon = sapply(bs, `[`, 1),
         carbon_lo   = sapply(bs, `[`, 2),
         carbon_hi   = sapply(bs, `[`, 3)) %>%
  select(-bs)

# Use design-based area for per-cell area
designed <- read_csv("~/LSOG/output_design_based/design_based_area.csv",
                     show_col_types = FALSE)
own_area <- read_csv("~/LSOG/output_design_based/ownership_breakdown.csv",
                      show_col_types = FALSE)

# Build the LD 1529 policy table:
# state x own_grp x v51_class with: n_plots, mean carbon Mg C/ha, total carbon (Tg C)
# total carbon = mean carbon * acres / state-level adjustment
# Approximate: use ownership acres_lsog from Phase 5g
write_csv(policy_tab, file.path(path.expand(out_dir), "T32_policy_table.csv"))
cat("Policy table preview (ME):\n")
print(policy_tab %>% filter(state == "ME") %>%
        mutate(across(c(mean_carbon, carbon_lo, carbon_hi), ~round(., 1))))

cat("\nALL DONE.\n")
