#!/usr/bin/env Rscript
# f3_fia_vs_pooled.R  firebreather. Influence of the OCC (Hagan) data: FIA only versus FIA + OCC ordinal models.
# Inputs: fia_vs_pooled_auc_DATA.csv (aggregate), the two 30 m statewide surfaces. No coordinates, no per point data.
suppressPackageStartupMessages({library(terra); library(data.table); library(ggplot2)})
dir.create("output", showWarnings = FALSE)
lg <- file("output/f3_log.txt", "w"); L <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, lg); flush(lg) }

# Figure A: AUC, paired
A <- fread("fia_vs_pooled_auc_DATA.csv")
lev_c <- c("Trans+ vs Not", "Type 2 pool (LS+OG) vs rest", "Type 1 (OG) vs rest", "Type 1 (OG) vs LS")
A[, contrast := factor(contrast, rev(lev_c))]
A[, evaluation := factor(evaluation, c("OCC field points", "FIA plots, out of fold"),
     labels = c("Scored at OCC field points", "Scored at FIA plots (out of fold)"))]
pa <- ggplot(A, aes(auc, contrast, colour = model)) + geom_vline(xintercept = 0.5, linetype = 3, linewidth = 0.3) +
  geom_errorbar(aes(xmin = lo, xmax = hi), width = 0.25, linewidth = 0.4, orientation = "y", position = position_dodge(0.55)) +
  geom_point(size = 1.6, position = position_dodge(0.55)) + facet_wrap(~evaluation, nrow = 1) +
  scale_colour_manual(NULL, values = c("FIA only" = "#2f5d8a", "FIA + OCC" = "#c0592b")) +
  scale_x_continuous("AUC (95% cluster bootstrap CI)", limits = c(0.15, 1)) + labs(y = NULL) +
  theme_classic(base_size = 8) + theme(legend.position = "bottom", strip.background = element_blank(),
  strip.text = element_text(face = "bold"), panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3))
ggsave("output/fig_fia_vs_pooled_auc.png", pa, width = 180, height = 80, units = "mm", dpi = 300)

# Figure B: maps, Type 2 and Type 1, FIA only, FIA + OCC, difference
rd <- function(f) { r <- rast(f); NAflag(r) <- 65535; r <- r[[1:3]] / 10000; names(r) <- c("ge1", "ge2", "og"); r }
pF <- rd("occ-ordinal-lsog_30m_state30-fiaonly_ME_DATA_2026-10-06_PROVISIONAL.tif")
pP <- rd("occ-ordinal-lsog_30m_state30_ME_DATA_2026-10-06_PROVISIONAL.tif")
stopifnot(compareGeom(pF, pP))
for (k in names(pP)) L(sprintf("%s mean: FIA only %.4f, FIA + OCC %.4f; cell correlation %.3f", k,
  global(pF[[k]], "mean", na.rm = TRUE)[1, 1], global(pP[[k]], "mean", na.rm = TRUE)[1, 1],
  layerCor(c(pF[[k]], pP[[k]]), "pearson", na.rm = TRUE)$pearson[1, 2]))
aF <- aggregate(pF, 5, mean, na.rm = TRUE); aP <- aggregate(pP, 5, mean, na.rm = TRUE); d <- aP - aF
bnd <- as.polygons(!is.na(aggregate(pP$ge1, 20, mean, na.rm = TRUE)))
seq_pal <- hcl.colors(50, "YlGnBu", rev = TRUE); div_pal <- hcl.colors(51, "Blue-Red 3")
png("output/fig_fia_vs_pooled_maps.png", width = 180, height = 150, units = "mm", res = 300)
par(mfrow = c(2, 3), mar = c(0.4, 0.4, 2.4, 3.6), cex = 0.62)
for (j in 1:2) {
  k <- c("ge2", "og")[j]; nm <- c("P(LS or OG), Type 2", "P(OG), Type 1")[j]
  zmax <- if (k == "og") max(0.05, global(c(aF[[k]], aP[[k]]), quantile, probs = 0.999, na.rm = TRUE)[, 1]) else 1
  dl <- max(abs(global(d[[k]], quantile, probs = c(0.005, 0.995), na.rm = TRUE)))
  plot(aF[[k]], col = seq_pal, range = c(0, zmax), axes = FALSE, box = FALSE, main = paste0(letters[3 * j - 2], "  ", nm, ", FIA only")); lines(bnd, lwd = 0.3, col = "grey40")
  plot(aP[[k]], col = seq_pal, range = c(0, zmax), axes = FALSE, box = FALSE, main = paste0(letters[3 * j - 1], "  ", nm, ", FIA + OCC")); lines(bnd, lwd = 0.3, col = "grey40")
  plot(clamp(d[[k]], -dl, dl), col = div_pal, range = c(-dl, dl), axes = FALSE, box = FALSE, main = paste0(letters[3 * j], "  Difference (FIA + OCC minus FIA only)")); lines(bnd, lwd = 0.3, col = "grey40")
}
dev.off()
L("done")
