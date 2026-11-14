#!/usr/bin/env Rscript
# d13_figure.R (November 13, 2026). Six-panel figure for the definition-to-map sensitivity analysis.
# Inputs are aggregates only: out/d12_{me,nb}_blocks_DATA.csv (20 km blocks), out/d5_me_aggregate_DATA.json,
# out/d9_nb_aggregate_DATA.json, and the two jurisdiction outlines. Design-based rates and intervals are those of
# Appendix S1 Table S3 (reproduced by d2 and d6). Output: 180 x 225 mm, 300 dpi PNG and a PDF.
suppressPackageStartupMessages({library(ggplot2); library(sf); library(patchwork); library(jsonlite); library(data.table)})
W <- path.expand("~/LSOG/2026-11-13_definition-map-sensitivity"); BS <- 20000
J <- list(
  me = list(name = "Maine", js = "d5_me_aggregate_DATA.json", crs = 32619,
            cut = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson",
            defs = c("V3", "V1", "V2", "V4", "V9_c3", "V7"),
            lab = c("Fixed deadwood", "Base card", "Height dropped", "Maximum diameter", "CORE4, cut 3", "Base card, cut 6"),
            lo = c(21.20, 14.61, 11.28, 8.45, 4.32, 1.72), hi = c(24.18, 17.23, 13.65, 10.54, 5.89, 2.80)),
  nb = list(name = "New Brunswick", js = "d9_nb_aggregate_DATA.json", crs = 32620,
            cut = "/fs/scratch/PUOM0008/crsfaaron/canada_landcover/nb_boundary_3979.geojson",
            defs = c("W2", "W1", "W4", "X9_c3", "X9", "W6"),
            lab = c("Height added", "Base card", "Quantile deadwood", "CORE4, cut 3", "CORE4, cut 4", "Base card, cut 6"),
            lo = c(36.89, 29.17, 8.51, 7.71, 4.87, 3.57), hi = c(41.82, 33.31, 10.88, 11.03, 7.48, 5.55)))
pal <- c("#0072B2", "#D55E00", "#009E73", "#CC79A7", "#E69F00", "#56B4E9")   # Okabe-Ito, colour-blind safe
theme_crsf_pub <- function(base = 8) theme_bw(base_size = base) + theme(panel.grid = element_blank(), panel.border = element_rect(colour = "grey20", fill = NA, linewidth = 0.4),
  plot.title = element_text(size = base + 1, face = "bold"), plot.tag = element_text(size = base + 1, face = "bold"), legend.key.height = unit(3, "mm"), legend.key.width = unit(9, "mm"),
  legend.title = element_text(size = base - 0.5), axis.text = element_text(colour = "grey15"), strip.background = element_blank())
