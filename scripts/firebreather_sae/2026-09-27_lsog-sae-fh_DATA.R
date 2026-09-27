#!/usr/bin/env Rscript
# 2026-09-27_lsog-sae-fh_DATA.R
# Small area estimation of LSOG class prevalence on H3 resolution 4 blocks, using each 10 m probability
# surface as the auxiliary variable. Inputs are BLOCK AGGREGATES built on Cardinal (no plot rows, no
# coordinates). Four estimators per block:
#   map      the surface's own block mean (what a fixed-threshold user implicitly trusts)
#   direct   the Hajek weighted mean of the plot labels in the block
#   greg     cross-fitted difference estimator, map mean + weighted mean out-of-fold residual
#   fh       Fay-Herriot EBLUP, direct ~ b0 + b1 * map, REML, Prasad-Rao MSE; synthetic where no plots
# Sampling variances are smoothed with a generalized variance function, psi_d = s2_pooled * sum(w^2)/sum(w)^2,
# so blocks whose direct estimate is 0 or 1 still carry an honest variance.
# Checks: leave-one-block-out prediction error of map vs fh-synthetic, net of sampling variance; totals
# against the jurisdiction design-based rate; the fixed-cut error the attenuation note describes.
# ME_CORE4J reuses the uncalibrated model's OOF residuals, so its greg column is not meaningful and is
# not reported; its fh and fixed-cut results are.
# Base R plus data.table and ggplot2. Seed not needed (no resampling). Output: aggregates only.
suppressPackageStartupMessages({ library(data.table); library(ggplot2) })
args <- commandArgs(TRUE); IN <- if (length(args)) args[1] else "input"; OUT <- "output"
dir.create(OUT, FALSE)
say <- function(...) cat(sprintf(...), "\n")

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
  X <- cbind(1, D$map_mean); f <- reml_fh(D$direct, X, D$psi)
  g <- f$s2 / (f$s2 + D$psi)
  syn <- as.numeric(X %*% f$b)
  est <- g * D$direct + (1 - g) * syn
  # Prasad-Rao MSE, REML: g1 + g2 + 2 g3
  g1 <- g * D$psi
  g2 <- (1 - g)^2 * rowSums((X %*% f$Vb) * X)
  Ibar <- 0.5 * sum(1 / (f$s2 + D$psi)^2); vs2 <- 1 / Ibar
  g3 <- D$psi^2 / (f$s2 + D$psi)^3 * vs2
  list(fit = f, gamma = g, syn = syn, est = est, mse = g1 + g2 + 2 * g3)
}

wslope <- function(y, x, w) { b <- coef(lm(y ~ x, weights = w)); unname(b[2]) }

