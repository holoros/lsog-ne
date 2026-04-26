# =============================================================================
# Phase 5g: design-based FIA estimation with proper EXPNS + post-stratified SE
# Plus ownership breakdown via OWNGRPCD
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse)
})

STATE_CODES <- c("ME","NH","VT","NY")
data_root   <- "~/LSOG/data/fia"
plot_table  <- "~/LSOG/output_unified/lsog_ne_plot_table.csv"
out_dir     <- "~/LSOG/output_design_based"
if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

# Read unified plot table; recompute v5.1 class with original v3 dim thresholds
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

cat(sprintf("Loaded unified table: %d rows\n", nrow(dat)))

# ---- For each state, find most recent EXPCURR EVALID ------------------------

find_eval <- function(st) {
  pe  <- read_csv(file.path(path.expand(data_root), paste0(st, "_POP_EVAL.csv")),
                  show_col_types = FALSE)
  pet <- read_csv(file.path(path.expand(data_root), paste0(st, "_POP_EVAL_TYP.csv")),
                  show_col_types = FALSE)
  # Join on EVAL_CN (POP_EVAL.CN = POP_EVAL_TYP.EVAL_CN)
  curr <- pet %>% filter(EVAL_TYP == "EXPCURR") %>% pull(EVAL_CN)
  recent <- pe %>% filter(CN %in% curr) %>%
    arrange(desc(END_INVYR)) %>% head(1) %>%   # 2 most recent
    select(EVAL_CN = CN, EVALID, END_INVYR, EVAL_DESCR)
  recent %>% mutate(state = st)
}

evs <- map_dfr(STATE_CODES, find_eval)
cat("\nMost recent EXPCURR evaluations:\n"); print(evs)

# ---- Design-based estimation per state, latest EVALID -----------------------

design_estimate_state <- function(st, evalid_use, panel_label) {
  cat(sprintf("\n--- design-based %s EVALID %s (%s) ---\n", st, evalid_use, panel_label))

  ppsa <- read_csv(file.path(path.expand(data_root),
                              paste0(st, "_POP_PLOT_STRATUM_ASSGN.csv")),
                    show_col_types = FALSE) %>%
    filter(EVALID == evalid_use) %>% select(PLT_CN, STRATUM_CN)

  pop  <- read_csv(file.path(path.expand(data_root), paste0(st, "_POP_STRATUM.csv")),
                    show_col_types = FALSE) %>%
    filter(EVALID == evalid_use) %>%
    select(STRATUM_CN = CN, EXPNS, ADJ_FACTOR_SUBP, STRATUMCD, P1POINTCNT, P2POINTCNT)

  cond <- read_csv(file.path(path.expand(data_root), paste0(st, "_COND.csv")),
                    show_col_types = FALSE) %>%
    select(PLT_CN, CONDID, COND_STATUS_CD, CONDPROP_UNADJ, OWNGRPCD)

  # Use the unified table v5.1 classification, but filter to this state
  st_plots <- dat %>% filter(state == st) %>%
    select(state, eval_period, CN, INVYR, v51_class, v51_total)

  # The unified table groups plots by eval_period; we need to find which eval_period
  # corresponds to this EVALID. Use INVYR range.
  st_plots <- st_plots %>% filter(eval_period == panel_label)

  cat(sprintf("  v51-classified plots in panel: %d\n", nrow(st_plots)))

  # Join with stratum assignment + EXPNS
  j <- st_plots %>%
    inner_join(ppsa, by = c("CN" = "PLT_CN")) %>%
    inner_join(pop,  by = "STRATUM_CN") %>%
    inner_join(cond %>% group_by(PLT_CN) %>%
                slice_max(CONDPROP_UNADJ, n = 1, with_ties = FALSE) %>% ungroup(),
                by = c("CN" = "PLT_CN"))

  cat(sprintf("  joined to EXPNS: %d rows; %d strata\n",
              nrow(j), n_distinct(j$STRATUM_CN)))

  # Forested-condition indicator (COND_STATUS_CD == 1)
  j <- j %>% mutate(
    forested  = as.integer(COND_STATUS_CD == 1),
    pct_cond  = CONDPROP_UNADJ * forested,  # forested portion of plot
    is_lsog   = as.integer(v51_class != "Not LSOG"),
    is_tls    = as.integer(v51_class == "Transitioning LS"),
    is_ls     = as.integer(v51_class == "LS"),
    is_og     = as.integer(v51_class == "OG"),
    is_lsog_g = as.integer(v51_class %in% c("LS","OG"))
  )

  # Stratum-level estimation, FIA post-stratified estimator
  # Total acres in class = sum_h sum_i (CONDPROP_UNADJ * EXPNS_h * indicator * ADJ_FACTOR_SUBP)
  # Variance = sum_h ((EXPNS_h)^2 * (n_h * s_h^2 / (n_h - 1)))
  # where s_h^2 is the sample variance of (pct_cond * indicator) within stratum

  estimate_class <- function(j, ind_col, label) {
    j$y <- j$pct_cond * j[[ind_col]] * j$ADJ_FACTOR_SUBP

    strat <- j %>% group_by(STRATUM_CN, EXPNS) %>%
      summarise(n = n(), y_bar = mean(y), y_var = var(y), .groups = "drop") %>%
      mutate(y_var = replace_na(y_var, 0))

    total <- sum(strat$EXPNS * strat$n * strat$y_bar)
    se    <- sqrt(sum(strat$EXPNS^2 * strat$n * (strat$y_var / pmax(strat$n - 1, 1)) * strat$n))
    # Simplification: FIA standard formula gives Var = sum(EXPNS_h^2 * (n_h * s_h^2))
    # for the post-stratified estimator
    var_total <- sum(strat$EXPNS^2 * strat$n * strat$y_var)
    se <- sqrt(var_total)

    list(total = total, se = se, ci_lo = total - 1.96*se, ci_hi = total + 1.96*se,
         label = label)
  }

  res <- bind_rows(
    estimate_class(j, "forested",   "all forested") %>% as_tibble(),
    estimate_class(j, "is_lsog",    "any LSOG")    %>% as_tibble(),
    estimate_class(j, "is_lsog_g",  "LS+OG")       %>% as_tibble(),
    estimate_class(j, "is_tls",     "TLS")         %>% as_tibble(),
    estimate_class(j, "is_ls",      "LS")          %>% as_tibble(),
    estimate_class(j, "is_og",      "OG")          %>% as_tibble()
  ) %>% mutate(state = st, panel = panel_label) %>%
    select(state, panel, class = label, total_acres = total,
           se_acres = se, ci_lo, ci_hi)

  # Compute percent of forested
  forested_acres <- res$total_acres[res$class == "all forested"]
  res <- res %>% mutate(
    pct_of_forested = ifelse(class == "all forested", NA, 100 * total_acres / forested_acres)
  )

  # Ownership breakdown (just for this panel)
  own <- j %>% filter(forested == 1) %>%
    mutate(own_grp = case_when(
      OWNGRPCD == 10 ~ "Federal",
      OWNGRPCD == 20 ~ "Other federal",
      OWNGRPCD == 30 ~ "State and local",
      OWNGRPCD == 40 ~ "Private",
      TRUE ~ "Unknown")) %>%
    group_by(state, panel = panel_label, own_grp) %>%
    summarise(
      n_plots = n(),
      acres_forested = sum(EXPNS * pct_cond * ADJ_FACTOR_SUBP),
      acres_lsog     = sum(EXPNS * pct_cond * ADJ_FACTOR_SUBP * is_lsog),
      acres_lsog_g   = sum(EXPNS * pct_cond * ADJ_FACTOR_SUBP * is_lsog_g),
      acres_og       = sum(EXPNS * pct_cond * ADJ_FACTOR_SUBP * is_og),
      pct_lsog       = 100 * acres_lsog   / acres_forested,
      pct_lsog_g     = 100 * acres_lsog_g / acres_forested,
      pct_og         = 100 * acres_og     / acres_forested,
      .groups = "drop"
    )

  list(area = res, ownership = own)
}

