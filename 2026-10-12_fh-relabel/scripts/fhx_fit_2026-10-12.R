#!/usr/bin/env Rscript
# fhx_fit_2026-10-12.R: copy of fhx_fit_2026-10-05.R (track fh-relabel). Changed: paths and date tags only. The
# prep blocks and the FH table it gates M0 against are the copies of the same mode (sae_block_prep_2026-10-12.py,
# sae_fh_2026-10-12.R) in the output folder given as the second argument. Original header follows.
# fhx_fit_2026-10-05.R  (track fh-crossfit). Runs on Cardinal. Block aggregates only.
# Refits the 2026-09-27 Maine transitioning and above Fay-Herriot model (2026-09-27_lsog-sae-fh_DATA.R)
# with a cross fitted block covariate. reml_fh and fh_fit are copied verbatim from that script; the
# GVF psi, the n >= 2 fit rule, the synthetic rule, the clamp to [0, 1], the leave one block out (LOBO)
# measure and the n_cells area weights are unchanged. Only the covariate x changes:
#   M0 map    block mean of the shipped 10 m surface (in sample; reproduces the published CSV, gate)
#   M1 sb     block mean of the prep OOF plot predictions (spatial_block folds, 2026-09-27 prep)
#   M2 lobo   block mean of plot predictions from the model with that H3 block held out (primary)
#   M3 k5     block mean of plot predictions, 5 fold over H3 blocks
# For M1 to M3, blocks outside the fit (n < 2, no plots) keep the map mean as their synthetic covariate:
# they have at most one plot, so no plot based covariate exists or it rests on one plot.
# Because the plot based covariate is measured on the same plots as the direct estimate, its sampling
# error covaries with the direct estimate's. The LOBO measure is reported raw (as in 2026-09-27) and with
# that covariance added back: E(theta - syn)^2 = E(direct - syn)^2 - psi + 2 b1 c_d, c_d = s_yo * k_d.
# Gates (hard exits): 66 blocks; M0 reproduces the published fh and fh_rmse to 1e-6; estimates in [0, 1].
# The statewide total against 13.40 to 15.91 is reported per method, and flagged, not gated.
suppressPackageStartupMessages(library(data.table))
set.seed(20261005)  # nothing is resampled; recorded for the rule
args <- commandArgs(TRUE); BASE <- args[1]
OUT <- if (length(args) > 1) args[2] else file.path(BASE, "out")
say <- function(...) cat(sprintf(...), "\n")
die <- function(...) { say(paste("GATE FAIL", sprintf(...))); quit(status = 2) }

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
if (nrow(B0) != 66 || nrow(PUB) != 66) die("block count %d / %d, expected 66", nrow(B0), nrow(PUB))
B0[is.na(n), `:=`(n = 0L, npos = 0L, sw = 0, sw2 = 0, swy = 0, swo = 0, swe = 0, swe2 = 0)]
B0 <- merge(B0, NEW[, !c("n", "npos", "sw", "swy"), with = FALSE], by = "h3", all.x = TRUE)
S <- B0[n > 0]
s2y <- S[, sum(swy - swy^2 / sw) / sum(sw)]
B0[, k := fifelse(sw > 0, sw2 / sw^2, NA_real_)]
B0[, direct := fifelse(sw > 0, swy / sw, NA_real_)]
B0[, psi := s2y * k]

