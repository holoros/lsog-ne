#!/usr/bin/env Rscript
# s1_labels_weights_core4.R
# Builds the pooled CORE4 cut-3 training table for the 10 m build.
#  (1) Resolves which CORE4 label definition reproduces the published sampling-table rates,
#      instead of guessing between the point sum and the axes-fired count.
#  (2) Joins labels to the Sep 4 pooled training table (AlphaEarth bands, spatial block)
#      and the Hansen time-since-disturbance covariate.
#  (3) Builds NB cell-level design weights from the CLI_Grid frame and checks them against the
#      published design effect and coverage. Maine plots carry weight 1.
# Output carries no coordinates. Every gate is a hard stop.
suppressPackageStartupMessages({ library(data.table); library(sf) })
e <- Sys.getenv
set.seed(as.integer(e("SEED")))
BUILD <- e("BUILD"); dir.create(file.path(BUILD, "logs"), FALSE, TRUE)
LOG <- file.path(BUILD, "logs", "s1_gates.txt")
say <- function(...) { m <- paste0(...); cat(m, "\n"); cat(m, "\n", file = LOG, append = TRUE) }
gate <- function(ok, msg) { say(if (ok) "PASS " else "FAIL ", msg); if (!ok) quit(status = 2) }
ref <- function(k) as.numeric(strsplit(e(k), ",")[[1]])

# ---- (1) label definition -------------------------------------------------
s <- fread(e("CORE4_SAMPLE"))
gate(nrow(s) == 13708, sprintf("CORE4 sample rows = %d (expected 13,708)", nrow(s)))
for (v in c("s_ba", "s_mat", "s_mat_max", "s_str", "s_can", "core4"))
  gate(v %in% names(s), paste("column present:", v))
z <- function(x) fifelse(is.na(x), 0L, as.integer(x))   # non-penalizing convention for unmatched covariates
s[, fired_max := (z(s_ba) > 0) + (z(s_mat_max) > 0) + (z(s_str) > 0) + (z(s_can) > 0)]
s[, fired_std := (z(s_ba) > 0) + (z(s_mat) > 0) + (z(s_str) > 0) + (z(s_can) > 0)]
cand <- list(A_fired_maxdia = s$fired_max >= 3L,
             B_fired_published_maturity = s$fired_std >= 3L,
             C_point_sum = z(s$core4) >= 3L)
rME <- ref("REF_ME_SAMPLE_RATE"); rNB <- ref("REF_NB_PUBLIC_RATE")
tab <- rbindlist(lapply(names(cand), function(k) {
  y <- cand[[k]]
  data.table(candidate = k,
             me_rate = 100 * mean(y[s$jurisdiction == "ME"]),
             nb_rate = 100 * mean(y[s$jurisdiction == "NB"]))
}))
tab[, me_ok := me_rate >= rME[2] & me_rate <= rME[3]]
tab[, nb_ok := nb_rate >= rNB[2] & nb_rate <= rNB[3]]
print(tab); fwrite(tab, file.path(BUILD, "logs", "s1_label_candidates.csv"))
hit <- tab[me_ok & nb_ok]
gate(nrow(hit) == 1, sprintf(
  "exactly one label definition reproduces ME %.2f [%.2f, %.2f] and NB %.2f [%.2f, %.2f]; matched: %s",
  rME[1], rME[2], rME[3], rNB[1], rNB[2], rNB[3], paste(hit$candidate, collapse = ", ")))
s[, core4_cut3 := as.integer(cand[[hit$candidate]])]
say("label definition adopted: ", hit$candidate)
if (requireNamespace("lsogscore", quietly = TRUE))
  say("lsogscore ", as.character(packageVersion("lsogscore")),
      " installed; confirm the adopted definition against lsogscore::score_core4 before publishing")

# ---- (2) join to predictors ---------------------------------------------
p <- fread(e("POOLED_TABLE"))
AE <- sprintf("AE_%02d", 0:63)
gate(all(c(AE, "plot_id_export", "jurisdiction", "blk") %in% names(p)), "pooled table has AE bands, id, blk")
tsd <- fread(e("TSD_TABLE"))[, .(plot_id, time_since_disturbance)]
p <- merge(p, tsd, by.x = "plot_id_export", by.y = "plot_id", all.x = TRUE)
m <- merge(p, s[, .(plot_id, core4_cut3)], by.x = "plot_id_export", by.y = "plot_id")
share <- nrow(m) / nrow(p)
if (share < 0.95) say("ids, pooled: ", paste(head(p$plot_id_export, 3), collapse = " "),
                      "  sample: ", paste(head(s$plot_id, 3), collapse = " "))
