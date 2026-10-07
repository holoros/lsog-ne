#!/usr/bin/env Rscript
# f4_recalibrate.R  firebreather. Prior shift recalibration of the FIA + OCC ordinal layers to FIA prevalence.
# The OCC rows oversample the upper classes, so each cumulative probability P(y >= k) is moved from the training
# prevalence to the FIA prevalence on the odds scale (Saerens et al. 2002), then the ordering is re-imposed.
# Training prevalences are fixed counts from s2 (3,530 pooled rows). Targets:
#   k = 1 (transitioning or above): FIA design based 14.66 percent (manuscript Section 4.4) [ASSUMPTION: the
#         lsog_class >= transitioning label is equivalent to the trans_cut4 label behind that estimate]
#   k = 2 (LS or OG): FIA sample rate 50 / 3,062; k = 3 (OG): 10 / 3,062 (Maine FIA is close to equal probability)
# Gate G6, external and not used to set the constants: the recalibrated statewide mean P(>= transitioning)
# must fall inside the FIA design based interval [13.40, 15.91]. Fails exit nonzero and write nothing final.
suppressPackageStartupMessages({library(terra); library(jsonlite)})
lg <- file("output/f4_log.txt", "w"); L <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, lg); flush(lg) }
n_tr <- 3530; pos_tr <- c(597, 151, 34)             # pooled training rows with y >= 1, 2, 3 (s2 log)
pi_s <- pos_tr / n_tr
pi_t <- c(0.1466, 50 / 3062, 10 / 3062)
lor <- log(pi_t / (1 - pi_t)) - log(pi_s / (1 - pi_s))
K <- data.frame(k = 1:3, pi_train = pi_s, pi_target = pi_t, log_odds_shift = lor)
L(paste(capture.output(print(K, digits = 4)), collapse = "\n"))
write_json(list(k = 1:3, log_odds_shift = lor, pi_train = pi_s, pi_target = pi_t), "output/recalibration_constants_DATA.json", digits = 10)

r <- rast("output/occ-ordinal-lsog_30m_ME_DATA_2026-10-06.tif"); NAflag(r) <- 65535
p <- r[[1:3]] / 10000
shift <- function(x, d) { x <- clamp(x, 1e-6, 1 - 1e-6); o <- log(x / (1 - x)) + d; 1 / (1 + exp(-o)) }
q1 <- shift(p[[1]], lor[1]); q2 <- min(shift(p[[2]], lor[2]), q1); q3 <- min(shift(p[[3]], lor[3]), q2)
q <- c(q1, q2, q3); names(q) <- c("ge1", "ge2", "og")
g0 <- global(p, "mean", na.rm = TRUE)[, 1]; g <- global(q, "mean", na.rm = TRUE)[, 1]
n_for <- global(!is.na(q1), "sum")[1, 1]; ha <- n_for * 900 / 1.033 / 1e4
L(sprintf("statewide mean before / after: >=trans %.2f%% / %.2f%%; >=LS %.2f%% / %.2f%%; OG %.3f%% / %.3f%%",
          100 * g0[1], 100 * g[1], 100 * g0[2], 100 * g[2], 100 * g0[3], 100 * g[3]))
L(sprintf("expected area after recalibration (forest %.0f ha): >=trans %.0f ha; >=LS %.0f ha; OG %.0f ha", ha, g[1] * ha, g[2] * ha, g[3] * ha))
ci <- function(x, n) 100 * binom.test(x, n)$conf.int
L(sprintf("FIA references: >=trans 14.66 [13.40, 15.91]; LS or OG sample rate %.2f [%.2f, %.2f]; OG %.2f [%.2f, %.2f]",
          100 * 50 / 3062, ci(50, 3062)[1], ci(50, 3062)[2], 100 * 10 / 3062, ci(10, 3062)[1], ci(10, 3062)[2]))
if (100 * g[1] < 13.40 || 100 * g[1] > 15.91) { L("G6 FAIL: recalibrated mean outside the FIA interval"); quit(status = 2) }
L("G6 PASS")
writeRaster(round(q * 10000), "output/occ-ordinal-lsog-recalibrated_30m_ME_DATA_2026-10-06.tif", datatype = "INT2U", NAflag = 65535,
            names = c("P_ge_trans_x1e4", "P_ge_LS_type2_x1e4", "P_OG_type1_x1e4"), overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
write.csv(data.frame(layer = c("P_ge_trans", "P_ge_LS_type2", "P_OG_type1"), mean_pct_raw = 100 * g0, mean_pct_recal = 100 * g,
                     expected_ha_recal = round(g * ha)), "output/occ_ordinal_recalibrated_shares_DATA.csv", row.names = FALSE)
L("done")