run_surface <- function(sname, label, publish_blocks) {
  B <- fread(file.path(IN, sprintf("sae_blocks_%s_DATA_2026-09-27.csv", sname)))
  B[is.na(n), `:=`(n = 0L, npos = 0L, sw = 0, sw2 = 0, swy = 0, swo = 0, swe = 0, swe2 = 0)]
  S <- B[n > 0]
  # pooled within-block variances for the GVF
  s2y <- S[, sum(swy - swy^2 / sw) / sum(sw)]
  s2e <- S[, sum(swe2 - swe^2 / sw) / sum(sw)]
  B[, k := fifelse(sw > 0, sw2 / sw^2, NA_real_)]
  B[, direct := fifelse(sw > 0, swy / sw, NA_real_)]
  B[, psi := s2y * k]
  B[, greg := fifelse(sw > 0, map_mean + swe / sw, NA_real_)]
  B[, greg_var := s2e * k]
  Fit <- B[n >= 2 & !is.na(map_mean)]
  FHm <- fh_fit(Fit)
  Fit[, `:=`(fh = FHm$est, fh_mse = FHm$mse, gamma = FHm$gamma, syn = FHm$syn)]
  B <- merge(B, Fit[, .(h3, fh, fh_mse, gamma)], by = "h3", all.x = TRUE)
  X <- cbind(1, B$map_mean)
  B[, syn := as.numeric(X %*% FHm$fit$b)]
  B[, syn_mse := FHm$fit$s2 + rowSums((X %*% FHm$fit$Vb) * X)]
  B[is.na(fh) & !is.na(map_mean), `:=`(fh = syn, fh_mse = syn_mse, gamma = 0)]
  B[, fh := pmin(pmax(fh, 0), 1)]

  # leave-one-block-out: synthetic FH fitted without block d, against the direct estimate net of psi
  lobo <- rbindlist(lapply(seq_len(nrow(Fit)), function(i) {
    f <- reml_fh(Fit$direct[-i], cbind(1, Fit$map_mean[-i]), Fit$psi[-i])
    data.table(h3 = Fit$h3[i], syn_lobo = f$b[1] + f$b[2] * Fit$map_mean[i])
  }))
  L <- merge(Fit[, .(h3, direct, psi, map_mean, n)], lobo, by = "h3")
  w <- L$n
  emse_map <- weighted.mean((L$direct - L$map_mean)^2 - L$psi, w)
  emse_syn <- weighted.mean((L$direct - L$syn_lobo)^2 - L$psi, w)

  # totals, area weights are the sampled forest cells
  A <- B[!is.na(map_mean)]
  tot <- list(
    design_weighted_obs = S[, sum(swy) / sum(sw)],
    map_share = A[, sum(map_mean * n_cells) / sum(n_cells)],
    fh_area_weighted = A[, sum(fh * n_cells) / sum(n_cells)])

  # fixed cut error: one cut chosen so the area above it equals the jurisdiction design-based rate,
  # read against each block's FH estimate
  qcols <- sprintf("q%02d", 1:99)
  share_above <- function(cut, Q) {
    # fraction of a block's cells above cut, linear in the 1..99 percentile grid
    apply(Q, 1, function(qv) { if (any(is.na(qv))) return(NA_real_)
      if (cut <= qv[1]) return(0.995)
      if (cut >= qv[99]) return(0.005)
      p <- approx(qv, (1:99) / 100, xout = cut, ties = "ordered")$y; 1 - p })
  }
  Q <- as.matrix(A[, ..qcols])
  target <- tot$design_weighted_obs
  fcut <- uniroot(function(c) sum(share_above(c, Q) * A$n_cells) / sum(A$n_cells) - target, c(1e-4, 0.9999))$root
  A[, sel_fixed := share_above(fcut, Q)]
  A[, cut_block := mapply(function(th, i) { if (th <= 0.01) return(Q[i, 99]); if (th >= 0.99) return(Q[i, 1])
      Q[i, max(1, min(99, round(100 * (1 - th))))] }, fh, seq_len(.N))]
  rows_fc <- A[!is.na(sel_fixed) & n >= 2]
  fixed_cut <- list(cut = fcut,
    wslope_selected_on_fh = wslope(rows_fc$sel_fixed, rows_fc$fh, rows_fc$n_cells),
    top_quartile_fh_blocks_selected_minus_fh = rows_fc[fh >= quantile(fh, 0.75), weighted.mean(sel_fixed - fh, n_cells)],
    bottom_quartile_fh_blocks_selected_minus_fh = rows_fc[fh <= quantile(fh, 0.25), weighted.mean(sel_fixed - fh, n_cells)],
    block_cut_range = range(A$cut_block, na.rm = TRUE),
    # the same comparison ranked by the noisy direct estimate, which regression to the mean biases toward
    # the opposite sign; reported to show why a plot-ranked check reads the direction the other way
    top_quartile_direct_blocks_selected_minus_direct = rows_fc[direct >= quantile(direct, 0.75), weighted.mean(sel_fixed - direct, n_cells)],
    bottom_quartile_direct_blocks_selected_minus_direct = rows_fc[direct <= quantile(direct, 0.25), weighted.mean(sel_fixed - direct, n_cells)],
    share_above_0.06 = sum(share_above(0.06, Q) * A$n_cells) / sum(A$n_cells),
    blocks_share_above_0.06_range = range(share_above(0.06, Q), na.rm = TRUE))

  summ <- list(surface = sname, label = label,
    blocks_total = nrow(B), blocks_with_plots = nrow(S), blocks_fit = nrow(Fit), plots = sum(S$n), positives = sum(S$npos),
    s2y_pooled = s2y, s2e_pooled = s2e,
    fh_b0 = FHm$fit$b[1], fh_b1 = FHm$fit$b[2], fh_b1_se = sqrt(FHm$fit$Vb[2, 2]), fh_sigma2_v = FHm$fit$s2,
    slope_map_on_direct_wls = wslope(Fit$map_mean, Fit$direct, Fit$n),
    slope_direct_on_map_wls = wslope(Fit$direct, Fit$map_mean, Fit$n),
    slope_direct_on_fh_wls = wslope(Fit$direct, Fit$fh, Fit$n),
    mean_gamma = mean(Fit$gamma),
    median_rrmse_direct = median(sqrt(Fit$psi) / pmax(Fit$direct, 1e-3)),
    median_rrmse_fh = median(sqrt(Fit$fh_mse) / pmax(Fit$fh, 1e-3)),
    median_mse_ratio_fh_over_direct = median(Fit$fh_mse / Fit$psi),
    lobo_emse_map = emse_map, lobo_emse_fh_synthetic = emse_syn,
    totals = tot, fixed_cut = fixed_cut)

  if (publish_blocks) {
    pub <- B[, .(h3, n_cells_sampled = n_cells, n_plots = n, map_mean, direct, direct_se = sqrt(psi), greg, greg_se = sqrt(greg_var),
                 fh, fh_rmse = sqrt(fh_mse), gamma)]
    pub <- merge(pub, A[, .(h3, cut_block, sel_fixed)], by = "h3", all.x = TRUE)
    fwrite(pub, file.path(OUT, sprintf("sae-blocks_%s_DATA_2026-09-27.csv", sname)))
  }
  # figure, anonymous
  P <- Fit[, .(map_mean, direct, fh, n)]
  lim <- c(0, max(c(P$direct, P$fh, P$map_mean), na.rm = TRUE) * 1.05)
  g <- ggplot(P, aes(map_mean, direct)) +
    geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "grey50", linewidth = 0.4) +
    geom_point(aes(size = n), shape = 21, fill = "grey80", colour = "grey35", stroke = 0.3) +
    geom_point(aes(y = fh), colour = "#1b6ca8", size = 1.4) +
    geom_abline(slope = FHm$fit$b[2], intercept = FHm$fit$b[1], colour = "#1b6ca8", linewidth = 0.6) +
    scale_size_area(max_size = 4, name = "Plots") +
    coord_equal(xlim = lim, ylim = lim) +
    labs(x = "Mapped block mean probability", y = "Block prevalence (gray, direct; blue, Fay-Herriot)",
         title = label) +
    theme_classic(base_size = 9) + theme(legend.position = "right", plot.title = element_text(size = 9))
  ggsave(file.path(OUT, sprintf("fig_sae_%s_2026-09-27.png", sname)), g, width = 120, height = 95, units = "mm", dpi = 300, bg = "white")
  ggsave(file.path(OUT, sprintf("fig_sae_%s_2026-09-27.pdf", sname)), g, width = 120, height = 95, units = "mm", bg = "white", device = if (capabilities("cairo")) cairo_pdf else "pdf")
  summ
}

