# =============================================================================
# Title: FIA LSOG Analysis for New England (v4)
# Author: A. Weiskittel
# Date: 2026-04-25
# Description:
#   Classify FIA plots into LSOG categories using a proxy scoring system
#   inspired by Hagan et al. (2024, 2025) and the RAP v2.0. Produces
#   bootstrap CIs on both percentage and acre estimates.
#
#   Designed to run on any New England state or set of states. Set
#   STATE_CODES below to control which states are processed.
#
# Fixes and improvements over v2:
#   1. Trees filtered to dominant condition (CONDID) before summarizing,
#      preventing cross-condition mixing of BA, TPA, and snag counts.
#   2. Snag TPA thresholds set from data (75th/90th percentile) rather
#      than arbitrary constants.
#   3. STDAGE fallback: when STDAGE is NA or 0, max_dia is used as a
#      proxy for maturity scoring.
#   4. Weighted standard deviation of DBH (TPA weighted) for the
#      structural complexity dimension.
#   5. EXPNS handled from the initial join; no redundant second join.
#   6. Multi-state support with regional comparison figures.
#   7. Publication-ready theme and colorblind-safe palette.
#
# Dependencies:
#   {STATE}_PLOT.csv, {STATE}_COND.csv, {STATE}_TREE.csv per state
#   from USDA FIA DataMart (https://apps.fs.usda.gov/fia/datamart/)
#
# References:
#   Hagan, J., B. Shamgochian, M. Taylor, and M. Reed. 2024. Using LiDAR
#     to Map, Quantify, and Conserve Late-successional Forest in Maine.
#     Our Climate Common, Georgetown, ME.
#   Hagan, J., B. Shamgochian, M. Taylor, and M. Reed. 2025. LSOG Rapid
#     Assessment Protocol (RAP) v2.0. Our Climate Common, Georgetown, ME.
#   Thompson, J., A. Daigneault, J. Plisinski, I. Moon, J. Norton, and
#     J. Hagan. 2026. Pathways for Protecting Maine's Remaining Old-Growth
#     Forests. Harvard Forest / University of Maine.
# =============================================================================

# --- Libraries ---------------------------------------------------------------
library(tidyverse)
library(scales)
library(patchwork)   # available for multi-panel figure composition

# =============================================================================
# CONFIGURATION (edit this section)
# =============================================================================

# States to process. Use FIA state abbreviations.
# Maine only:       c("ME")
# All New England:  c("ME", "NH", "VT", "MA", "CT", "RI")
STATE_CODES <- c("ME", "NH", "VT", "NY")

# Root directory for FIA data. The script looks for files in two places:
#   1. {data_root}/{ST}/{ST}_PLOT.csv  (multi-state layout)
#   2. {data_root}/{ST}_PLOT.csv       (flat layout, fallback)
#
# For Maine only, you can point directly at the FIA data folder:
data_root <- "~/LSOG/data/fia"
#
# For multi-state, point at a parent directory containing state subfolders:
# data_root <- "/home/aweiskittel/Documents/FIA"

# Output directory for figures and CSV exports
out_dir <- "~/LSOG/output_v4"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Reproducibility
set.seed(42)
N_BOOT <- 2000

# LSOG classification thresholds (total score out of 10)
THRESH_OG    <- 8
THRESH_LS    <- 6
THRESH_TRANS <- 4

# Approximate total forest area by state (acres, source: FIA EVALIDator ~2020)
# Used only as fallback when EXPNS is absent from COND table
FOREST_ACRES <- tribble(
  ~state, ~forest_acres,
  "ME",   17600000,
  "NH",    4800000,
  "VT",    4600000,
  "MA",    3000000,
  "CT",    1700000,
  "RI",     360000
)

# Evaluation period definitions (eastern annual panels, 5 year cycles)
# Adjust yr_lo/yr_hi as needed for your data vintage
eval_breaks <- tribble(
  ~eval_period,    ~yr_lo, ~yr_hi, ~eval_year,
  "1999-2003",      1999,   2003,   2001,
  "2004-2008",      2004,   2008,   2006,
  "2009-2013",      2009,   2013,   2011,
  "2014-2018",      2014,   2018,   2016,
  "2019-2023",      2019,   2023,   2021
)

# =============================================================================
# PUBLICATION THEME
# =============================================================================

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    axis.title       = element_text(size = 12),
    axis.text        = element_text(size = 10),
    legend.position  = "bottom",
    legend.title     = element_text(size = 10),
    legend.text      = element_text(size = 9),
    strip.text       = element_text(size = 11, face = "bold"),
    plot.title       = element_text(size = 14, face = "bold"),
    plot.subtitle    = element_text(size = 10, color = "gray30"),
    plot.caption     = element_text(size = 8, color = "gray50", hjust = 0),
    plot.margin      = margin(10, 10, 10, 10)
  )

