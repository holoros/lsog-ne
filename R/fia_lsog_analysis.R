###############################################################################
# FIA-Based LSOG Classification for Maine
# Implementing the Our Climate Common LSOG RAP (v2.0) Framework
# Using USDA Forest Inventory and Analysis Data
#
# Author: Aaron Weiskittel / Claude collaboration
# Date: March 2026
#
# Purpose:
#   Approximate the 17-metric LSOG Rapid Assessment Protocol (Shamgochian
#   et al. 2025) using FIA TREE, COND, and PLOT tables. Classify FIA plots
#   into four LSOG classes (Not LSOG, Transitioning LS, LS, Old Growth),
#   estimate the proportion of Maine forestland in each class, and visualize
#   trends from 1995 to the present.
#
# Important caveats:
#   FIA does not collect all 17 RAP metrics. Epiphyte presence (Metrics
#   12 through 17), pit-and-mound microtopography (Metric 2), and treefall
#   gap observations (Metric 1) are not available. This script uses a
#   scoring system grounded in the quantitative structural data from
#   Appendix A of the RAP document to approximate LSOG class membership.
#
# Data requirements:
#   Download Maine FIA CSV tables from the FIA DataMart:
#   https://apps.fs.usda.gov/fia/datamart/datamart.html
#   Required files: ME_TREE.csv, ME_COND.csv, ME_PLOT.csv
#   Place them in a working directory and set the path below.
###############################################################################

# =============================================================================
# 0. Setup
# =============================================================================

library(tidyverse)
library(scales)

# Set your data directory here
data_dir <- "/home/aweiskittel/Documents/MAINE/DATA/FIA/ME/"  # adjust to wherever your FIA CSVs live

# FIA constants
ACRES_PER_HA     <- 2.47105
IN_PER_CM        <- 0.393701
DBH_THRESHOLD_IN <- 16  # 40 cm ~ 15.75 in; RAP uses 16 in

# Maine FIPS state code
STATE_ME <- 23

# Shade-intolerant species codes (FIA SPCD) for Maine
# Quaking aspen (746), bigtooth aspen (743), paper birch (375),
# mountain paper birch (379)
SHADE_INTOL_SPCD <- c(746, 743, 375, 379)

# =============================================================================
# 1. Load and Filter FIA Data
# =============================================================================

cat("Loading FIA tables...\n")

plot_raw <- read_csv(file.path(data_dir, "ME_PLOT.csv"),
                     show_col_types = FALSE)
cond_raw <- read_csv(file.path(data_dir, "ME_COND.csv"),
                     show_col_types = FALSE)
tree_raw <- read_csv(file.path(data_dir, "ME_TREE.csv"),
                     show_col_types = FALSE)

# Filter to sampled plots in Maine
# PLOT_STATUS_CD == 1 means sampled
plot_df <- plot_raw %>%
  filter(STATECD == STATE_ME,
         PLOT_STATUS_CD == 1) %>%
  select(CN, STATECD, UNITCD, COUNTYCD, PLOT, INVYR,
         LAT, LON, DESIGNCD, PLOT_STATUS_CD,
         any_of("MEESSION"))

# Create a unique plot key that persists across remeasurements
plot_df <- plot_df %>%
  mutate(PLT_KEY = paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "_"))

# Use any_of() for columns that may not exist in all DataMart versions
# COND_STATUS_CD == 1 means forested (accessible)
cond_df <- cond_raw %>%
  filter(COND_STATUS_CD == 1) %>%
  select(PLT_CN, CONDID, COND_STATUS_CD, CONDPROP_UNADJ,
         STDAGE, STDSZCD, FORTYPCD,
         DSTRBCD1, DSTRBCD2, DSTRBCD3,
         TRTCD1, TRTCD2, TRTCD3,
         SICOND, BALIVE,
         starts_with("OWNGRPCD"),
         any_of(c("FORTYPGRPCD", "FLDTYPCD", "EXPNS", "EXPCURR")))

