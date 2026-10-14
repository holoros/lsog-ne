#!/usr/bin/env Rscript
# repro_gate_2026-10-12.R (track fh-relabel). Runs on Cardinal. Block aggregates only.
# Reproduction gate: the copied chain run with FHR_MODE=old (October 5 inputs: September table, 2026-09-23 surface,
# rf_trans_final_2026-09-23.pkl) must reproduce every intermediate and the table of record of the October 5 chain.
# Same key set, same columns, same NA pattern, numeric max abs difference <= 1e-9 (1e-6 for the 2026-09-27 FH table,
# which was produced on firebreather under R 4.5.1, the tolerance fhx_fit_2026-10-05.R used for that comparison).
# Writes out/repro_gate_2026-10-12.csv and, only if every row passes, out/REPRO_GATE_PASS_2026-10-12.txt.
suppressPackageStartupMessages(library(data.table))
H <- path.expand("~/LSOG"); R <- file.path(H, "2026-10-12_fh-relabel/out"); O <- file.path(R, "repro_old")
pairs <- list(
  list("prep_blocks", file.path(O, "sae_blocks_ME_TRANS_DATA_2026-10-12.csv"), file.path(H, "2026-09-27_sae-block-prep/out/sae_blocks_ME_TRANS_DATA_2026-09-27.csv"), "h3", 1e-9),
  list("fh_2026_09_27", file.path(O, "sae-blocks_ME_TRANS_DATA_2026-10-12.csv"), file.path(H, "2026-10-01_surface-maps/sae-blocks_ME_TRANS_DATA_2026-09-27.csv"), "h3", 1e-6),
  list("fhx_blocks", file.path(O, "fhx_blocks_ME_TRANS_DATA_2026-10-12.csv"), file.path(H, "2026-10-05_fh-crossfit/out/fhx_blocks_ME_TRANS_DATA_2026-10-05.csv"), "h3", 1e-9),
  list("method_summary", file.path(O, "fhx_method_summary_2026-10-12.csv"), file.path(H, "2026-10-05_fh-crossfit/out/fhx_method_summary_2026-10-05.csv"), "method", 1e-9),
  list("provisional", file.path(O, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12_PROVISIONAL.csv"), file.path(H, "2026-10-05_fh-crossfit/out/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05_PROVISIONAL.csv"), "h3", 1e-9),
  list("table_of_record", file.path(O, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv"), file.path(H, "2026-10-05_fh-crossfit/out/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05.csv"), "h3", 1e-9))
res <- rbindlist(lapply(pairs, function(p) {
  a <- fread(p[[2]], colClasses = list(character = p[[4]])); b <- fread(p[[3]], colClasses = list(character = p[[4]]))
  k <- p[[4]]; setkeyv(a, k); setkeyv(b, k)
  same_keys <- nrow(a) == nrow(b) && all(a[[k]] == b[[k]]); same_cols <- identical(names(a), names(b))
  dmax <- 0; na_ok <- TRUE; nonnum_ok <- TRUE
  if (same_keys && same_cols) for (cc in setdiff(names(a), k)) {
    x <- a[[cc]]; y <- b[[cc]]
    if (!identical(is.na(x), is.na(y))) { na_ok <- FALSE; next }
    if (is.numeric(x) && is.numeric(y)) { m <- !is.na(x); if (any(m)) dmax <- max(dmax, abs(x[m] - y[m])) }
    else if (is.logical(x) || is.character(x)) { if (!identical(as.character(x), as.character(y))) nonnum_ok <- FALSE }
  }
  data.table(item = p[[1]], rows_new = nrow(a), rows_ref = nrow(b), same_keys = same_keys, same_columns = same_cols,
             same_na_pattern = na_ok, nonnumeric_equal = nonnum_ok, max_abs_diff = dmax, tol = p[[5]],
             pass = same_keys && same_cols && na_ok && nonnum_ok && dmax <= p[[5]])
}))
print(res)
fwrite(res, file.path(R, "repro_gate_2026-10-12.csv"))
if (all(res$pass)) { writeLines(sprintf("REPRO GATE PASS %s, %d of %d items", format(Sys.time()), nrow(res), nrow(res)), file.path(R, "REPRO_GATE_PASS_2026-10-12.txt")); cat("REPRO_GATE_PASS\n") } else { cat("REPRO_GATE_FAIL\n"); quit(status = 2) }