lsog_colors <- c(
  "Transitioning LS"       = "#8FBC8F",
  "LS (Late Successional)" = "#2E8B57",
  "OG (Old Growth)"        = "#1B4332"
)

lsog_fill <- c(
  "Transitioning LS" = "#8FBC8F",
  "LS"               = "#2E8B57",
  "OG"               = "#1B4332"
)

# Acre label helper
acre_label <- function(x) {
  ifelse(x >= 1e6,
         paste0(format(round(x / 1e6, 1), nsmall = 1), "M"),
         paste0(format(round(x / 1e3), big.mark = ","), "K"))
}

# Weighted standard deviation
wt_sd <- function(x, w) {
  if (length(x) < 2 || sum(w, na.rm = TRUE) == 0) return(0)
  mu <- weighted.mean(x, w, na.rm = TRUE)
  sqrt(sum(w * (x - mu)^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
}

# =============================================================================
# MAIN PROCESSING FUNCTION: one state at a time
# =============================================================================

process_state <- function(st) {

  cat(sprintf("\n%s\n Processing %s\n%s\n", strrep("=", 70), st, strrep("=", 70)))

  # --- File paths ------------------------------------------------------------
  # Adjust this logic to match your directory layout
  st_dir <- file.path(data_root, st)
  if (!dir.exists(st_dir)) {
    # Try flat layout: data_root/ME_PLOT.csv
    st_dir <- data_root
  }

  plot_file <- file.path(st_dir, paste0(st, "_PLOT.csv"))
  cond_file <- file.path(st_dir, paste0(st, "_COND.csv"))
  tree_file <- file.path(st_dir, paste0(st, "_TREE.csv"))

  for (f in c(plot_file, cond_file, tree_file)) {
    if (!file.exists(f)) {
      cat(sprintf("  WARNING: %s not found. Skipping %s.\n", f, st))
      return(NULL)
    }
  }

  # --- 1. Load ---------------------------------------------------------------
  plot_df <- read_csv(plot_file, show_col_types = FALSE)
  cond_df <- read_csv(cond_file, show_col_types = FALSE)
  tree_df <- read_csv(tree_file, show_col_types = FALSE)

  cat(sprintf("  Loaded: %s plots, %s cond, %s trees\n",
              format(nrow(plot_df), big.mark = ","),
              format(nrow(cond_df), big.mark = ","),
              format(nrow(tree_df), big.mark = ",")))

  # --- 2. Build plot x condition x eval_period table -------------------------

  # Identify shared join keys (guard against missing CYCLE/SUBCYCLE)
  shared_keys <- intersect(names(plot_df), names(cond_df))
  shared_keys <- intersect(shared_keys, c("INVYR", "CYCLE", "SUBCYCLE"))
  join_keys   <- c("CN" = "PLT_CN", setNames(shared_keys, shared_keys))

  plot_cond <- plot_df %>%
    inner_join(cond_df, by = join_keys) %>%
    filter(COND_STATUS_CD == 1) %>%
    mutate(INVYR = as.integer(INVYR)) %>%
    inner_join(eval_breaks %>% select(eval_period, yr_lo, yr_hi, eval_year),
               by = character()) %>%
    filter(INVYR >= yr_lo, INVYR <= yr_hi)

  # Keep dominant condition per plot per evaluation period
  plot_cond <- plot_cond %>%
    group_by(CN, eval_period) %>%
    slice_max(order_by = CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>%
    ungroup()

  if (nrow(plot_cond) == 0) {
    cat(sprintf("  WARNING: No forested plot-conditions for %s. Skipping.\n", st))
    return(NULL)
  }

  cat(sprintf("  Plot x cond records: %s\n",
              format(nrow(plot_cond), big.mark = ",")))

  # --- 3. Summarize tree metrics on DOMINANT CONDITION ONLY ------------------
  #
  # FIX v3: filter tree_df to the dominant condition we selected, preventing
  # cross-condition mixing of BA, TPA, and snag counts.

  dom_cond <- plot_cond %>%
    distinct(CN, CONDID, eval_period)

  # Determine tree join key for CONDID
  # FIA tree records carry PLT_CN and CONDID.
  # A tree can appear in multiple eval_periods (same plot re-measured), so
  # this is an expected many-to-many join. The relationship argument
  # requires dplyr >= 1.1.0; fall back to a simple join if unavailable.
  tree_dom <- tryCatch(
    tree_df %>%
      inner_join(dom_cond, by = c("PLT_CN" = "CN", "CONDID"),
                 relationship = "many-to-many"),
    error = function(e) {
      tree_df %>%
        inner_join(dom_cond, by = c("PLT_CN" = "CN", "CONDID"))
    }
  )

  # 3a. Snag summary (STATUSCD == 2, standing dead >= 5 in DBH)
  snag_summary <- tree_dom %>%
    filter(STATUSCD == 2, DIA >= 5.0) %>%
    group_by(PLT_CN, eval_period) %>%
    summarise(
      n_snags  = n(),
      snag_tpa = sum(TPA_UNADJ, na.rm = TRUE),
      snag_ba  = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
      .groups  = "drop"
    )

  # 3b. Live tree summary (STATUSCD == 1, DBH >= 1 in)
  live_summary <- tree_dom %>%
    filter(STATUSCD == 1, DIA >= 1.0) %>%
    group_by(PLT_CN, eval_period) %>%
    summarise(
      n_live     = n(),
      ba_total   = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
      ba_large   = sum(0.005454 * DIA^2 * TPA_UNADJ * (DIA >= 20),
                       na.rm = TRUE),
      qmd        = sqrt(sum(DIA^2 * TPA_UNADJ, na.rm = TRUE) /
                        sum(TPA_UNADJ, na.rm = TRUE)),
      # FIX v3: TPA-weighted standard deviation of DBH
      sd_dia     = wt_sd(DIA, TPA_UNADJ),
      max_dia    = max(DIA, na.rm = TRUE),
      tpa        = sum(TPA_UNADJ, na.rm = TRUE),
      .groups    = "drop"
    )

  # 3c. Merge live + snag (plots with no snags get 0)
  tree_summary <- live_summary %>%
    left_join(snag_summary, by = c("PLT_CN", "eval_period")) %>%
    mutate(
      n_snags  = replace_na(n_snags, 0L),
      snag_tpa = replace_na(snag_tpa, 0),
      snag_ba  = replace_na(snag_ba, 0)
    )

  # --- 3d. Data-driven snag thresholds (FIX v3) -----------------------------
  # Set score boundaries at ~75th and ~90th percentiles of snag TPA among
  # plots that have at least one snag, so the dimension discriminates.

  snag_nonzero <- tree_summary$snag_tpa[tree_summary$snag_tpa > 0]

  if (length(snag_nonzero) > 10) {
    snag_q <- quantile(snag_nonzero, probs = c(0.5, 0.75, 0.90))
    SNAG_THRESH_1 <- round(snag_q[["75%"]])
    SNAG_THRESH_2 <- round(snag_q[["90%"]])
  } else {
    # Too few snag records; use conservative defaults
    SNAG_THRESH_1 <- 10
    SNAG_THRESH_2 <- 20
  }

  cat(sprintf("  Snag TPA thresholds (data-driven): score 1 >= %d, score 2 >= %d\n",
              SNAG_THRESH_1, SNAG_THRESH_2))
  cat(sprintf("  Plots with >= 1 snag: %.1f%%\n",
              100 * mean(tree_summary$snag_tpa > 0)))

  # --- 4. Score LSOG dimensions and classify ---------------------------------

  plot_scored <- plot_cond %>%
    left_join(tree_summary, by = c("CN" = "PLT_CN", "eval_period")) %>%
    mutate(
      # Fill NAs for plots with no matching tree records
      ba_total   = replace_na(ba_total, 0),
      ba_large   = replace_na(ba_large, 0),
      sd_dia     = replace_na(sd_dia, 0),
      max_dia    = replace_na(max_dia, 0),
      n_snags    = replace_na(n_snags, 0L),
      snag_tpa   = replace_na(snag_tpa, 0),

      # Dim 1: Large tree basal area (ft2/ac, live trees DBH >= 20 in)
      score_ba_large = case_when(
        ba_large >= 80 ~ 2L,
        ba_large >= 40 ~ 1L,
        TRUE           ~ 0L
      ),

      # Dim 2: Stand maturity
      # FIX v3: fall back to max_dia when STDAGE is missing or zero
      score_maturity = case_when(
        !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
        !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
        (is.na(STDAGE) | STDAGE == 0) & max_dia >= 20 ~ 1L,
        TRUE                           ~ 0L
      ),

      # Dim 3: Structural complexity (weighted sd of DBH, inches)
      score_structure = case_when(
        sd_dia >= 6 ~ 2L,
        sd_dia >= 3 ~ 1L,
        TRUE        ~ 0L
      ),

      # Dim 4: Canopy closure / stocking (total BA, ft2/ac)
      score_canopy = case_when(
        ba_total >= 120 ~ 2L,
        ba_total >= 80 ~ 1L,
        TRUE            ~ 0L
      ),

      # Dim 5: Dead wood / snag presence (TPA-based, data-driven thresholds)
      score_deadwood = case_when(
        snag_tpa >= SNAG_THRESH_2 ~ 2L,
        snag_tpa >= SNAG_THRESH_1 ~ 1L,
        TRUE                      ~ 0L
      ),

      # Total score (0 to 10)
      total_score = score_ba_large + score_maturity + score_structure +
                    score_canopy + score_deadwood,

      # Classification
      lsog_class = case_when(
        total_score >= THRESH_OG    ~ "OG",
        total_score >= THRESH_LS    ~ "LS",
        total_score >= THRESH_TRANS ~ "Transitioning LS",
        TRUE                        ~ "Not LSOG"
      ),
      lsog_class = factor(lsog_class,
                           levels = c("Not LSOG", "Transitioning LS",
                                      "LS", "OG"))
    )

  # Diagnostic output
  cat("\n  Score dimension distributions:\n")
  cat("    Dim 1 (large tree BA): ")
  print(table(plot_scored$score_ba_large))
  cat("    Dim 2 (maturity):      ")
  print(table(plot_scored$score_maturity))
  cat("    Dim 3 (structure):     ")
  print(table(plot_scored$score_structure))
  cat("    Dim 4 (canopy):        ")
  print(table(plot_scored$score_canopy))
  cat("    Dim 5 (dead wood):     ")
  print(table(plot_scored$score_deadwood))
  cat("\n  Total score distribution:\n  ")
  print(table(plot_scored$total_score))
  cat("\n  Classification by period:\n")
  print(table(plot_scored$eval_period, plot_scored$lsog_class))

  plot_classified <- plot_scored

  # --- 5. Attach expansion factors -------------------------------------------
  #
  # FIX v3: use EXPNS already present from the initial join; no second join.

  has_expns <- "EXPNS" %in% names(plot_classified) &&
               any(!is.na(plot_classified$EXPNS))

  st_forest_acres <- FOREST_ACRES %>%
    filter(state == st) %>%
    pull(forest_acres)
  if (length(st_forest_acres) == 0) st_forest_acres <- NA_real_

  if (has_expns) {
    cat(sprintf("  Using EXPNS from COND table for expansion.\n"))
    plot_acres <- plot_classified %>%
      mutate(plot_acres = EXPNS)
  } else if (!is.na(st_forest_acres)) {
    cat(sprintf("  EXPNS not found; approximating from %.1fM acre forest base.\n",
                st_forest_acres / 1e6))
    plot_acres <- plot_classified %>%
      group_by(eval_period) %>%
      mutate(plot_acres = st_forest_acres / n() * CONDPROP_UNADJ) %>%
      ungroup()
  } else {
    cat(sprintf("  WARNING: no EXPNS and no forest area for %s. Using plot counts only.\n", st))
    plot_acres <- plot_classified %>%
      mutate(plot_acres = 1)
  }

  # --- 6. Bootstrap CIs (percentage and acres) -------------------------------

  cat("  Bootstrapping...\n")

  boot_results <- plot_acres %>%
    group_by(eval_period, eval_year) %>%
    group_split() %>%
    map_dfr(function(grp) {
      n  <- nrow(grp)
      ep <- grp$eval_period[1]
      ey <- grp$eval_year[1]

      boot_mat <- replicate(N_BOOT, {
        idx <- sample.int(n, replace = TRUE)
        cls <- grp$lsog_class[idx]
        ac  <- grp$plot_acres[idx]
        c(
          pct_trans    = 100 * mean(cls == "Transitioning LS"),
          pct_ls       = 100 * mean(cls == "LS"),
          pct_og       = 100 * mean(cls == "OG"),
          pct_ls_og    = 100 * mean(cls %in% c("LS", "OG")),
          pct_all_lsog = 100 * mean(cls != "Not LSOG"),
          ac_trans     = sum(ac[cls == "Transitioning LS"], na.rm = TRUE),
          ac_ls        = sum(ac[cls == "LS"], na.rm = TRUE),
          ac_og        = sum(ac[cls == "OG"], na.rm = TRUE),
          ac_ls_og     = sum(ac[cls %in% c("LS", "OG")], na.rm = TRUE),
          ac_all_lsog  = sum(ac[cls != "Not LSOG"], na.rm = TRUE)
        )
      })

      ci <- apply(boot_mat, 1, quantile, probs = c(0.025, 0.975))
      pt <- function(var) sum(grp$plot_acres[grp$lsog_class == var], na.rm = TRUE)

      tibble(
        state       = st,
        eval_period = ep,
        eval_year   = ey,
        n_plots     = n,

        # Percentage point estimates
        pct_trans    = 100 * mean(grp$lsog_class == "Transitioning LS"),
        pct_ls       = 100 * mean(grp$lsog_class == "LS"),
        pct_og       = 100 * mean(grp$lsog_class == "OG"),
        pct_ls_og    = 100 * mean(grp$lsog_class %in% c("LS", "OG")),
        pct_all_lsog = 100 * mean(grp$lsog_class != "Not LSOG"),

        # Percentage CIs
        pct_trans_lo = ci["2.5%",  "pct_trans"],
        pct_trans_hi = ci["97.5%", "pct_trans"],
        pct_ls_lo    = ci["2.5%",  "pct_ls"],
        pct_ls_hi    = ci["97.5%", "pct_ls"],
        pct_og_lo    = ci["2.5%",  "pct_og"],
        pct_og_hi    = ci["97.5%", "pct_og"],
        pct_lsog_lo  = ci["2.5%",  "pct_ls_og"],
        pct_lsog_hi  = ci["97.5%", "pct_ls_og"],

        # Acre point estimates
        acres_trans    = pt("Transitioning LS"),
        acres_ls       = pt("LS"),
        acres_og       = pt("OG"),
        acres_ls_og    = pt("LS") + pt("OG"),
        acres_all_lsog = pt("Transitioning LS") + pt("LS") + pt("OG"),

        # Acre CIs
        ac_trans_lo  = ci["2.5%",  "ac_trans"],
        ac_trans_hi  = ci["97.5%", "ac_trans"],
        ac_ls_lo     = ci["2.5%",  "ac_ls"],
        ac_ls_hi     = ci["97.5%", "ac_ls"],
        ac_og_lo     = ci["2.5%",  "ac_og"],
        ac_og_hi     = ci["97.5%", "ac_og"],
        ac_lsog_lo   = ci["2.5%",  "ac_ls_og"],
        ac_lsog_hi   = ci["97.5%", "ac_ls_og"],
        ac_all_lo    = ci["2.5%",  "ac_all_lsog"],
        ac_all_hi    = ci["97.5%", "ac_all_lsog"],

        # Metadata
        snag_thresh_1 = SNAG_THRESH_1,
        snag_thresh_2 = SNAG_THRESH_2,
        has_expns     = has_expns
      )
    })

  cat(sprintf("  Done. %d period(s) processed for %s.\n",
              nrow(boot_results), st))

  return(boot_results)
}

# =============================================================================
# EXECUTE: loop over states
# =============================================================================

cat("\n")
cat(strrep("=", 70), "\n")
cat(" FIA LSOG Analysis v4 (relaxed dims): New England\n")
cat(strrep("=", 70), "\n")
cat(sprintf(" States: %s\n", paste(STATE_CODES, collapse = ", ")))
cat(sprintf(" Bootstrap resamples: %s\n", format(N_BOOT, big.mark = ",")))
cat(sprintf(" Thresholds: OG >= %d, LS >= %d, Trans >= %d\n",
            THRESH_OG, THRESH_LS, THRESH_TRANS))

all_results <- map_dfr(STATE_CODES, process_state)

if (nrow(all_results) == 0) {
  stop("No results produced. Check data paths and file availability.")
}

# Export combined results
write_csv(all_results, file.path(out_dir, "fia_lsog_all_states_v4.csv"))
cat(sprintf("\nCombined results exported: %d rows\n", nrow(all_results)))

# =============================================================================
# STATE LEVEL FIGURES (per state)
# =============================================================================

for (st in unique(all_results$state)) {

  st_data <- all_results %>% filter(state == st)
  if (nrow(st_data) == 0) next

  # --- Percentage time series (all classes, combined panel) ------------------
  facet_pct <- st_data %>%
    select(eval_period, eval_year,
           pct_trans, pct_trans_lo, pct_trans_hi,
           pct_ls, pct_ls_lo, pct_ls_hi,
           pct_og, pct_og_lo, pct_og_hi) %>%
    pivot_longer(cols = c(pct_trans, pct_ls, pct_og),
                 names_to = "cr", values_to = "pct") %>%
    mutate(
      lo = case_when(cr == "pct_trans" ~ pct_trans_lo,
                     cr == "pct_ls"    ~ pct_ls_lo,
                     cr == "pct_og"    ~ pct_og_lo),
      hi = case_when(cr == "pct_trans" ~ pct_trans_hi,
                     cr == "pct_ls"    ~ pct_ls_hi,
                     cr == "pct_og"    ~ pct_og_hi),
      class = factor(case_when(
        cr == "pct_trans" ~ "Transitioning LS",
        cr == "pct_ls"    ~ "LS (Late Successional)",
        cr == "pct_og"    ~ "OG (Old Growth)"),
        levels = names(lsog_colors))
    )

  p_st_pct <- ggplot(facet_pct,
      aes(x = eval_year, y = pct, color = class, fill = class)) +
    geom_ribbon(aes(ymin = lo, ymax = hi), alpha = 0.12, color = NA) +
    geom_errorbar(aes(ymin = lo, ymax = hi),
                  width = 0.5, linewidth = 0.4,
                  position = position_dodge(width = 0.8)) +
    geom_line(linewidth = 1.0) +
    geom_point(size = 2.5, position = position_dodge(width = 0.8)) +
    scale_color_manual(values = lsog_colors, name = "LSOG Class") +
    scale_fill_manual(values = lsog_colors, name = "LSOG Class") +
    scale_x_continuous(breaks = st_data$eval_year,
                       labels = st_data$eval_period) +
    scale_y_continuous(labels = function(x) paste0(x, "%"),
                       limits = c(0, NA)) +
    labs(
      title    = paste0("LSOG Forest Percentage Trends: ", st),
      subtitle = "All classes with 95% bootstrap CIs",
      x = "Evaluation Period", y = "Percent of Plots",
      caption = paste0("n = ", format(N_BOOT, big.mark = ","),
                       " bootstrap resamples. Source: USDA FIA DataMart.\n",
                       "LSOG proxy scoring inspired by RAP v2.0 (Hagan et al. 2025).")
    ) +
    theme_pub +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))

  ggsave(file.path(out_dir, paste0("lsog_pct_combined_", st, "_v4.png")),
         p_st_pct, width = 10, height = 6, dpi = 300, bg = "white")

  # --- Acre faceted by class -------------------------------------------------
  facet_ac <- st_data %>%
    select(eval_period, eval_year,
           acres_trans, ac_trans_lo, ac_trans_hi,
           acres_ls, ac_ls_lo, ac_ls_hi,
           acres_og, ac_og_lo, ac_og_hi) %>%
    pivot_longer(cols = c(acres_trans, acres_ls, acres_og),
                 names_to = "cr", values_to = "acres") %>%
    mutate(
      lo = case_when(cr == "acres_trans" ~ ac_trans_lo,
                     cr == "acres_ls"    ~ ac_ls_lo,
                     cr == "acres_og"    ~ ac_og_lo),
      hi = case_when(cr == "acres_trans" ~ ac_trans_hi,
                     cr == "acres_ls"    ~ ac_ls_hi,
                     cr == "acres_og"    ~ ac_og_hi),
      class = factor(case_when(
        cr == "acres_trans" ~ "Transitioning LS",
        cr == "acres_ls"    ~ "LS (Late Successional)",
        cr == "acres_og"    ~ "OG (Old Growth)"),
        levels = names(lsog_colors))
    )

  p_st_ac <- ggplot(facet_ac,
      aes(x = eval_year, y = acres, color = class)) +
    geom_ribbon(aes(ymin = lo, ymax = hi, fill = class),
                alpha = 0.15, color = NA) +
    geom_errorbar(aes(ymin = lo, ymax = hi),
                  width = 0.6, linewidth = 0.4) +
    geom_line(linewidth = 1.1) +
    geom_point(size = 2.5) +
    facet_wrap(~class, scales = "free_y", ncol = 3) +
    scale_color_manual(values = lsog_colors, guide = "none") +
    scale_fill_manual(values = lsog_colors, guide = "none") +
    scale_x_continuous(breaks = st_data$eval_year,
                       labels = st_data$eval_period) +
    scale_y_continuous(labels = function(x) acre_label(x),
                       limits = c(0, NA)) +
    labs(
      title    = paste0("LSOG Acreage Trends: ", st),
      subtitle = "Estimated acres with 95% bootstrap CIs",
      x = "Evaluation Period", y = "Acres",
      caption = paste0("Source: USDA FIA DataMart. RAP v2.0 proxy classification.\n",
                       "Snag thresholds (data-driven): score 1 >= ",
                       st_data$snag_thresh_1[1], " TPA, score 2 >= ",
                       st_data$snag_thresh_2[1], " TPA.")
    ) +
    theme_pub +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 8))

  ggsave(file.path(out_dir, paste0("lsog_acres_facet_", st, "_v4.png")),
         p_st_ac, width = 12, height = 5, dpi = 300, bg = "white")

  cat(sprintf("  Figures saved for %s\n", st))
}