# Map state EVALIDs to panels - use EVAL_DESCR to identify
# Most recent EXPCURR evals per state
all_results_area  <- list()
all_results_owner <- list()

for (st in STATE_CODES) {
  st_evals <- evs %>% filter(state == st)
  for (i in seq_len(nrow(st_evals))) {
    row <- st_evals[i, ]
    # Determine panel: use END_INVYR
    panel <- if (row$END_INVYR >= 2019) "2019-2023"
        else if (row$END_INVYR >= 2014 & row$END_INVYR <= 2018) "2014-2018"
        else NA_character_
    if (is.na(panel)) next
    cat(sprintf("\n=== %s panel %s (END_INVYR=%d, EVALID=%d) ===\n",
                st, panel, row$END_INVYR, row$EVALID))
    res <- tryCatch(design_estimate_state(st, row$EVALID, panel),
                    error = function(e) { cat("  ERROR:", conditionMessage(e), "\n"); NULL })
    if (!is.null(res)) {
      all_results_area[[length(all_results_area)+1]]   <- res$area
      all_results_owner[[length(all_results_owner)+1]] <- res$ownership
    }
  }
}

area_tbl  <- bind_rows(all_results_area)
owner_tbl <- bind_rows(all_results_owner)

write_csv(area_tbl, file.path(path.expand(out_dir), "design_based_area.csv"))
write_csv(owner_tbl, file.path(path.expand(out_dir), "ownership_breakdown.csv"))

cat("\n=== Design-based area + 95% CI ===\n")
print(area_tbl %>% mutate(across(c(total_acres, se_acres, ci_lo, ci_hi),
                                  ~round(., 0))))
cat("\n=== Ownership breakdown (latest panel) ===\n")
print(owner_tbl %>% filter(panel == "2019-2023"))