tree_df <- tree_raw %>%
  select(PLT_CN, CONDID, SUBP, TREE, STATUSCD,
         SPCD, DIA, HT, ACTUALHT,
         TPA_UNADJ, DRYBIO_AG, CARBON_AG,
         CCLCD, TREECLCD, DECAYCD,
         CR, CDIEBKCD,
         any_of(c("STANDING_DEAD_CD", "PREVDIA")))

cat(sprintf("  Plots: %d records across %d inventory years\n",
            nrow(plot_df), n_distinct(plot_df$INVYR)))
cat(sprintf("  Conditions: %d records\n", nrow(cond_df)))
cat(sprintf("  Trees: %d records\n", nrow(tree_df)))

# =============================================================================
# 2. Join Tables and Compute Plot-Level Metrics
# =============================================================================

cat("Computing plot-level structural metrics...\n")

# Join plot info to conditions
plot_cond <- plot_df %>%
  inner_join(cond_df, by = c("CN" = "PLT_CN")) %>%
  # Keep only the dominant condition per plot
  group_by(CN) %>%
  slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
  ungroup()

# Build the column list for the join dynamically
join_cols <- c("CN", "PLT_KEY", "INVYR", "CONDID",
               "STDAGE", "FORTYPCD",
               "DSTRBCD1", "TRTCD1", "TRTCD2", "TRTCD3",
               "CONDPROP_UNADJ", "LAT", "LON")
for (opt_col in c("FORTYPGRPCD", "FLDTYPCD")) {
  if (opt_col %in% names(plot_cond)) join_cols <- c(join_cols, opt_col)
}

tree_plot <- tree_df %>%
  inner_join(
    plot_cond %>% select(all_of(join_cols)),
    by = c("PLT_CN" = "CN", "CONDID")
  )

# Build dynamic grouping columns for the summarise step
group_cols <- c("PLT_CN", "PLT_KEY", "INVYR", "CONDID", "STDAGE",
                "FORTYPCD", "DSTRBCD1", "TRTCD1", "TRTCD2", "TRTCD3",
                "CONDPROP_UNADJ", "LAT", "LON")
for (opt_col in c("FORTYPGRPCD", "FLDTYPCD")) {
  if (opt_col %in% names(tree_plot)) group_cols <- c(group_cols, opt_col)
}

# --------------------------------------------------------------------------
# Compute per-plot structural metrics inspired by the RAP and Appendix A
# --------------------------------------------------------------------------