# =============================================================================
# REGIONAL COMPARISON FIGURES
# =============================================================================

if (length(unique(all_results$state)) > 1) {

  cat("\nGenerating regional comparison figures...\n")

  # State display order (north to south, roughly)
  state_order <- c("ME", "NH", "VT", "MA", "CT", "RI")
  state_names <- c(ME = "Maine", NH = "New Hampshire", VT = "Vermont",
                   MA = "Massachusetts", CT = "Connecticut", RI = "Rhode Island")

  all_results <- all_results %>%
    mutate(
      state = factor(state, levels = intersect(state_order, unique(state))),
      state_name = state_names[as.character(state)]
    )

  # --- R1: All LSOG % by state over time (faceted) --------------------------

  p_region_pct <- ggplot(all_results,
      aes(x = eval_year, y = pct_all_lsog)) +
    geom_ribbon(aes(ymin = pct_lsog_lo, ymax = pct_lsog_hi),
                fill = "#2E8B57", alpha = 0.15) +
    geom_errorbar(aes(ymin = pct_lsog_lo, ymax = pct_lsog_hi),
                  width = 0.5, linewidth = 0.4, color = "#1B4332") +
    geom_line(color = "#2E8B57", linewidth = 1.1) +
    geom_point(color = "#1B4332", size = 2) +
    facet_wrap(~state_name, scales = "free_y", ncol = 3) +
    scale_x_continuous(breaks = eval_breaks$eval_year,
                       labels = eval_breaks$eval_period) +
    scale_y_continuous(labels = function(x) paste0(x, "%"),
                       limits = c(0, NA)) +
    labs(
      title    = "LSOG Forest Trends Across New England",
      subtitle = "Percentage of FIA plots in any LSOG class (95% bootstrap CI)",
      x = "Evaluation Period", y = "Percent of Plots (All LSOG)",
      caption = paste0("Source: USDA FIA DataMart. LSOG proxy classification v3.\n",
                       "Bootstrap n = ", format(N_BOOT, big.mark = ","),
                       ". Snag thresholds set per state from data.")
    ) +
    theme_pub +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7))

  ggsave(file.path(out_dir, "lsog_pct_regional_facet_v4.png"),
         p_region_pct, width = 14, height = 8, dpi = 300, bg = "white")

  # --- R2: Most recent period bar chart by state -----------------------------

  latest <- all_results %>%
    group_by(state) %>%
    slice_max(order_by = eval_year, n = 1) %>%
    ungroup()

  bar_data <- latest %>%
    select(state, state_name, pct_trans, pct_ls, pct_og) %>%
    pivot_longer(cols = c(pct_trans, pct_ls, pct_og),
                 names_to = "cr", values_to = "pct") %>%
    mutate(
      class = factor(case_when(
        cr == "pct_trans" ~ "Transitioning LS",
        cr == "pct_ls"    ~ "LS",
        cr == "pct_og"    ~ "OG"),
        levels = c("OG", "LS", "Transitioning LS"))
    )

  p_region_bar <- ggplot(bar_data,
      aes(x = state, y = pct, fill = class)) +
    geom_col(alpha = 0.85, color = "white", linewidth = 0.3) +
    scale_fill_manual(values = lsog_fill, name = "LSOG Class") +
    scale_y_continuous(labels = function(x) paste0(x, "%"),
                       expand = expansion(mult = c(0, 0.08))) +
    labs(
      title    = "LSOG Composition by State (Most Recent Period)",
      subtitle = paste0("FIA proxy classification, period: ",
                        latest$eval_period[1]),
      x = NULL, y = "Percent of Plots",
      caption = "Source: USDA FIA DataMart. LSOG proxy classification v3."
    ) +
    theme_pub

  ggsave(file.path(out_dir, "lsog_pct_state_bar_v4.png"),
         p_region_bar, width = 10, height = 6, dpi = 300, bg = "white")

  # --- R3: All LSOG acres by state (most recent) ----------------------------

  p_region_acres <- ggplot(latest,
      aes(x = state, y = acres_all_lsog)) +
    geom_col(fill = "#2E8B57", alpha = 0.8, width = 0.6) +
    geom_errorbar(aes(ymin = ac_all_lo, ymax = ac_all_hi),
                  width = 0.25, linewidth = 0.5, color = "#1B4332") +
    geom_text(aes(label = acre_label(acres_all_lsog)),
              vjust = -0.5, size = 3.5, fontface = "bold") +
    scale_y_continuous(labels = function(x) acre_label(x),
                       limits = c(0, NA),
                       expand = expansion(mult = c(0, 0.15))) +
    labs(
      title    = "Total LSOG Acreage by State (Most Recent Period)",
      subtitle = paste0("All LSOG classes combined, period: ",
                        latest$eval_period[1]),
      x = NULL, y = "Acres (All LSOG)",
      caption = "Source: USDA FIA DataMart. 95% bootstrap CI shown."
    ) +
    theme_pub

  ggsave(file.path(out_dir, "lsog_acres_state_bar_v4.png"),
         p_region_acres, width = 10, height = 6, dpi = 300, bg = "white")

  # --- R4: Heatmap of % LSOG by state and period ----------------------------

  heat_data <- all_results %>%
    select(state_name, eval_period, pct_all_lsog) %>%
    mutate(state_name = factor(state_name,
           levels = rev(state_names[intersect(state_order,
                        levels(all_results$state))])))

  p_heat <- ggplot(heat_data,
      aes(x = eval_period, y = state_name, fill = pct_all_lsog)) +
    geom_tile(color = "white", linewidth = 1) +
    geom_text(aes(label = sprintf("%.1f%%", pct_all_lsog)),
              size = 3.5, fontface = "bold") +
    scale_fill_gradient(low = "#F0F7F2", high = "#1B4332",
                        name = "% LSOG") +
    labs(
      title    = "LSOG Prevalence Across New England",
      subtitle = "Percentage of FIA plots in any LSOG class",
      x = "Evaluation Period", y = NULL,
      caption = "Source: USDA FIA DataMart. LSOG proxy classification v3."
    ) +
    theme_pub +
    theme(
      panel.grid       = element_blank(),
      axis.text.x      = element_text(angle = 30, hjust = 1),
      legend.position  = "right"
    )

  ggsave(file.path(out_dir, "lsog_heatmap_regional_v4.png"),
         p_heat, width = 10, height = 5, dpi = 300, bg = "white")

  cat("  Regional figures saved.\n")
}

