# d2_me_gate.R (November 13, 2026). Reproduction gate of the PREREG: each Maine label set must return its
# Appendix S1 Table S3 design-based rate to the printed digit before any surface is fit.
# Estimator: plot flag applied to every forest condition of the plot, weighted by CONDPROP_UNADJ x ADJ_FACTOR_SUBP,
# post-stratified ratio of means on EVALID 232301 (ratio_est copied from instrument_sweep/me_instrument_sweep_core4.R).
suppressPackageStartupMessages(library(data.table))
DB <- "/users/PUOM0008/crsfaaron/fia_data"; W <- path.expand("~/LSOG/2026-11-13_definition-map-sensitivity"); EV <- 232301L
L <- fread(file.path(W, "RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv"), colClasses = list(character = "PLT_CN"))
cond <- fread(file.path(DB, "ME_COND.csv"), select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "CONDPROP_UNADJ"), colClasses = list(character = "PLT_CN"))
ppsa <- fread(file.path(DB, "ME_POP_PLOT_STRATUM_ASSGN.csv"), select = c("PLT_CN", "STRATUM_CN", "EVALID"), colClasses = list(character = c("PLT_CN", "STRATUM_CN")))[EVALID == EV, .(PLT_CN, STRATUM_CN)]
pop <- fread(file.path(DB, "ME_POP_STRATUM.csv"), select = c("CN", "EVALID", "EXPNS", "ADJ_FACTOR_SUBP"), colClasses = list(character = "CN"))[EVALID == EV, .(STRATUM_CN = CN, EXPNS, ADJ_FACTOR_SUBP)]
cond <- cond[PLT_CN %in% ppsa$PLT_CN]; cond[, forest := as.integer(COND_STATUS_CD == 1)]
cond <- merge(cond, L, by = "PLT_CN", all.x = TRUE); V <- setdiff(names(L), "PLT_CN")
cond[, scored := as.integer(!is.na(get(V[1])))]
ratio_est <- function(cond, numcol, dencol) {
  j <- merge(cond[, .(PLT_CN, CONDID, CONDPROP_UNADJ, y_ind = as.numeric(get(numcol)), x_ind = as.numeric(get(dencol)))], ppsa, by = "PLT_CN")
  j <- merge(j, pop, by = "STRATUM_CN"); j[is.na(y_ind), y_ind := 0]; j[is.na(x_ind), x_ind := 0]
  j[, y := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * y_ind]; j[, x := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * x_ind]
  p <- j[, .(y = sum(y), x = sum(x)), by = .(STRATUM_CN, EXPNS, PLT_CN)]
  h <- p[, .(n = .N, ybar = mean(y), xbar = mean(x), vy = var(y), vx = var(x), cxy = if (.N > 1) cov(y, x) else 0), by = .(STRATUM_CN, EXPNS)]
  h[is.na(vy), vy := 0][is.na(vx), vx := 0][is.na(cxy), cxy := 0]
  TY <- sum(h$EXPNS * h$n * h$ybar); TX <- sum(h$EXPNS * h$n * h$xbar); R <- TY / TX
  varR <- sum(h$EXPNS^2 * h$n * (h$vy - 2 * R * h$cxy + R^2 * h$vx)) / TX^2
  c(pct = 100 * R, se = 100 * sqrt(max(varR, 0)), den_ac = TX)
}
target <- c(V3 = 22.69, V1 = 15.92, V2 = 12.46, V4 = 9.50, V9_c3 = 5.10, V7 = 2.26)
res <- rbindlist(lapply(V, function(v) {
  cond[, flag_num := as.integer(forest == 1 & scored == 1 & get(v) == 1)]
  e <- ratio_est(cond, "flag_num", "forest")
  data.table(variant = v, pct = e[["pct"]], lo = e[["pct"]] - 1.96 * e[["se"]], hi = e[["pct"]] + 1.96 * e[["se"]], den_ac = e[["den_ac"]],
             n_pos_plots = cond[flag_num == 1, uniqueN(PLT_CN)], target = target[[v]], pass = round(e[["pct"]], 2) == target[[v]])
}))
res[, n_eval_plots := uniqueN(cond$PLT_CN)][, n_scored_forest_plots := cond[forest == 1 & scored == 1, uniqueN(PLT_CN)]]
fwrite(res, file.path(W, "out/d2_me_gate_DATA.csv")); print(res)
cat(if (all(res$pass)) "GATE PASS\n" else "GATE FAIL\n"); if (!all(res$pass)) quit(status = 3)
