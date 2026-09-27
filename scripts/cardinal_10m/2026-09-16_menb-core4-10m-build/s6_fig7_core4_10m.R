#!/usr/bin/env Rscript
# s6_fig7_core4_10m.R  Figure 7 of the ME/NB manuscript: the 10 m CORE4 structural core surface (jurisdiction calibrated by default)
# (panel a) paired with its block-bootstrap SD (panel b), both jurisdictions on one EPSG:3979 canvas.
# The 10 m layers are summarized to 250 m for display (mean of valid forest cells). Display cells where
# more than half of the valid 10 m cells are flagged as extrapolation are drawn in grey in both panels.
# Reads final layers (or .part when gates are still pending) and the s4 summary and s5 interval JSON.
suppressPackageStartupMessages({
  library(terra); library(sf); library(ggplot2); library(tidyterra); library(patchwork)
  library(ggsci); library(jsonlite); library(scales)
})
terraOptions(memfrac = 0.6, progress = 0)
FIN  <- Sys.getenv("FINAL"); B <- Sys.getenv("BUILD"); DATE <- "2026-09-16"
AGG  <- 25L                                    # 25 x 10 m = 250 m display cells
SUF  <- Sys.getenv("FIG_SUFFIX", "-jurcal")        # "-jurcal" for the jurisdiction-calibrated product, "" for pooled
lay  <- function(k, J) { kk <- if (k == "extrapolation-flag") k else paste0(k, SUF)
                         f <- file.path(FIN, sprintf("core4-structural-core-%s_10m_%s_DATA_%s.tif", kk, J, DATE))
                         if (file.exists(f)) f else paste0(f, ".part") }
one <- function(k) {
  v <- vrt(c(lay(k, "ME"), lay(k, "NB")), filename = file.path(B, sprintf("fig7_%s%s.vrt", k, SUF)), overwrite = TRUE)
  aggregate(v, AGG, mean, na.rm = TRUE, filename = file.path(B, sprintf("fig7_%s%s_250m.tif", k, SUF)), overwrite = TRUE)
}
m <- c(one("probability") / 10000, one("bootstrap-sd") / 10000, one("extrapolation-flag"))
names(m) <- c("prob", "sd", "extrap")
ext_mask <- m$extrap > 0.5
prob <- mask(m$prob, ext_mask, maskvalues = 1); sd <- mask(m$sd, ext_mask, maskvalues = 1)
ext  <- st_as_sf(as.polygons(ext_mask, dissolve = TRUE)) |> subset(extrap == 1)
rd <- function(f) st_geometry(st_transform(st_read(f, quiet = TRUE), crs(m)))
bnd <- st_sf(geometry = c(rd(Sys.getenv("ME_BOUNDARY")), rd(Sys.getenv("NB_BOUNDARY"))))
S  <- fromJSON(file.path(FIN, sprintf("core4-10m-jurcal-summary_DATA_%s.json", DATE)))
lab <- function(J) sprintf("%s %.2f%% [%.2f, %.2f]", J, S[[paste0(J, "_share_cal_pct")]],
                           S[[paste0(J, "_share_cal_pct_2p5_97p5")]][1], S[[paste0(J, "_share_cal_pct_2p5_97p5")]][2])
th <- theme_void(base_size = 13) +
  theme(plot.title = element_text(face = "bold", size = 15, margin = margin(b = 4)),
        plot.subtitle = element_blank(),
        legend.position = "bottom", legend.title = element_text(face = "bold", size = 10.5, vjust = 0.85),
        legend.text = element_text(size = 10), legend.key.width = unit(0.9, "cm"),
        legend.key.height = unit(0.32, "cm"), plot.background = element_rect(fill = "white", colour = NA))
base <- function(r, fill_scale, ttl, sub) {
  ggplot() +
    geom_spatraster(data = r) + fill_scale +
    geom_sf(data = ext, fill = "grey70", colour = NA) +
    geom_sf(data = bnd, fill = NA, colour = "grey20", linewidth = 0.35) +
    coord_sf(crs = crs(m), expand = FALSE) +
    labs(title = ttl, subtitle = sub) + th
}
qmax <- as.numeric(quantile(spatSample(prob, 200000, na.rm = TRUE)[[1]], 0.995, na.rm = TRUE))
pa <- base(prob, scale_fill_gsea(name = "Probability", limits = c(0, qmax), breaks = pretty(c(0, qmax), n = 4),
                                  oob = squish, na.value = NA, labels = number_format(accuracy = 0.01)),
           "a. Probability", NULL)
sq <- as.numeric(quantile(spatSample(sd, 200000, na.rm = TRUE)[[1]], 0.995, na.rm = TRUE))
pb <- base(sd, scale_fill_distiller(palette = "Greys", direction = 1, name = "SD", limits = c(0, sq), breaks = pretty(c(0, sq), n = 3),
                                    oob = squish, na.value = NA, labels = number_format(accuracy = 0.01)),
           "b. Bootstrap SD", NULL)
p <- (pa + pb + plot_layout(ncol = 2)) +
  plot_annotation(caption = paste0("Forest share with 95% bootstrap percentile interval: ", lab("ME"), ";\n", lab("NB"), ". ",
                                   "Mean per-pixel bootstrap SD: ME ", sprintf("%.3f", S$ME_mean_sd_cal), ", NB ",
                                   sprintf("%.3f", S$NB_mean_sd_cal), ".\nGrey: most 10 m cells outside the training envelope. Display at 250 m."),
                  theme = theme(plot.caption = element_text(size = 9.5, hjust = 0, colour = "grey20")))
out <- file.path(FIN, sprintf("fig7_core4-structural-core-10m%s_%s", SUF, DATE))
ggsave(paste0(out, ".pdf"), p, width = 17.4, height = 13.5, units = "cm", device = cairo_pdf)
ggsave(paste0(out, ".png"), p, width = 17.4, height = 13.5, units = "cm", dpi = 400, bg = "white")
ggsave(paste0(out, "_THUMB.png"), p, width = 17.4, height = 13.5, units = "cm", dpi = 110, bg = "white")
write.csv(data.frame(display_resolution_m = AGG * 10,
                     share_display_cells_masked_extrapolation = as.numeric(global(ext_mask, mean, na.rm = TRUE)),
                     prob_display_max_q995 = qmax, sd_display_max_q995 = sq),
          file.path(FIN, sprintf("fig7_display-summary%s_%s.csv", SUF, DATE)), row.names = FALSE)
cat("FIG7_DONE\n")