panels <- list()
for (j in names(J)) {
  cfg <- J[[j]]; R <- fromJSON(file.path(W, "out", cfg$js)); B <- fread(file.path(W, "out", sprintf("d12_%s_blocks_DATA.csv", j)))
  stopifnot(identical(R$defs, cfg$defs)); B <- B[n >= 10000]; B[, ge3 := 100 * (c3 + c4 + c5 + c6) / n]
  sq <- function(bx, by) st_polygon(list(matrix(c(bx, by, bx + 1, by, bx + 1, by + 1, bx, by + 1, bx, by) * BS, ncol = 2, byrow = TRUE)))
  blk <- st_sf(ge3 = B$ge3, geometry = st_sfc(Map(sq, B$bx, B$by), crs = 3979)); out <- st_transform(st_union(st_make_valid(st_read(cfg$cut, quiet = TRUE))), 3979)
  blk <- suppressWarnings(st_intersection(blk, out))
  pm <- ggplot() + geom_sf(data = blk, aes(fill = ge3), colour = "white", linewidth = 0.1) + geom_sf(data = out, fill = NA, colour = "grey20", linewidth = 0.3) +
    coord_sf(crs = cfg$crs, datum = NA) + scale_fill_viridis_c(option = "viridis", direction = -1, limits = c(0, 60), oob = scales::squish, breaks = c(0, 20, 40, 60), labels = c("0", "20", "40", "60+"),
      name = "Forest flagged under at least\nthree of six definitions (%)") + labs(title = cfg$name) + theme_crsf_pub() + theme(legend.position = "bottom", legend.title.position = "left")
  E <- data.table(k = 1:6, def = cfg$defs, design = unlist(R$design_pct[cfg$defs]), lo = cfg$lo, hi = cfg$hi,
                  mapped = sapply(cfg$defs, function(v) R$mapped_mean_prob_pct[[v]]$est), mlo = sapply(cfg$defs, function(v) R$mapped_mean_prob_pct[[v]]$ci[1]), mhi = sapply(cfg$defs, function(v) R$mapped_mean_prob_pct[[v]]$ci[2]))
  E[, `:=`(hj = ifelse(k %% 2 == 1, 1.9, -0.9), vj = ifelse(k %% 2 == 1, -0.7, 1.6), col = factor(k))]
  sl <- R$extent_tracking; lim <- c(0, ceiling(max(E$hi, E$mhi) / 5) * 5 + 1)
  pe <- ggplot(E, aes(design, mapped, colour = col)) + geom_abline(slope = 1, intercept = 0, linetype = "22", colour = "grey45", linewidth = 0.35) +
    geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0, linewidth = 0.45) + geom_errorbar(aes(ymin = mlo, ymax = mhi), width = 0, linewidth = 0.45) + geom_point(size = 1.8) +
    geom_text(aes(label = k, hjust = hj, vjust = vj), size = 2.6, fontface = "bold", show.legend = FALSE) +
    annotate("text", x = lim[1] + 0.03 * diff(lim), y = lim[2] - 0.04 * diff(lim), hjust = 0, vjust = 1, size = 2.5, colour = "grey15",
             label = sprintf("Slope %.2f (%.2f to %.2f)", sl$slope_mapped_on_design, sl$ci[1], sl$ci[2])) +
    scale_colour_manual(values = pal, guide = "none") + coord_equal(xlim = lim, ylim = lim, expand = FALSE) +
    labs(x = "Design-based extent (% of forest)", y = "Mapped extent (mean probability, %)") + theme_crsf_pub()
  M <- CJ(a = 1:6, b = 1:6)[a != b]
  M[, val := mapply(function(a, b) { key <- paste(cfg$defs[min(a, b)], cfg$defs[max(a, b)], sep = "|"); if (a < b) R$jaccard[[key]] else R$overlap_of_smaller[[key]] }, a, b)]
  ax <- paste(1:6, cfg$lab)
  po <- ggplot(M, aes(factor(b), factor(a, levels = 6:1), fill = val)) + geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%.2f", val), colour = val > 0.55), size = 2.4, show.legend = FALSE) + scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "grey10")) +
    scale_fill_viridis_c(option = "mako", direction = -1, limits = c(0, 1), name = "Overlap of flagged cells") + scale_x_discrete(labels = 1:6, position = "top") + scale_y_discrete(labels = rev(ax)) +
    coord_equal(expand = FALSE) + labs(x = NULL, y = NULL) + theme_crsf_pub() + theme(legend.position = "bottom", legend.title.position = "left", axis.ticks = element_blank(),
      axis.text.y = element_text(colour = rev(pal), face = "bold"), axis.text.x = element_text(colour = pal, face = "bold"))
  panels[[j]] <- list(pm, pe, po)
}
# Tags are set by hand and the matrix row is wrapped, so its long axis labels do not push the rows above to the right.
tg <- function(p, t) p + labs(tag = t)
lg <- theme(legend.position = "bottom", legend.title = element_text(size = 7, margin = margin(r = 14)))
top <- (tg(panels$me[[1]], "(a)") | tg(panels$nb[[1]], "(b)")) + plot_layout(guides = "collect") & lg
mid <- tg(panels$me[[2]], "(c)") | tg(panels$nb[[2]], "(d)")
bot <- (tg(panels$me[[3]], "(e)") | tg(panels$nb[[3]], "(f)")) + plot_layout(guides = "collect") & lg
fig <- wrap_elements(full = top) / wrap_elements(full = mid) / wrap_elements(full = bot) + plot_layout(heights = c(1.3, 1, 1.05))
ggsave(file.path(W, "out", "2026-11-13_menb-definition-map-sensitivity_fig_REVIEW.png"), fig, width = 180, height = 225, units = "mm", dpi = 300, bg = "white")
ggsave(file.path(W, "out", "2026-11-13_menb-definition-map-sensitivity_fig_REVIEW.pdf"), fig, width = 180, height = 225, units = "mm", bg = "white")
cat("FIG DONE\n")
