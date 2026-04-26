# =============================================================================
# Build figures and maps for v5.1 results
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(scales); library(viridis)
  library(maps); library(sf); library(cowplot)
})

# ---- Theme + palette --------------------------------------------------------

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        axis.title = element_text(size = 12),
        axis.text  = element_text(size = 10),
        legend.position = "bottom",
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption = element_text(size = 8, color = "gray50", hjust = 0))

lsog_pal <- c(
  "Not LSOG"          = "#D8D8D8",
  "Transitioning LS"  = "#8FBC8F",
  "LS"                = "#2E8B57",
  "OG"                = "#1B4332"
)

state_full <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont", NY = "New York")

# ---- Load summary (with bootstrap CIs) and unified plot table --------------

summ <- read_csv("~/LSOG/output_v5/fia_lsog_v5_all_states.csv", show_col_types = FALSE)
plots <- read_csv("~/LSOG/output_unified/lsog_ne_plot_table.csv", show_col_types = FALSE)

# Recompute v5.1 class from raw inputs (original v3 dims + 18/25m RH95 + 4/6/8 in /12)
plots <- plots %>% mutate(
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

# ---- FIGURE 1: All-LSOG percent by state with 95% CIs (latest panel) -------

latest <- summ %>% filter(eval_period == "2019-2023") %>%
  mutate(state_lab = state_full[state],
         state_lab = factor(state_lab, levels = state_full[c("ME","NH","VT","NY")]))

f1 <- ggplot(latest, aes(x = state_lab, y = pct_all)) +
  geom_col(fill = "#2E8B57", alpha = 0.85, width = 0.55) +
  geom_errorbar(aes(ymin = pct_all_lo, ymax = pct_all_hi),
                width = 0.18, linewidth = 0.6, color = "#1B4332") +
  geom_text(aes(label = sprintf("%.1f%%\n(%.1f-%.1f)", pct_all, pct_all_lo, pct_all_hi)),
            vjust = -0.4, size = 3.5, fontface = "bold") +
  scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, NA),
                     expand = expansion(mult = c(0, 0.18))) +
  labs(title = "All-LSOG percent of FIA plots by state (v5.1)",
       subtitle = "FIA panel 2019-2023, 95% bootstrap CIs (n=2,000)",
       x = NULL, y = "Percent of plots in any LSOG class",
       caption = "v5.1 = 6-dimension proxy (5 FIA + Potapov 2021 GEDI canopy height); class thresh 4/6/8 in /12.") +
  theme_pub
ggsave("~/LSOG/output_figures/fig1_state_all_lsog_pct.png",
       f1, width = 9, height = 5.5, dpi = 200, bg = "white")

# ---- FIGURE 2: Stacked composition (TLS / LS / OG / Not LSOG) by state ------

stack <- summ %>% filter(eval_period == "2019-2023") %>%
  mutate(state_lab = factor(state_full[state],
                             levels = state_full[c("ME","NH","VT","NY")])) %>%
  select(state_lab, pct_trans, pct_ls, pct_og) %>%
  mutate(pct_not = 100 - pct_trans - pct_ls - pct_og) %>%
  pivot_longer(cols = c(pct_not, pct_trans, pct_ls, pct_og),
               names_to = "class_short", values_to = "pct") %>%
  mutate(class = factor(case_when(
    class_short == "pct_not"   ~ "Not LSOG",
    class_short == "pct_trans" ~ "Transitioning LS",
    class_short == "pct_ls"    ~ "LS",
    class_short == "pct_og"    ~ "OG"),
    levels = c("Not LSOG","Transitioning LS","LS","OG")))

f2 <- ggplot(stack, aes(x = state_lab, y = pct, fill = class)) +
  geom_col(alpha = 0.9, width = 0.6, color = "white", linewidth = 0.3) +
  scale_fill_manual(values = lsog_pal, name = "LSOG class") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     expand = expansion(mult = c(0, 0.04))) +
  labs(title = "LSOG class composition by state (v5.1)",
       subtitle = "FIA panel 2019-2023, percent of plots",
       x = NULL, y = "Percent of plots") +
  theme_pub
ggsave("~/LSOG/output_figures/fig2_state_class_composition.png",
       f2, width = 9, height = 5.5, dpi = 200, bg = "white")

# ---- FIGURE 3: v4 long time series (1999-2023) ------------------------------

