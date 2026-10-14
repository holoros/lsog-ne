#!/usr/bin/env Rscript
# sae_refine_2026-10-13.R (track sae-refine). Runs on Cardinal. Prototype and evaluation only; adopts nothing.
# Compares, on the 66 H3 resolution 4 Maine transitioning blocks and the record's LOBO protocol, the table of
# record (M2_oof_h3_lobo cross fitted FH, ~/LSOG/2026-10-12_fh-relabel) with
#   C1 unit level logistic GLMM  y ~ logit(o_lobo) + (1 | h3), EBP of block rates over the map side covariate
#      distribution (99 block percentiles of the rebuilt 10 m surface), parametric bootstrap MSE
#   C2 spatial FH, SAR block effect on H3 ring 1 adjacency (row standardised, all 66 blocks), REML,
#      parametric bootstrap MSE
#   C3 hierarchical Bayes binomial logit FH (area level), Metropolis within Gibbs, posterior summaries
# LOBO error (identical to fhx_fit_2026-10-12.R): over the 61 fitted blocks (n >= 2), refit without block i,
# predict its synthetic value s_i, error = weighted mean over i of (direct_i - s_i)^2 - psi_i, weights n_i.
# Inputs read: record block files (aggregates) and out/plot_lobo_RESTRICTED.csv (h3, y, o_lobo; no ids).
# Outputs are block or method aggregates only. Gates are hard exits (status 2).
suppressPackageStartupMessages({ library(data.table); library(lme4) })
SEED <- 20261013L; set.seed(SEED)
NB <- as.integer(Sys.getenv("SAE_NBOOT", "500"))
T <- path.expand("~/LSOG/2026-10-13_sae-refine"); OUT <- file.path(T, "out")
REC <- path.expand("~/LSOG/2026-10-12_fh-relabel/out")
ELOG <- file.path(T, "logs", "error_log.txt")
say <- function(...) cat(sprintf(...), "\n")
die <- function(...) { m <- paste("GATE FAIL", sprintf(...)); say(m); cat(m, "\n", file = ELOG, append = TRUE); quit(status = 2) }
soft <- function(expr, what) tryCatch(expr, error = function(e) { m <- sprintf("%s ERROR %s: %s", Sys.time(), what, conditionMessage(e))
  cat(m, "\n", file = ELOG, append = TRUE); say(m); NULL })
Sys.umask("077")

## ---- record functions, copied verbatim from fhx_fit_2026-10-12.R ----
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