plot_metrics <- tree_plot %>%
  group_by(across(all_of(group_cols))) %>%
  summarise(
    # --- RAP Metric 5 proxy: large live trees per hectare ---
    # TPA_UNADJ is trees per acre; convert to per hectare
    n_large_live_ha = sum(
      TPA_UNADJ[STATUSCD == 1 & DIA >= DBH_THRESHOLD_IN],
      na.rm = TRUE
    ) * ACRES_PER_HA,

    # --- RAP Metric 6 proxy: large dead trees (snags) per hectare ---
    n_large_dead_ha = sum(
      TPA_UNADJ[STATUSCD == 2 & DIA >= DBH_THRESHOLD_IN],
      na.rm = TRUE
    ) * ACRES_PER_HA,

    # --- RAP Metric 11 proxy: shade-intolerant stems in overstory ---
    # CCLCD: 1=open grown, 2=dominant, 3=codominant
    n_shade_intol_ha = sum(
      TPA_UNADJ[STATUSCD == 1 &
                 SPCD %in% SHADE_INTOL_SPCD &
                 CCLCD %in% c(1, 2, 3)],
      na.rm = TRUE
    ) * ACRES_PER_HA,

    # --- Appendix A metrics ---
    # Total live basal area (ft2/ac)
    ba_live = sum(
      TPA_UNADJ[STATUSCD == 1] *
        (pi / 4) * (DIA[STATUSCD == 1] / 12)^2,
      na.rm = TRUE
    ),

    # Basal area of trees >= 16" dbh (ft2/ac)
    ba_large = sum(
      TPA_UNADJ[STATUSCD == 1 & DIA >= DBH_THRESHOLD_IN] *
        (pi / 4) * (DIA[STATUSCD == 1 & DIA >= DBH_THRESHOLD_IN] / 12)^2,
      na.rm = TRUE
    ),

    # Dead tree basal area (ft2/ac)
    ba_dead = sum(
      TPA_UNADJ[STATUSCD == 2] *
        (pi / 4) * (DIA[STATUSCD == 2] / 12)^2,
      na.rm = TRUE
    ),

    # Quadratic mean diameter of live trees (cm)
    qmd_cm = {
      live_idx <- which(STATUSCD == 1 & !is.na(DIA) & TPA_UNADJ > 0)
      if (length(live_idx) > 0) {
        sum_ba  <- sum(TPA_UNADJ[live_idx] * DIA[live_idx]^2)
        sum_tpa <- sum(TPA_UNADJ[live_idx])
        sqrt(sum_ba / sum_tpa) * 2.54
      } else {
        NA_real_
      }
    },

    # Coefficient of variation of DBH (live trees, cm)
    cv_dbh = {
      live_dia <- DIA[STATUSCD == 1 & !is.na(DIA)]
      if (length(live_dia) > 2) {
        sd(live_dia * 2.54) / mean(live_dia * 2.54) * 100
      } else {
        NA_real_
      }
    },

    # RAP Metric 4 proxy: trees with broken/dead tops
    # Use very low crown ratio as a proxy for broken tops
    has_broken_tops = any(
      STATUSCD == 1 & !is.na(CR) & CR <= 15 & DIA >= 10,
      na.rm = TRUE
    ),

    # RAP Metric 3 proxy: recruitment in understory
    # Shade-tolerant species as small trees (DIA 1 to 5")
    # Sugar maple (318), red spruce (97), hemlock (261),
    # yellow birch (371), American beech (531)
    has_recruitment = any(
      STATUSCD == 1 &
        SPCD %in% c(318, 97, 261, 371, 531) &
        DIA >= 1 & DIA < 5,
      na.rm = TRUE
    ),

    # Total live trees per hectare (all sizes)
    tpa_total_ha = sum(TPA_UNADJ[STATUSCD == 1], na.rm = TRUE) * ACRES_PER_HA,

    .groups = "drop"
  ) %>%
  mutate(
    # Proportion of basal area in large trees
    prop_ba_large = ifelse(ba_live > 0, ba_large / ba_live, 0),

    # Proportion of shade-intolerant trees (of total)
    prop_shade_intol = ifelse(tpa_total_ha > 0,
                              n_shade_intol_ha / tpa_total_ha, 0)
  )

# --------------------------------------------------------------------------
# Add harvest history flags from COND table
# --------------------------------------------------------------------------

plot_metrics <- plot_metrics %>%
  mutate(
    # RAP Metrics 8/9 proxy: evidence of treatment/harvest
    # TRTCD: 10=cutting, 20=site prep, 30=artificial regen, etc.
    has_recent_treatment = coalesce(TRTCD1, 0) %in% c(10, 20) |
                           coalesce(TRTCD2, 0) %in% c(10, 20) |
                           coalesce(TRTCD3, 0) %in% c(10, 20),

    # DSTRBCD1: disturbance code
    # 80 = harvest or human caused
    has_harvest_disturb  = coalesce(DSTRBCD1, 0) %in% c(80)
  )

cat(sprintf("  Computed metrics for %d plot-conditions\n", nrow(plot_metrics)))

# =============================================================================
# 3. LSOG Classification Scoring System
# =============================================================================
#
# Since we cannot run the actual RAP Random Forest model on FIA data (missing
# epiphyte and other field-only metrics), we build a scoring system calibrated
# to the quantitative thresholds in RAP Appendix A and the variable importance
# rankings in Appendix B Table 3.
# =============================================================================

cat("Classifying plots into LSOG categories...\n")

