suppressPackageStartupMessages({
  library(tidyverse); library(scales); library(viridis)
})

theme_pub <- theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_text(size = 12), axis.text = element_text(size = 10),
        plot.title = element_text(size = 14, face = "bold"),
        plot.subtitle = element_text(size = 10, color = "gray30"),
        plot.caption  = element_text(size = 8, color = "gray50", hjust = 0))

state_full <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont", NY = "New York")
acre_lab <- function(x) ifelse(x >= 1e6, sprintf("%.1fM", x/1e6),
                                ifelse(x >= 1e3, sprintf("%.0fK", x/1e3),
                                       sprintf("%.0f", x)))

area  <- read_csv("~/LSOG/output_design_based/design_based_area.csv", show_col_types = FALSE)
own   <- read_csv("~/LSOG/output_design_based/ownership_breakdown.csv", show_col_types = FALSE)
boot  <- read_csv("~/LSOG/output_v5/fia_lsog_v5_all_states.csv",        show_col_types = FALSE)

# Filter to latest panel only
area_2019 <- area %>% filter(panel == "2019-2023")
own_2019  <- own  %>% filter(panel == "2019-2023")
boot_2019 <- boot %>% filter(eval_period == "2019-2023")

# ---- Fig 6: design-based vs bootstrap shares -------------------------------

# Compare percent-of-forested (design) vs percent-of-plots (bootstrap)
db_pct <- area_2019 %>% filter(class %in% c("any LSOG","LS+OG","OG")) %>%
  mutate(method = "Design-based (% of forested area)") %>%
  select(state, panel, class, pct = pct_of_forested, method)

bs_pct <- boot_2019 %>% transmute(
  state, panel = eval_period,
  any_LSOG = pct_all, LSOG_g = pct_ls + pct_og, OG = pct_og
) %>% pivot_longer(cols = c(any_LSOG, LSOG_g, OG),
                   names_to = "class", values_to = "pct") %>%
  mutate(class = recode(class, any_LSOG = "any LSOG", LSOG_g = "LS+OG"),
         method = "Bootstrap (% of FIA plots)")

cmp <- bind_rows(db_pct, bs_pct) %>%
  mutate(state_lab = factor(state_full[state], levels = state_full[c("ME","NH","VT","NY")]),
         class_ord = factor(class, levels = c("any LSOG","LS+OG","OG")))

f6 <- ggplot(cmp, aes(x = state_lab, y = pct, fill = method)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85,
           color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.1f", pct)),
            position = position_dodge(width = 0.7), vjust = -0.4, size = 3) +
  facet_wrap(~class_ord, scales = "free_y") +
  scale_fill_manual(values = c("Bootstrap (% of FIA plots)" = "#8FBC8F",
                                "Design-based (% of forested area)" = "#1B4332"),
                    name = NULL) +
  labs(title = "Bootstrap (plot-share) vs design-based (forested-area-share) estimates",
       subtitle = "v5.1, FIA panel 2019-2023; design-based uses POP_STRATUM EXPNS + post-stratified SE",
       x = NULL, y = "Percent",
       caption = "Two methods agree closely. Design-based is the FIA-standard reporting basis.") +
  theme_pub +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 25, hjust = 1, size = 9))
ggsave("~/LSOG/output_figures/fig6_bootstrap_vs_designbased.png",
       f6, width = 12, height = 5.5, dpi = 200, bg = "white")

# ---- Fig 7: design-based acres with 95% CI by state x class -----------------

ac_plot <- area_2019 %>% filter(class %in% c("any LSOG","LS+OG","OG")) %>%
  mutate(state_lab = factor(state_full[state], levels = state_full[c("ME","NH","VT","NY")]),
         class_ord = factor(class, levels = c("any LSOG","LS+OG","OG")))