run <- function(method, xcol) {
  B <- copy(B0)
  if (is.null(xcol)) { B[, x := map_mean]; cxy <- 0 } else {
    so <- B[[paste0("swo_", xcol)]]; so2 <- B[[paste0("swo2_", xcol)]]; syo <- B[[paste0("swyo_", xcol)]]
    B[, x := fifelse(n >= 2, so / sw, map_mean)]
    Sx <- B[n > 0]; so_s <- so[B$n > 0]; syo_s <- syo[B$n > 0]
    cxy <- sum(syo_s - Sx$swy * so_s / Sx$sw) / sum(Sx$sw)   # pooled within block cov(y, o)
  }
  B[, cov_d := cxy * k]
  Fit <- B[n >= 2 & !is.na(map_mean)]
  FHm <- fh_fit(Fit)
  Fit[, `:=`(fh = FHm$est, fh_mse = FHm$mse, gamma = FHm$gamma)]
  B <- merge(B, Fit[, .(h3, fh, fh_mse, gamma)], by = "h3", all.x = TRUE)
  X <- cbind(1, B$x)
  B[, syn := as.numeric(X %*% FHm$fit$b)]
  B[, syn_mse := FHm$fit$s2 + rowSums((X %*% FHm$fit$Vb) * X)]
  B[is.na(fh) & !is.na(map_mean), `:=`(fh = syn, fh_mse = syn_mse, gamma = 0)]
  n_out <- B[fh < 0 | fh > 1, .N]
  B[, fh := pmin(pmax(fh, 0), 1)]
  lobo <- rbindlist(lapply(seq_len(nrow(Fit)), function(i) {
    f <- reml_fh(Fit$direct[-i], cbind(1, Fit$x[-i]), Fit$psi[-i])
    data.table(h3 = Fit$h3[i], syn_lobo = f$b[1] + f$b[2] * Fit$x[i], b1_lobo = f$b[2])
  }))
  Lb <- merge(Fit[, .(h3, direct, psi, map_mean, x, n, cov_d)], lobo, by = "h3")
  w <- Lb$n
  A <- B[!is.na(map_mean)]
  list(B = B, n_out_of_range_before_clamp = n_out, summ = data.table(
    method = method, blocks = nrow(B), blocks_fit = nrow(Fit), blocks_synthetic = nrow(B) - nrow(Fit),
    b0 = FHm$fit$b[1], b1 = FHm$fit$b[2], b1_se = sqrt(FHm$fit$Vb[2, 2]), sigma2_v = FHm$fit$s2,
    mean_gamma_fit = mean(Fit$gamma),
    statewide_fh_pct = 100 * A[, sum(fh * n_cells) / sum(n_cells)],
    rmse_median_pct = 100 * median(sqrt(B$fh_mse)), rmse_min_pct = 100 * min(sqrt(B$fh_mse)), rmse_max_pct = 100 * max(sqrt(B$fh_mse)),
    rmse_median_fit_pct = 100 * median(sqrt(Fit$fh_mse)),
    mse_ratio_fh_over_direct_median = median(Fit$fh_mse / Fit$psi),
    lobo_emse_fh_syn = weighted.mean((Lb$direct - Lb$syn_lobo)^2 - Lb$psi, w),
    lobo_emse_fh_syn_covadj = weighted.mean((Lb$direct - Lb$syn_lobo)^2 - Lb$psi + 2 * Lb$b1_lobo * Lb$cov_d, w),
    lobo_emse_raw_x = weighted.mean((Lb$direct - Lb$x)^2 - Lb$psi + 2 * Lb$cov_d, w),
    lobo_emse_map = weighted.mean((Lb$direct - Lb$map_mean)^2 - Lb$psi, w),
    pooled_cov_y_x = cxy))
}

R <- list(M0_map = run("M0_map_insample", NULL), M1_sb = run("M1_oof_spatialblock", "sb"),
          M2_lobo = run("M2_oof_h3_lobo", "lobo"), M3_k5 = run("M3_oof_h3_k5", "k5"),
          Mins = run("Mref_insample_at_plots", "ins"))

# gate: M0 reproduces the published CSV
chk <- merge(R$M0_map$B[, .(h3, fh, fh_rmse = sqrt(fh_mse))], PUB[, .(h3, fh_p = fh, rmse_p = fh_rmse)], by = "h3")
d1 <- max(abs(chk$fh - chk$fh_p)); d2 <- max(abs(chk$fh_rmse - chk$rmse_p))
say("M0 reproduction: max |fh diff| %.3e, max |fh_rmse diff| %.3e over %d blocks", d1, d2, nrow(chk))
if (nrow(chk) != 66 || d1 > 1e-6 || d2 > 1e-6) die("M0 does not reproduce the published CSV")

ref <- R$M0_map$B[, .(h3, fh0 = fh)]
for (nm in names(R)) {
  Bm <- R[[nm]]$B
  if (nrow(Bm) != 66) die("%s has %d blocks", nm, nrow(Bm))
  if (any(is.na(Bm$fh)) || any(Bm$fh < 0 | Bm$fh > 1)) die("%s has estimates outside [0, 1] or missing", nm)
  m <- merge(Bm[, .(h3, fh)], ref, by = "h3")
  R[[nm]]$summ[, `:=`(n_change_gt_2pp_vs_M0 = sum(abs(m$fh - m$fh0) > 0.02),
                      max_abs_change_pp_vs_M0 = 100 * max(abs(m$fh - m$fh0)),
                      n_clamped = R[[nm]]$n_out_of_range_before_clamp)]
  st <- R[[nm]]$summ$statewide_fh_pct
  R[[nm]]$summ[, total_in_db_interval_13.40_15.91 := st >= 13.40 & st <= 15.91]
}
TAB <- rbindlist(lapply(R, `[[`, "summ"))
TAB[, `:=`(design_weighted_obs_pct = 100 * S[, sum(swy) / sum(sw)], map_share_pct = 100 * B0[!is.na(map_mean), sum(map_mean * n_cells) / sum(n_cells)],
           s2y_pooled = s2y)]
fwrite(TAB, file.path(OUT, "fhx_method_summary_2026-10-12.csv"))
print(TAB)

# provisional block CSV: primary method M2, blocks with at least 3 plots, H3 index only
P2 <- R$M2_lobo$B; P0 <- R$M0_map$B
pub <- merge(P2[n >= 3, .(h3, n_plots = n, map_mean, x_crossfit = x, direct, direct_se = sqrt(psi),
                          fh_crossfit = fh, fh_crossfit_rmse = sqrt(fh_mse), gamma_crossfit = gamma)],
             P0[, .(h3, fh_insample_2026_09_27 = fh, fh_insample_rmse = sqrt(fh_mse))], by = "h3")
if (any(pub$n_plots < 3)) die("block with fewer than 3 plots in the provisional CSV")
fwrite(pub, file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12_PROVISIONAL.csv"))
say("provisional CSV: %d blocks with n >= 3 of 66", nrow(pub))
say("FIT_DONE")
