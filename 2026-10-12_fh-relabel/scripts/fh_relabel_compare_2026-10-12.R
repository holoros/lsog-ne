#!/usr/bin/env Rscript
# fh_relabel_compare_2026-10-12.R (track fh-relabel). Runs on Cardinal. Block aggregates only, no plot rows.
# Old = October 5 table of record (September labels, 2026-09-23 surface); new = 2026-10-12 table of record (jobA v5.1
# labels on the 2019 to 2023 visit, rebuilt 2026-10-12 surface). Writes out/fh_relabel_compare_DATA.csv.
suppressPackageStartupMessages(library(data.table))
H <- path.expand("~/LSOG"); R <- file.path(H, "2026-10-12_fh-relabel/out")
OLD <- fread(file.path(H, "2026-10-05_fh-crossfit/out/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05.csv"), colClasses = list(character = "h3"))
NEW <- fread(file.path(R, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv"), colClasses = list(character = "h3"))
MSo <- fread(file.path(H, "2026-10-05_fh-crossfit/out/fhx_method_summary_2026-10-05.csv"))
MSn <- fread(file.path(R, "fhx_method_summary_2026-10-12.csv"))
out <- list()
add <- function(metric, o, n, note = "") out[[length(out) + 1]] <<- data.table(metric = metric, old_2026_10_05 = as.numeric(o), new_2026_10_12 = as.numeric(n), new_minus_old = as.numeric(n) - as.numeric(o), note = note)
st <- function(B) 100 * B[!is.na(map_mean), sum(fh * n_cells_sampled) / sum(n_cells_sampled)]
# approximate interval for the area weighted statewide FH: block MSEs summed with area weights, covariance between
# blocks (shared regression coefficients) ignored. Not part of the October 5 method; reported for orientation only.
se <- function(B) { A <- B[!is.na(map_mean)]; a <- A$n_cells_sampled / sum(A$n_cells_sampled); 100 * sqrt(sum(a^2 * A$fh_rmse^2)) }
add("blocks_total", nrow(OLD), nrow(NEW))
add("blocks_with_plots", OLD[n_plots > 0, .N], NEW[n_plots > 0, .N])
add("blocks_fit_n_ge_2", OLD[synthetic == 0, .N], NEW[synthetic == 0, .N])
add("blocks_synthetic", OLD[, sum(synthetic)], NEW[, sum(synthetic)])
add("plots_in_blocks", OLD[, sum(n_plots)], NEW[, sum(n_plots)], "plots with a true coordinate inside a mapped block")
add("statewide_fh_pct", st(OLD), st(NEW), "M2 cross fitted, area weighted by sampled forest cells")
add("statewide_fh_approx95_lo_pct", st(OLD) - 1.96 * se(OLD), st(NEW) - 1.96 * se(NEW), "independence approximation, between block covariance ignored; not in the October 5 method")
add("statewide_fh_approx95_hi_pct", st(OLD) + 1.96 * se(OLD), st(NEW) + 1.96 * se(NEW), "as above")
add("statewide_inside_design_interval_13.40_15.91", st(OLD) >= 13.40 & st(OLD) <= 15.91, st(NEW) >= 13.40 & st(NEW) <= 15.91, "design based Maine any-LSOG 14.66 [13.40, 15.91]; 1 = inside")
add("block_rmse_median_pct", 100 * median(OLD$fh_rmse), 100 * median(NEW$fh_rmse), "all 66 blocks")
add("block_rmse_min_pct", 100 * min(OLD$fh_rmse), 100 * min(NEW$fh_rmse))
add("block_rmse_max_pct", 100 * max(OLD$fh_rmse), 100 * max(NEW$fh_rmse))
add("block_rmse_median_fit_blocks_pct", 100 * median(OLD[synthetic == 0, fh_rmse]), 100 * median(NEW[synthetic == 0, fh_rmse]))
g <- function(M, m, col) M[method == m][[col]]
for (m in c("M2_oof_h3_lobo", "Mref_insample_at_plots", "M0_map_insample")) {
  add(sprintf("lobo_emse_fh_syn_%s", m), g(MSo, m, "lobo_emse_fh_syn"), g(MSn, m, "lobo_emse_fh_syn"), "LOBO mean squared error of the synthetic FH net of sampling variance, n weighted (raw, as 2026-09-27)")
  add(sprintf("lobo_emse_fh_syn_covadj_%s", m), g(MSo, m, "lobo_emse_fh_syn_covadj"), g(MSn, m, "lobo_emse_fh_syn_covadj"), "same, with the covariate sampling covariance added back")
}
add("lobo_emse_ratio_crossfit_over_insample_plots", g(MSo, "M2_oof_h3_lobo", "lobo_emse_fh_syn_covadj") / g(MSo, "Mref_insample_at_plots", "lobo_emse_fh_syn_covadj"),
    g(MSn, "M2_oof_h3_lobo", "lobo_emse_fh_syn_covadj") / g(MSn, "Mref_insample_at_plots", "lobo_emse_fh_syn_covadj"), "cov adjusted; below 1 means the cross fitted covariate predicts held out blocks better")
add("b1_crossfit", g(MSo, "M2_oof_h3_lobo", "b1"), g(MSn, "M2_oof_h3_lobo", "b1"))
add("sigma2_v_crossfit", g(MSo, "M2_oof_h3_lobo", "sigma2_v"), g(MSn, "M2_oof_h3_lobo", "sigma2_v"))
add("mean_gamma_fit_crossfit", g(MSo, "M2_oof_h3_lobo", "mean_gamma_fit"), g(MSn, "M2_oof_h3_lobo", "mean_gamma_fit"))
add("direct_statewide_weighted_pct", g(MSo, "M2_oof_h3_lobo", "design_weighted_obs_pct"), g(MSn, "M2_oof_h3_lobo", "design_weighted_obs_pct"), "plots in blocks, w = 1")
add("map_share_pct", g(MSo, "M2_oof_h3_lobo", "map_share_pct"), g(MSn, "M2_oof_h3_lobo", "map_share_pct"), "surface block means, area weighted (old 2026-09-23 surface, new 2026-10-12 rebuild)")
add("statewide_fh_insample_map_cov_pct", st(copy(OLD)[, fh := fh_insample_2026_09_27]), st(copy(NEW)[, fh := fh_insample_2026_09_27]), "M0, map mean covariate, in sample")
C <- merge(OLD[, .(h3, fo = fh)], NEW[, .(h3, fn = fh)], by = "h3")
d <- 100 * (C$fn - C$fo); q <- quantile(d, c(0, 0.05, 0.25, 0.5, 0.75, 0.95, 1), names = FALSE)
add("per_block_change_blocks_compared", nrow(C), nrow(C), "h3 blocks common to both tables; both columns give the count")
nm <- c("min", "q05", "q25", "median", "q75", "q95", "max")
for (i in seq_along(q)) add(sprintf("per_block_change_fh_pp_%s", nm[i]), NA, q[i], "new minus old block FH, percentage points; value in new_minus_old")
add("per_block_change_mean_abs_pp", NA, mean(abs(d)), "value in new_minus_old")
add("per_block_n_abs_change_gt_2pp", NA, sum(abs(d) > 2), "value in new_minus_old")
TAB <- rbindlist(out)
TAB[metric %like% "^per_block_change_(fh_pp|mean_abs|n_abs)", `:=`(new_minus_old = new_2026_10_12, new_2026_10_12 = NA_real_)]
fwrite(TAB, file.path(R, "fh_relabel_compare_DATA.csv"))
print(TAB[, .(metric, old_2026_10_05, new_2026_10_12, new_minus_old)])
cat("COMPARE_DONE\n")