## ---- block inputs, exactly as fhx_fit_2026-10-12.R ----
B0 <- fread(file.path(REC, "sae_blocks_ME_TRANS_DATA_2026-10-12.csv"))
NEW <- fread(file.path(REC, "fhx_blocks_ME_TRANS_DATA_2026-10-12.csv"))
RECT <- fread(file.path(REC, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv"))
MS <- fread(file.path(REC, "fhx_method_summary_2026-10-12.csv"))[method == "M2_oof_h3_lobo"]
for (D in list(B0, NEW, RECT)) D[, h3 := as.character(h3)]
if (nrow(B0) != 66 || nrow(RECT) != 66 || nrow(MS) != 1) die("inputs: %d prep blocks, %d record blocks, %d M2 rows", nrow(B0), nrow(RECT), nrow(MS))
B0[is.na(n), `:=`(n = 0L, npos = 0L, sw = 0, sw2 = 0, swy = 0, swo = 0, swe = 0, swe2 = 0)]
B0 <- merge(B0, NEW[, !c("n", "npos", "sw", "swy"), with = FALSE], by = "h3", all.x = TRUE)
S <- B0[n > 0]
s2y <- S[, sum(swy - swy^2 / sw) / sum(sw)]
B0[, k := fifelse(sw > 0, sw2 / sw^2, NA_real_)]
B0[, direct := fifelse(sw > 0, swy / sw, NA_real_)]
B0[, psi := s2y * k]
B0[, x := fifelse(n >= 2, swo_lobo / sw, map_mean)]
Sx <- B0[n > 0]
cxy <- Sx[, sum(swyo_lobo - swy * swo_lobo / sw) / sum(sw)]
B0[, cov_d := cxy * k]
setorder(B0, h3)
B0[, fit := n >= 2 & !is.na(map_mean)]
O <- which(B0$fit); nO <- length(O)
if (nO != 61) die("expected 61 fitted blocks, got %d", nO)
if (any(is.na(B0$map_mean))) die("map mean missing for some block")
wst <- B0$n_cells / sum(B0$n_cells)
statewide <- function(est) 100 * sum(est * wst)
emse <- function(direct, syn, psi, w) weighted.mean((direct - syn)^2 - psi, w)

## ---- R0 reproduction of the record (M2) ----
FHm <- fh_fit(B0[O])
R0 <- copy(B0)
R0[, `:=`(est = NA_real_, mse = NA_real_, gamma = 0)]
R0[O, `:=`(est = FHm$est, mse = FHm$mse, gamma = FHm$gamma)]
Xa <- cbind(1, R0$x)
syn_all <- as.numeric(Xa %*% FHm$fit$b); synmse_all <- FHm$fit$s2 + rowSums((Xa %*% FHm$fit$Vb) * Xa)
ii <- which(is.na(R0$est)); R0[ii, `:=`(est = syn_all[ii], mse = synmse_all[ii])]
R0[, est := pmin(pmax(est, 0), 1)]
lobo_fh <- rbindlist(lapply(O, function(i) {
  oo <- setdiff(O, i); f <- reml_fh(B0$direct[oo], cbind(1, B0$x[oo]), B0$psi[oo]); xi <- c(1, B0$x[i])
  data.table(h3 = B0$h3[i], syn = sum(f$b * xi), b1 = f$b[2], pvar = f$s2 + drop(xi %*% f$Vb %*% xi))
}))
L0 <- merge(B0[O, .(h3, direct, psi, n, map_mean, cov_d)], lobo_fh, by = "h3")
rep <- c(statewide_fh_pct = statewide(R0$est), rmse_median_pct = 100 * median(sqrt(R0$mse)),
         rmse_min_pct = 100 * min(sqrt(R0$mse)), rmse_max_pct = 100 * max(sqrt(R0$mse)),
         mean_gamma_fit = mean(R0$gamma[O]), sigma2_v = FHm$fit$s2, b1 = FHm$fit$b[2],
         lobo_emse_fh_syn = L0[, emse(direct, syn, psi, n)],
         lobo_emse_fh_syn_covadj = L0[, weighted.mean((direct - syn)^2 - psi + 2 * b1 * cov_d, n)],
         lobo_emse_map = L0[, emse(direct, map_mean, psi, n)])
G <- data.table(metric = names(rep), this_code = unname(rep), record = as.numeric(MS[, names(rep), with = FALSE]))
chk <- merge(R0[, .(h3, est, rm = sqrt(mse))], RECT[, .(h3, fh, fh_rmse)], by = "h3")
G <- rbind(G, data.table(metric = c("block_fh_maxabsdiff", "block_fh_rmse_maxabsdiff"), this_code = c(max(abs(chk$est - chk$fh)), max(abs(chk$rm - chk$fh_rmse))), record = 0))
G[, absdiff := abs(this_code - record)]
# method summary is written to 6 decimals by fwrite of rounded print? compare relative to stored precision
G[, pass := absdiff <= 1e-6]
fwrite(G, file.path(OUT, "repro_gate_DATA.csv"))
print(G)
if (!all(G$pass)) die("reproduction gate: %s", paste(G$metric[!G$pass], collapse = ", "))
say("GATE PASS reproduction of the record (M2_oof_h3_lobo) to 1e-6")

## ---- C2 spatial FH (SAR on H3 ring 1, all 66 blocks, row standardised) ----
ADJ <- fread(file.path(OUT, "h3_ring1_adjacency_66.csv"), colClasses = "character")
Wf <- matrix(0, 66, 66, dimnames = list(B0$h3, B0$h3))
Wf[cbind(match(ADJ$h3_a, B0$h3), match(ADJ$h3_b, B0$h3))] <- 1
if (any(is.na(match(c(ADJ$h3_a, ADJ$h3_b), B0$h3))) || !isSymmetric(unname(Wf))) die("adjacency not symmetric or not on the 66 blocks")
rs <- function(W) { d <- rowSums(W); d[d == 0] <- 1; W / d }
W66 <- rs(Wf)
sarK <- function(rho, W) { A <- diag(nrow(W)) - rho * W; chol2inv(chol(crossprod(A))) }
sfh_reml <- function(y, X, psi, idx, W) {
  nll <- function(p) {
    s2 <- exp(p[1]); rho <- 0.99 * tanh(p[2])
    V <- s2 * sarK(rho, W)[idx, idx] + diag(psi, length(psi))
    cV <- tryCatch(chol(V), error = function(e) NULL); if (is.null(cV)) return(1e10)
    Vi <- chol2inv(cV); XtVX <- crossprod(X, Vi %*% X); b <- solve(XtVX, crossprod(X, Vi %*% y)); r <- y - X %*% b
    0.5 * (2 * sum(log(diag(cV))) + as.numeric(determinant(XtVX)$modulus) + drop(crossprod(r, Vi %*% r)))
  }
  st <- as.matrix(expand.grid(log(c(1e-4, 1e-3, 4e-3)), atanh(c(-0.5, 0, 0.5, 0.8) / 0.99)))
  v0 <- apply(st, 1, nll); o <- optim(st[which.min(v0), ], nll, control = list(maxit = 2000, reltol = 1e-12))
  o <- optim(o$par, nll, control = list(maxit = 2000, reltol = 1e-12))
  s2 <- exp(o$par[1]); rho <- 0.99 * tanh(o$par[2])
  V <- s2 * sarK(rho, W)[idx, idx] + diag(psi, length(psi)); Vi <- chol2inv(chol(V))
  Vb <- solve(crossprod(X, Vi %*% X)); b <- drop(Vb %*% crossprod(X, Vi %*% y))
  list(s2 = s2, rho = rho, b = b, Vb = Vb, Vi = Vi, nll = o$value, conv = o$convergence)
}
sfh_pred <- function(f, y, X_O, idx, Xall, W, at = seq_len(nrow(Xall))) {
  Gm <- f$s2 * sarK(f$rho, W); C <- Gm[at, idx, drop = FALSE]
  r <- y - X_O %*% f$b
  est <- drop(Xall[at, , drop = FALSE] %*% f$b + C %*% (f$Vi %*% r))
  D <- Xall[at, , drop = FALSE] - C %*% f$Vi %*% X_O
  pvar <- diag(Gm)[at] - rowSums((C %*% f$Vi) * C) + rowSums((D %*% f$Vb) * D)
  list(est = est, pvar = pvar)
}
XA <- cbind(1, B0$x)
yO <- B0$direct[O]; psiO <- B0$psi[O]
F2 <- sfh_reml(yO, XA[O, ], psiO, O, W66)
P2 <- sfh_pred(F2, yO, XA[O, ], O, XA, W66)
say("SFH: sigma2 %.6f rho %.4f b %s conv %d", F2$s2, F2$rho, paste(round(F2$b, 4), collapse = " "), F2$conv)
# implementation cross check against sae::eblupSFH on the 61 block sub graph (soft, logged)
xc <- soft({
  W61 <- rs(Wf[O, O]); f61 <- sfh_reml(yO, XA[O, ], psiO, seq_len(nO), W61)
  dd <- data.frame(direct = yO, x = B0$x[O], psi = psiO)
  s <- sae::eblupSFH(direct ~ x, vardir = psi, proxmat = W61, method = "REML", data = dd)
  data.table(check = "SFH REML vs sae::eblupSFH (61 block subgraph)", own_s2 = f61$s2, sae_s2 = s$fit$refvar,
             own_rho = f61$rho, sae_rho = s$fit$spatialcorr, own_b1 = f61$b[2], sae_b1 = s$fit$estcoef[2, 1])
}, "sae cross check")
if (!is.null(xc)) { print(xc); fwrite(xc, file.path(OUT, "sfh_sae_crosscheck_DATA.csv")) }
# parametric bootstrap MSE (all 66 blocks)
set.seed(SEED + 2)
K66 <- F2$s2 * sarK(F2$rho, W66); cK <- chol(K66); mu <- drop(XA %*% F2$b)
e2 <- matrix(NA_real_, NB, 66); nfail2 <- 0L
for (bb in seq_len(NB)) {
  th <- mu + drop(crossprod(cK, rnorm(66))); ys <- th[O] + rnorm(nO, 0, sqrt(psiO))
  fb <- soft(sfh_reml(ys, XA[O, ], psiO, O, W66), "sfh boot")
  if (is.null(fb)) { nfail2 <- nfail2 + 1L; next }
  e2[bb, ] <- sfh_pred(fb, ys, XA[O, ], O, XA, W66)$est - th
}
mse2 <- colMeans(e2^2, na.rm = TRUE)
C2 <- data.table(h3 = B0$h3, est = pmin(pmax(P2$est, 0), 1), mse = mse2, mse_analytic_g1g2 = P2$pvar)
lobo2 <- rbindlist(lapply(O, function(i) {
  oo <- setdiff(O, i); f <- sfh_reml(B0$direct[oo], XA[oo, ], B0$psi[oo], oo, W66)
  p <- sfh_pred(f, B0$direct[oo], XA[oo, ], oo, XA, W66, at = i)
  data.table(h3 = B0$h3[i], syn = p$est, pvar = p$pvar, b1 = f$b[2])
}))
say("SFH done, bootstrap failures %d of %d", nfail2, NB); gc()

## ---- C1 unit level logistic GLMM with EBP over the map side covariate distribution ----
P <- fread(file.path(OUT, "plot_lobo_RESTRICTED.csv"), colClasses = c(h3 = "character"))
if (nrow(P) != sum(B0$n) || sum(P$y) != sum(B0$npos)) die("plot file: %d rows %d positives vs blocks %d %d", nrow(P), sum(P$y), sum(B0$n), sum(B0$npos))
clip <- function(p) pmin(pmax(p, 1e-4), 1 - 1e-4)
P[, lx := qlogis(clip(o_lobo))]
qc <- sprintf("q%02d", 1:99); LXP <- qlogis(clip(as.matrix(B0[, ..qc])))
if (any(!is.finite(LXP))) die("map percentiles missing")
pidx <- split(seq_len(nrow(P)), factor(P$h3, levels = B0$h3))
gfit <- function(d) suppressMessages(suppressWarnings(glmer(y ~ lx + (1 | h3), data = d, family = binomial,
                   control = glmerControl(optimizer = "bobyqa", calc.derivs = FALSE))))
gpar <- function(f) list(b = unname(fixef(f)), s = as.data.frame(VarCorr(f))$sdcor[1], Vb = as.matrix(vcov(f)))
vgrid <- function(s) if (s < 1e-6) list(v = 0, w = 1) else { v <- seq(-6, 6, length.out = 241) * s; list(v = v, w = dnorm(v, 0, s)) }
ebp1 <- function(b, s, lxs, ys, lxpop) {
  g <- vgrid(s)
  llv <- if (length(ys)) { eta <- outer(b[1] + b[2] * lxs, g$v, "+"); colSums(ys * eta - log1p(exp(eta))) } else 0
  lw <- llv + log(g$w); w <- exp(lw - max(lw)); w <- w / sum(w)
  sum(w * colMeans(plogis(outer(b[1] + b[2] * lxpop, g$v, "+"))))
}
ebp_all <- function(pp, y, lx) vapply(seq_len(66), function(d) { j <- pidx[[d]]
  ebp1(pp$b, pp$s, lx[j], y[j], LXP[d, ]) }, 0)
G1 <- gfit(P); p1 <- gpar(G1)
say("GLMM: b %s sigma_v %.4f (logit scale), plots %d, blocks %d", paste(round(p1$b, 4), collapse = " "), p1$s, nrow(P), length(unique(P$h3)))
est1 <- ebp_all(p1, P$y, P$lx)
set.seed(SEED + 1)
mu1p <- p1$b[1] + p1$b[2] * P$lx; bi <- match(P$h3, B0$h3)
e1 <- matrix(NA_real_, NB, 66); nfail1 <- 0L
for (bb in seq_len(NB)) {
  v <- rnorm(66, 0, p1$s)
  th <- rowMeans(plogis(LXP * p1$b[2] + p1$b[1] + v))
  ys <- rbinom(nrow(P), 1, plogis(mu1p + v[bi]))
  Pb <- data.table(h3 = P$h3, y = ys, lx = P$lx)
  fb <- soft(gfit(Pb), "glmm boot"); if (is.null(fb)) { nfail1 <- nfail1 + 1L; next }
  e1[bb, ] <- ebp_all(gpar(fb), ys, P$lx) - th
}
mse1 <- colMeans(e1^2, na.rm = TRUE)
C1 <- data.table(h3 = B0$h3, est = est1, mse = mse1)
set.seed(SEED + 3)
lobo1 <- rbindlist(lapply(O, function(i) {
  hi <- B0$h3[i]; f <- gpar(gfit(P[h3 != hi])); g <- vgrid(f$s)
  syn_map <- sum(g$w / sum(g$w) * colMeans(plogis(outer(f$b[1] + f$b[2] * LXP[i, ], g$v, "+"))))
  syn_plot <- sum(g$w / sum(g$w) * colMeans(plogis(outer(f$b[1] + f$b[2] * P[h3 == hi, lx], g$v, "+"))))
  bd <- MASS::mvrnorm(2000, f$b, f$Vb); vd <- rnorm(2000, 0, f$s)
  thd <- rowMeans(plogis(bd[, 1] + vd + outer(bd[, 2], LXP[i, ])))
  data.table(h3 = hi, syn = syn_map, syn_plotcov = syn_plot, pvar = var(thd), b1 = f$b[2])
}))
say("GLMM done, bootstrap failures %d of %d", nfail1, NB); gc()

## ---- C3 hierarchical Bayes binomial logit FH (area level) ----
hb <- function(npos, n, lx, iters = 20000, burn = 5000, thin = 10, seed = 1) {
  set.seed(seed); m <- length(n); X <- cbind(1, lx)
  g0 <- glm(cbind(npos, n - npos) ~ lx, family = binomial); b <- unname(coef(g0)); L <- t(chol(vcov(g0) * 1.5))
  s2 <- 0.1; v <- rep(0, m); sdv <- rep(0.4, m); acc <- rep(0, m); accb <- 0
  ll <- function(eta) npos * eta - n * log1p(exp(eta))
  K <- (iters - burn) %/% thin; Pb <- matrix(NA_real_, K, 2); Ps2 <- numeric(K); Pp <- matrix(NA_real_, K, m); k <- 0
  for (it in seq_len(iters)) {
    xb <- drop(X %*% b)
    vp <- v + rnorm(m, 0, sdv); a <- log(runif(m)) < ll(xb + vp) - ll(xb + v) - (vp^2 - v^2) / (2 * s2)
    v[a] <- vp[a]; acc <- acc + a
    if (it <= burn && it %% 100 == 0) { sdv <- sdv * exp(acc / 100 - 0.44); acc[] <- 0 }
    bp <- b + drop(L %*% rnorm(2))
    if (log(runif(1)) < sum(ll(drop(X %*% bp) + v)) - sum(ll(xb + v))) { b <- bp; accb <- accb + 1 }
    s2 <- 1 / rgamma(1, shape = (m - 1) / 2, rate = sum(v^2) / 2)
    if (it > burn && (it - burn) %% thin == 0) { k <- k + 1; Pb[k, ] <- b; Ps2[k] <- s2; Pp[k, ] <- plogis(drop(X %*% b) + v) }
  }
  list(b = Pb, s2 = Ps2, p = Pp, accb = accb / iters)
}
rhat <- function(a, b) { n <- length(a); W <- (var(a) + var(b)) / 2; Bv <- n * var(c(mean(a), mean(b))); sqrt(((n - 1) / n * W + Bv / n) / W) }
t3 <- system.time({
  lxO <- qlogis(clip(B0$x[O])); H1 <- hb(B0$npos[O], B0$n[O], lxO, seed = 11); H2 <- hb(B0$npos[O], B0$n[O], lxO, seed = 12)
})[3]
rh <- c(b0 = rhat(H1$b[, 1], H2$b[, 1]), b1 = rhat(H1$b[, 2], H2$b[, 2]), s2 = rhat(H1$s2, H2$s2))
say("HB: %.1f s for two chains, Rhat %s, b accept %.2f", t3, paste(sprintf("%s %.3f", names(rh), rh), collapse = ", "), H1$accb)
Hb <- rbind(H1$b, H2$b); Hs2 <- c(H1$s2, H2$s2); Hp <- rbind(H1$p, H2$p)
lxA <- qlogis(clip(B0$x)); set.seed(SEED + 4)
D3 <- sapply(seq_len(66), function(d) { if (B0$fit[d]) Hp[, match(d, O)] else plogis(Hb[, 1] + Hb[, 2] * lxA[d] + rnorm(nrow(Hb), 0, sqrt(Hs2))) })
C3 <- data.table(h3 = B0$h3, est = colMeans(D3), mse = apply(D3, 2, var),
                 lo = apply(D3, 2, quantile, 0.025), hi = apply(D3, 2, quantile, 0.975))
run3 <- TRUE
lobo3 <- rbindlist(lapply(O, function(i) {
  oo <- setdiff(O, i); h <- hb(B0$npos[oo], B0$n[oo], qlogis(clip(B0$x[oo])), iters = 12000, burn = 3000, thin = 6, seed = 100 + i)
  th <- plogis(h$b[, 1] + h$b[, 2] * lxA[i] + rnorm(nrow(h$b), 0, sqrt(h$s2)))
  data.table(h3 = B0$h3[i], syn = mean(th), pvar = var(th))
}))
say("HB done"); gc()

## ---- comparison ----
z <- qnorm(0.975)
Lc <- B0[O, .(h3, direct, psi, n, map_mean, x, cov_d)]
evalL <- function(L, covadj = NULL) {
  L <- merge(Lc, L, by = "h3")
  out <- list(lobo_emse = L[, emse(direct, syn, psi, n)],
              lobo_emse_covadj = if (is.null(covadj)) NA_real_ else L[, weighted.mean((direct - syn)^2 - psi + 2 * covadj(.SD) * cov_d, n)],
              cover95_heldout = if ("pvar" %in% names(L)) L[, mean(abs(direct - syn) <= z * sqrt(pvar + psi))] else NA_real_,
              cover95_heldout_wt = if ("pvar" %in% names(L)) L[, weighted.mean(abs(direct - syn) <= z * sqrt(pvar + psi), n)] else NA_real_)
  out
}
rec_fh <- RECT[match(B0$h3, h3), fh]
blk <- function(C) {
  est <- C$est; rm <- sqrt(C$mse)
  list(statewide_pct = statewide(est), rmse_median_pct = 100 * median(rm), rmse_min_pct = 100 * min(rm), rmse_max_pct = 100 * max(rm),
       n_move_gt2pp_vs_record = sum(abs(est - rec_fh) > 0.02), max_abs_move_pp_vs_record = 100 * max(abs(est - rec_fh)))
}
na_blk <- list(statewide_pct = statewide(B0$map_mean), rmse_median_pct = NA_real_, rmse_min_pct = NA_real_, rmse_max_pct = NA_real_,
               n_move_gt2pp_vs_record = sum(abs(B0$map_mean - rec_fh) > 0.02), max_abs_move_pp_vs_record = 100 * max(abs(B0$map_mean - rec_fh)))
b1HB <- colMeans(Hb)[2]
hb_slope <- function(D) { p <- D$syn; b1HB * p * (1 - p) / (D$x * (1 - D$x)) }   # delta method slope of syn in x, approximate
R0C <- data.table(h3 = R0$h3, est = R0$est, mse = R0$mse)
rows <- list(
  c(method = "M0_map_block_mean", evalL(L0[, .(h3, syn = map_mean)]), na_blk, params = "plain map block mean, no model"),
  c(method = "R0_record_M2_crossfit_FH", evalL(L0[, .(h3, syn, pvar, b1)], function(D) D$b1), blk(R0C),
    params = sprintf("sigma2_v %.6f, b1 %.4f, mean gamma %.3f", FHm$fit$s2, FHm$fit$b[2], mean(R0$gamma[O]))),
  c(method = "C1_unit_GLMM_EBP_mappop", evalL(lobo1[, .(h3, syn, pvar)]), blk(C1),
    params = sprintf("b0 %.4f, b1 %.4f, sigma_v %.4f logit, %d of %d bootstrap fits ok", p1$b[1], p1$b[2], p1$s, NB - nfail1, NB)),
  c(method = "C1b_unit_GLMM_plotcov_synthetic", evalL(lobo1[, .(h3, syn = syn_plotcov, b1)], function(D) D$b1 * D$syn * (1 - D$syn) / (D$x * (1 - D$x))),
    lapply(na_blk, function(v) NA_real_), params = "LOBO only: held out synthetic averaged over the held out plots' cross fitted covariate"),
  c(method = "C2_spatial_FH_SAR_ring1", evalL(lobo2[, .(h3, syn, pvar, b1)], function(D) D$b1), blk(C2),
    params = sprintf("sigma2 %.6f, rho %.4f, b1 %.4f, %d of %d bootstrap fits ok", F2$s2, F2$rho, F2$b[2], NB - nfail2, NB)),
  c(method = "C3_HB_binomial_logit_FH", evalL(lobo3[, .(h3, syn, pvar)], hb_slope), blk(C3),
    params = sprintf("post mean b1 %.4f, sigma2_v %.4f logit, Rhat max %.3f", b1HB, mean(Hs2), max(rh))))
CMP <- rbindlist(lapply(rows, as.data.table), fill = TRUE)
rec_l <- CMP[method == "R0_record_M2_crossfit_FH", lobo_emse]; map_l <- CMP[method == "M0_map_block_mean", lobo_emse]
CMP[, `:=`(in_db_interval_13.40_15.91 = statewide_pct >= 13.40 & statewide_pct <= 15.91,
           beats_record_lobo = lobo_emse < rec_l, beats_map_lobo = lobo_emse < map_l)]
CMP[, recommended := grepl("^C[123]_", method) & beats_record_lobo & beats_map_lobo & in_db_interval_13.40_15.91]
CMP[method == "C1b_unit_GLMM_plotcov_synthetic", recommended := NA]
## paired block bootstrap of the LOBO error (adversarial pass): resample the 61 held out blocks, n weights
synl <- list(L0[, .(h3, syn = map_mean)], lobo_fh[, .(h3, syn)], lobo1[, .(h3, syn)], lobo1[, .(h3, syn = syn_plotcov)], lobo2[, .(h3, syn)], lobo3[, .(h3, syn)])
Lo <- Lc[order(h3)]
E <- sapply(synl, function(s) { m <- merge(Lo, s, by = "h3"); setorder(m, h3); (m$direct - m$syn)^2 - m$psi })
if (!isTRUE(all.equal(colSums(E * Lo$n) / sum(Lo$n), CMP$lobo_emse, tolerance = 1e-12))) die("bootstrap error matrix does not reproduce the LOBO errors")
set.seed(SEED + 5)
BS <- replicate(4000, { j <- sample(nO, replace = TRUE); colSums(E[j, , drop = FALSE] * Lo$n[j]) / sum(Lo$n[j]) })
dR <- sweep(BS, 2, BS[2, ]); dM <- sweep(BS, 2, BS[1, ])
CMP[, `:=`(d_vs_record_lo = apply(dR, 1, quantile, 0.025), d_vs_record_hi = apply(dR, 1, quantile, 0.975),
           d_vs_map_lo = apply(dM, 1, quantile, 0.025), d_vs_map_hi = apply(dM, 1, quantile, 0.975),
           share_boot_below_both = rowMeans(dR < 0 & dM < 0))]
## gates on outputs (hard): estimates in [0, 1], MSE finite positive, statewide within a physical plausibility band
## (half to double the design point 14.66, EVALID 232301), bootstrap failure share below 10 percent
for (nm in c("C1", "C2", "C3")) { C <- get(nm)
  if (nrow(C) != 66 || any(!is.finite(C$est)) || any(C$est < 0 | C$est > 1)) die("%s estimates missing or outside [0, 1]", nm)
  if (any(!is.finite(C$mse)) || any(C$mse <= 0)) die("%s MSE not finite positive", nm)
  st <- statewide(C$est); if (st < 14.66 / 2 || st > 14.66 * 2) die("%s statewide %.2f outside 7.33 to 29.32", nm, st) }
if (nfail1 > 0.1 * NB || nfail2 > 0.1 * NB) die("bootstrap failures GLMM %d SFH %d of %d", nfail1, nfail2, NB)
fwrite(CMP, file.path(OUT, "sae_refine_compare_DATA.csv"))
print(CMP[, .(method, lobo_emse, lobo_emse_covadj, d_vs_record_lo, d_vs_record_hi, d_vs_map_lo, d_vs_map_hi, share_boot_below_both, cover95_heldout, statewide_pct, rmse_median_pct, rmse_min_pct, rmse_max_pct, n_move_gt2pp_vs_record, recommended)])

## per block aggregates (no plot level content)
lohi <- function(C) list(pmax(C$est - z * sqrt(C$mse), 0), pmin(C$est + z * sqrt(C$mse), 1))
BL <- data.table(h3 = B0$h3, n_plots = B0$n, synthetic_record = as.integer(!B0$fit), map_mean = B0$map_mean,
                 direct = B0$direct, direct_se = sqrt(B0$psi),
                 rec_est = R0$est, rec_rmse = sqrt(R0$mse), glmm_est = C1$est, glmm_rmse = sqrt(C1$mse),
                 sfh_est = C2$est, sfh_rmse = sqrt(C2$mse), sfh_rmse_analytic_g1g2 = sqrt(C2$mse_analytic_g1g2),
                 hb_est = C3$est, hb_sd = sqrt(C3$mse), hb_lo = C3$lo, hb_hi = C3$hi)
BL[, c("rec_lo", "rec_hi") := lohi(R0C)][, c("glmm_lo", "glmm_hi") := lohi(C1)][, c("sfh_lo", "sfh_hi") := lohi(C2)]
fwrite(BL, file.path(OUT, "sae_refine_blocks_DATA.csv"))
LB <- Reduce(function(a, b) merge(a, b, by = "h3"), list(Lc[, .(h3, n, direct, psi, map_mean)], lobo_fh[, .(h3, rec_syn = syn, rec_pvar = pvar)],
       lobo1[, .(h3, glmm_syn = syn, glmm_syn_plotcov = syn_plotcov, glmm_pvar = pvar)], lobo2[, .(h3, sfh_syn = syn, sfh_pvar = pvar)],
       lobo3[, .(h3, hb_syn = syn, hb_pvar = pvar)]))
fwrite(LB, file.path(OUT, "sae_refine_lobo_blocks_DATA.csv"))
jsonlite::write_json(list(seed = SEED, nboot = NB, glmm = list(b = p1$b, sigma_v = p1$s, boot_fail = nfail1),
  sfh = list(s2 = F2$s2, rho = F2$rho, b = F2$b, conv = F2$conv, boot_fail = nfail2), hb = list(rhat = as.list(rh), seconds_two_chains = t3, b_accept = H1$accb),
  calib = list(statewide_map_mean_pct = statewide(B0$map_mean), plot_lobo_mean_pct = 100 * mean(P$o_lobo), obs_pct = 100 * mean(P$y))),
  file.path(OUT, "sae_refine_summary.json"), auto_unbox = TRUE, digits = 10, pretty = TRUE)

## ---- figure ----
fig <- soft({
  suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
  ord <- order(BL$rec_est); BL[, rank := match(seq_len(.N), ord)]
  lv <- c("Record cross fitted FH", "C1 unit level GLMM (EBP)", "C2 spatial FH (SAR)", "C3 HB binomial logit FH")
  LL <- rbind(BL[, .(rank, m = lv[1], e = rec_est, lo = rec_lo, hi = rec_hi)], BL[, .(rank, m = lv[2], e = glmm_est, lo = glmm_lo, hi = glmm_hi)],
              BL[, .(rank, m = lv[3], e = sfh_est, lo = sfh_lo, hi = sfh_hi)], BL[, .(rank, m = lv[4], e = hb_est, lo = hb_lo, hi = hb_hi)])
  LL[, m := factor(m, lv)]
  pal <- c("#000000", "#E69F00", "#0072B2", "#009E73")
  pa <- ggplot(LL, aes(rank, 100 * e, colour = m)) +
    geom_linerange(aes(ymin = 100 * lo, ymax = 100 * hi), position = position_dodge(0.7), linewidth = 0.3, alpha = 0.8) +
    geom_point(position = position_dodge(0.7), size = 0.8) +
    geom_point(data = BL[n_plots >= 2], aes(rank, 100 * direct), inherit.aes = FALSE, shape = 1, size = 1.1, colour = "grey45") +
    scale_colour_manual(values = pal, name = NULL) +
    labs(x = "Block (H3 resolution 4), ordered by record estimate", y = "Transitioning and above (%)",
         tag = "a") + theme_classic(base_size = 9) + theme(legend.position = "top", legend.key.width = unit(10, "pt"))
  cm <- CMP[method != "C1b_unit_GLMM_plotcov_synthetic"]
  cm[, lab := c("Map block mean", lv)[match(method, c("M0_map_block_mean", "R0_record_M2_crossfit_FH", "C1_unit_GLMM_EBP_mappop", "C2_spatial_FH_SAR_ring1", "C3_HB_binomial_logit_FH"))]]
  cm[, lab := factor(lab, rev(c("Map block mean", lv)))]
  pb <- ggplot(cm, aes(1e4 * lobo_emse, lab)) + geom_vline(xintercept = 1e4 * rec_l, linetype = "dashed", colour = "grey40") + geom_vline(xintercept = 1e4 * map_l, linetype = "dotted", colour = "grey40") +
    geom_point(size = 2) + labs(x = "LOBO error, estimated MSE of held out synthetic (x 1e-4)", y = NULL, tag = "b") + theme_classic(base_size = 9)
  pc <- ggplot(cm[!is.na(rmse_median_pct)], aes(statewide_pct, lab)) + annotate("rect", xmin = 13.40, xmax = 15.91, ymin = -Inf, ymax = Inf, fill = "grey90") +
    geom_vline(xintercept = 14.66, colour = "grey40") + geom_point(size = 2) + labs(x = "Statewide (%), shaded: design based 95% CI", y = NULL, tag = "c") + theme_classic(base_size = 9)
  p <- pa / (pb | pc) + plot_layout(heights = c(1.6, 1))
  ragg::agg_png(file.path(OUT, "fig_sae_refine_blocks.png"), width = 7.5, height = 6.5, units = "in", res = 300); print(p); dev.off()
  ggsave(file.path(OUT, "fig_sae_refine_blocks.pdf"), p, width = 7.5, height = 6.5)
  TRUE
}, "figure")
say("REFINE_DONE")
