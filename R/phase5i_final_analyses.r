# =============================================================================
# Phase 5i: 10 final refinements (A-J)
# A. Maine unorganized vs organized split (county-based proxy)
# B. Carbon x ownership cross-tabulation
# C. Species composition of LSOG plots
# D. Ownership CIs (bootstrap)
# E. Multi-state logistic recalibration
# F. Plot-level "near-LSOG" probability map
# G. (in separate report assembler)
# H. Patch-level spatial clustering (Moran's I)
# I. Trend test statistics
# J. State-by-state RH95 sensitivity
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(scales); library(broom); library(viridis)
  library(maps); library(sf)
})

STATE_CODES <- c("ME","NH","VT","NY")
data_root   <- "~/LSOG/data/fia"
plot_table  <- "~/LSOG/output_unified/lsog_ne_plot_table.csv"
out_dir     <- "~/LSOG/output_final"
fig_dir     <- "~/LSOG/output_figures"
if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12), axis.text = element_text(size = 10),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption  = element_text(size = 8, color = "gray50", hjust = 0))
state_full <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont", NY = "New York")
lsog_pal <- c("Not LSOG"="#D8D8D8","Transitioning LS"="#8FBC8F","LS"="#2E8B57","OG"="#1B4332")

# Load + recompute v5.1
dat <- read_csv(path.expand(plot_table), show_col_types = FALSE) %>%
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

# Helper for bootstrap CI of mean
boot_ci <- function(x, n = 1000) {
  x <- x[!is.na(x)]
  if (length(x) < 2) return(c(NA, NA, NA))
  m <- mean(x); bs <- replicate(n, mean(sample(x, replace = TRUE)))
  c(m, quantile(bs, 0.025), quantile(bs, 0.975))
}

# ===========================================================================
# A. MAINE UNORGANIZED vs ORGANIZED SPLIT
# ===========================================================================
cat("\n--- A: Maine unorganized vs organized split ---\n")

# Read full ME plot to get COUNTYCD - take ME plots and join with COUNTYCD
me_plot <- read_csv(file.path(path.expand(data_root), "ME_PLOT.csv"),
                    show_col_types = FALSE,
                    col_select = c(CN, COUNTYCD)) %>%
  rename(plot_cn = CN)

# Maine UT-dominated counties (FIPS county codes):
# 003 Aroostook, 007 Franklin, 019 Penobscot (mixed), 021 Piscataquis,
# 025 Somerset, 029 Washington (mixed)
# Pure-UT proxy: 003, 021, 025, 007 (most of Franklin)
UT_COUNTIES <- c(3, 7, 21, 25, 29)   # treating these as "northern Maine / largely UT"

dat_me <- dat_19 %>% filter(state == "ME") %>%
  inner_join(me_plot, by = c("CN" = "plot_cn")) %>%
  mutate(region = if_else(COUNTYCD %in% UT_COUNTIES,
                          "Northern Maine (UT-dominated)", "Southern Maine"))

a_summary <- dat_me %>%
  count(region, v51_class) %>%
  group_by(region) %>%
  mutate(pct = 100 * n / sum(n), n_total = sum(n)) %>%
  ungroup()
write_csv(a_summary, file.path(path.expand(out_dir), "A_maine_ut_split.csv"))
print(a_summary)

# Compare to Hagan UT-only
me_north <- dat_me %>% filter(region == "Northern Maine (UT-dominated)")
cat(sprintf("\nNorthern ME (n=%d, county-based UT proxy):\n", nrow(me_north)))
cat(sprintf("  TLS  %.1f%%  vs Hagan UT 17.2%%\n",
            100 * mean(me_north$v51_class == "Transitioning LS")))
cat(sprintf("  LS+OG %.2f%%  vs Hagan UT 4.2%%\n",
            100 * mean(me_north$v51_class %in% c("LS","OG"))))
cat(sprintf("  All LSOG %.1f%%  vs Hagan UT 21.4%%\n",
            100 * mean(me_north$v51_class != "Not LSOG")))

# ===========================================================================
# B. CARBON x OWNERSHIP CROSS-TABULATION
# ===========================================================================
cat("\n--- B: Carbon x ownership ---\n")