gate(share >= 0.95, sprintf("label join covers %.1f%% of pooled rows (need >= 95%%)", 100 * share))
m <- m[is.finite(time_since_disturbance)]
bad <- m[, rowSums(!is.finite(as.matrix(.SD))) > 0, .SDcols = AE]
m <- m[!bad]
say(sprintf("training rows %d (ME %d, NB %d), positives %d",
            nrow(m), m[jurisdiction == "ME", .N], m[jurisdiction == "NB", .N], sum(m$core4_cut3)))
gate(sum(m$core4_cut3) >= 300, "at least 300 CORE4 positives for a stable fit")
rng <- range(as.matrix(m[, ..AE]))
gate(rng[1] >= -1.0001 && rng[2] <= 1.0001, sprintf("AlphaEarth values within [-1, 1] after dequantization (range %.3f to %.3f)", rng[1], rng[2]))

# ---- (3) NB design weights from the CLI_Grid frame ------------------------
lyr <- st_layers(e("CLI_GRID_GDB"))
say("CLI_Grid layers: ", paste(lyr$name, lyr$features, sep = "=", collapse = "; "))
li <- which(lyr$features == as.integer(e("REF_NB_FRAME_POINTS")))
gate(length(li) == 1, "one CLI_Grid layer with 18,334 frame points")
frame <- st_transform(st_read(e("CLI_GRID_GDB"), lyr$name[li], quiet = TRUE), 4326)
fxy <- st_coordinates(st_centroid(st_geometry(frame)))
cell <- function(lon, lat) paste(floor(lon * 4), floor(lat * 4))      # quarter-degree cells
fcell <- data.table(cell = cell(fxy[, 1], fxy[, 2]))[, .(n_frame = .N), by = cell]
xy <- fread(e("NB_PUBLIC_XY"))
gate(all(c("plot_id_export", "lon", "lat") %in% names(xy)), "nb_public_plot_xy.csv has plot_id_export, lon, lat")
gate(!any(grepl("^ME_", xy$plot_id_export)), "no Maine rows in the coordinate file")
xy[, cell := cell(lon, lat)]
pc <- xy[, .(n_meas = .N), by = cell]
cov <- merge(fcell, pc, by = "cell", all.x = TRUE)[, n_meas := fifelse(is.na(n_meas), 0L, n_meas)]
coverage <- 100 * nrow(xy) / sum(cov$n_frame)
gate(abs(coverage - as.numeric(e("REF_NB_COVERAGE"))) <= 1.0,
     sprintf("NB panel coverage %.2f%% vs published %.2f%%", coverage, as.numeric(e("REF_NB_COVERAGE"))))
xy <- merge(xy, cov[, .(cell, w = n_frame / pmax(n_meas, 1L))], by = "cell")
xy[, w := w / mean(w)]
deff <- nrow(xy) * sum(xy$w^2) / sum(xy$w)^2
gate(abs(deff - as.numeric(e("REF_NB_DEFF"))) <= 0.05,
     sprintf("NB design effect %.3f vs published %.3f", deff, as.numeric(e("REF_NB_DEFF"))))
m <- merge(m, xy[, .(plot_id_export, w)], by = "plot_id_export", all.x = TRUE)
m[jurisdiction == "ME", w := 1]
gate(m[jurisdiction == "NB", mean(is.finite(w))] >= 0.98, "design weight attached to >= 98% of NB training rows")
m <- m[is.finite(w)]
nbw <- m[jurisdiction == "NB", weighted.mean(core4_cut3, w)] * 100
say(sprintf("NB weighted training rate %.2f%% (reference public rate %.2f [%.2f, %.2f])", nbw, rNB[1], rNB[2], rNB[3]))

out <- m[, c("plot_id_export", "jurisdiction", "blk", AE, "time_since_disturbance", "core4_cut3", "w"), with = FALSE]
fwrite(out, file.path(BUILD, "core4_training_table_DATA_2026-09-16.csv"))
say("S1_DONE rows=", nrow(out))