v4 <- read_csv("~/LSOG/output_v4/fia_lsog_all_states_v4.csv", show_col_types = FALSE)
v4 <- v4 %>% mutate(state_lab = factor(state_full[state],
                                       levels = state_full[c("ME","NH","VT","NY")]))

f3 <- ggplot(v4, aes(x = eval_year, y = pct_all_lsog, color = state_lab, group = state_lab)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5) +
  scale_color_brewer(type = "qual", palette = "Set1", name = "State") +
  scale_x_continuous(breaks = unique(v4$eval_year), labels = unique(v4$eval_period)) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, NA)) +
  labs(title = "All-LSOG percent over time, 1999-2023 (v4 baseline, no GEDI dim)",
       subtitle = "v4 uses 5 FIA dimensions only, comparable across all FIA panels",
       x = "FIA evaluation period", y = "Percent of plots in any LSOG class",
       caption = "Northeast forests aging: NH and NY roughly doubled their LSOG share over 20 years.") +
  theme_pub +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave("~/LSOG/output_figures/fig3_v4_timeseries_1999_2023.png",
       f3, width = 11, height = 5.5, dpi = 200, bg = "white")

# ---- FIGURE 4: Acres-by-class (latest panel) -------------------------------

acres <- summ %>% filter(eval_period == "2019-2023") %>%
  mutate(state_lab = factor(state_full[state],
                            levels = state_full[c("ME","NH","VT","NY")])) %>%
  select(state_lab, acres_trans, acres_ls, acres_og) %>%
  pivot_longer(cols = c(acres_trans, acres_ls, acres_og),
               names_to = "cls", values_to = "acres") %>%
  mutate(class = factor(case_when(
    cls == "acres_trans" ~ "Transitioning LS",
    cls == "acres_ls"    ~ "LS",
    cls == "acres_og"    ~ "OG"),
    levels = c("Transitioning LS","LS","OG")))

acre_lab <- function(x) ifelse(x >= 1e6, sprintf("%.1fM", x/1e6),
                                ifelse(x >= 1e3, sprintf("%.0fK", x/1e3),
                                       sprintf("%.0f", x)))

f4 <- ggplot(acres, aes(x = state_lab, y = acres, fill = class)) +
  geom_col(alpha = 0.9, width = 0.6, color = "white", linewidth = 0.3,
           position = position_stack()) +
  scale_fill_manual(values = lsog_pal[c("Transitioning LS","LS","OG")],
                    name = "LSOG class") +
  scale_y_continuous(labels = acre_lab, expand = expansion(mult = c(0, 0.06))) +
  labs(title = "LSOG acres by class and state (v5.1)",
       subtitle = "FIA panel 2019-2023, FIA-EXPNS or state-forest-area expansion",
       x = NULL, y = "Acres") +
  theme_pub
ggsave("~/LSOG/output_figures/fig4_state_acres_stacked.png",
       f4, width = 9, height = 5.5, dpi = 200, bg = "white")

# ---- MAPS ----------------------------------------------------------------

# state polygons
state_sf <- sf::st_as_sf(maps::map("state", regions = c("maine","new hampshire",
                                    "vermont","new york"), plot = FALSE, fill = TRUE))
state_sf <- state_sf %>% mutate(state_full = ID)

# Latest panel plot points only
plots_latest <- plots %>% filter(eval_period == "2019-2023",
                                 !is.na(LAT), !is.na(LON))

plot_sf <- sf::st_as_sf(plots_latest, coords = c("LON","LAT"), crs = 4326,
                        remove = FALSE)

# ---- MAP 1: Maine plot map -------------------------------------------------

me_state <- state_sf %>% filter(state_full == "maine")
me_plots <- plot_sf %>% filter(state == "ME")
me_plots <- me_plots %>%
  mutate(class_ord = factor(v51_class,
                            levels = c("Not LSOG","Transitioning LS","LS","OG"))) %>%
  arrange(class_ord)  # plot LSOG points on top

