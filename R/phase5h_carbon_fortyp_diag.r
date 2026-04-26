# =============================================================================
# Phase 5h: carbon stocks + forest type breakdown + OG plot diagnostics
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(scales)
})

STATE_CODES <- c("ME","NH","VT","NY")
data_root   <- "~/LSOG/data/fia"
plot_table  <- "~/LSOG/output_unified/lsog_ne_plot_table.csv"
out_dir     <- "~/LSOG/output_extras"
fig_dir     <- "~/LSOG/output_figures"
if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

# Load unified table, compute v5.1 class
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
  ) %>% filter(eval_period == "2019-2023")

cat(sprintf("Plots in 2019-2023 panel: %d\n", nrow(dat)))

# ---- 1) CARBON STOCKS BY V5.1 CLASS ----------------------------------------

# Compute plot-level total aboveground biomass (lbs/acre) and convert to
# Mg C / ha
compute_plot_carbon <- function(st) {
  cat(sprintf("  loading %s_TREE.csv ...\n", st))
  tf <- read_csv(file.path(path.expand(data_root), paste0(st, "_TREE.csv")),
                 show_col_types = FALSE,
                 col_types = cols(.default = col_guess()))

  # Aboveground biomass in lbs per acre = sum(DRYBIO_AG * TPA_UNADJ)
  # Live trees only, DBH >= 1"
  tf %>% filter(STATUSCD == 1, DIA >= 1.0, !is.na(DRYBIO_AG)) %>%
    group_by(PLT_CN, CONDID) %>%
    summarise(
      live_lbs_per_acre = sum(DRYBIO_AG * TPA_UNADJ, na.rm = TRUE),
      n_trees           = n(),
      .groups = "drop"
    )
}

cat("\n=== computing plot-level live biomass per state ===\n")
plot_bio <- map_dfr(STATE_CODES, function(st)
  compute_plot_carbon(st) %>% mutate(state = st))

# Convert lbs/acre -> Mg C / ha
# 1 lb = 0.000453592 Mg ; per acre to per ha = 2.471
# Multiply by 0.5 to get carbon from biomass
plot_bio <- plot_bio %>% mutate(
  live_MgC_per_ha = live_lbs_per_acre * 0.000453592 * 2.4710538 * 0.5
)

# Join carbon to v5.1 classified plots
dat_c <- dat %>% select(state, CN, eval_period, v51_class, v51_total) %>%
  left_join(plot_bio, by = c("CN" = "PLT_CN", "state"))

# Mean carbon by class with bootstrap CI
boot_mean_ci <- function(x, n = 2000) {
  x <- x[!is.na(x)]
  if (length(x) < 2) return(c(mean = NA, lo = NA, hi = NA))
  m <- mean(x)
  bs <- replicate(n, mean(sample(x, replace = TRUE)))
  c(mean = m, lo = quantile(bs, 0.025), hi = quantile(bs, 0.975))
}

set.seed(42)
carbon_summary <- dat_c %>% filter(!is.na(live_MgC_per_ha)) %>%
  group_by(state, v51_class) %>%
  summarise(
    n_plots = n(),
    bs = list(boot_mean_ci(live_MgC_per_ha, 1000)),
    .groups = "drop"
  ) %>%
  unnest_wider(bs)

write_csv(carbon_summary, file.path(path.expand(out_dir), "carbon_by_class.csv"))
cat("\n=== Carbon stocks (live AGB Mg C/ha) by class ===\n")
print(carbon_summary %>% mutate(across(c(mean, `lo.2.5%`, `hi.97.5%`), ~round(., 1))))

# ---- 2) FOREST TYPE BREAKDOWN ----------------------------------------------

# We need FORTYPCD from COND. Read just the columns we need.
cat("\n=== forest type breakdown ===\n")

read_cond_fortyp <- function(st) {
  cf <- read_csv(file.path(path.expand(data_root), paste0(st, "_COND.csv")),
                 show_col_types = FALSE,
                 col_select = c(PLT_CN, CONDID, COND_STATUS_CD, CONDPROP_UNADJ, FORTYPCD))
  cf %>% filter(COND_STATUS_CD == 1) %>%
    group_by(PLT_CN) %>% slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup() %>% mutate(state = st)
}

cond_ftyp <- map_dfr(STATE_CODES, read_cond_fortyp)

# Map FORTYPCD to forest-type group names
fortyp_group <- function(code) {
  case_when(
    code %in% 101:140 ~ "White-red-jack pine",
    code %in% 121:129 ~ "Spruce-fir",
    code %in% 161:170 ~ "Loblolly-shortleaf pine",
    code %in% 401:409 ~ "Oak-pine",
    code %in% 501:509 ~ "Oak-hickory",
    code %in% 601:609 ~ "Oak-gum-cypress",
    code %in% 701:709 ~ "Elm-ash-cottonwood",
    code %in% 801:809 ~ "Maple-beech-birch",
    code %in% 901:909 ~ "Aspen-birch",
    code == 999       ~ "Nonstocked",
    is.na(code)       ~ "Unknown",
    TRUE              ~ paste0("Other (", code, ")")
  )
}

dat_f <- dat %>% select(state, CN, v51_class) %>%
  inner_join(cond_ftyp %>% select(PLT_CN, state, FORTYPCD), by = c("CN" = "PLT_CN", "state"))

dat_f <- dat_f %>% mutate(fort_grp = fortyp_group(FORTYPCD))

# Top-level summary: distribution of LSOG class within each forest type group
fortyp_summary <- dat_f %>%
  count(state, fort_grp, v51_class) %>%
  group_by(state, fort_grp) %>%
  mutate(pct = 100 * n / sum(n), n_total = sum(n)) %>%
  ungroup()

