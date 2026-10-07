#!/usr/bin/env Rscript
# f3_fia_vs_pooled.R  firebreather. Influence of the OCC (Hagan) data: FIA only versus FIA + OCC ordinal models.
# Inputs: fia_vs_pooled_auc_DATA.csv (aggregate), the two 30 m statewide surfaces. No coordinates, no per point data.
suppressPackageStartupMessages({library(terra); library(data.table); library(ggplot2)})
dir.create("output", showWarnings = FALSE)
lg <- file("output/f3b_log.txt", "w"); L <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, lg); flush(lg) }

# Figure B: maps, Type 2 and Type 1, FIA only, FIA + OCC, difference
rd <- function(f) { r <- rast(f); NAflag(r) <- 65535; r <- r[[1:3]] / 10000; names(r) <- c("ge1", "ge2", "og"); r }
pF <- rd("occ-ordinal-lsog_30m_state30-fiaonly_ME_DATA_2026-10-06_PROVISIONAL.tif")
pP <- rd("occ-ordinal-lsog_30m_state30_ME_DATA_2026-10-06_PROVISIONAL.tif")
stopifnot(compareGeom(pF, pP))
aF <- aggregate(pF, 5, mean, na.rm = TRUE); aP <- aggregate(pP, 5, mean, na.rm = TRUE); d <- aP - aF
for (k in names(aP)) { v <- na.omit(cbind(values(aF[[k]]), values(aP[[k]])))
  L(sprintf("%s (150 m display cells): mean FIA only %.4f, FIA + OCC %.4f, Spearman %.3f", k, mean(v[, 1]), mean(v[, 2]), cor(v[, 1], v[, 2], method = "spearman"))) }
bnd <- as.polygons(!is.na(aggregate(pP$ge1, 20, mean, na.rm = TRUE)))
seq_pal <- hcl.colors(50, "YlGnBu", rev = TRUE); div_pal <- hcl.colors(51, "Blue-Red 3")
png("output/fig_fia_vs_pooled_maps.png", width = 180, height = 160, units = "mm", res = 300)
par(mfrow = c(2, 3), mar = c(0.4, 0.4, 2.4, 3.6), cex = 0.62)
for (j in 1:2) {
  k <- c("ge2", "og")[j]; nm <- c("Type 2 P(LS or OG)", "Type 1 P(OG)")[j]
  zmax <- max(quantile(c(values(aF[[k]]), values(aP[[k]])), 0.995, na.rm = TRUE))
  dl <- max(abs(global(d[[k]], quantile, probs = c(0.005, 0.995), na.rm = TRUE)))
  plot(aF[[k]], col = seq_pal, range = c(0, zmax), axes = FALSE, box = FALSE, main = paste0(letters[3 * j - 2], "  ", nm, ", FIA only")); lines(bnd, lwd = 0.3, col = "grey40")
  plot(aP[[k]], col = seq_pal, range = c(0, zmax), axes = FALSE, box = FALSE, main = paste0(letters[3 * j - 1], "  ", nm, ", FIA + OCC")); lines(bnd, lwd = 0.3, col = "grey40")
  plot(clamp(d[[k]], -dl, dl), col = div_pal, range = c(-dl, dl), axes = FALSE, box = FALSE, main = paste0(letters[3 * j], "  Difference (pooled minus FIA)")); lines(bnd, lwd = 0.3, col = "grey40")
}
dev.off()
L("done")
