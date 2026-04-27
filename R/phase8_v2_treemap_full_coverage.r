# =============================================================================
# Phase 8 v2: full TreeMap coverage by extending FIA panel lookup
# Builds a PLT_CN -> v4_class lookup for ALL ME plots (1999-2023 panels),
# then applies to TreeMap raster to close the 50% Unknown gap.
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(data.table); library(tidyverse); library(foreign)
})

# Helper: compute v4 class for a state across all panels
# Uses ORIGINAL v3 dim thresholds (matches v5.1 baseline minus Potapov)
compute_v4_all_panels <- function(st) {
  cat(sprintf("  scoring %s all panels...\n", st))

  # Load FIA tables
  pf <- fread(file.path("/users/PUOM0008/crsfaaron/fia_data",
                         paste0(st, "_PLOT.csv")))
  cf <- fread(file.path("/users/PUOM0008/crsfaaron/fia_data",
                         paste0(st, "_COND.csv")))
  tf <- fread(file.path("/users/PUOM0008/crsfaaron/fia_data",
                         paste0(st, "_TREE.csv")))

  # Use dominant condition per plot per INVYR (not panel-aggregated)
  pc <- pf[cf, on = c(CN = "PLT_CN"), nomatch = 0L
          ][COND_STATUS_CD == 1
          ][order(CN, -CONDPROP_UNADJ)
          ][, .SD[1], by = .(CN, INVYR)]

  # Tree summary on dominant condition
  td <- tf[pc[, .(CN, CONDID)], on = c(PLT_CN = "CN", "CONDID"),
            nomatch = 0L,
            allow.cartesian = TRUE]

  # Snag summary
  snag <- td[STATUSCD == 2 & DIA >= 5.0,
             .(snag_tpa = sum(TPA_UNADJ, na.rm = TRUE)), by = PLT_CN]
  # Live tree summary
  live <- td[STATUSCD == 1 & DIA >= 1.0,
             .(ba_total = sum(0.005454 * DIA^2 * TPA_UNADJ, na.rm = TRUE),
               ba_large = sum(0.005454 * DIA^2 * TPA_UNADJ * (DIA >= 20),
                               na.rm = TRUE),
               sd_dia   = {
                  d <- DIA; w <- TPA_UNADJ
                  if (length(d) < 2 || sum(w, na.rm = TRUE) == 0) 0
                  else {
                    mu <- weighted.mean(d, w, na.rm = TRUE)
                    sqrt(sum(w * (d - mu)^2, na.rm = TRUE) /
                          sum(w, na.rm = TRUE))
                  }
               },
               max_dia  = max(DIA, na.rm = TRUE)),
             by = PLT_CN]
  ts <- merge(live, snag, by = "PLT_CN", all.x = TRUE)
  ts[is.na(snag_tpa), snag_tpa := 0]

  # Data-driven snag thresholds across ALL plots in state
  snz <- ts$snag_tpa[ts$snag_tpa > 0]
  s1 <- if (length(snz) > 10) round(quantile(snz, 0.75)) else 10
  s2 <- if (length(snz) > 10) round(quantile(snz, 0.90)) else 20

  # v4 score: ORIGINAL v3 dim thresholds (matches v5.1)
  scored <- pc[ts, on = c(CN = "PLT_CN"), nomatch = 0L]
  scored[, `:=`(
    s_ba_large = fifelse(ba_large >= 80, 2L, fifelse(ba_large >= 40, 1L, 0L)),
    s_maturity = fifelse(!is.na(STDAGE) & STDAGE >= 120, 2L,
                  fifelse(!is.na(STDAGE) & STDAGE >= 80, 1L,
                  fifelse((is.na(STDAGE) | STDAGE == 0) & max_dia >= 24, 1L, 0L))),
    s_structure = fifelse(sd_dia >= 8, 2L, fifelse(sd_dia >= 5, 1L, 0L)),
    s_canopy    = fifelse(ba_total >= 150, 2L, fifelse(ba_total >= 100, 1L, 0L)),
    s_deadwood  = fifelse(snag_tpa >= s2, 2L,
                          fifelse(snag_tpa >= s1, 1L, 0L))
  )]
  scored[, v4_total := s_ba_large + s_maturity + s_structure + s_canopy + s_deadwood]
  scored[, v4_class := fifelse(v4_total >= 8, "OG",
                       fifelse(v4_total >= 6, "LS",
                       fifelse(v4_total >= 4, "Transitioning LS", "Not LSOG")))]

  scored[, .(PLT_CN = CN, INVYR, state = st, v4_total, v4_class)]
}