write_csv(fortyp_summary, file.path(path.expand(out_dir), "fortyp_by_class.csv"))
cat("\nForest type x v5.1 class (top groups):\n")
print(fortyp_summary %>% filter(n_total >= 50) %>% arrange(state, fort_grp, v51_class))

# ---- 3) OG/LS PLOT DIAGNOSTICS ---------------------------------------------

cat("\n=== OG plot diagnostics ===\n")

og_plots <- dat %>% filter(v51_class == "OG")
ls_plots <- dat %>% filter(v51_class == "LS")
near_og  <- dat %>% filter(v51_total %in% c(6, 7))   # LS or just-below-OG

cat(sprintf("OG plots: %d, LS plots: %d, near-OG (score 6-7): %d\n",
            nrow(og_plots), nrow(ls_plots), nrow(near_og)))

# What dim scores characterize OG plots? Compare mean dim scores
dim_means <- bind_rows(
  og_plots %>% mutate(grp = "OG (score >=8)"),
  ls_plots %>% mutate(grp = "LS (6-7)"),
  dat %>% filter(v51_class == "Transitioning LS") %>% mutate(grp = "TLS (4-5)"),
  dat %>% filter(v51_class == "Not LSOG") %>% mutate(grp = "Not LSOG (<4)")
) %>%
  group_by(grp) %>%
  summarise(across(c(s_ba_large, s_maturity, s_structure, s_canopy,
                      s_deadwood, s_height), mean, .names = "mean_{col}"),
             .groups = "drop")

write_csv(dim_means, file.path(path.expand(out_dir), "og_dim_score_means.csv"))
print(dim_means)

# For OG plots specifically: what are their actual values?
og_detail <- og_plots %>%
  select(state, CN, INVYR, ba_total, ba_large, sd_dia, max_dia, snag_tpa,
         STDAGE, potapov_rh95, v51_total) %>%
  arrange(desc(v51_total))
write_csv(og_detail, file.path(path.expand(out_dir), "og_plot_detail.csv"))
cat("\nAll OG plots in panel 2019-2023:\n")
print(og_detail)

# What's limiting near-OG plots? Average gap from 2pt max per dimension
gap_means <- near_og %>%
  summarise(
    gap_ba_large  = mean(2 - s_ba_large),
    gap_maturity  = mean(2 - s_maturity),
    gap_structure = mean(2 - s_structure),
    gap_canopy    = mean(2 - s_canopy),
    gap_deadwood  = mean(2 - s_deadwood),
    gap_height    = mean(2 - s_height)
  )
cat("\nAvg points-from-2pt-max for near-OG plots (score 6-7):\n")
print(gap_means)
write_csv(gap_means, file.path(path.expand(out_dir), "near_og_gap_means.csv"))

# ---- FIGURES ---------------------------------------------------------------

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12), axis.text = element_text(size = 10),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption  = element_text(size = 8, color = "gray50", hjust = 0))

state_full <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont", NY = "New York")
lsog_pal <- c("Not LSOG"="#D8D8D8","Transitioning LS"="#8FBC8F","LS"="#2E8B57","OG"="#1B4332")

# Fig 10: Carbon by LSOG class
f10 <- ggplot(carbon_summary,
              aes(x = factor(state_full[state],
                              levels = state_full[c("ME","NH","VT","NY")]),
                  y = mean, fill = v51_class)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65, alpha = 0.85,
           color = "white", linewidth = 0.3) +
  geom_errorbar(aes(ymin = `lo.2.5%`, ymax = `hi.97.5%`),
                position = position_dodge(width = 0.75), width = 0.18,
                linewidth = 0.4, color = "#1B4332") +
  geom_text(aes(label = sprintf("%.0f", mean)),
            position = position_dodge(width = 0.75), vjust = -0.3, size = 3) +
  scale_fill_manual(values = lsog_pal, name = "v5.1 class") +
  labs(title = "Live aboveground carbon stocks by LSOG class (Mg C/ha)",
       subtitle = "FIA panel 2019-2023, mean with 95% bootstrap CIs",
       x = NULL, y = "Live aboveground carbon (Mg C/ha)",
       caption = "Carbon = 0.5 * DRYBIO_AG; FIA TREE table; live trees DBH >= 1in.") +
  theme_pub +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 20, hjust = 1, size = 9))
ggsave(file.path(path.expand(fig_dir), "fig10_carbon_by_class.png"),
       f10, width = 12, height = 5.5, dpi = 200, bg = "white")

# Fig 11: forest type x LSOG class composition
fortyp_plot <- fortyp_summary %>%
  filter(n_total >= 100, fort_grp != "Unknown", fort_grp != "Nonstocked") %>%
  filter(state == "ME")

f11 <- ggplot(fortyp_plot,
              aes(x = fort_grp, y = pct, fill = v51_class)) +
  geom_col(position = "stack", alpha = 0.85, width = 0.65, color = "white") +
  scale_fill_manual(values = lsog_pal, name = "v5.1 class") +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(title = "Maine: LSOG class composition by forest type group",
       subtitle = "FIA panel 2019-2023, types with >=100 plots",
       x = NULL, y = "Percent of plots in forest type group",
       caption = "FORTYPCD groups; spruce-fir and maple-beech-birch dominate Maine.") +
  theme_pub +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 25, hjust = 1, size = 9))
ggsave(file.path(path.expand(fig_dir), "fig11_fortyp_class_ME.png"),
       f11, width = 11, height = 5.5, dpi = 200, bg = "white")

cat("\nDone. Outputs in", out_dir, "and", fig_dir, "\n")
