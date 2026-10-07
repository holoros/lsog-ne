#!/usr/bin/env Rscript
# f1_multimap_figure.R  Multi map comparison at the OCC field points, drawn from aggregate tables only.
# Inputs: occ_multimap_auc_DATA_cardinal.csv (AUC, site cluster bootstrap CI), occ_cut_capture_DATA.csv.
# Run on firebreather. Headless; 180 x 90 mm at 300 dpi.
suppressPackageStartupMessages({library(data.table); library(ggplot2)})
dir.create("output", showWarnings = FALSE)
A <- fread("occ_multimap_auc_DATA_cardinal.csv")
C <- fread("occ_cut_capture_DATA.csv")
lev_m <- c("30 m tolerance score (Sep 4)", "10 m CORE4 (Sep 16)", "10 m transitioning (Sep 23, Zenodo)", "New ordinal, out of fold")
short <- c("30 m tolerance score", "10 m CORE4", "10 m transitioning", "New ordinal (OOF)")
lev_c <- c("Trans+ vs Not", "Type 2 pool (LS+OG) vs rest", "Type 1 (OG) vs rest", "Type 1 (OG) vs LS")
A[, map := factor(map, rev(lev_m), labels = rev(short))]
A[, contrast := factor(contrast, lev_c, labels = sprintf("%s (positives = %d)", lev_c, A[match(lev_c, contrast), n_pos]))]
pal <- c("#9a9a9a", "#6a8fb3", "#2f5d8a", "#c0592b"); names(pal) <- short
th <- theme_classic(base_size = 8) + theme(legend.position = "bottom", strip.background = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0), panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3))
pa <- ggplot(A, aes(auc, map, colour = map)) + geom_vline(xintercept = 0.5, linetype = 3, linewidth = 0.3) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = 0.25, linewidth = 0.4) + geom_point(size = 1.6) +
  facet_wrap(~contrast, ncol = 1) + scale_colour_manual(values = pal, guide = "none") +
  scale_x_continuous("AUC at OCC field points (95% site bootstrap CI)", limits = c(0.15, 1), breaks = seq(0.2, 1, 0.2)) +
  labs(y = NULL, title = "a") + th + theme(plot.title = element_text(face = "bold"))
Cl <- melt(C, id.vars = c("map", "cut"), variable.name = "occ_class", value.name = "share")
Cl[, occ_class := factor(occ_class, c("Not LS", "Trans LS", "LS", "Old-growth"))]
Cl[, lab := sprintf("%s, p > %.3f", fifelse(map == "m10_core4", "10 m CORE4", "10 m transitioning"), cut)]
Cl[, mapl := fifelse(map == "m10_core4", "10 m CORE4", "10 m transitioning")]; Cl[, cutl := sprintf("p > %.3f", cut)]
pb <- ggplot(Cl, aes(occ_class, 100 * share, fill = mapl, alpha = cutl, group = lab)) + geom_col(position = position_dodge(0.85), width = 0.8) +
  scale_fill_manual(NULL, values = c("10 m CORE4" = "#6a8fb3", "10 m transitioning" = "#2f5d8a")) +
  scale_alpha_manual(NULL, values = c(0.35, 1)) +
  scale_y_continuous("OCC points above the cut (%)", limits = c(0, 100), expand = c(0, 0)) +
  labs(x = "OCC field class", title = "b") + th + theme(plot.title = element_text(face = "bold")) +
  guides(fill = guide_legend(ncol = 1), alpha = guide_legend(ncol = 1))
ggsave("output/fig_occ_multimap_comparison.png",
       gridExtra::arrangeGrob(pa, pb, ncol = 2, widths = c(1.25, 1)), width = 180, height = 120, units = "mm", dpi = 300)
cat("done\n")
