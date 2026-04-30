# =============================================================================
# Phase 8 v3 NE wall-to-wall: ME/NH/VT/NY x 2020/2022
# Fix: TreeMap CONUS raster has activeCat=4 (ForTypName); freq() returns
# strings, breaking TM_ID merge. We strip levels with levels(rc) <- NULL
# so freq() returns raw integer Value codes (Value == TM_ID, verified).
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(data.table); library(foreign)
  library(sf); library(maps)
})

OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_treemap"

all_v4 <- fread(file.path(OUT, "all_v4_lookup.csv"),
                 colClasses = list(character = "PLT_CN"))
cat(sprintf("v4 lookup: %d PLT_CNs\n", nrow(all_v4)))
cat("v4 class table:\n"); print(all_v4[, .N, by = v4_class][order(-N)])

state_sf <- sf::st_as_sf(maps::map("state",
  regions = c("maine","new hampshire","vermont","new york"),
  plot = FALSE, fill = TRUE))
state_sf$state_short <- c("ME","NH","VT","NY")[match(state_sf$ID,
                          c("maine","new hampshire","vermont","new york"))]
state_v <- terra::vect(state_sf)

PIXEL_AC <- 0.222394

run1 <- function(state_short, year, conus_rast, vat) {
  out_csv <- sprintf("%s/treemap_%s_%d_v3.csv", OUT, state_short, year)
  if (file.exists(out_csv)) {
    cat(sprintf("  skip %s %d (exists)\n", state_short, year))
    return(fread(out_csv))
  }
  cat(sprintf("\n--- %s %d ---\n", state_short, year))

  poly <- state_v[state_v$state_short == state_short, ]
  poly_proj <- terra::project(poly, terra::crs(conus_rast))
  rc <- terra::crop(conus_rast, poly_proj)
  rc <- terra::mask(rc, poly_proj)

  # CRITICAL FIX: drop categorical levels so freq() returns raw integer Value
  # codes (Value == TM_ID per vat). Without this, freq() returns ForTypName
  # strings and the merge to vat fails -> all-Unknown bug.
  levels(rc) <- NULL

  fr <- as.data.table(terra::freq(rc, digits = 0))
  setnames(fr, c("layer","TM_ID","Count"))
  fr <- fr[!is.na(TM_ID) & TM_ID > 0]
  fr[, TM_ID := as.integer(TM_ID)]
  cat(sprintf("  unique TM_IDs: %d, pixels: %d\n",
              nrow(fr), sum(fr$Count)))

  vat_use <- copy(vat[, .(TM_ID, PLT_CN)])
  vat_use[, TM_ID := as.integer(TM_ID)]
  vat_use[, PLT_CN := sprintf("%.0f", as.numeric(PLT_CN))]

  fr <- merge(fr, vat_use, by = "TM_ID", all.x = TRUE)
  matched_vat <- sum(!is.na(fr$PLT_CN))
  cat(sprintf("  TM_IDs matched to vat: %d / %d\n", matched_vat, nrow(fr)))

  fr <- merge(fr, all_v4[, .(PLT_CN, v4_class)], by = "PLT_CN", all.x = TRUE)
  fr[, v4_class := fifelse(is.na(v4_class), "Unknown", v4_class)]

  agg <- fr[, .(n_TM_IDs = .N,
                 pixels = sum(Count, na.rm = TRUE),
                 acres = sum(Count, na.rm = TRUE) * PIXEL_AC),
             by = v4_class]
  agg[, pct := round(100 * pixels / sum(pixels), 2)]
  agg[, year := year]
  agg[, state := state_short]
  agg <- agg[order(-pixels)]

  fwrite(agg, out_csv)
  cat(sprintf("  saved %s\n", basename(out_csv)))
  print(agg)
  agg
}

# Process all 8 state-years
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
  fwrite(combined, file.path(OUT, "treemap_NE_lsog_v3.csv"))
  summary <- combined[v4_class %in% c("Transitioning LS","LS","OG"),
                       .(any_lsog_pct = sum(pct),
                          any_lsog_ac  = sum(acres)),
                       by = .(state, year)][order(state, year)]
  fwrite(summary, file.path(OUT, "treemap_NE_summary_v3.csv"))
  cat("\n=== Final NE summary v3 ===\n")
  print(summary)
}