cat("=== Building all-panels v4 lookup for ME ===\n")
me_v4 <- compute_v4_all_panels("ME")
cat(sprintf("  scored %d ME plot-INVYR combinations\n", nrow(me_v4)))
cat(sprintf("  unique PLT_CNs: %d\n", uniqueN(me_v4$PLT_CN)))
cat("  panel breakdown:\n")
print(me_v4[, .N, by = INVYR][order(INVYR)])
cat("  v4 class distribution:\n")
print(me_v4[, .N, by = v4_class][order(-N)])

# For each PLT_CN, take the LATEST INVYR's v4 class as the canonical value
me_v4_latest <- me_v4[order(PLT_CN, -INVYR)][, .SD[1], by = PLT_CN]
cat(sprintf("\nUnique PLT_CN -> v4_class lookup: %d entries\n", nrow(me_v4_latest)))

# Also extend to NH, VT, NY for cross-state imputation cases
cat("\n=== Extending to NH/VT/NY ===\n")
other_v4 <- rbindlist(lapply(c("NH","VT","NY"), compute_v4_all_panels))
other_v4_latest <- other_v4[order(PLT_CN, -INVYR)][, .SD[1], by = PLT_CN]
cat(sprintf("  NH/VT/NY combined unique PLT_CNs: %d\n", nrow(other_v4_latest)))

all_v4 <- rbind(me_v4_latest, other_v4_latest)
cat(sprintf("\n4-state combined v4 lookup: %d unique PLT_CNs\n", nrow(all_v4)))
fwrite(all_v4, "/users/PUOM0008/crsfaaron/LSOG/output_treemap/all_v4_lookup.csv")

# ---- Now apply to TreeMap raster ----
cat("\n=== Applying lookup to TreeMap rasters ===\n")
PIXEL_AC <- 0.222394

results <- list()
for (cfg in list(
  list(year = 2020, vat = "/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif.vat.dbf",
        rast = "/users/PUOM0008/crsfaaron/TREEMAP/ME_TM_20.tif"),
  list(year = 2022, vat = "/users/PUOM0008/crsfaaron/TREEMAP/TM2022/TreeMap2022_CONUS.tif.vat.dbf",
        rast = "/users/PUOM0008/crsfaaron/TREEMAP/ME_TM_22.tif")
)) {
  cat(sprintf("\n--- ME TreeMap %d ---\n", cfg$year))
  vat <- as.data.table(read.dbf(cfg$vat, as.is = TRUE))
  vat[, PLT_CN := as.character(PLT_CN)]
  all_v4_dt <- copy(all_v4); all_v4_dt[, PLT_CN := as.character(PLT_CN)]

  r <- terra::rast(cfg$rast)
  fr <- as.data.table(terra::freq(r, digits = 0))
  setnames(fr, c("layer","TM_ID","Count"))
  fr <- fr[!is.na(TM_ID) & TM_ID > 0]

  fr <- merge(fr, vat[, .(TM_ID, PLT_CN, FORTYPCD)], by = "TM_ID", all.x = TRUE)
  fr <- merge(fr, all_v4_dt[, .(PLT_CN, v4_class)], by = "PLT_CN", all.x = TRUE)
  fr[, v4_class := fifelse(is.na(v4_class), "Unknown (PLT_CN not in NE 1999-2023)", v4_class)]

  agg <- fr[, .(n_TM_IDs = .N,
                 pixels = sum(Count, na.rm = TRUE),
                 acres = sum(Count, na.rm = TRUE) * PIXEL_AC),
             by = v4_class]
  agg[, pct := round(100 * pixels / sum(pixels), 2)]
  agg[, year := cfg$year]
  agg[, state := "ME"]
  print(agg)

  results[[length(results)+1]] <- agg
}

all_results <- rbindlist(results)
fwrite(all_results, "/users/PUOM0008/crsfaaron/LSOG/output_treemap/treemap_me_lsog_v2.csv")
cat("\nSaved output_treemap/treemap_me_lsog_v2.csv\n")
print(all_results)
