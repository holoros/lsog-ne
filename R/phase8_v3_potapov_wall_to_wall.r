# =============================================================================
# Phase 8 v3-Potapov: GEDI/Potapov-aware wall-to-wall
#
# Builds a hybrid PLT_CN -> class lookup:
#   - 2019-2023 panel plots: use v5.1 class (includes Potapov RH95 dimension)
#   - older-panel plots:     use v4 class (no canopy height)
#
# Then applies hybrid lookup to TreeMap 2020 and 2022 pixels, with the
# levels(rc) <- NULL fix from Phase 8 v3 NE wall-to-wall.
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(data.table); library(foreign)
  library(sf); library(maps)
})

OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_treemap"

# ---- Build hybrid lookup ----
unified <- fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv",
                  colClasses = list(character = "CN"))
v4_lookup <- fread(file.path(OUT, "all_v4_lookup.csv"),
                   colClasses = list(character = "PLT_CN"))

# Latest panel v5 class for each plot
v5_latest <- unified[eval_period == "2019-2023",
                      .(PLT_CN = sprintf("%.0f", as.numeric(CN)),
                        v5_class)]
cat(sprintf("v5 (latest panel) lookup: %d entries\n", nrow(v5_latest)))
cat("  v5 class distribution:\n"); print(v5_latest[, .N, by = v5_class][order(-N)])

# Hybrid: prefer v5, fall back to v4
hybrid <- v4_lookup[, .(PLT_CN, hybrid_class = v4_class, source = "v4")]
hybrid <- merge(hybrid, v5_latest, by = "PLT_CN", all.x = TRUE)
hybrid[!is.na(v5_class), `:=`(hybrid_class = v5_class, source = "v5")]
hybrid[, v5_class := NULL]

cat(sprintf("\nHybrid lookup: %d total, %d via v5, %d via v4\n",
            nrow(hybrid), sum(hybrid$source == "v5"),
            sum(hybrid$source == "v4")))
cat("  hybrid class distribution:\n")
print(hybrid[, .N, by = hybrid_class][order(-N)])

fwrite(hybrid, file.path(OUT, "hybrid_v5_v4_lookup.csv"))

# ---- Apply to TreeMap rasters ----
state_sf <- sf::st_as_sf(maps::map("state",
  regions = c("maine","new hampshire","vermont","new york"),
  plot = FALSE, fill = TRUE))
state_sf$state_short <- c("ME","NH","VT","NY")[match(state_sf$ID,
                          c("maine","new hampshire","vermont","new york"))]
state_v <- terra::vect(state_sf)

PIXEL_AC <- 0.222394

run1 <- function(state_short, year, conus_rast, vat) {
  out_csv <- sprintf("%s/treemap_%s_%d_v3pot.csv", OUT, state_short, year)
  if (file.exists(out_csv)) {
    cat(sprintf("  skip %s %d\n", state_short, year))
    return(fread(out_csv))
  }
  cat(sprintf("\n--- %s %d ---\n", state_short, year))

  poly <- state_v[state_v$state_short == state_short, ]
  poly_proj <- terra::project(poly, terra::crs(conus_rast))
  rc <- terra::crop(conus_rast, poly_proj)
  rc <- terra::mask(rc, poly_proj)
  levels(rc) <- NULL  # critical: get raw integer Value codes

  fr <- as.data.table(terra::freq(rc, digits = 0))
  setnames(fr, c("layer","TM_ID","Count"))
  fr <- fr[!is.na(TM_ID) & TM_ID > 0]
  fr[, TM_ID := as.integer(TM_ID)]

  vat_use <- copy(vat[, .(TM_ID, PLT_CN)])
  vat_use[, TM_ID := as.integer(TM_ID)]
  vat_use[, PLT_CN := sprintf("%.0f", as.numeric(PLT_CN))]

  fr <- merge(fr, vat_use, by = "TM_ID", all.x = TRUE)
  fr <- merge(fr, hybrid[, .(PLT_CN, hybrid_class, source)],
              by = "PLT_CN", all.x = TRUE)
  fr[, hybrid_class := fifelse(is.na(hybrid_class), "Unknown", hybrid_class)]
  fr[, source := fifelse(is.na(source), "none", source)]

  agg <- fr[, .(n_TM_IDs = .N,
                 pixels = sum(Count, na.rm = TRUE),
                 acres = sum(Count, na.rm = TRUE) * PIXEL_AC),
             by = .(hybrid_class, source)]
  agg[, pct := round(100 * pixels / sum(pixels), 2)]
  agg[, year := year]
  agg[, state := state_short]
  agg <- agg[order(-pixels)]

  fwrite(agg, out_csv)
  cat(sprintf("  saved %s\n", basename(out_csv)))
  print(agg)
  agg
}

results <- list()
for (year in c(2020, 2022)) {
  vat_path  <- sprintf("/users/PUOM0008/crsfaaron/TREEMAP/TM%d/TreeMap%d_CONUS.tif.vat.dbf",
                       year, year)
  rast_path <- sprintf("/users/PUOM0008/crsfaaron/TREEMAP/TM%d/TreeMap%d_CONUS.tif",
                       year, year)
  cat(sprintf("\n=== Loading TreeMap %d ===\n", year))
  vat <- as.data.table(read.dbf(vat_path, as.is = TRUE))
  conus_rast <- terra::rast(rast_path)
  for (st in c("ME","NH","VT","NY")) {
    res <- tryCatch(run1(st, year, conus_rast, vat),
                    error = function(e) {
                      cat("ERROR:", conditionMessage(e), "\n"); NULL
                    })
    if (!is.null(res)) results[[length(results)+1]] <- res
  }
  rm(conus_rast); gc()
}

if (length(results) > 0) {
  combined <- rbindlist(results)
  fwrite(combined, file.path(OUT, "treemap_NE_lsog_v3pot.csv"))
  summary <- combined[hybrid_class %in% c("Transitioning LS","LS","OG"),
                       .(any_lsog_pct = sum(pct),
                          any_lsog_ac  = sum(acres)),
                       by = .(state, year)][order(state, year)]
  fwrite(summary, file.path(OUT, "treemap_NE_summary_v3pot.csv"))
  cat("\n=== Phase 8 v3-Potapov NE summary ===\n")
  print(summary)
}
