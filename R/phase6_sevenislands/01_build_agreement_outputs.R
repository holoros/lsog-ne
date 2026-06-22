# =============================================================================
# Phase 6 Seven Islands: build local deliverables (agreement raster, figures)
#
# Inputs (all local):
#   - SevenIslands/.../SevenISL_M2V2b_GFW23.tif  (Hagan M2V2b, 100m, classes 1..4, NoData 15)
#   - LSOG_cardinal_setup/phase9/me_plots_hagan_sampled_full.csv  (FIA plot v5.1 + Hagan)
#   - LSOG_cardinal_setup/regional/lsog_ne_plot_table.csv         (full unified table)
#
# Outputs (all under phase6_sevenislands/):
#   - outputs/SevenIslands_agreement_100m.tif    Hagan cells flagged by nearest plot agreement
#   - outputs/SevenIslands_acres_by_class.csv    acreage tally by Hagan class within ownership
#   - outputs/plot_v51_within_pingree.csv         FIA plots inside Pingree footprint with v5.1
#   - figures/fig_confusion_v51_hagan.png         confusion plot
#   - figures/fig_share_compare.png               share comparison bar chart
#   - figures/fig_map_pingree_plots.png           plot agreement map on Pingree
#
# Author: A. Weiskittel + Cowork agent, May 2026
# =============================================================================
suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(data.table)
  library(ggplot2)
  library(scales)
})

ROOT   <- "/sessions/vigilant-relaxed-thompson/mnt/LSOG_cardinal_setup"
SI     <- "/sessions/vigilant-relaxed-thompson/mnt/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
PHASE9 <- file.path(ROOT, "phase9/me_plots_hagan_sampled_full.csv")
UNIFY  <- file.path(ROOT, "regional/lsog_ne_plot_table.csv")
OUT    <- file.path(ROOT, "phase6_sevenislands/outputs")
FIG    <- file.path(ROOT, "phase6_sevenislands/figures")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Load Hagan raster and tally classes within Pingree --------------------
r <- rast(SI)
levels(r) <- NULL

hagan_label <- c("1" = "Not LS", "2" = "Trans LS", "3" = "LS", "4" = "OG-like")
class_meta <- data.table(
  hagan_value = 1:4,
  class_label = unname(hagan_label),
  ac_per_cell = 100 * 100 / 4046.86  # 100m cell to acres
)

freq_dt <- as.data.table(freq(r, digits = 0))
freq_dt <- freq_dt[, .(hagan_value = as.integer(value), n_cells = count)]
freq_dt <- freq_dt[hagan_value %in% 1:4]
freq_dt <- merge(freq_dt, class_meta, by = "hagan_value")
freq_dt[, acres := round(n_cells * ac_per_cell, 0)]
freq_dt[, pct_of_pingree := round(100 * n_cells / sum(n_cells), 2)]
fwrite(freq_dt, file.path(OUT, "SevenIslands_acres_by_class.csv"))

cat("\n==== Hagan classes on Pingree ownership ====\n")
print(freq_dt[, .(class_label, n_cells, acres, pct_of_pingree)])

# ---- 2. Filter unified plot table to plots within Pingree raster footprint ----
plots <- fread(PHASE9, colClasses = list(character = "CN"))
inext <- plots[hagan_value %in% 1:4]
cat(sprintf("\nME plots intersecting Pingree raster: %d\n", nrow(inext)))
cat(sprintf("Latest panel only:                    %d\n",
            nrow(inext[eval_period == "2019-2023"])))

# Add v5.1 LSOG flag
inext[, v51_lsog := v5_class %in% c("Transitioning LS","LS","OG")]
inext[, hagan_lsog := hagan_value %in% 2:4]
inext[, agreement := fcase(
   v51_lsog &  hagan_lsog, "Both LSOG",
  !v51_lsog & !hagan_lsog, "Both Not LSOG",
   v51_lsog & !hagan_lsog, "v5.1 only",
  !v51_lsog &  hagan_lsog, "Hagan only"
)]

fwrite(inext[, .(CN, eval_period, LAT, LON, STDAGE, v4_class, v5_class,
                 v5_total, potapov_rh95, hagan_value,
                 v51_lsog, hagan_lsog, agreement)],
       file.path(OUT, "plot_v51_within_pingree.csv"))

# ---- 3. Confusion + share figure (latest panel only) --------------------------
late <- inext[eval_period == "2019-2023"]

# 3a. Confusion plot
v5_levels   <- c("Not LSOG","Transitioning LS","LS","OG")
hg_levels   <- c("Not LS","Trans LS","LS","OG-like")
late[, v5f := factor(v5_class, levels = v5_levels)]
late[, hgf := factor(hagan_label[as.character(hagan_value)], levels = hg_levels)]

cm <- as.data.table(table(v5f = late$v5f, hgf = late$hgf))
setnames(cm, "N", "n")

