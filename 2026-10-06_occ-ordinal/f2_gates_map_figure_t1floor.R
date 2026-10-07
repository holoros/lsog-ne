#!/usr/bin/env Rscript
# f2_gates_map_figure.R  firebreather. Gates, Type 1 / Type 2 screening layer, and map figures for the
# OCC + FIA ordinal surface. Inputs are model surfaces and aggregates only (no coordinates, no per point data).
# Gates are hard exits: nothing is renamed from _PROVISIONAL unless all pass.
suppressPackageStartupMessages({library(terra); library(data.table); library(jsonlite)})
dir.create("output", showWarnings = FALSE); set.seed(20261006)
lg <- file("output/f2_log.txt", "w"); L <- function(...) { m <- paste0(...); cat(m, "\n"); writeLines(m, lg); flush(lg) }
fail <- character()
TH <- fromJSON("screening_thresholds_DATA.json"); L("thresholds: ", toJSON(TH, auto_unbox = TRUE, digits = 4))
cov <- fread("coverage_state30_DATA.csv"); sh <- sum(cov$predicted) / sum(cov$forest_cells)
L(sprintf("G1 coverage of M3 frame forest, state 30 m: %.4f (threshold 0.98)", sh)); if (sh < 0.98) fail <- c(fail, "G1")
r <- rast("occ-ordinal-lsog_30m_state30_ME_DATA_2026-10-06_PROVISIONAL.tif"); names(r) <- c("ge1", "ge2", "og", "env")
NAflag(r) <- 65535
p <- r[[1:3]] / 10000
g <- global(p, c("min", "max", "mean"), na.rm = TRUE); print(g)
if (any(g$max > 1) || any(g$min < 0)) fail <- c(fail, "G3 range")
mono <- global((p$og > p$ge2 + 1e-6) | (p$ge2 > p$ge1 + 1e-6), "sum", na.rm = TRUE)[1, 1]
L("G3b ordinal monotonicity violations: ", mono); if (mono > 0) fail <- c(fail, "G3b")
m1 <- 100 * g["ge1", "mean"]
# G5 absurdity bound. External reference: FIA design based transitioning and above, 14.66 [13.40, 15.91] (manuscript 4.4).
# The OCC sample over represents the upper classes, so an upward shift is expected; outside 5 to 40 percent is absurd.
L(sprintf("G5 statewide mean P(>= transitioning) = %.2f%% vs FIA 14.66 [13.40, 15.91]", m1)); if (m1 < 5 || m1 > 40) fail <- c(fail, "G5")
n_for <- global(!is.na(p$ge1), "sum")[1, 1]; ha_for <- n_for * 900 / 1.033 / 1e4   # EPSG:3979 overstatement, Methods 3.12
L(sprintf("forest predicted: %.0f ha (M3 frame reference 7,410,000 ha)", ha_for))
if (abs(ha_for / 7.41e6 - 1) > 0.05) fail <- c(fail, "G2 frame area")
# A Type 1 class is drawn only if the OG vs LS cut has usable specificity (pre-registered floor 0.5).
t1ok <- TH$type1_spec_vs_LS >= 0.5
L(sprintf("Type 1 class %s: OG vs LS cut %.4f has specificity %.3f", ifelse(t1ok, "drawn", "NOT drawn"), TH$type1_cut_within_type2, TH$type1_spec_vs_LS))
cls <- ifel(is.na(p$ge1), NA, ifel(p$ge2 >= TH$type2_cut, if (t1ok) ifel(p$og >= TH$type1_cut_within_type2, 2, 1) else 1, 0))
fr <- freq(cls); fr$share <- fr$count / sum(fr$count)
L("screening class shares of forest (0 other, 1 Type 2, 2 Type 1): ", paste(sprintf("%d: %.3f%%", fr$value, 100 * fr$share), collapse = "; "))
ea <- 100 * g[, "mean"]; L(sprintf("expected shares (mean probability): >=trans %.2f%%, >=LS %.2f%%, OG %.3f%%", ea[1], ea[2], ea[3]))
fwrite(data.table(layer = c("P_ge_trans", "P_ge_LS_type2", "P_OG_type1"), mean_pct = ea,
                  screening_pct = c(NA, 100 * sum(fr$share[fr$value >= 1]), if (t1ok) 100 * sum(fr$share[fr$value == 2]) else NA)),
       "output/occ_ordinal_state_shares_DATA.csv")
if (length(fail)) { L("GATES FAILED: ", paste(fail, collapse = ", ")); quit(status = 2) }
writeRaster(c(round(p * 10000), cls), "output/occ-ordinal-lsog_30m_ME_DATA_2026-10-06.tif", datatype = "INT2U", NAflag = 65535,
            names = c("P_ge_trans_x1e4", "P_ge_LS_type2_x1e4", "P_OG_type1_x1e4", "screen_class"), overwrite = TRUE,
            gdal = c("COMPRESS=DEFLATE", "TILED=YES"))
L("all gates pass; product written")

# Figure 1, statewide (display aggregated to 150 m)
pd <- aggregate(p, 5, mean, na.rm = TRUE); cd <- aggregate(cls, 5, "modal", na.rm = TRUE)
bnd <- as.polygons(!is.na(aggregate(p$ge1, 20, mean, na.rm = TRUE)))
pal <- hcl.colors(50, "YlGnBu", rev = TRUE)
png("output/fig_occ_ordinal_state30.png", width = 180, height = 72, units = "mm", res = 300)
par(mfrow = c(1, 4), mar = c(0.4, 0.4, 2.2, 3.2), cex = 0.6)
ttl <- c("a  P(transitioning or above)", "b  P(LS or OG), Type 2 pool", "c  P(OG), Type 1")
zmax <- c(1, 1, max(0.05, global(pd$og, quantile, probs = 0.999, na.rm = TRUE)[1, 1]))
for (k in 1:3) { plot(pd[[k]], col = pal, range = c(0, zmax[k]), axes = FALSE, box = FALSE, main = ttl[k], plg = list(cex = 0.8))
                 lines(bnd, lwd = 0.3, col = "grey40") }
if (t1ok) plot(cd, col = c("#e6e2d3", "#6aa36f", "#1f4e2c"), type = "classes", levels = c("Other forest", "Type 2 (LS)", "Type 1 (OG)"),
     axes = FALSE, box = FALSE, main = "d  Screening classes", plg = list(cex = 0.8)) else
  plot(cd, col = c("#e6e2d3", "#6aa36f"), type = "classes", levels = c("Other forest", sprintf("Type 2 pool, p >= %.3f", TH$type2_cut)),
     axes = FALSE, box = FALSE, main = "d  Type 2 screen (no Type 1 class)", plg = list(cex = 0.8)); lines(bnd, lwd = 0.3, col = "grey40")
dev.off()

# Figure 2, 10 m study tile shown at 20 m
s <- rast("occ-ordinal-lsog_20m_study-display_DATA_2026-10-06.tif"); NAflag(s) <- 65535; s <- s[[1:3]] / 10000
png("output/fig_occ_ordinal_study10.png", width = 180, height = 85, units = "mm", res = 300)
par(mfrow = c(1, 2), mar = c(0.4, 0.4, 2.2, 3.2), cex = 0.6)
plot(s[[2]], col = pal, range = c(0, 1), axes = FALSE, box = FALSE, main = "a  P(LS or OG), Type 2 pool")
plot(s[[3]], col = pal, range = c(0, zmax[3]), axes = FALSE, box = FALSE, main = "b  P(OG), Type 1")
dev.off()
L("done")