f7 <- ggplot(ac_plot, aes(x = state_lab, y = total_acres, fill = class_ord)) +
  geom_col(width = 0.55, alpha = 0.85, color = "white") +
  geom_errorbar(aes(ymin = ci_lo, ymax = ci_hi),
                width = 0.18, linewidth = 0.5, color = "#1B4332") +
  geom_text(aes(label = acre_lab(total_acres)), vjust = -0.6, size = 3.5,
            fontface = "bold") +
  facet_wrap(~class_ord, scales = "free_y") +
  scale_fill_manual(values = c("any LSOG"="#8FBC8F","LS+OG"="#2E8B57","OG"="#1B4332"),
                    name = NULL, guide = "none") +
  scale_y_continuous(labels = acre_lab, expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Design-based acres by class with FIA post-stratified 95% CI",
       subtitle = "v5.1, FIA panel 2019-2023",
       x = NULL, y = "Acres",
       caption = "CIs from FIA design-based estimator: Sum_h (EXPNS_h^2 * n_h * s_h^2)") +
  theme_pub +
  theme(axis.text.x = element_text(angle = 20, hjust = 1, size = 9))
ggsave("~/LSOG/output_figures/fig7_designbased_acres_ci.png",
       f7, width = 12, height = 5.5, dpi = 200, bg = "white")

# ---- Fig 8: ownership breakdown ----------------------------------------------

own_plot <- own_2019 %>% filter(own_grp != "Unknown") %>%
  mutate(state_lab = factor(state_full[state], levels = state_full[c("ME","NH","VT","NY")]),
         own_grp = factor(own_grp,
                          levels = c("Private","State and local","Federal","Other federal")))

f8 <- ggplot(own_plot, aes(x = state_lab, y = pct_lsog, fill = own_grp)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65, alpha = 0.85,
           color = "white", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.0f%%", pct_lsog)),
            position = position_dodge(width = 0.75), vjust = -0.3, size = 3) +
  scale_fill_brewer(type = "qual", palette = "Set2", name = "Owner group") +
  labs(title = "Any-LSOG percent of forested area by ownership and state",
       subtitle = "v5.1, FIA panel 2019-2023; OWNGRPCD codes",
       x = NULL, y = "Percent any-LSOG of forested area in owner group",
       caption = "Federal/Other-federal often have higher LSOG share but smaller acreage.") +
  theme_pub +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 20, hjust = 1, size = 9))
ggsave("~/LSOG/output_figures/fig8_ownership_lsog_pct.png",
       f8, width = 12, height = 5.5, dpi = 200, bg = "white")

# ---- Fig 9: ownership breakdown - acres -----------------------------------

f9 <- ggplot(own_plot, aes(x = state_lab, y = acres_lsog, fill = own_grp)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.65, alpha = 0.85,
           color = "white", linewidth = 0.3) +
  geom_text(aes(label = acre_lab(acres_lsog)),
            position = position_dodge(width = 0.75), vjust = -0.3, size = 3) +
  scale_fill_brewer(type = "qual", palette = "Set2", name = "Owner group") +
  scale_y_continuous(labels = acre_lab, expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Any-LSOG acres by ownership and state (v5.1)",
       subtitle = "FIA panel 2019-2023; design-based EXPNS-weighted",
       x = NULL, y = "Acres in any LSOG class",
       caption = "Most LSOG acres are on private land in absolute terms.") +
  theme_pub +
  theme(legend.position = "bottom",
        axis.text.x = element_text(angle = 20, hjust = 1, size = 9))
ggsave("~/LSOG/output_figures/fig9_ownership_lsog_acres.png",
       f9, width = 12, height = 5.5, dpi = 200, bg = "white")

# Print key tables
cat("\n=== Design-based summary, latest panel ===\n")
print(area_2019 %>% mutate(across(c(total_acres, se_acres, ci_lo, ci_hi),
                                   ~round(., 0))))

cat("\n=== Ownership LSOG percent of forested ===\n")
print(own_2019 %>% select(state, own_grp, n_plots,
                            acres_forested, pct_lsog, pct_lsog_g, pct_og) %>%
      mutate(across(c(acres_forested), ~round(., 0)),
             across(c(pct_lsog, pct_lsog_g, pct_og), ~round(., 2))))
