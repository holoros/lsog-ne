#!/usr/bin/env Rscript
# fhx_promote_2026-10-12.R: copy of fhx_promote_2026-10-05.R (track fh-relabel). Changed: paths, date tags, and
# the two gates that checked the 2026-09-27/10-05 numbers themselves (statewide rounds to 14.00; exactly 5
# synthetic blocks), which apply only with FHR_MODE=old; with FHR_MODE=new the synthetic count is gated against
# the copied fit's method summary, and the 13.40 to 15.91 interval gate is kept. greg, greg_se and sel_fixed
# come from, and are gated against, the copied 2026-09-27 FH producer of the same mode. Column names are kept
# (fh_insample_2026_09_27 holds the in-sample map covariate fit of the mode's surface). Original header follows.
# fhx_promote_2026-10-05.R  (track hexmap-crossfit). Runs on Cardinal. Block aggregates only.
# Promotes method M2 (cross fitted covariate, leave one H3 block out) of ~/LSOG/2026-10-05_fh-crossfit
# to the 66 block record table, in the column layout of sae-blocks_ME_TRANS_DATA_2026-09-27.csv.
# The fh-crossfit run kept the 66 block M2 table in memory only (it wrote the 59 block provisional CSV),
# so this script refits M2 with reml_fh, fh_fit and run() copied verbatim from fhx_fit_2026-10-05.R,
# then checks it against the provisional CSV and the method summary before writing anything.
# Columns: h3, n_cells_sampled, n_plots, map_mean, direct, direct_se, greg, greg_se (unchanged from
# 2026-09-27: GREG does not use the FH covariate), fh, fh_rmse, gamma (M2), cut_block (recomputed from
# the M2 fh with the 2026-09-27 rule), sel_fixed (recomputed, gated equal to 2026-09-27), plus
# x_crossfit, synthetic (1 = no direct estimate in the fit, gamma 0), fh_insample_2026_09_27, fh_insample_rmse.
# Gates (hard exits): 66 blocks; fh in [0, 1]; statewide total rounds to 14.00 and lies in 13.40 to 15.91;
# M2 equals the provisional CSV (1e-10) on its 59 blocks; statewide equals the method summary (1e-9);
# sel_fixed equals 2026-09-27 (1e-9); the record file must not already exist.
suppressPackageStartupMessages(library(data.table))
set.seed(20261005)  # nothing is resampled; recorded for the rule
MODE <- Sys.getenv("FHR_MODE", "new"); if (!MODE %in% c("old", "new")) stop("FHR_MODE must be old or new")
FX <- path.expand("~/LSOG/2026-10-12_fh-relabel"); OUT <- if (MODE == "new") file.path(FX, "out") else file.path(FX, "out", "repro_old")
REC <- file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv")
say <- function(...) cat(sprintf(...), "\n")
die <- function(...) { say(paste("GATE FAIL", sprintf(...))); quit(status = 2) }
if (file.exists(REC)) die("record file already exists, not overwriting: %s", REC)

reml_fh <- function(y, X, psi) {
  nll <- function(ls2) {
    s2 <- exp(ls2); V <- s2 + psi; Vi <- 1 / V
    XtVX <- crossprod(X, X * Vi); b <- solve(XtVX, crossprod(X, y * Vi)); r <- y - X %*% b
    0.5 * (sum(log(V)) + as.numeric(determinant(XtVX)$modulus) + sum(r^2 * Vi))
  }
  o <- optimize(nll, c(log(1e-8), log(max(var(y), 1e-6) * 10)))
  s2 <- exp(o$minimum)
  if (nll(log(1e-8)) <= o$objective + 1e-9) s2 <- 0
  V <- s2 + psi; Vi <- 1 / V; XtVX <- crossprod(X, X * Vi); Vb <- solve(XtVX)
  b <- Vb %*% crossprod(X, y * Vi)
  list(s2 = s2, b = as.numeric(b), Vb = Vb)
}
fh_fit <- function(D) {
  X <- cbind(1, D$x); f <- reml_fh(D$direct, X, D$psi)
  g <- f$s2 / (f$s2 + D$psi)
  syn <- as.numeric(X %*% f$b)
  est <- g * D$direct + (1 - g) * syn
  g1 <- g * D$psi
  g2 <- (1 - g)^2 * rowSums((X %*% f$Vb) * X)
  Ibar <- 0.5 * sum(1 / (f$s2 + D$psi)^2); vs2 <- 1 / Ibar
  g3 <- D$psi^2 / (f$s2 + D$psi)^3 * vs2
  list(fit = f, gamma = g, syn = syn, est = est, mse = g1 + g2 + 2 * g3)
}

