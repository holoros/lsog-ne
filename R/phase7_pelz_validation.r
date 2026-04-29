# =============================================================================
# Phase 7: Pelz et al. 2023 cross-validation on NE NFS lands
# Filter FIA plots to OWNCD==11 (USFS NFS), apply Pelz Eastern Region R9 OG
# criteria per FIA condition, compare to v5.1 OG/LS calls.
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse); library(data.table); library(scales)
})

STATE_CODES <- c("ME","NH","VT","NY")
data_root <- "/users/PUOM0008/crsfaaron/fia_data"
out_dir   <- "/users/PUOM0008/crsfaaron/LSOG/output_phase7"
fig_dir   <- "/users/PUOM0008/crsfaaron/LSOG/output_figures"

# Pelz Eastern Region (R9) OG criteria (uniform thresholds across types):
# - Stand age >= 100 yr (per Tyrrell 1998 most-common type minimum)
# - Density >= 5 trees/ac of DBH >= 12 in (per most-common type minimum)
# These are the minimum across the Tyrrell vegetation types Pelz uses.
PELZ_MIN_STDAGE  <- 100   # years
PELZ_MIN_DBH_IN  <- 12.0  # inches
PELZ_MIN_TREES_PER_AC <- 5

# Compute Pelz OG indicator per FIA plot
compute_pelz_per_state <- function(st) {
  cat(sprintf("\n--- %s ---\n", st))
  pf <- fread(file.path(data_root, paste0(st, "_PLOT.csv")),
              select = c("CN","INVYR","STATECD","UNITCD","COUNTYCD","PLOT","LAT","LON"))
  cf <- fread(file.path(data_root, paste0(st, "_COND.csv")),
              select = c("PLT_CN","CONDID","COND_STATUS_CD","CONDPROP_UNADJ",
                          "OWNCD","OWNGRPCD","STDAGE","FORTYPCD"))
  tf <- fread(file.path(data_root, paste0(st, "_TREE.csv")),
              select = c("PLT_CN","CONDID","DIA","TPA_UNADJ","STATUSCD"))

  # USFS NFS lands only (OWNCD == 11)
  cf <- cf[COND_STATUS_CD == 1 & OWNCD == 11]
  cat(sprintf("  NFS forested conditions: %d\n", nrow(cf)))

  # Per-plot dominant NFS condition (highest CONDPROP_UNADJ)
  cf <- cf[order(PLT_CN, -CONDPROP_UNADJ)][, .SD[1], by = PLT_CN]

  # Compute trees-per-acre of DBH >= 12 in (live trees only)
  big <- tf[STATUSCD == 1 & DIA >= PELZ_MIN_DBH_IN,
            .(big_trees_per_ac = sum(TPA_UNADJ, na.rm = TRUE)),
            by = .(PLT_CN, CONDID)]

  out <- merge(cf, big, by = c("PLT_CN","CONDID"), all.x = TRUE)
  out[is.na(big_trees_per_ac), big_trees_per_ac := 0]

  out <- merge(out, pf[, .(CN, LAT, LON, INVYR)],
                by.x = "PLT_CN", by.y = "CN", all.x = TRUE)
  out[, state := st]

  # Pelz OG indicator
  out[, pelz_og := !is.na(STDAGE) &
                   STDAGE >= PELZ_MIN_STDAGE &
                   big_trees_per_ac >= PELZ_MIN_TREES_PER_AC]

  cat(sprintf("  Pelz OG flagged: %d / %d (%.2f%%)\n",
              sum(out$pelz_og), nrow(out), 100 * mean(out$pelz_og)))
  out[]
}

cat("=== Phase 7: Pelz NFS-only cross-validation ===\n")
cat(sprintf("Pelz thresholds: STDAGE >= %d yr, %.1f trees/ac of DBH >= %.1f in\n",
            PELZ_MIN_STDAGE, PELZ_MIN_TREES_PER_AC, PELZ_MIN_DBH_IN))

pelz_plots <- rbindlist(lapply(STATE_CODES, compute_pelz_per_state))

# Per-state summary of NFS plots
cat("\n=== NFS plots per state ===\n")
print(pelz_plots[, .(n_NFS_plots = .N,
                      n_pelz_og   = sum(pelz_og),
                      pct_pelz_og = round(100 * mean(pelz_og), 2)),
                  by = state])

# Cross-validation against v5.1 (from unified table)
unified <- fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv",
                  colClasses = list(character = "CN"))
unified[, CN := as.character(CN)]
pelz_plots[, PLT_CN := as.character(PLT_CN)]