classify_lsog <- function(df) {
  df %>%
    mutate(
      # --- Score: Number of large live trees per hectare ---
      # (Variable importance rank #2, MDA 16.3%)
      # Appendix A panel (c) means: Not=8, Trans=54, LS=96, OG=92
      score_large_live = case_when(
        n_large_live_ha >= 70 ~ 4,
        n_large_live_ha >= 40 ~ 3,
        n_large_live_ha >= 20 ~ 2,
        n_large_live_ha >= 5  ~ 1,
        TRUE                  ~ 0
      ),

      # --- Score: Proportion of BA in large trees ---
      # Appendix A panel (e) means: Not=0.10, Trans=0.25, LS=0.50, OG=0.59
      score_prop_ba = case_when(
        prop_ba_large >= 0.50 ~ 4,
        prop_ba_large >= 0.35 ~ 3,
        prop_ba_large >= 0.18 ~ 2,
        prop_ba_large >= 0.08 ~ 1,
        TRUE                  ~ 0
      ),

      # --- Score: Harvest evidence ---
      # (Variable importance rank #3 and #4, MDA 15.0% and 13.0%)
      # No treatment = more LSOG-like
      score_no_harvest = case_when(
        !has_recent_treatment & !has_harvest_disturb ~ 3,
        !has_recent_treatment &  has_harvest_disturb ~ 1,
        TRUE                                         ~ 0
      ),

      # --- Score: Shade-intolerant overstory ---
      # (Variable importance rank #5, MDA 12.4%)
      # Fewer shade-intolerant trees = more LSOG-like
      score_shade_tol = case_when(
        n_shade_intol_ha == 0  ~ 3,
        n_shade_intol_ha <= 12 ~ 2,
        n_shade_intol_ha <= 30 ~ 1,
        TRUE                   ~ 0
      ),

      # --- Score: Large snags per hectare ---
      # Appendix A panel (b)
      score_snags = case_when(
        n_large_dead_ha >= 15 ~ 3,
        n_large_dead_ha >= 8  ~ 2,
        n_large_dead_ha >= 3  ~ 1,
        TRUE                  ~ 0
      ),

      # --- Score: QMD ---
      # Appendix A panel (g) means: Not=15, Trans=27, LS=29, OG=27 cm
      score_qmd = case_when(
        is.na(qmd_cm)    ~ 0,
        qmd_cm >= 28      ~ 3,
        qmd_cm >= 22      ~ 2,
        qmd_cm >= 16      ~ 1,
        TRUE              ~ 0
      ),

      # --- Score: CV of DBH ---
      # Appendix A panel (h) means: Not=36, Trans=52, LS=56, OG=70
      # Higher CV = more structural complexity / multi-aged character
      score_cv = case_when(
        is.na(cv_dbh)   ~ 0,
        cv_dbh >= 60     ~ 3,
        cv_dbh >= 48     ~ 2,
        cv_dbh >= 35     ~ 1,
        TRUE             ~ 0
      ),

      # --- Score: Stand age ---
      # RAP Table 1: Not<100, Trans=100-150, LS=150-200, OG>200
      score_age = case_when(
        is.na(STDAGE)     ~ NA_real_,
        STDAGE >= 175      ~ 4,
        STDAGE >= 125      ~ 3,
        STDAGE >= 80       ~ 2,
        STDAGE >= 60       ~ 1,
        TRUE               ~ 0
      ),

      # --- Score: Broken tops (proxy for Metric 4) ---
      score_broken = ifelse(has_broken_tops, 1, 0),

      # --- Score: Understory recruitment (proxy for Metric 3) ---
      score_recruit = ifelse(has_recruitment, 1, 0),

      # --- Score: Dead tree basal area ---
      # Appendix A panel (b) means: Not=7, Trans=17, LS=18, OG=31 ft2/ac
      score_dead_ba = case_when(
        ba_dead >= 25 ~ 3,
        ba_dead >= 15 ~ 2,
        ba_dead >= 8  ~ 1,
        TRUE          ~ 0
      ),

      # --- Total score ---
      # Weight components by approximate variable importance
      total_score = (
        score_large_live * 2.0 +   # rank 2, high importance
        score_prop_ba    * 1.5 +   # strong structural metric
        score_no_harvest * 2.0 +   # ranks 3 and 4 combined
        score_shade_tol  * 1.5 +   # rank 5
        score_snags      * 1.0 +
        score_qmd        * 1.0 +
        score_cv         * 1.0 +
        score_age        * 1.5 +   # strong contextual weight
        score_broken     * 0.5 +
        score_recruit    * 0.5 +
        score_dead_ba    * 0.8
      ),

      # Maximum possible score:
      # 4*2 + 4*1.5 + 3*2 + 3*1.5 + 3*1 + 3*1 + 3*1 + 4*1.5 +
      # 1*0.5 + 1*0.5 + 3*0.8
      # = 8 + 6 + 6 + 4.5 + 3 + 3 + 3 + 6 + 0.5 + 0.5 + 2.4 = 42.9
      #
      # Classification thresholds:
      #   OG:              score >= 34  (~80% of max)
      #   LS:              score >= 25  (~58% of max)
      #   Transitioning:   score >= 16  (~37% of max)
      #   Not LSOG:        score <  16

      lsog_class = case_when(
        total_score >= 34 ~ "OG",
        total_score >= 25 ~ "LS",
        total_score >= 16 ~ "Transitioning LS",
        TRUE              ~ "Not LSOG"
      ),

      lsog_class = factor(lsog_class,
                          levels = c("Not LSOG", "Transitioning LS",
                                     "LS", "OG"))
    )
}

