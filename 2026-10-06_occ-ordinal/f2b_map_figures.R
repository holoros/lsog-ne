#!/usr/bin/env Rscript
# f2b_map_figures.R  firebreather. Redraw the FIA + OCC ordinal map figures from the gated product
# (output/occ-ordinal-lsog_30m_ME_DATA_2026-10-06.tif) and the 20 m study display copy. Layout fix only;
# no values change. Colour ranges run to the 99.5th percentile so the low probability layers are legible.
suppressPackageStartupMessages({library(terra); library(jsonlite)})
TH <- fromJSON("screening_thresholds_DATA.json")
r <- rast("output/occ-ordinal-lsog_30m_ME_DATA_2026-10-06.tif"); NAflag(r) <- 65535
p <- aggregate(r[[1:3]] / 10000, 5, mean, na.rm = TRUE); cl <- aggregate(r[[4]], 5, "modal", na.rm = TRUE)
bnd <- as.polygons(!is.na(aggregate(r[[1]], 20, mean, na.rm = TRUE)))
pal <- hcl.colors(50, "YlGnBu", rev = TRUE)
q <- function(x) as.numeric(quantile(values(x), 0.995, na.rm = TRUE))
ttl <- c("a  P(transitioning or above)", "b  Type 2 pool, P(LS or OG)", "c  Type 1, P(OG)")
png("output/fig_occ_ordinal_state30.png", width = 180, height = 190, units = "mm", res = 300)
par(mfrow = c(2, 2), mar = c(0.5, 0.5, 2.4, 4.5), cex = 0.7)
for (k in 1:3) { plot(p[[k]], col = pal, range = c(0, q(p[[k]])), axes = FALSE, box = FALSE, main = ttl[k]); lines(bnd, lwd = 0.3, col = "grey40") }
plot(cl, col = c("#e6e2d3", "#2e7d4f"), type = "classes", levels = c("Other forest", sprintf("Type 2, p >= %.3f", TH$type2_cut)),
     axes = FALSE, box = FALSE, main = "d  Type 2 screen", plg = list(x = "bottomright", cex = 0.85)); lines(bnd, lwd = 0.3, col = "grey40")
dev.off()
s <- rast("occ-ordinal-lsog_20m_study-display_DATA_2026-10-06.tif"); NAflag(s) <- 65535; s <- s[[1:3]] / 10000
png("output/fig_occ_ordinal_study10.png", width = 180, height = 90, units = "mm", res = 300)
par(mfrow = c(1, 2), mar = c(0.5, 0.5, 2.4, 4.5), cex = 0.7)
plot(s[[2]], col = pal, range = c(0, q(s[[2]])), axes = FALSE, box = FALSE, main = "a  Type 2 pool, P(LS or OG), 10 m model")
plot(s[[3]], col = pal, range = c(0, q(s[[3]])), axes = FALSE, box = FALSE, main = "b  Type 1, P(OG), 10 m model")
dev.off()
cat("done\n")
