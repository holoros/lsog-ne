# d15_me_design_agreement.R (November 14, 2026). Design-based share of Maine forest meeting at least one, at least
# three, and all six of the mapped definitions, from the plot labels of d1 and the ratio estimator of d2 (EVALID 232301).
# Added after the blind referee read of patch42 asked for an inventory benchmark for the mapped agreement shares.
suppressPackageStartupMessages(library(data.table))
W <- path.expand("~/LSOG/2026-11-13_definition-map-sensitivity"); src <- readLines(file.path(W, "scripts/d2_me_gate.R"))
eval(parse(text = src[seq_len(grep("^target <- ", src) - 1)]))       # data, cond table and ratio_est exactly as in d2
cond[, cnt := rowSums(.SD), .SDcols = V]
res <- rbindlist(lapply(list(any = 1L, ge3 = 3L, all6 = 6L), function(k) {
  cond[, flag_num := as.integer(forest == 1 & scored == 1 & !is.na(cnt) & cnt >= k)]; e <- ratio_est(cond, "flag_num", "forest")
  data.table(min_definitions = k, pct = e[["pct"]], lo = e[["pct"]] - 1.96 * e[["se"]], hi = e[["pct"]] + 1.96 * e[["se"]], n_pos_plots = cond[flag_num == 1, uniqueN(PLT_CN)])
}), idcol = "set")
fwrite(res, file.path(W, "out/d15_me_design_agreement_DATA.csv")); print(res)