m1 <- ggplot() +
  geom_sf(data = me_state, fill = "#F7F7F4", color = "gray40", linewidth = 0.4) +
  geom_sf(data = me_plots, aes(color = class_ord, size = class_ord, alpha = class_ord)) +
  scale_color_manual(values = lsog_pal, name = "v5.1 class") +
  scale_size_manual(values = c("Not LSOG"=0.6, "Transitioning LS"=1.0,
                               "LS"=1.6, "OG"=2.4), guide = "none") +
  scale_alpha_manual(values = c("Not LSOG"=0.3, "Transitioning LS"=0.7,
                                "LS"=0.85, "OG"=1.0), guide = "none") +
  labs(title = "Maine FIA plots by v5.1 LSOG class",
       subtitle = sprintf("FIA panel 2019-2023, n=%d plots; LSOG plots emphasized",
                          nrow(me_plots)),
       caption = "Locations are FIA-public lat/lon (fuzzed up to ~1 km).") +
  guides(color = guide_legend(override.aes = list(size = c(2.5, 2.5, 2.5, 2.5),
                                                   alpha = c(0.5, 0.85, 1, 1)))) +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(color = "gray30", size = 10),
        plot.caption  = element_text(color = "gray50", size = 8, hjust = 0),
        legend.position = "right")
ggsave("~/LSOG/output_figures/map1_maine_plot_class.png",
       m1, width = 9, height = 11, dpi = 200, bg = "white")

# ---- MAP 2: Regional NE plot map -------------------------------------------

state_full_lower <- state_sf %>%
  mutate(name_short = c("maine"="ME","new hampshire"="NH",
                         "vermont"="VT","new york"="NY")[state_full])

reg_plots <- plot_sf %>%
  mutate(class_ord = factor(v51_class,
                            levels = c("Not LSOG","Transitioning LS","LS","OG"))) %>%
  arrange(class_ord)

m2 <- ggplot() +
  geom_sf(data = state_sf, fill = "#F7F7F4", color = "gray40", linewidth = 0.4) +
  geom_sf(data = reg_plots,
          aes(color = class_ord, size = class_ord, alpha = class_ord)) +
  scale_color_manual(values = lsog_pal, name = "v5.1 class") +
  scale_size_manual(values = c("Not LSOG"=0.5, "Transitioning LS"=0.8,
                               "LS"=1.4, "OG"=2.2), guide = "none") +
  scale_alpha_manual(values = c("Not LSOG"=0.25, "Transitioning LS"=0.65,
                                "LS"=0.85, "OG"=1.0), guide = "none") +
  labs(title = "Northeast FIA plots by v5.1 LSOG class",
       subtitle = "ME, NH, VT, NY FIA panel 2019-2023",
       caption = "FIA-public lat/lon; LSOG plots emphasized in size and saturation.") +
  guides(color = guide_legend(override.aes = list(size = c(2.5, 2.5, 2.5, 2.5),
                                                  alpha = c(0.5, 0.85, 1, 1)))) +
  theme_void(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(color = "gray30", size = 10),
        plot.caption  = element_text(color = "gray50", size = 8, hjust = 0),
        legend.position = "right")
ggsave("~/LSOG/output_figures/map2_ne_plot_class.png",
       m2, width = 12, height = 9, dpi = 200, bg = "white")

# ---- FIGURE 5: Score distribution by state ---------------------------------

f5 <- ggplot(plots %>% filter(eval_period == "2019-2023") %>%
              mutate(state_lab = factor(state_full[state],
                                        levels = state_full[c("ME","NH","VT","NY")])),
              aes(x = v51_total, fill = state_lab)) +
  geom_histogram(binwidth = 1, color = "white", linewidth = 0.2) +
  facet_wrap(~state_lab, scales = "free_y", ncol = 4) +
  scale_x_continuous(breaks = 0:12) +
  scale_fill_brewer(type = "qual", palette = "Set1", guide = "none") +
  geom_vline(xintercept = c(4, 6, 8), linetype = "dashed", color = "gray40") +
  labs(title = "v5.1 total-score histogram by state",
       subtitle = "Class thresholds: TLS >=4 (green), LS >=6 (darker green), OG >=8 (darkest)",
       x = "v5.1 total score (out of 12)", y = "Plot count",
       caption = "Vertical dashed lines mark class thresholds.") +
  theme_pub +
  theme(panel.grid.major.x = element_line(color = "gray90"))
ggsave("~/LSOG/output_figures/fig5_v51_score_dist.png",
       f5, width = 12, height = 4.5, dpi = 200, bg = "white")

cat("\n=== Outputs ===\n")
list.files("~/LSOG/output_figures")
