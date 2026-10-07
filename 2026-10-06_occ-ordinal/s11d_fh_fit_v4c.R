#!/usr/bin/env Rscript
# s11d_fh_fit_v4c.R  (red team revision, 7 October 2026: v4c covariates from s11c; adds a paired block bootstrap of
# the LOBO error difference against the matching baseline.) Fay-Herriot for Maine transitioning and above (H3 resolution 4) with the rebuilt FIA + OCC
# (Hagan) 10 m map as the auxiliary. reml_fh and fh_fit are copied verbatim from fhx_fit_2026-10-05.R; the GVF psi,
# the n >= 2 fit rule, the synthetic rule, the clamp to [0, 1], the LOBO measure and the n_cells area weights are
# unchanged. Methods compared on the same 66 blocks and the same direct estimates:
#   M0  shipped 10 m transitioning surface, block map mean (published 2026-09-27; gate: reproduced to 1e-6)
#   M2  2026-10-05 cross fit (leave one H3 block out, AE only)            [current table of record]
#   M4  rebuilt v4 map, block mean of the recalibrated surface (in sample for its training plots)
#   M5  rebuilt v4 learner, leave one H3 block out cross fit at the block's plots, recalibrated (primary candidate)
# The statewide total against 13.40 to 15.91 is reported per method, not gated.
suppressPackageStartupMessages(library(data.table))
args <- commandArgs(TRUE); OUT <- args[1]; L <- path.expand("~/LSOG")
say <- function(...) cat(sprintf(...), "\n"); die <- function(...) { say(paste("GATE FAIL", sprintf(...))); quit(status = 2) }
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
  g <- f$s2 / (f$s2 + D$psi); syn <- as.numeric(X %*% f$b); est <- g * D$direct + (1 - g) * syn
  g1 <- g * D$psi; g2 <- (1 - g)^2 * rowSums((X %*% f$Vb) * X)
  Ibar <- 0.5 * sum(1 / (f$s2 + D$psi)^2); vs2 <- 1 / Ibar; g3 <- D$psi^2 / (f$s2 + D$psi)^3 * vs2
  list(fit = f, gamma = g, syn = syn, est = est, mse = g1 + g2 + 2 * g3)
}
B0 <- fread(file.path(L, "2026-09-27_sae-block-prep/out/sae_blocks_ME_TRANS_DATA_2026-09-27.csv"))
PUB <- fread(file.path(L, "2026-10-01_surface-maps/sae-blocks_ME_TRANS_DATA_2026-09-27.csv"))
OLD <- fread(file.path(L, "2026-10-05_fh-crossfit/out/fhx_blocks_ME_TRANS_DATA_2026-10-05.csv"))
V4 <- fread(file.path(OUT, "agg/fh_blocks_v4c_DATA.csv"))
if (nrow(B0) != 66) die("prep has %d blocks", nrow(B0))
B0[is.na(n), `:=`(n = 0L, npos = 0L, sw = 0, sw2 = 0, swy = 0, swo = 0, swe = 0, swe2 = 0)]
B0 <- merge(B0, OLD[, .(h3, swo_lobo, swo2_lobo, swyo_lobo)], by = "h3", all.x = TRUE)
B0 <- merge(B0, V4[, .(h3, n_v4 = n, swy_v4 = swy, swo_v4lobo, swo2_v4lobo, swyo_v4lobo, map_mean_v4, n_cells_v4)], by = "h3", all.x = TRUE)
S <- B0[n > 0]; s2y <- S[, sum(swy - swy^2 / sw) / sum(sw)]
B0[, k := fifelse(sw > 0, sw2 / sw^2, NA_real_)]; B0[, direct := fifelse(sw > 0, swy / sw, NA_real_)]; B0[, psi := s2y * k]
run <- function(method, xmap, so = NULL, so_n = NULL, syo = NULL, sy = NULL) {
  B <- copy(B0); B[, mapx := xmap]
  if (is.null(so)) { B[, x := mapx]; cxy <- 0 } else {
    B[, x := fifelse(!is.na(so_n) & so_n >= 2, so / so_n, mapx)]
    ok <- !is.na(so_n) & so_n > 0
    cxy <- sum(syo[ok] - sy[ok] * so[ok] / so_n[ok]) / sum(so_n[ok])
  }
  B[, cov_d := cxy * k]
  Fit <- B[n >= 2 & !is.na(mapx)]; FHm <- fh_fit(Fit)
  Fit[, `:=`(fh = FHm$est, fh_mse = FHm$mse, gamma = FHm$gamma)]
  B <- merge(B, Fit[, .(h3, fh, fh_mse, gamma)], by = "h3", all.x = TRUE)
  X <- cbind(1, B$x); B[, syn := as.numeric(X %*% FHm$fit$b)]; B[, syn_mse := FHm$fit$s2 + rowSums((X %*% FHm$fit$Vb) * X)]
  B[is.na(fh) & !is.na(mapx), `:=`(fh = syn, fh_mse = syn_mse, gamma = 0)]
  n_out <- B[fh < 0 | fh > 1, .N]; B[, fh := pmin(pmax(fh, 0), 1)]
  lobo <- rbindlist(lapply(seq_len(nrow(Fit)), function(i) {
    f <- reml_fh(Fit$direct[-i], cbind(1, Fit$x[-i]), Fit$psi[-i])
    data.table(h3 = Fit$h3[i], syn_lobo = f$b[1] + f$b[2] * Fit$x[i], b1_lobo = f$b[2]) }))
  Lb <- merge(Fit[, .(h3, direct, psi, x, n, cov_d)], lobo, by = "h3"); w <- Lb$n
  A <- B[!is.na(mapx)]
  Lb[, e := (direct - syn_lobo)^2 - psi + 2 * b1_lobo * cov_d]
  list(B = B, Lb = Lb, summ = data.table(method = method, blocks = nrow(B), blocks_fit = nrow(Fit), b0 = FHm$fit$b[1], b1 = FHm$fit$b[2],
    b1_se = sqrt(FHm$fit$Vb[2, 2]), sigma2_v = FHm$fit$s2, mean_gamma_fit = mean(Fit$gamma),
    statewide_fh_pct = 100 * A[, sum(fh * n_cells) / sum(n_cells)],
    rmse_median_pct = 100 * median(sqrt(B$fh_mse), na.rm = TRUE), rmse_median_fit_pct = 100 * median(sqrt(Fit$fh_mse)),
    mse_ratio_fh_over_direct_median = median(Fit$fh_mse / Fit$psi),
    lobo_emse_fh_syn_covadj = weighted.mean((Lb$direct - Lb$syn_lobo)^2 - Lb$psi + 2 * Lb$b1_lobo * Lb$cov_d, w),
    n_clamped = n_out, pooled_cov_y_x = cxy))
}
R <- list(M0 = run("M0_shipped_map_insample", B0$map_mean),
          M2 = run("M2_crossfit_2026-10-05_AE", B0$map_mean, B0$swo_lobo, B0$n, B0$swyo_lobo, B0$swy),
          M4 = run("M4_v4_map_mean", B0$map_mean_v4),
          M5 = run("M5_v4_crossfit_lobo", B0$map_mean_v4, B0$swo_v4lobo, B0$n_v4, B0$swyo_v4lobo, B0$swy_v4))