# Recompute v5.1 class fresh for each panel
unified[, `:=`(
  s_ba_large = fifelse(ba_large >= 80, 2L, fifelse(ba_large >= 40, 1L, 0L)),
  s_maturity = fifelse(!is.na(STDAGE) & STDAGE >= 120, 2L,
                fifelse(!is.na(STDAGE) & STDAGE >= 80, 1L,
                fifelse((is.na(STDAGE) | STDAGE == 0) & max_dia >= 24, 1L, 0L))),
  s_structure = fifelse(sd_dia >= 8, 2L, fifelse(sd_dia >= 5, 1L, 0L)),
  s_canopy    = fifelse(ba_total >= 150, 2L, fifelse(ba_total >= 100, 1L, 0L)),
  s_deadwood  = fifelse(snag_tpa >= snag_thresh_2, 2L,
                        fifelse(snag_tpa >= snag_thresh_1, 1L, 0L)),
  s_height    = fifelse(!is.na(potapov_rh95) & potapov_rh95 >= 25, 2L,
                fifelse(!is.na(potapov_rh95) & potapov_rh95 >= 18, 1L, 0L))
)]
unified[, v51_total := s_ba_large + s_maturity + s_structure + s_canopy +
                        s_deadwood + s_height]
unified[, v51_class := fifelse(v51_total >= 8, "OG",
                       fifelse(v51_total >= 6, "LS",
                       fifelse(v51_total >= 4, "Transitioning LS", "Not LSOG")))]

# Match Pelz NFS plots to v5.1 class via CN
joined <- merge(pelz_plots[, .(PLT_CN, state, INVYR, STDAGE, big_trees_per_ac,
                                 pelz_og, FORTYPCD, OWNCD)],
                 unified[, .(CN, eval_period, v51_class, v51_total)],
                 by.x = "PLT_CN", by.y = "CN")

cat(sprintf("\nNFS plots matched to v5.1 unified table: %d\n", nrow(joined)))

# Confusion matrix: v5.1_class x pelz_og
conf <- joined[, .N, by = .(v51_class, pelz_og)]
cat("\n=== Confusion matrix: v5.1 class x Pelz OG flag ===\n")
print(dcast(conf, v51_class ~ pelz_og, value.var = "N", fill = 0))

# Cohen's kappa: v5.1 OG vs Pelz OG (binary)
kappa_binary <- function(y_true, y_pred) {
  ct <- table(y_true, y_pred)
  if (any(dim(ct) < 2)) return(NA_real_)
  n <- sum(ct); po <- sum(diag(ct)) / n
  pe <- sum(rowSums(ct) * colSums(ct)) / n^2
  (po - pe) / (1 - pe)
}

joined[, v51_og := v51_class == "OG"]
joined[, v51_lsog := v51_class %in% c("LS","OG")]
joined[, v51_any  := v51_class != "Not LSOG"]

# Kappas for various binary cuts
kappas <- data.table(
  comparison = c("v5.1 OG vs Pelz OG",
                  "v5.1 LS+OG vs Pelz OG",
                  "v5.1 any-LSOG vs Pelz OG"),
  kappa = c(
    kappa_binary(joined$pelz_og, joined$v51_og),
    kappa_binary(joined$pelz_og, joined$v51_lsog),
    kappa_binary(joined$pelz_og, joined$v51_any)
  )
)
print(kappas)

# Save outputs
fwrite(joined, file.path(out_dir, "phase7_NFS_plot_classifications.csv"))
fwrite(conf,    file.path(out_dir, "phase7_v51_pelz_confusion.csv"))
fwrite(kappas,  file.path(out_dir, "phase7_kappas.csv"))

# Per-state summary
state_summary <- joined[, .(
  n_NFS_plots = .N,
  v51_OG = sum(v51_og),
  v51_LSOG = sum(v51_lsog),
  v51_any = sum(v51_any),
  pelz_OG = sum(pelz_og),
  agreement_OG = sum(v51_og & pelz_og),
  agreement_anyLSOG = sum(v51_any & pelz_og),
  pct_pelz_OG = round(100 * mean(pelz_og), 2),
  pct_v51_OG = round(100 * mean(v51_og), 2),
  pct_v51_anyLSOG = round(100 * mean(v51_any), 2)
), by = state]
fwrite(state_summary, file.path(out_dir, "phase7_state_summary.csv"))

cat("\n=== Per-state summary (NE NFS lands) ===\n")
print(state_summary)

# Compare Pelz Eastern Region NFS area (~123,000 ha = 304K ac) to our flagging
total_pelz_og <- sum(joined$pelz_og)
cat(sprintf("\nTotal NFS plots flagged Pelz-OG in NE: %d (of %d total NE-NFS plots)\n",
            total_pelz_og, nrow(joined)))
cat("(Pelz 2023 reports ~304K ac OG total NFS-Eastern Region; this is",
    "the FIA-plot-based count for NE NFS portion only.)\n")

cat("\nDone.\n")