# =============================================================================
# COMPARISON WITH HAGAN ET AL. (2024) / THOMPSON ET AL. (2026)
# =============================================================================

cat("\n")
cat(strrep("=", 70), "\n")
cat(" COMPARISON: FIA Proxy v4 (v3R relaxed dims) vs. Hagan et al. (2024) LiDAR\n")
cat(strrep("=", 70), "\n")

me_data <- all_results %>% filter(state == "ME", eval_period == "2014-2018")

if (nrow(me_data) > 0) {
  cat("\n  Hagan et al. (2024) / Thompson et al. (2026):\n")
  cat("    Scope: unorganized townships (~3.86M ha / ~9.5M acres)\n")
  cat("    Method: LiDAR random forest classifier, ground truthed\n")
  cat("    Transitioning LS:  662,696 ha (1,637,522 ac)  17.2%\n")
  cat("    LS + OG:           161,881 ha (  400,008 ac)   4.2%\n")
  cat("    All LSOG:          824,577 ha (2,037,530 ac)  21.4%\n")

  cat(sprintf("\n  FIA Proxy v4 (relaxed dims, %s, all Maine, 17.6M acres):\n",
              me_data$eval_period))
  cat(sprintf("    Transitioning LS: %10s ac  (%.1f%%)\n",
              format(round(me_data$acres_trans), big.mark = ","),
              me_data$pct_trans))
  cat(sprintf("    LS:               %10s ac  (%.2f%%)\n",
              format(round(me_data$acres_ls), big.mark = ","),
              me_data$pct_ls))
  cat(sprintf("    OG:               %10s ac  (%.3f%%)\n",
              format(round(me_data$acres_og), big.mark = ","),
              me_data$pct_og))
  cat(sprintf("    LS + OG:          %10s ac  (%.2f%%)\n",
              format(round(me_data$acres_ls_og), big.mark = ","),
              me_data$pct_ls_og))
  cat(sprintf("    All LSOG:         %10s ac  (%.1f%%)\n",
              format(round(me_data$acres_all_lsog), big.mark = ","),
              me_data$pct_all_lsog))
  cat(sprintf("    Snag thresholds:  score 1 >= %d TPA, score 2 >= %d TPA\n",
              me_data$snag_thresh_1, me_data$snag_thresh_2))

  cat("\n  Key methodological differences:\n")
  cat("    1. Scope: statewide vs. unorganized townships only\n")
  cat("    2. Method: FIA proxy scoring vs. LiDAR canopy structure model\n")
  cat("    3. Resolution: ~3,150 plots/cycle vs. wall to wall (1 ha pixels)\n")
  cat("    4. The LiDAR classifier detects canopy features (gaps, vertical\n")
  cat("       heterogeneity) that FIA plot variables cannot capture\n")
  cat("    5. FIA proxy 'Transitioning LS' thresholds may be conservative\n")
  cat("       relative to the LiDAR definition\n")
  cat("    6. LiDAR data acquired 2015 to 2018 vs. FIA 5 year rolling panel\n")
} else {
  cat("  Maine 2014-2018 data not available for comparison.\n")
}

cat("\n")
cat(strrep("=", 70), "\n")
cat(" ANALYSIS COMPLETE\n")
cat(sprintf(" Output directory: %s\n", out_dir))
cat(strrep("=", 70), "\n")