plot_classified <- classify_lsog(plot_metrics)

# Quick summary
cat("\nClassification summary (all years combined):\n")
print(table(plot_classified$lsog_class))

# =============================================================================
# 4. Area Estimation Over Time
# =============================================================================
#
# FIA uses a rolling panel design in its annual inventory. We group inventory
# years into evaluation periods to smooth out the panel-based sampling.
# =============================================================================

cat("Estimating area proportions over time...\n")

# Define evaluation periods
# Maine periodic inventory: ~1995
# Annual inventory started ~1999; full cycle is 5 years
plot_classified <- plot_classified %>%
  mutate(
    eval_period = case_when(
      INVYR <= 1997                    ~ "1995-1997",
      INVYR >= 1998 & INVYR <= 2002    ~ "1999-2003",
      INVYR >= 2003 & INVYR <= 2007    ~ "2003-2007",
      INVYR >= 2008 & INVYR <= 2012    ~ "2008-2012",
      INVYR >= 2013 & INVYR <= 2017    ~ "2013-2017",
      INVYR >= 2018 & INVYR <= 2022    ~ "2018-2022",
      INVYR >= 2023                    ~ "2023-2025",
      TRUE                             ~ NA_character_
    ),
    # Midpoint year for plotting
    eval_year = case_when(
      INVYR <= 1997                    ~ 1996,
      INVYR >= 1998 & INVYR <= 2002    ~ 2001,
      INVYR >= 2003 & INVYR <= 2007    ~ 2005,
      INVYR >= 2008 & INVYR <= 2012    ~ 2010,
      INVYR >= 2013 & INVYR <= 2017    ~ 2015,
      INVYR >= 2018 & INVYR <= 2022    ~ 2020,
      INVYR >= 2023                    ~ 2024,
      TRUE                             ~ NA_real_
    )
  ) %>%
  filter(!is.na(eval_period))

# Compute proportions by evaluation period
area_summary <- plot_classified %>%
  group_by(eval_period, eval_year) %>%
  summarise(
    n_plots      = n(),
    n_not_lsog   = sum(lsog_class == "Not LSOG"),
    n_trans      = sum(lsog_class == "Transitioning LS"),
    n_ls         = sum(lsog_class == "LS"),
    n_og         = sum(lsog_class == "OG"),
    pct_not_lsog = n_not_lsog / n_plots * 100,
    pct_trans    = n_trans    / n_plots * 100,
    pct_ls       = n_ls       / n_plots * 100,
    pct_og       = n_og       / n_plots * 100,
    pct_lsog_combined = (n_trans + n_ls + n_og) / n_plots * 100,
    pct_ls_og         = (n_ls + n_og) / n_plots * 100,
    .groups = "drop"
  )

cat("\nArea proportions by evaluation period:\n")
print(area_summary %>%
        select(eval_period, n_plots, pct_not_lsog, pct_trans,
               pct_ls, pct_og, pct_ls_og) %>%
        mutate(across(starts_with("pct"), ~round(.x, 2))))