# Recompute plot-level live AGB (Mg C/ha) from TREE files
# For efficiency, only do this for plots in the 2019-2023 panel
cat("  computing plot-level carbon...\n")
plot_carbon <- map_dfr(STATE_CODES, function(st) {
  tf <- read_csv(file.path(path.expand(data_root), paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_types = cols(.default = col_guess()))
  tf %>% filter(STATUSCD == 1, DIA >= 1.0, !is.na(DRYBIO_AG)) %>%
    group_by(PLT_CN, CONDID) %>%
    summarise(
      live_lbs_per_acre = sum(DRYBIO_AG * TPA_UNADJ, na.rm = TRUE),
      .groups = "drop") %>%
    mutate(state = st,
           live_MgC_per_ha = live_lbs_per_acre * 0.000453592 * 2.4710538 * 0.5)
})

# Read OWNGRPCD per plot from COND
cond_own <- map_dfr(STATE_CODES, function(st) {
  read_csv(file.path(path.expand(data_root), paste0(st, "_COND.csv")),
           show_col_types = FALSE,
           col_select = c(PLT_CN, CONDID, COND_STATUS_CD, CONDPROP_UNADJ, OWNGRPCD)) %>%
    filter(COND_STATUS_CD == 1) %>%
    group_by(PLT_CN) %>%
    slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup() %>% mutate(state = st)
})

dat_co <- dat_19 %>%
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

set.seed(42)
b_summary <- dat_co %>%
  group_by(state, own_grp, v51_class) %>%
  summarise(
    n_plots = n(),
    bs = list(boot_ci(live_MgC_per_ha)),
    .groups = "drop") %>%
  mutate(carbon_mean = sapply(bs, `[`, 1),
         carbon_lo   = sapply(bs, `[`, 2),
         carbon_hi   = sapply(bs, `[`, 3)) %>%
  select(-bs)

write_csv(b_summary, file.path(path.expand(out_dir), "B_carbon_by_ownership_class.csv"))
cat("  carbon Mg C/ha by ownership x class - sample:\n")
print(b_summary %>% filter(state == "ME"))

# ===========================================================================
# C. SPECIES COMPOSITION OF LSOG PLOTS
# ===========================================================================
cat("\n--- C: Species composition ---\n")

# Per-plot dominant species by BA
plot_species <- map_dfr(STATE_CODES, function(st) {
  tf <- read_csv(file.path(path.expand(data_root), paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_select = c(PLT_CN, CONDID, SPCD, STATUSCD, DIA, TPA_UNADJ),
                 col_types = cols(.default = col_guess()))
  tf %>% filter(STATUSCD == 1, DIA >= 1.0) %>%
    group_by(PLT_CN, SPCD) %>%
    summarise(ba = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
              .groups = "drop") %>%
    group_by(PLT_CN) %>%
    slice_max(ba, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    mutate(state = st)
})

# Common species names (standard FIA SPCD codes)
spcd_names <- tribble(
  ~SPCD, ~species,
  12,    "Balsam fir",
  16,    "Eastern hemlock",
  43,    "Atlantic white-cedar",
  68,    "Northern white-cedar",
  91,    "Eastern white pine",
  93,    "Black spruce",
  94,    "White spruce",
  95,    "Norway spruce",
  97,    "Red spruce",
  121,   "Pitch pine",
  125,   "Red pine",
  129,   "Eastern white pine",
  261,   "Eastern hemlock",
  306,   "Sugar maple",
  315,   "Striped maple",
  316,   "Red maple",
  318,   "Sugar maple",
  371,   "Yellow birch",
  372,   "Sweet birch",
  375,   "Paper birch",
  379,   "Gray birch",
  402,   "American hornbeam",
  407,   "Pignut hickory",
  409,   "Shagbark hickory",
  531,   "American beech",
  541,   "Black ash",
  544,   "White ash",
  545,   "Green ash",
  546,   "American elm",
  601,   "Black walnut",
  602,   "Butternut",
  701,   "Bigtooth aspen",
  741,   "Quaking aspen",
  743,   "Bigtooth aspen",
  746,   "Quaking aspen",
  762,   "Black cherry",
  802,   "White oak",
  812,   "Bur oak",
  823,   "Bur oak",
  833,   "Northern red oak",
  837,   "Eastern white oak",
  837,   "Eastern white oak",
  855,   "Scarlet oak",
  951,   "American basswood"
)

dat_sp <- dat_19 %>%
  inner_join(plot_species %>% select(PLT_CN, SPCD, state),
             by = c("CN" = "PLT_CN", "state")) %>%
  left_join(spcd_names, by = "SPCD") %>%
  mutate(species = if_else(is.na(species),
                            paste0("SPCD-", SPCD), species))

c_summary <- dat_sp %>%
  filter(v51_class %in% c("Transitioning LS","LS","OG")) %>%
  count(state, v51_class, species) %>%
  group_by(state, v51_class) %>%
  arrange(desc(n)) %>%
  slice_head(n = 5) %>%
  ungroup()
write_csv(c_summary, file.path(path.expand(out_dir), "C_species_composition.csv"))
cat("  top 5 species per state x LSOG class:\n")
print(c_summary, n = Inf)

# ===========================================================================
# D. OWNERSHIP CIs (bootstrap of LSOG percent within each owner group)
# ===========================================================================
cat("\n--- D: Ownership CIs ---\n")

set.seed(42)
d_summary <- dat_co %>%
  group_by(state, own_grp) %>%
  group_split() %>%
  map_dfr(function(g) {
    n <- nrow(g)
    if (n < 5) return(tibble())
    pct_lsog   <- 100 * mean(g$v51_class != "Not LSOG")
    pct_lsog_g <- 100 * mean(g$v51_class %in% c("LS","OG"))
    pct_og     <- 100 * mean(g$v51_class == "OG")
    bs <- replicate(1000, {
      idx <- sample.int(n, replace = TRUE)
      cls <- g$v51_class[idx]
      c(100 * mean(cls != "Not LSOG"),
        100 * mean(cls %in% c("LS","OG")),
        100 * mean(cls == "OG"))
    })
    tibble(
      state = g$state[1], own_grp = g$own_grp[1], n_plots = n,
      pct_lsog, pct_lsog_lo = quantile(bs[1,], 0.025),
      pct_lsog_hi = quantile(bs[1,], 0.975),
      pct_lsog_g, pct_lsog_g_lo = quantile(bs[2,], 0.025),
      pct_lsog_g_hi = quantile(bs[2,], 0.975),
      pct_og, pct_og_lo = quantile(bs[3,], 0.025),
      pct_og_hi = quantile(bs[3,], 0.975)
    )
  })
write_csv(d_summary, file.path(path.expand(out_dir), "D_ownership_with_ci.csv"))
print(d_summary %>% filter(state == "ME") %>% select(state, own_grp, n_plots,
        pct_lsog, pct_lsog_lo, pct_lsog_hi))

# ===========================================================================
# E. MULTI-STATE LOGISTIC RECALIBRATION
# ===========================================================================
cat("\n--- E: Multi-state logit fit ---\n")

# Need ORNL probs - already in unified table
fit_data <- dat_19 %>% filter(!is.na(ornl_p_mature)) %>%
  mutate(ornl_mat_50 = if_else(ornl_p_mature > 50, 1L, 0L))

m_multi <- glm(ornl_mat_50 ~ s_ba_large + s_maturity + s_structure +
                              s_canopy + s_deadwood + s_height + state,
                data = fit_data, family = binomial)
me_coefs <- broom::tidy(m_multi) %>% mutate(odds_ratio = exp(estimate))
write_csv(me_coefs, file.path(path.expand(out_dir), "E_multistate_logit_coefs.csv"))
cat("  multi-state logit coefs (target: ORNL mature > 50):\n")
print(me_coefs)

# ===========================================================================
# F. PLOT-LEVEL "near-LSOG" PROBABILITY MAP - generate predictions
# ===========================================================================
cat("\n--- F: Plot-level probability ---\n")

dat_pred <- fit_data %>%
  mutate(p_mature = predict(m_multi, ., type = "response"))
write_csv(dat_pred %>% select(state, eval_period, CN, LAT, LON,
                                p_mature, v51_class, v51_total),
          file.path(path.expand(out_dir), "F_plot_predicted_probability.csv"))

# Probability map (Northeast)
state_sf <- sf::st_as_sf(maps::map("state", regions = c("maine","new hampshire",
                                  "vermont","new york"), plot = FALSE, fill = TRUE))
plot_sf <- sf::st_as_sf(dat_pred %>% filter(!is.na(LAT), !is.na(LON)),
                        coords = c("LON","LAT"), crs = 4326)
m_prob <- ggplot() +
  geom_sf(data = state_sf, fill = "#F7F7F4", color = "gray40", linewidth = 0.4) +
  geom_sf(data = plot_sf, aes(color = p_mature), size = 0.7, alpha = 0.8) +
  scale_color_viridis_c(option = "magma", direction = -1, name = "P(mature)",
                        limits = c(0, 1)) +
  labs(title = "Predicted P(ORNL mature > 50) at FIA plot locations",
       subtitle = "v5.1 multi-state logit, FIA panel 2019-2023",
       caption = "Logit fit on 6 dim scores + state effect; high prob = high LSOG-like signal.") +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(color = "gray30", size = 10),
        plot.caption  = element_text(color = "gray50", size = 8, hjust = 0),
        legend.position = "right")
ggsave(file.path(path.expand(fig_dir), "fig12_predicted_probability_map.png"),
       m_prob, width = 12, height = 9, dpi = 200, bg = "white")

# ===========================================================================
# H. SPATIAL CLUSTERING (simple distance-to-nearest-LSOG measure)
# ===========================================================================
cat("\n--- H: Spatial clustering ---\n")

# For each state, compute LSOG plot density vs random expectation
spatial_results <- map_dfr(STATE_CODES, function(st) {
  d <- dat_19 %>% filter(state == st, !is.na(LAT), !is.na(LON))
  lsog <- d %>% filter(v51_class != "Not LSOG")
  if (nrow(lsog) < 10) return(tibble())

  # Distance from each LSOG plot to nearest other LSOG plot
  pts <- as.matrix(lsog[, c("LON","LAT")])
  if (nrow(pts) < 2) return(tibble())
  d_mat <- as.matrix(dist(pts))
  diag(d_mat) <- NA
  nearest_lsog_dist <- apply(d_mat, 1, min, na.rm = TRUE)

  # Same for random subsample of all plots
  set.seed(42)
  rand_idx <- sample.int(nrow(d), nrow(lsog))
  rand_pts <- as.matrix(d[rand_idx, c("LON","LAT")])
  rd_mat <- as.matrix(dist(rand_pts))
  diag(rd_mat) <- NA
  nearest_rand_dist <- apply(rd_mat, 1, min, na.rm = TRUE)

  tibble(state = st,
         lsog_mean_nearest_deg = mean(nearest_lsog_dist),
         random_mean_nearest_deg = mean(nearest_rand_dist),
         clustering_ratio = mean(nearest_rand_dist) / mean(nearest_lsog_dist),
         n_lsog = nrow(lsog))
})
write_csv(spatial_results, file.path(path.expand(out_dir), "H_spatial_clustering.csv"))
cat("  clustering ratio (random / LSOG nearest-distance, >1 means LSOG clustered):\n")
print(spatial_results)

# ===========================================================================
# I. TREND TESTS (linear regression on v4 1999-2023)
# ===========================================================================
cat("\n--- I: Trend tests ---\n")

v4 <- read_csv("~/LSOG/output_v4/fia_lsog_all_states_v4.csv", show_col_types = FALSE)
trends <- v4 %>% group_by(state) %>%
  summarise(
    fit = list(lm(pct_all_lsog ~ eval_year)),
    .groups = "drop"
  ) %>%
  mutate(
    coefs = lapply(fit, broom::tidy)
  ) %>%
  select(state, coefs) %>%
  unnest(coefs) %>%
  filter(term == "eval_year") %>%
  rename(slope = estimate, slope_se = std.error,
         t_stat = statistic, p_value = p.value) %>%
  mutate(slope_per_decade = slope * 10)

write_csv(trends, file.path(path.expand(out_dir), "I_trend_tests.csv"))
print(trends)

# ===========================================================================
# J. STATE-BY-STATE RH95 SENSITIVITY
# ===========================================================================
cat("\n--- J: State-by-state RH95 sensitivity ---\n")

j_results <- map_dfr(STATE_CODES, function(st) {
  d <- dat_19 %>% filter(state == st, !is.na(ornl_p_mature), !is.na(potapov_rh95)) %>%
    mutate(ornl_mat_50 = if_else(ornl_p_mature > 50, 1L, 0L))
  if (nrow(d) < 50) return(tibble())

  grid <- expand_grid(t1 = c(8, 10, 12, 14, 16, 18), t2 = c(18, 20, 22, 25)) %>%
    filter(t1 < t2)

  pmap_dfr(grid, function(t1, t2) {
    sch <- with(d, case_when(
      potapov_rh95 >= t2 ~ 2L,
      potapov_rh95 >= t1 ~ 1L,
      TRUE ~ 0L))
    total <- d$s_ba_large + d$s_maturity + d$s_structure + d$s_canopy +
             d$s_deadwood + sch
    cls <- as.integer(total >= 4)  # any LSOG
    fp <- sum(cls == 1 & d$ornl_mat_50 == 0)
    fn <- sum(cls == 0 & d$ornl_mat_50 == 1)
    tp <- sum(cls == 1 & d$ornl_mat_50 == 1)
    tn <- sum(cls == 0 & d$ornl_mat_50 == 0)
    n <- nrow(d)
    po <- (tp + tn) / n
    pe <- ((tp+fp)/n) * ((tp+fn)/n) + ((tn+fn)/n) * ((tn+fp)/n)
    kappa <- (po - pe) / (1 - pe)
    tibble(state = st, t1, t2, kappa,
           pct_any = 100 * mean(cls == 1))
  })
}) %>%
  group_by(state) %>%
  arrange(desc(kappa)) %>%
  slice_head(n = 3) %>%
  ungroup()

write_csv(j_results, file.path(path.expand(out_dir), "J_state_rh95_sensitivity.csv"))
print(j_results)

cat("\nALL DONE.\n")
