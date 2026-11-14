# Figure 3 rebuild (November 14, 2026) from Appendix S1 Table S3 (rates and intervals) and the three ratios of main-text
# Results. The earlier script was not found; values are typed from the manuscript tables. Changes: typeface matched to
# Figures 1, 2, 4 and 5; lower-panel label "Height axis removed from Maine's card" (the New Brunswick card has none);
# the in-figure note "every interval lies well above 1" removed. 180 x 165 mm, 300 dpi.
suppressPackageStartupMessages({library(ggplot2); library(patchwork)})
O <- "/users/PUOM0008/crsfaaron/LSOG/2026-11-14_fig123-rerender/out"
cls <- c(C = "Comparable axes only", D = "Deadwood only", H = "Height and deadwood")
pal <- c("Comparable axes only" = "#2166AC", "Deadwood only" = "#EF8A62", "Height and deadwood" = "#B2182B")
me <- data.frame(lab = c("Deadwood on fixed thresholds", "Published six-axis", "CORE4 comparable axes, cut 3", "Height axis dropped", "No height, fixed deadwood, max-dia maturity",
  "Maturity as max diameter", "Published six-axis, cut 5", "CORE4 max-dia maturity, cut 3", "CORE4 comparable axes, cut 4", "CORE4 max-dia maturity, cut 4", "Published six-axis, cut 6", "CORE4 comparable axes, cut 5"),
  est = c(22.69, 15.92, 14.46, 12.46, 11.99, 9.50, 6.94, 5.10, 4.14, 2.33, 2.26, 1.30), lo = c(21.20, 14.61, 13.21, 11.28, 10.83, 8.45, 6.03, 4.32, 3.42, 1.79, 1.72, 0.89),
  hi = c(24.18, 17.23, 15.72, 13.65, 13.16, 10.54, 7.86, 5.89, 4.85, 2.87, 2.80, 1.72), k = c("H", "H", "C", "D", "D", "H", "H", "C", "C", "C", "H", "C"), pub = c(F, T, F, F, F, F, F, F, F, F, F, F))
nb <- data.frame(lab = c("Height axis added", "CORE4 comparable axes, cut 2", "CORE4 max-dia maturity, cut 2", "Published five-axis", "Maturity as max diameter", "Deadwood on quantile thresholds",
  "CORE4 comparable axes, cut 3", "CORE4 max-dia maturity, cut 3", "Published five-axis, cut 5", "CORE4 max-dia maturity, cut 4", "CORE4 comparable axes, cut 4", "Published five-axis, cut 6",
  "CORE4 comparable axes, cut 5", "CORE4 comparable axes, cut 6", "CORE4 comparable axes, cut 7"),
  est = c(39.39, 33.92, 33.70, 31.47, 31.38, 9.75, 9.67, 9.37, 8.56, 6.12, 5.18, 4.49, 3.06, 1.29, 0.36), lo = c(36.89, 31.58, 31.28, 29.17, 29.08, 8.51, 7.97, 7.71, 6.97, 4.87, 4.15, 3.57, 2.16, 0.85, 0.17),
  hi = c(41.82, 35.75, 35.54, 33.31, 33.14, 10.88, 11.30, 11.03, 10.06, 7.48, 6.41, 5.55, 4.03, 1.75, 0.75), k = c("H", "C", "C", "D", "D", "D", "C", "C", "D", "C", "C", "D", "C", "C", "C"), pub = c(F, F, F, T, F, F, F, F, F, F, F, F, F, F, F))
th <- theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(), panel.grid.major.x = element_line(colour = "grey90", linewidth = 0.3),
  axis.text = element_text(colour = "grey10", size = 8), plot.title = element_text(face = "bold", size = 10), legend.position = "bottom", legend.title = element_blank(), legend.text = element_text(size = 8.5))
pan <- function(d, ttl) { d$lab <- factor(d$lab, levels = rev(d$lab)); d$cls <- factor(cls[d$k], levels = cls)
  ggplot(d, aes(est, lab, colour = cls)) + geom_vline(xintercept = d$est[d$pub], linetype = "dashed", colour = "grey35", linewidth = 0.4) +
    geom_linerange(aes(xmin = lo, xmax = hi), linewidth = 0.7, show.legend = FALSE) + geom_point(size = 2.2) +
    geom_point(data = d[d$pub, ], size = 2.4, shape = 21, fill = "white", stroke = 0.9, show.legend = FALSE) +
    scale_colour_manual(values = pal, drop = FALSE) + scale_x_continuous(limits = c(0, 43), breaks = seq(0, 40, 10), expand = c(0.01, 0)) +
    labs(title = ttl, x = "Rate (% of forest)", y = NULL) + th + theme(axis.text.y = element_text(size = 7.5)) }
r <- data.frame(lab = factor(c("Each jurisdiction's\npublished instrument", "Height axis removed\nfrom Maine's card", "CORE4, only axes\ncomparable across the border"),
  levels = c("Each jurisdiction's\npublished instrument", "Height axis removed\nfrom Maine's card", "CORE4, only axes\ncomparable across the border")),
  est = c(1.98, 2.53, 1.84), lo = c(1.78, 2.25, 1.45), hi = c(2.20, 2.84, 2.32), cls = factor(c("Deadwood only", "Deadwood only", "Comparable axes only"), levels = cls))
r$txt <- sprintf("%.2f [%.2f, %.2f]", r$est, r$lo, r$hi)
pr <- ggplot(r, aes(lab, est)) + geom_hline(yintercept = 1, linetype = "dashed", colour = "grey35", linewidth = 0.4) + geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.08, linewidth = 0.8, colour = "#2166AC") +
  geom_point(size = 3, colour = "#2166AC") + geom_text(aes(y = hi, label = txt), vjust = -0.9, size = 2.9, colour = "grey10") +
  scale_y_continuous(limits = c(0, 3.5), breaks = seq(0, 3.5, 0.5), expand = c(0, 0)) + labs(title = "Ratio of the New Brunswick rate to the Maine rate", x = NULL, y = "Ratio of estimates") + th + theme(panel.grid.major.y = element_line(colour = "grey90", linewidth = 0.3), panel.grid.major.x = element_blank(), axis.text.x = element_text(size = 8.5))
top <- (pan(me, "Maine") | pan(nb, "New Brunswick")) + plot_layout(guides = "collect") & theme(legend.position = "bottom", plot.margin = margin(4, 16, 2, 4), legend.box.margin = margin(0, 60, 0, 0))
fig <- wrap_elements(full = top) / wrap_elements(full = pr) + plot_layout(heights = c(2.2, 1))
ggsave(file.path(O, "2026-11-14_fig3-instrument-sensitivity_REVIEW.png"), fig, width = 180, height = 165, units = "mm", dpi = 300, device = ragg::agg_png, bg = "white")
ggsave(file.path(O, "2026-11-14_fig3-instrument-sensitivity_REVIEW.pdf"), fig, width = 180, height = 165, units = "mm", bg = "white")
cat("FIG3 DONE\n")