# =============================================================================
# 5. Visualization
# =============================================================================

cat("Creating visualizations...\n")

# Color palette inspired by forest condition
lsog_colors <- c(
  "Not LSOG"          = "#D4A574",
  "Transitioning LS"  = "#8FBC8F",
  "LS"                = "#2E8B57",
  "OG"                = "#1B4332"
)

# -------------------------------------------------------------------------
# Plot A: Stacked area chart of LSOG class proportions over time
# -------------------------------------------------------------------------

area_long <- area_summary %>%
  select(eval_period, eval_year,
         pct_not_lsog, pct_trans, pct_ls, pct_og) %>%
  pivot_longer(cols = starts_with("pct_"),
               names_to = "class",
               values_to = "pct") %>%
  mutate(
    class = case_when(
      class == "pct_not_lsog" ~ "Not LSOG",
      class == "pct_trans"    ~ "Transitioning LS",
      class == "pct_ls"       ~ "LS",
      class == "pct_og"       ~ "OG"
    ),
    class = factor(class,
                   levels = c("OG", "LS", "Transitioning LS", "Not LSOG"))
  )

p_stacked <- ggplot(area_long,
                     aes(x = eval_year, y = pct, fill = class)) +
  geom_area(alpha = 0.85, color = "white", linewidth = 0.3) +
  scale_fill_manual(
    values = c("OG"                = "#1B4332",
               "LS"                = "#2E8B57",
               "Transitioning LS"  = "#8FBC8F",
               "Not LSOG"          = "#D4A574"),
    name = "LSOG Class"
  ) +
  scale_x_continuous(
    breaks = area_summary$eval_year,
    labels = area_summary$eval_period
  ) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Estimated LSOG Forest Composition in Maine Over Time",
    subtitle = paste0(
      "Based on FIA plot-level structural metrics mapped to the ",
      "Our Climate Common LSOG RAP classification system"
    ),
    x = "Evaluation Period",
    y = "Percentage of Sampled Forest Area",
    caption = paste0(
      "Source: USDA FIA DataMart (ME_TREE, ME_COND, ME_PLOT)\n",
      "Classification is a proxy based on available FIA structural metrics; ",
      "epiphyte and other field-only RAP metrics are not available."
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold", size = 15),
    plot.subtitle   = element_text(size = 10, color = "gray30"),
    plot.caption    = element_text(size = 8, color = "gray50", hjust = 0),
    axis.text.x     = element_text(angle = 30, hjust = 1),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("lsog_stacked_area.png", p_stacked,
       width = 10, height = 6.5, dpi = 300)

# -------------------------------------------------------------------------
# Plot B: LS + OG combined trend line with bootstrap confidence interval
# -------------------------------------------------------------------------

set.seed(42)
n_boot <- 1000

boot_results <- area_summary %>%
  rowwise() %>%
  mutate(
    boot_ci = list({
      n <- n_plots
      k <- n_ls + n_og
      props <- rbinom(n_boot, n, k / n) / n * 100
      tibble(
        lo = quantile(props, 0.025),
        hi = quantile(props, 0.975)
      )
    })
  ) %>%
  unnest(boot_ci)

p_trend <- ggplot(boot_results,
                  aes(x = eval_year, y = pct_ls_og)) +
  geom_ribbon(aes(ymin = lo, ymax = hi),
              fill = "#2E8B57", alpha = 0.2) +
  geom_line(color = "#2E8B57", linewidth = 1.2) +
  geom_point(color = "#1B4332", size = 3) +
  geom_text(aes(label = sprintf("%.1f%%", pct_ls_og)),
            nudge_y = 0.5, size = 3.5, fontface = "bold") +
  # Reference line from Hagan et al. 2024: ~4% is LS or OG-like
  geom_hline(yintercept = 4, linetype = "dashed",
             color = "firebrick", alpha = 0.6) +
  annotate("text", x = min(boot_results$eval_year) + 1, y = 4.4,
           label = "Hagan et al. (2024) LiDAR estimate: ~4%",
           color = "firebrick", size = 3.2, hjust = 0) +
  scale_x_continuous(
    breaks = area_summary$eval_year,
    labels = area_summary$eval_period
  ) +
  scale_y_continuous(labels = label_percent(scale = 1),
                     limits = c(0, NA)) +
  labs(
    title = "Late-Successional and Old Growth Forest in Maine",
    subtitle = "Combined LS + OG as % of sampled forestland (FIA proxy classification)",
    x = "Evaluation Period",
    y = "% of Forest Area (LS + OG)",
    caption = paste0(
      "Shaded band = 95% bootstrap CI | Dashed line = LiDAR-based estimate ",
      "(Hagan et al. 2024)\n",
      "Source: USDA FIA DataMart. LSOG proxy classification based on RAP v2.0 ",
      "(Shamgochian et al. 2025)."
    )
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title      = element_text(face = "bold", size = 15),
    plot.subtitle   = element_text(size = 10, color = "gray30"),
    plot.caption    = element_text(size = 8, color = "gray50", hjust = 0),
    axis.text.x     = element_text(angle = 30, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave("lsog_trend_ls_og.png", p_trend,
       width = 10, height = 6, dpi = 300)

# -------------------------------------------------------------------------
# Plot C: Faceted view of individual LSOG class trends
# -------------------------------------------------------------------------

area_long_facet <- area_summary %>%
  select(eval_period, eval_year,
         pct_trans, pct_ls, pct_og) %>%
  pivot_longer(cols = starts_with("pct_"),
               names_to = "class",
               values_to = "pct") %>%
  mutate(
    class = case_when(
      class == "pct_trans" ~ "Transitioning LS",
      class == "pct_ls"    ~ "LS (Late Successional)",
      class == "pct_og"    ~ "OG (Old Growth)"
    ),
    class = factor(class,
                   levels = c("Transitioning LS",
                              "LS (Late Successional)",
                              "OG (Old Growth)"))
  )

p_facet <- ggplot(area_long_facet,
                  aes(x = eval_year, y = pct, color = class)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5) +
  facet_wrap(~class, scales = "free_y", ncol = 3) +
  scale_color_manual(
    values = c("Transitioning LS"       = "#8FBC8F",
               "LS (Late Successional)"  = "#2E8B57",
               "OG (Old Growth)"         = "#1B4332"),
    guide = "none"
  ) +
  scale_x_continuous(
    breaks = area_summary$eval_year,
    labels = area_summary$eval_period
  ) +
  scale_y_continuous(labels = label_percent(scale = 1),
                     limits = c(0, NA)) +
  labs(
    title = "LSOG Class Trends in Maine by Category",
    subtitle = "FIA proxy estimates for each LSOG class over time",
    x = "Evaluation Period",
    y = "% of Forest Area",
    caption = paste0(
      "Source: USDA FIA DataMart. ",
      "Classification proxy based on Our Climate Common RAP v2.0."
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold", size = 14),
    plot.subtitle   = element_text(size = 10, color = "gray30"),
    plot.caption    = element_text(size = 8, color = "gray50", hjust = 0),
    axis.text.x     = element_text(angle = 45, hjust = 1, size = 8),
    strip.text      = element_text(face = "bold", size = 11),
    panel.grid.minor = element_blank()
  )

ggsave("lsog_facet_trends.png", p_facet,
       width = 12, height = 5, dpi = 300)

# =============================================================================
# 6. Diagnostic Summary: Score Distribution by Class
# =============================================================================

p_score_dist <- ggplot(plot_classified,
                       aes(x = total_score, fill = lsog_class)) +
  geom_histogram(binwidth = 2, color = "white", alpha = 0.8) +
  scale_fill_manual(values = lsog_colors, name = "LSOG Class") +
  geom_vline(xintercept = c(16, 25, 34),
             linetype = "dashed", color = "gray40") +
  annotate("text", x = 8,  y = Inf, label = "Not LSOG",
           vjust = 2, size = 3, color = "gray40") +
  annotate("text", x = 20, y = Inf, label = "Trans. LS",
           vjust = 2, size = 3, color = "gray40") +
  annotate("text", x = 29, y = Inf, label = "LS",
           vjust = 2, size = 3, color = "gray40") +
  annotate("text", x = 38, y = Inf, label = "OG",
           vjust = 2, size = 3, color = "gray40") +
  labs(
    title = "Distribution of LSOG Composite Scores Across FIA Plots",
    subtitle = "Dashed lines show classification thresholds",
    x = "LSOG Composite Score",
    y = "Number of Plots"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("lsog_score_distribution.png", p_score_dist,
       width = 9, height = 5.5, dpi = 300)

# =============================================================================
# 7. Sensitivity Analysis on Thresholds
# =============================================================================

run_sensitivity <- function(df, thresh_trans, thresh_ls, thresh_og) {
  df %>%
    mutate(
      lsog_alt = case_when(
        total_score >= thresh_og    ~ "OG",
        total_score >= thresh_ls    ~ "LS",
        total_score >= thresh_trans ~ "Transitioning LS",
        TRUE                        ~ "Not LSOG"
      )
    ) %>%
    group_by(eval_period, eval_year) %>%
    summarise(
      pct_ls_og = sum(lsog_alt %in% c("LS", "OG")) / n() * 100,
      .groups = "drop"
    ) %>%
    mutate(
      thresholds = sprintf("Trans=%d, LS=%d, OG=%d",
                           thresh_trans, thresh_ls, thresh_og)
    )
}

sensitivity_df <- bind_rows(
  run_sensitivity(plot_classified, 14, 23, 32),  # lower
  run_sensitivity(plot_classified, 16, 25, 34),  # base case
  run_sensitivity(plot_classified, 18, 27, 36)   # higher
)

p_sensitivity <- ggplot(sensitivity_df,
                        aes(x = eval_year, y = pct_ls_og,
                            color = thresholds, linetype = thresholds)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_continuous(
    breaks = area_summary$eval_year,
    labels = area_summary$eval_period
  ) +
  labs(
    title = "Sensitivity of LS+OG Estimates to Classification Thresholds",
    subtitle = "Three threshold scenarios for the composite scoring system",
    x = "Evaluation Period",
    y = "% of Forest Area (LS + OG)",
    color = "Thresholds",
    linetype = "Thresholds"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title      = element_text(face = "bold"),
    axis.text.x     = element_text(angle = 30, hjust = 1),
    legend.position = "bottom",
    panel.grid.minor = element_blank()
  )

ggsave("lsog_sensitivity.png", p_sensitivity,
       width = 10, height = 6, dpi = 300)

# =============================================================================
# 8. Export Results
# =============================================================================

# Build export column list dynamically
export_cols <- c("PLT_KEY", "INVYR", "eval_period", "eval_year",
                 "LAT", "LON", "STDAGE", "FORTYPCD")
for (opt_col in c("FORTYPGRPCD", "FLDTYPCD")) {
  if (opt_col %in% names(plot_classified)) {
    export_cols <- c(export_cols, opt_col)
  }
}
export_cols <- c(export_cols,
                 "n_large_live_ha", "n_large_dead_ha", "n_shade_intol_ha",
                 "ba_live", "ba_large", "ba_dead",
                 "prop_ba_large", "qmd_cm", "cv_dbh",
                 "total_score", "lsog_class")

write_csv(
  plot_classified %>% select(all_of(export_cols)),
  "fia_lsog_classified_plots.csv"
)

write_csv(area_summary, "fia_lsog_area_summary.csv")

cat("\n=== Analysis complete ===\n")
cat("Output files:\n")
cat("  lsog_stacked_area.png         - Stacked area chart of all classes\n")
cat("  lsog_trend_ls_og.png          - LS+OG trend with bootstrap CI\n")
cat("  lsog_facet_trends.png         - Individual class trend panels\n")
cat("  lsog_score_distribution.png   - Score histogram with thresholds\n")
cat("  lsog_sensitivity.png          - Threshold sensitivity analysis\n")
cat("  fia_lsog_classified_plots.csv - Full plot-level classifications\n")
cat("  fia_lsog_area_summary.csv     - Period-level area summary\n")