B0 <- fread(file.path(OUT, "sae_blocks_ME_TRANS_DATA_2026-10-12.csv"))
PUB <- fread(file.path(OUT, "sae-blocks_ME_TRANS_DATA_2026-10-12.csv"))
NEW <- fread(file.path(OUT, "fhx_blocks_ME_TRANS_DATA_2026-10-12.csv"))
PROV <- fread(file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12_PROVISIONAL.csv"))
MS <- fread(file.path(OUT, "fhx_method_summary_2026-10-12.csv"))
for (D in list(B0, PUB, NEW, PROV)) D[, h3 := as.character(h3)]
if (nrow(B0) != 66 || nrow(PUB) != 66) die("block count %d / %d, expected 66", nrow(B0), nrow(PUB))
B0[is.na(n), `:=`(n = 0L, npos = 0L, sw = 0, sw2 = 0, swy = 0, swo = 0, swe = 0, swe2 = 0)]
B0 <- merge(B0, NEW[, !c("n", "npos", "sw", "swy"), with = FALSE], by = "h3", all.x = TRUE)
S <- B0[n > 0]
s2y <- S[, sum(swy - swy^2 / sw) / sum(sw)]
B0[, k := fifelse(sw > 0, sw2 / sw^2, NA_real_)]
B0[, direct := fifelse(sw > 0, swy / sw, NA_real_)]
B0[, psi := s2y * k]

run <- function(xcol) {   # fhx_fit_2026-10-05.R run(), estimate part only
  B <- copy(B0)
  if (is.null(xcol)) { B[, x := map_mean] } else {
    so <- B[[paste0("swo_", xcol)]]
    B[, x := fifelse(n >= 2, so / sw, map_mean)]
  }
  Fit <- B[n >= 2 & !is.na(map_mean)]
  FHm <- fh_fit(Fit)
  Fit[, `:=`(fh = FHm$est, fh_mse = FHm$mse, gamma = FHm$gamma)]
  B <- merge(B, Fit[, .(h3, fh, fh_mse, gamma)], by = "h3", all.x = TRUE)
  X <- cbind(1, B$x)
  B[, syn := as.numeric(X %*% FHm$fit$b)]
  B[, syn_mse := FHm$fit$s2 + rowSums((X %*% FHm$fit$Vb) * X)]
  B[, synthetic := as.integer(is.na(fh))]
  B[is.na(fh) & !is.na(map_mean), `:=`(fh = syn, fh_mse = syn_mse, gamma = 0)]
  B[, fh := pmin(pmax(fh, 0), 1)]
  B
}
M2 <- run("lobo"); M0 <- run(NULL)

# gates
if (nrow(M2) != 66) die("M2 has %d blocks", nrow(M2))
if (any(is.na(M2$fh)) || any(M2$fh < 0 | M2$fh > 1)) die("M2 fh missing or outside [0, 1]")
st <- 100 * M2[!is.na(map_mean), sum(fh * n_cells) / sum(n_cells)]
say("statewide M2 %.6f percent", st)
if ((MODE == "old" && sprintf("%.2f", st) != "14.00") || st < 13.40 || st > 15.91) die("statewide %.4f not 14.00 (old) or not inside 13.40 to 15.91", st)
ms <- MS[method == "M2_oof_h3_lobo", statewide_fh_pct]
if (abs(ms - st) > 1e-9) die("statewide differs from method summary: %.10f vs %.10f", st, ms)
cp <- merge(PROV[, .(h3, fh_crossfit, fh_crossfit_rmse, x_crossfit)], M2[, .(h3, fh, rm = sqrt(fh_mse), x)], by = "h3")
if (nrow(cp) != nrow(PROV)) die("provisional blocks not all found")
d <- max(abs(cp$fh - cp$fh_crossfit), abs(cp$rm - cp$fh_crossfit_rmse), abs(cp$x - cp$x_crossfit))
say("M2 vs provisional (%d blocks): max abs diff %.3e", nrow(cp), d)
if (d > 1e-10) die("M2 refit does not reproduce the provisional CSV")
nsyn <- if (MODE == "old") 5L else as.integer(MS[method == "M2_oof_h3_lobo", blocks_synthetic])
if (M2[, sum(synthetic)] != nsyn) die("expected %d synthetic blocks, got %d", nsyn, M2[, sum(synthetic)])

# cut_block and sel_fixed with the 2026-09-27 rule (A = blocks with a map mean)
A <- M2[!is.na(map_mean)]
qcols <- sprintf("q%02d", 1:99)
share_above <- function(cut, Q) {
  apply(Q, 1, function(qv) { if (any(is.na(qv))) return(NA_real_)
    if (cut <= qv[1]) return(0.995)
    if (cut >= qv[99]) return(0.005)
    p <- approx(qv, (1:99) / 100, xout = cut, ties = "ordered")$y; 1 - p })
}
Q <- as.matrix(A[, ..qcols])
target <- S[, sum(swy) / sum(sw)]
fcut <- uniroot(function(c) sum(share_above(c, Q) * A$n_cells) / sum(A$n_cells) - target, c(1e-4, 0.9999))$root
A[, sel_fixed := share_above(fcut, Q)]
A[, cut_block := mapply(function(th, i) { if (th <= 0.01) return(Q[i, 99]); if (th >= 0.99) return(Q[i, 1])
    Q[i, max(1, min(99, round(100 * (1 - th))))] }, fh, seq_len(.N))]
sc <- merge(A[, .(h3, sel_fixed)], PUB[, .(h3, sp = sel_fixed)], by = "h3")
dsel <- max(abs(sc$sel_fixed - sc$sp), na.rm = TRUE)
say("sel_fixed vs copied FH producer (%s): max abs diff %.3e", MODE, dsel)
if (dsel > 1e-9) die("sel_fixed does not reproduce 2026-09-27")

rec <- M2[, .(h3, n_cells_sampled = n_cells, n_plots = n, map_mean, direct, direct_se = sqrt(psi),
              fh, fh_rmse = sqrt(fh_mse), gamma, x_crossfit = x, synthetic)]
rec <- merge(rec, PUB[, .(h3, greg, greg_se)], by = "h3")
rec <- merge(rec, A[, .(h3, cut_block, sel_fixed)], by = "h3", all.x = TRUE)
rec <- merge(rec, M0[, .(h3, fh_insample_2026_09_27 = fh, fh_insample_rmse = sqrt(fh_mse))], by = "h3")
setcolorder(rec, c("h3", "n_cells_sampled", "n_plots", "map_mean", "direct", "direct_se", "greg", "greg_se",
                   "fh", "fh_rmse", "gamma", "cut_block", "sel_fixed", "x_crossfit", "synthetic",
                   "fh_insample_2026_09_27", "fh_insample_rmse"))
if (nrow(rec) != 66) die("record has %d rows", nrow(rec))
fwrite(rec, REC)
say("summary: blocks %d, synthetic %d, n<3 %d, fh range %.4f to %.4f, rmse median %.4f range %.4f to %.4f, statewide %.4f",
    nrow(rec), rec[, sum(synthetic)], rec[, sum(n_plots < 3)], min(rec$fh), max(rec$fh),
    median(rec$fh_rmse), min(rec$fh_rmse), max(rec$fh_rmse), st)
say("RECORD_WRITTEN %s", REC)