SURF <- list(
  ME_TRANS  = list("Maine, transitioning and above (FIA, v5.1 score \u2265 4)", TRUE),
  ME_CORE4  = list("Maine, CORE4 structural core (16 September surface)", TRUE),
  ME_CORE4J = list("Maine, CORE4 structural core, jurisdiction calibrated (16 September)", TRUE),
  NB_CORE4L = list("New Brunswick, CORE4 structural core, licensed labels", FALSE),
  NB_TRANSL = list("New Brunswick, transitioning and above, licensed labels", FALSE))
res <- list()
for (s in names(SURF)) {
  f <- file.path(IN, sprintf("sae_blocks_%s_DATA_2026-09-27.csv", s))
  if (!file.exists(f)) { say("skip %s, no input", s); next }
  say("== %s", s); res[[s]] <- run_surface(s, SURF[[s]][[1]], SURF[[s]][[2]])
  str(res[[s]][c("fh_b0", "fh_b1", "fh_b1_se", "fh_sigma2_v", "mean_gamma", "slope_map_on_direct_wls", "median_mse_ratio_fh_over_direct", "lobo_emse_map", "lobo_emse_fh_synthetic", "totals", "fixed_cut")])
}
if (requireNamespace("sae", quietly = TRUE)) {
  for (s in names(res)) {
    B <- fread(file.path(IN, sprintf("sae_blocks_%s_DATA_2026-09-27.csv", s)))[n >= 2 & !is.na(map_mean)]
    s2y <- res[[s]]$s2y_pooled; B[, direct := swy / sw][, psi := s2y * sw2 / sw^2]
    m <- sae::eblupFH(direct ~ map_mean, vardir = psi, method = "REML", data = B)
    res[[s]]$crosscheck_sae_pkg <- list(b = as.numeric(m$fit$estcoef$beta), sigma2_v = m$fit$refvar)
    say("%s sae::eblupFH b = %s, refvar = %.3g", s, paste(round(m$fit$estcoef$beta, 4), collapse = ", "), m$fit$refvar)
  }
} else say("sae package not available, cross-check skipped")
jsonlite_ok <- requireNamespace("jsonlite", quietly = TRUE)
if (jsonlite_ok) writeLines(jsonlite::toJSON(res, auto_unbox = TRUE, digits = 6, pretty = TRUE), file.path(OUT, "sae_summary_2026-09-27.json")) else saveRDS(res, file.path(OUT, "sae_summary_2026-09-27.rds"))
cat("done\n")
