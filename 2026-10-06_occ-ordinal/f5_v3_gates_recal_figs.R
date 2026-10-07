#!/usr/bin/env Rscript
# f5_v3_gates_recal_figs.R  firebreather. v3 rebuild (AE + structure + aspen/poplar, introduced larch and planted
# hard negatives): gates, prior shift recalibration to FIA prevalence (as f4), and figures comparing v1 and v3.
# Inputs are surfaces and aggregates only. Gates are hard exits; nothing is renamed from _PROVISIONAL on failure.
suppressPackageStartupMessages({library(terra); library(jsonlite); library(data.table)})
dir.create("output", showWarnings = FALSE)
lg <- file("output/f5_log.txt", "w"); L <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, lg); flush(lg) }
fail <- character()
meta <- fromJSON("v3_meta.json"); cov <- fread("coverage_state30_v3_DATA.csv")
sh <- sum(cov$predicted) / sum(cov$forest_cells); L(sprintf("G1 coverage of M3 frame forest, v3 30 m: %.4f (threshold 0.98)", sh))
if (sh < 0.98) fail <- c(fail, "G1")
r <- rast("occ-ordinal-v3-lsog_30m_state30_ME_DATA_2026-10-06_PROVISIONAL.tif"); NAflag(r) <- 65535
p <- r[[1:3]] / 10000; names(p) <- c("ge1", "ge2", "og")
g <- global(p, c("min", "max", "mean"), na.rm = TRUE); print(g)
if (any(g$max > 1) || any(g$min < 0)) fail <- c(fail, "G3 range")
mono <- global((p$og > p$ge2 + 1e-6) | (p$ge2 > p$ge1 + 1e-6), "sum", na.rm = TRUE)[1, 1]; L("G3b monotonicity violations: ", mono)
if (mono > 0) fail <- c(fail, "G3b")
n_for <- global(!is.na(p$ge1), "sum")[1, 1]; ha <- n_for * 900 / 1.033 / 1e4
L(sprintf("forest predicted %.0f ha (M3 reference 7,410,000)", ha)); if (abs(ha / 7.41e6 - 1) > 0.05) fail <- c(fail, "G2")
# recalibration constants from the v3 training prevalence
pi_s <- meta$pos / meta$n; pi_t <- c(0.1466, 50 / 3062, 10 / 3062)
lor <- log(pi_t / (1 - pi_t)) - log(pi_s / (1 - pi_s))
L(sprintf("v3 training prevalence %s of %d; log odds shifts %s", paste(meta$pos, collapse = ", "), meta$n, paste(round(lor, 4), collapse = ", ")))
write_json(list(k = 1:3, log_odds_shift = lor, pi_train = pi_s, pi_target = pi_t), "output/recalibration_constants_v3_DATA.json", digits = 10)
shift <- function(x, d) { x <- clamp(x, 1e-6, 1 - 1e-6); 1 / (1 + exp(-(log(x / (1 - x)) + d))) }
q1 <- shift(p$ge1, lor[1]); q2 <- min(shift(p$ge2, lor[2]), q1); q3 <- min(shift(p$og, lor[3]), q2)
q <- c(q1, q2, q3); names(q) <- c("ge1", "ge2", "og"); gq <- global(q, "mean", na.rm = TRUE)[, 1]
L(sprintf("recalibrated statewide mean: >=trans %.2f%%, >=LS %.2f%%, OG %.3f%%; expected ha %.0f, %.0f, %.0f",
          100 * gq[1], 100 * gq[2], 100 * gq[3], gq[1] * ha, gq[2] * ha, gq[3] * ha))
L("FIA references: >=trans 14.66 [13.40, 15.91]; LS or OG 1.63 [1.21, 2.15]; OG 0.33 [0.16, 0.60]")
if (100 * gq[1] < 13.40 || 100 * gq[1] > 15.91) fail <- c(fail, "G6 recalibrated >=trans outside FIA interval")
if (length(fail)) { L("GATES FAILED: ", paste(fail, collapse = ", ")); quit(status = 2) }
writeRaster(round(q * 10000), "output/occ-ordinal-v3-lsog-recalibrated_30m_ME_DATA_2026-10-06.tif", datatype = "INT2U", NAflag = 65535,
            names = c("P_ge_trans_x1e4", "P_ge_LS_type2_x1e4", "P_OG_type1_x1e4"), overwrite = TRUE, gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
L("all gates pass; v3 recalibrated 30 m product written")

# v1 recalibrated for the comparison (written by f4)
v1 <- rast("output/occ-ordinal-lsog-recalibrated_30m_ME_DATA_2026-10-06.tif"); NAflag(v1) <- 65535; v1 <- v1 / 10000; names(v1) <- c("ge1", "ge2", "og")
if (!compareGeom(v1, q, stopOnError = FALSE)) v1 <- resample(v1, q, "near")
a1 <- aggregate(v1, 5, mean, na.rm = TRUE); a3 <- aggregate(q, 5, mean, na.rm = TRUE); d <- a3 - a1
for (k in c("ge1", "ge2")) { v <- na.omit(cbind(values(a1[[k]]), values(a3[[k]])))
  L(sprintf("%s v1 vs v3 (150 m cells): mean %.4f vs %.4f, Spearman %.3f", k, mean(v[, 1]), mean(v[, 2]), cor(v[, 1], v[, 2], method = "spearman"))) }
bnd <- as.polygons(!is.na(aggregate(q$ge1, 20, mean, na.rm = TRUE)))
pal <- hcl.colors(50, "YlGnBu", rev = TRUE); dpal <- hcl.colors(51, "Blue-Red 3")
qq <- function(x) as.numeric(quantile(values(x), 0.995, na.rm = TRUE))
png("output/fig_v1_vs_v3_type2.png", width = 180, height = 85, units = "mm", res = 300)
par(mfrow = c(1, 3), mar = c(0.5, 0.5, 2.4, 4.2), cex = 0.62)
zm <- max(qq(a1$ge2), qq(a3$ge2)); dl <- max(abs(quantile(values(d$ge2), c(0.005, 0.995), na.rm = TRUE)))
plot(a1$ge2, col = pal, range = c(0, zm), axes = FALSE, box = FALSE, main = "a  Type 2, v1 (AE)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(a3$ge2, col = pal, range = c(0, zm), axes = FALSE, box = FALSE, main = "b  Type 2, v3 (AE + structure)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(clamp(d$ge2, -dl, dl), col = dpal, range = c(-dl, dl), axes = FALSE, box = FALSE, main = "c  v3 minus v1"); lines(bnd, lwd = 0.3, col = "grey40")
dev.off()
png("output/fig_v3_state30.png", width = 180, height = 95, units = "mm", res = 300)
par(mfrow = c(1, 3), mar = c(0.5, 0.5, 2.4, 4.2), cex = 0.62)
ttl <- c("a  P(transitioning or above)", "b  Type 2, P(LS or OG)", "c  Type 1, P(OG)")
for (k in 1:3) { plot(a3[[k]], col = pal, range = c(0, qq(a3[[k]])), axes = FALSE, box = FALSE, main = ttl[k]); lines(bnd, lwd = 0.3, col = "grey40") }
dev.off()
L("done")