chk <- merge(R$M0$B[, .(h3, fh, r = sqrt(fh_mse))], PUB[, .(h3, fp = fh, rp = fh_rmse)], by = "h3")
d1 <- max(abs(chk$fh - chk$fp)); d2 <- max(abs(chk$r - chk$rp)); say("M0 reproduction: %.2e, %.2e", d1, d2)
if (d1 > 1e-6 || d2 > 1e-6) die("M0 does not reproduce the published table")
for (nm in names(R)) { Bm <- R[[nm]]$B; if (any(is.na(Bm$fh)) || any(Bm$fh < 0 | Bm$fh > 1)) die("%s estimates missing or outside [0, 1]", nm)
  st <- R[[nm]]$summ$statewide_fh_pct; R[[nm]]$summ[, total_in_13.40_15.91 := st >= 13.40 & st <= 15.91] }
TAB <- rbindlist(lapply(R, `[[`, "summ")); fwrite(TAB, file.path(OUT, "agg/fh_v4c_method_summary_DATA.csv")); print(TAB)
P <- merge(R$M5$B[n >= 3, .(h3, n_plots = n, direct, direct_se = sqrt(psi), x_v4_crossfit = x, map_mean_v4 = mapx, fh_v4 = fh, fh_v4_rmse = sqrt(fh_mse))],
           R$M2$B[, .(h3, fh_m2 = fh, fh_m2_rmse = sqrt(fh_mse))], by = "h3")
fwrite(P, file.path(OUT, "agg/sae-blocks_ME_TRANS_v4c-crossfit_DATA_2026-10-07_PROVISIONAL.csv"))
set.seed(20261007)
pb <- function(a, b, B = 2000) { X <- merge(R[[a]]$Lb[, .(h3, n, ea = e)], R[[b]]$Lb[, .(h3, eb = e)], by = "h3")
  d0 <- with(X, weighted.mean(ea - eb, n)); bs <- replicate(B, { i <- sample(nrow(X), replace = TRUE); with(X[i], weighted.mean(ea - eb, n)) })
  data.table(comparison = paste(a, "minus", b), diff = d0, lo = quantile(bs, 0.025), hi = quantile(bs, 0.975), blocks = nrow(X)) }
BT <- rbind(pb("M5", "M2"), pb("M4", "M0"), pb("M5", "M0")); print(BT); fwrite(BT, file.path(OUT, "agg/fh_v4c_lobo_diff_boot_DATA.csv"))
say("S11D DONE")