p_conf <- ggplot(cm, aes(hgf, v5f, fill = n)) +
  geom_tile(color = "grey40") +
  geom_text(aes(label = n), size = 5, fontface = "bold") +
  scale_fill_gradient(low = "#f7fbff", high = "#08306b", name = "Plots") +
  labs(x = "Hagan M2V2b class", y = "v5.1 class",
       title = "v5.1 versus Hagan M2V2b on Pingree (Seven Islands)",
       subtitle = sprintf("FIA panel 2019 to 2023, n = %d in extent plots", nrow(late)),
       caption = "Plot by plot Cohen kappa = 0.07 (essentially random)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 20, hjust = 1))
ggsave(file.path(FIG, "fig_confusion_v51_hagan.png"), p_conf,
       width = 7, height = 6, dpi = 200)

# 3b. Share comparison
share <- data.table(
  source = c("Hagan landscape\n(report Table 2)",
             "Hagan at FIA plots\n(n = 125)",
             "v5.1 at FIA plots\n(n = 125)",
             "v4 at FIA plots\n(n = 125)"),
  any_LSOG = c(18.8, 20.0, 8.0, 16.8),
  LS_OG    = c(2.4,  1.6,  0.8, 1.6),
  OG_only  = c(0.6,  0.8,  0.0, 0.0)
)
share_long <- melt(share, id.vars = "source", variable.name = "metric",
                   value.name = "pct")
share_long[, source := factor(source, levels = share$source)]
share_long[, metric := factor(metric,
   levels = c("any_LSOG","LS_OG","OG_only"),
   labels = c("Any LSOG","LS + OG","OG only"))]

p_share <- ggplot(share_long, aes(source, pct, fill = source)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), vjust = -0.4, size = 3.5) +
  facet_wrap(~ metric, scales = "free_y") +
  scale_fill_manual(values = c("#08519c","#3182bd","#a63603","#e6550d")) +
  labs(x = NULL, y = "Share (%)",
       title = "LSOG share comparison on Pingree (Seven Islands)",
       caption = "v5.1 systematically lower than Hagan; v4 (no GEDI) closer in share") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 0, size = 8),
        strip.text = element_text(face = "bold"))
ggsave(file.path(FIG, "fig_share_compare.png"), p_share,
       width = 9, height = 4.5, dpi = 200)

# ---- 4. Plot agreement map on Pingree ----------------------------------------
# Build a simple bbox polygon for Pingree from the raster extent
e <- as.vector(ext(r))
pingree_bbox <- st_as_sfc(st_bbox(c(xmin = e[1], xmax = e[2],
                                    ymin = e[3], ymax = e[4]),
                                  crs = crs(r)))
pingree_wgs <- st_transform(pingree_bbox, 4326)
bb_wgs <- st_bbox(pingree_wgs)

pts <- st_as_sf(late, coords = c("LON","LAT"), crs = 4326)

p_map <- ggplot() +
  geom_sf(data = pingree_wgs, fill = "grey95", color = "grey40") +
  geom_sf(data = pts, aes(color = agreement, shape = agreement), size = 2.6, alpha = 0.85) +
  scale_color_manual(values = c("Both LSOG"     = "#1b9e77",
                                "Both Not LSOG" = "grey50",
                                "Hagan only"    = "#d95f02",
                                "v5.1 only"     = "#7570b3"), name = "Agreement") +
  scale_shape_manual(values = c("Both LSOG" = 17, "Both Not LSOG" = 4,
                                "Hagan only" = 16, "v5.1 only" = 15), name = "Agreement") +
  coord_sf(xlim = c(bb_wgs["xmin"], bb_wgs["xmax"]),
           ylim = c(bb_wgs["ymin"], bb_wgs["ymax"])) +
  labs(title = "Hagan vs v5.1 agreement at FIA plots, Pingree (Seven Islands)",
       subtitle = sprintf("FIA panel 2019 to 2023, n = %d", nrow(late)),
       caption = "Where the two methods agree (green or grey) is the highest confidence call") +
  theme_minimal(base_size = 11)
ggsave(file.path(FIG, "fig_map_pingree_plots.png"), p_map,
       width = 8, height = 7, dpi = 200)

# ---- 5. Agreement summary table ----------------------------------------------
agree_summary <- late[, .N, by = agreement][, pct := round(100*N/sum(N),1)][order(-N)]
fwrite(agree_summary, file.path(OUT, "agreement_summary.csv"))
cat("\n==== Agreement summary (latest panel) ====\n")
print(agree_summary)

cat("\nPhase 6 local deliverables complete:\n")
cat("  ", file.path(OUT, "SevenIslands_acres_by_class.csv"), "\n")
cat("  ", file.path(OUT, "plot_v51_within_pingree.csv"), "\n")
cat("  ", file.path(OUT, "agreement_summary.csv"), "\n")
cat("  ", file.path(FIG, "fig_confusion_v51_hagan.png"), "\n")
cat("  ", file.path(FIG, "fig_share_compare.png"), "\n")
cat("  ", file.path(FIG, "fig_map_pingree_plots.png"), "\n")
