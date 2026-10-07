#!/usr/bin/env Rscript
# f6_v4_figs.R  firebreather. Figures for the rebuilt FIA + OCC (Hagan) map, v4 run (10 m, aggregated to 30 m by
# averaging on Cardinal; recalibrated to FIA prevalence and gated there). Inputs are surfaces and aggregates only.
#   fig_v4_state.png         a P(>= transitioning), b Type 2 P(LS or OG), c composition class, d Type 2 screen
#   fig_v1_vs_v4_type2.png   Type 2 from the 6 October pooled model (v1, recalibrated) against v4, and the difference
suppressPackageStartupMessages({library(terra); library(jsonlite)})
dir.create("output", showWarnings = FALSE)
meta <- fromJSON("v4_meta.json"); cut <- meta$type2_cut
r <- rast("occ-ordinal-v4-lsog-recalibrated_30m-from10m_ME_DATA_2026-10-06.tif"); NAflag(r) <- 65535; r <- r / 1e4
names(r) <- c("ge1", "ge2", "og", "sw")
a <- aggregate(r, 5, mean, na.rm = TRUE)
comp <- classify(a$sw, rbind(c(-Inf, 0.35, 0), c(0.35, 0.65, 1), c(0.65, Inf, 2)))
bnd <- as.polygons(!is.na(aggregate(r$ge1, 20, mean, na.rm = TRUE)))
pal <- hcl.colors(50, "YlGnBu", rev = TRUE); q <- function(x) as.numeric(quantile(values(x), 0.995, na.rm = TRUE))
# the screen is applied to the raw (pre recalibration) Type 2 probability in s9; recalibration is monotone, so map the cut
lor2 <- log(50 / 3062 / (1 - 50 / 3062)) - log(meta$pos[2] / meta$n / (1 - meta$pos[2] / meta$n))
cut_rec <- 1 / (1 + exp(-(log(cut / (1 - cut)) + lor2)))
scr <- a$ge2 >= cut_rec
png("output/fig_v4_state.png", width = 180, height = 190, units = "mm", res = 300)
par(mfrow = c(2, 2), mar = c(0.5, 0.5, 2.4, 4.5), cex = 0.7)
plot(a$ge1, col = pal, range = c(0, q(a$ge1)), axes = FALSE, box = FALSE, main = "a  P(transitioning or above)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(a$ge2, col = pal, range = c(0, q(a$ge2)), axes = FALSE, box = FALSE, main = "b  Type 2, P(LS or OG)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(comp, col = c("#c9a66b", "#9bb58f", "#2f5d4a"), type = "classes", levels = c("Hardwood", "Mixedwood", "Softwood"),
     axes = FALSE, box = FALSE, main = "c  Composition (softwood share of BA)", plg = list(x = "bottomright", cex = 0.85)); lines(bnd, lwd = 0.3, col = "grey40")
plot(scr, col = c("#e6e2d3", "#2e7d4f"), type = "classes", levels = c("Other forest", "Type 2 screen"),
     axes = FALSE, box = FALSE, main = "d  Type 2 screen (OCC Youden cut)", plg = list(x = "bottomright", cex = 0.85)); lines(bnd, lwd = 0.3, col = "grey40")
dev.off()
v1 <- rast("output/occ-ordinal-lsog-recalibrated_30m_ME_DATA_2026-10-06.tif"); NAflag(v1) <- 65535; v1 <- v1[[2]] / 1e4
v1 <- resample(v1, r$ge2, "near"); a1 <- aggregate(v1, 5, mean, na.rm = TRUE); d <- a$ge2 - a1
v <- na.omit(cbind(values(a1), values(a$ge2)))
cat(sprintf("Type 2 v1 vs v4 (150 m): mean %.4f vs %.4f, Spearman %.3f\n", mean(v[, 1]), mean(v[, 2]), cor(v[, 1], v[, 2], method = "spearman")))
cat(sprintf("composition area shares (150 m display cells): HW %.3f, MX %.3f, SW %.3f\n", mean(values(comp) == 0, na.rm = TRUE), mean(values(comp) == 1, na.rm = TRUE), mean(values(comp) == 2, na.rm = TRUE)))
cat(sprintf("Type 2 screen share of forest: %.3f (cut %.4f raw, %.4f recalibrated)\n", global(scr, "mean", na.rm = TRUE)[1, 1], cut, cut_rec))
dl <- as.numeric(max(abs(quantile(values(d), c(0.005, 0.995), na.rm = TRUE)))); zm <- max(q(a1), q(a$ge2))
png("output/fig_v1_vs_v4_type2.png", width = 180, height = 85, units = "mm", res = 300)
par(mfrow = c(1, 3), mar = c(0.5, 0.5, 2.4, 4.2), cex = 0.62)
plot(a1, col = pal, range = c(0, zm), axes = FALSE, box = FALSE, main = "a  Type 2, 6 Oct pooled (AE only)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(a$ge2, col = pal, range = c(0, zm), axes = FALSE, box = FALSE, main = "b  Type 2, rebuilt (AE + 10 m CHM)"); lines(bnd, lwd = 0.3, col = "grey40")
plot(clamp(d, -dl, dl), col = hcl.colors(51, "Blue-Red 3"), range = c(-dl, dl), axes = FALSE, box = FALSE, main = "c  Rebuilt minus 6 Oct"); lines(bnd, lwd = 0.3, col = "grey40")
dev.off()
cat("done\n")
