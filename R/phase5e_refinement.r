# =============================================================================
# Phase 5e: refinement sweep over v5 configurations
# Find a defensible configuration with plausible regional pattern
# =============================================================================

suppressPackageStartupMessages({ library(tidyverse) })

# Load unified plot table (has raw FIA inputs + Potapov RH95)
dat <- read_csv("~/LSOG/output_unified/lsog_ne_plot_table.csv",
                show_col_types = FALSE)

cat(sprintf("Loaded %d rows, %d states, %d panels\n",
            nrow(dat), n_distinct(dat$state), n_distinct(dat$eval_period)))

# Score generator: takes raw inputs, returns total + class
score_one <- function(d, dims, rh, class_thresh) {
  s_ba_large <- with(d, case_when(
    ba_large >= dims$ba_large_2 ~ 2L,
    ba_large >= dims$ba_large_1 ~ 1L,
    TRUE ~ 0L))
  s_maturity <- with(d, case_when(
    !is.na(STDAGE) & STDAGE >= dims$stdage_2 ~ 2L,
    !is.na(STDAGE) & STDAGE >= dims$stdage_1 ~ 1L,
    (is.na(STDAGE) | STDAGE == 0) & max_dia >= dims$max_dia ~ 1L,
    TRUE ~ 0L))
  s_structure <- with(d, case_when(
    sd_dia >= dims$sd_dia_2 ~ 2L,
    sd_dia >= dims$sd_dia_1 ~ 1L,
    TRUE ~ 0L))
  s_canopy <- with(d, case_when(
    ba_total >= dims$ba_total_2 ~ 2L,
    ba_total >= dims$ba_total_1 ~ 1L,
    TRUE ~ 0L))
  s_deadwood <- with(d, case_when(
    snag_tpa >= snag_thresh_2 ~ 2L,
    snag_tpa >= snag_thresh_1 ~ 1L,
    TRUE ~ 0L))
  s_height <- with(d, case_when(
    !is.na(potapov_rh95) & potapov_rh95 >= rh$t2 ~ 2L,
    !is.na(potapov_rh95) & potapov_rh95 >= rh$t1 ~ 1L,
    TRUE ~ 0L))
  total <- s_ba_large + s_maturity + s_structure + s_canopy + s_deadwood + s_height
  cls <- factor(case_when(
    total >= class_thresh$og    ~ "OG",
    total >= class_thresh$ls    ~ "LS",
    total >= class_thresh$trans ~ "Transitioning LS",
    TRUE ~ "Not LSOG"),
    levels = c("Not LSOG","Transitioning LS","LS","OG"))
  list(total = total, cls = cls,
       sba = s_ba_large, sm = s_maturity, ss = s_structure,
       sc = s_canopy, sd = s_deadwood, sh = s_height)
}

# Define variant configurations
ORIG_DIMS <- list(
  ba_large_1 = 40,  ba_large_2 = 80,
  stdage_1 = 80,    stdage_2 = 120,
  max_dia = 24,
  sd_dia_1 = 5,     sd_dia_2 = 8,
  ba_total_1 = 100, ba_total_2 = 150
)
RELAXED_DIMS <- list(
  ba_large_1 = 40,  ba_large_2 = 80,
  stdage_1 = 80,    stdage_2 = 120,
  max_dia = 20,
  sd_dia_1 = 3,     sd_dia_2 = 6,
  ba_total_1 = 80,  ba_total_2 = 120
)

variants <- list(
  list(name = "A. v5 current (relaxed dims, 10/20m, 4/6/8)",
       dims = RELAXED_DIMS, rh = list(t1=10,t2=20),
       class_thresh = list(trans=4, ls=6, og=8)),
  list(name = "B. relaxed dims, 18/25m, 4/6/8",
       dims = RELAXED_DIMS, rh = list(t1=18,t2=25),
       class_thresh = list(trans=4, ls=6, og=8)),
  list(name = "C. relaxed dims, 18/25m, 5/7/9 (proportional /12)",
       dims = RELAXED_DIMS, rh = list(t1=18,t2=25),
       class_thresh = list(trans=5, ls=7, og=9)),
  list(name = "D. ORIGINAL dims, 18/25m, 4/6/8",
       dims = ORIG_DIMS, rh = list(t1=18,t2=25),
       class_thresh = list(trans=4, ls=6, og=8)),
  list(name = "E. ORIGINAL dims, 18/25m, 5/7/9",
       dims = ORIG_DIMS, rh = list(t1=18,t2=25),
       class_thresh = list(trans=5, ls=7, og=9)),
  list(name = "F. ORIGINAL dims, 22/28m, 5/7/9 (strictest)",
       dims = ORIG_DIMS, rh = list(t1=22,t2=28),
       class_thresh = list(trans=5, ls=7, og=9))
)

# Compute share by state x panel for each variant
out <- map_dfr(variants, function(v) {
  scored <- score_one(dat, v$dims, v$rh, v$class_thresh)
  d <- dat %>% mutate(cls = scored$cls, tot = scored$total)
  d %>% group_by(state, eval_period) %>%
    summarise(
      pct_any_lsog = 100 * mean(cls != "Not LSOG"),
      pct_ls_og    = 100 * mean(cls %in% c("LS","OG")),
      pct_og       = 100 * mean(cls == "OG"),
      .groups = "drop"
    ) %>% mutate(variant = v$name)
}) %>%
  pivot_wider(names_from = c(state, eval_period),
              values_from = c(pct_any_lsog, pct_ls_og, pct_og),
              names_glue = "{state}_{eval_period}_{.value}")

# Cleaner long format for display
long <- map_dfr(variants, function(v) {
  scored <- score_one(dat, v$dims, v$rh, v$class_thresh)
  d <- dat %>% mutate(cls = scored$cls)
  d %>% group_by(state, eval_period) %>%
    summarise(
      any_lsog = round(100 * mean(cls != "Not LSOG"), 1),
      ls_og    = round(100 * mean(cls %in% c("LS","OG")), 2),
      og       = round(100 * mean(cls == "OG"), 3),
      .groups = "drop"
    ) %>% mutate(variant = v$name)
})

# Compact print: variant x state, all-LSOG percent
cat("\n--- All-LSOG percent by variant x state (latest panel) ---\n")
latest <- long %>% filter(eval_period == "2019-2023")
print(latest %>% select(variant, state, any_lsog) %>%
        pivot_wider(names_from = state, values_from = any_lsog),
      n = Inf, width = Inf)

cat("\n--- LS+OG percent by variant x state (latest panel) ---\n")
print(latest %>% select(variant, state, ls_og) %>%
        pivot_wider(names_from = state, values_from = ls_og),
      n = Inf, width = Inf)

cat("\n--- OG percent by variant x state (latest panel) ---\n")
print(latest %>% select(variant, state, og) %>%
        pivot_wider(names_from = state, values_from = og),
      n = Inf, width = Inf)

# Save full long output
write_csv(long, "~/LSOG/output_unified/v5_variant_sweep.csv")
cat("\nWrote ~/LSOG/output_unified/v5_variant_sweep.csv\n")

# Reference points
cat("\n--- Reference benchmarks ---\n")
cat("Hagan/Thompson 2024 LiDAR (Maine unorganized 9.5M ac):\n")
cat("  Trans LS: 17.2%, LS+OG: 4.2%, all LSOG: 21.4%\n")
cat("ORNL 2498 mature_prob > 50:  ~33% in ME (statewide)\n")
cat("Plausible field-defensible regional ranges:\n")
cat("  ME 15-25%, NH 25-40%, VT 30-45%, NY 25-45% all-LSOG\n")
