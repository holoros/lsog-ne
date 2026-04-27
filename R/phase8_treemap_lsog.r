# =============================================================================
# Phase 8: TreeMap-based wall-to-wall LSOG estimation
# Each TreeMap pixel = an imputed FIA PLT_CN. Look up v5.1 class via PLT_CN.
# =============================================================================
suppressPackageStartupMessages({
  library(terra); library(data.table); library(tidyverse); library(foreign)
})

TM_CONFIG <- list(
  list(year = 2020,
        vat_dbf  = "/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif.vat.dbf",
        me_rast  = "/users/PUOM0008/crsfaaron/TREEMAP/ME_TM_20.tif"),
  list(year = 2022,
        vat_dbf  = "/users/PUOM0008/crsfaaron/TREEMAP/TM2022/TreeMap2022_CONUS.tif.vat.dbf",
        me_rast  = "/users/PUOM0008/crsfaaron/TREEMAP/ME_TM_22.tif")
)

# Load v5.1 plot table (recompute v5.1 class fresh)
unified <- fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv") %>%
  as_tibble() %>%
  filter(eval_period == "2019-2023") %>%
  mutate(
    s_ba_large = case_when(ba_large >= 80 ~ 2L, ba_large >= 40 ~ 1L, TRUE ~ 0L),
    s_maturity = case_when(
      !is.na(STDAGE) & STDAGE >= 120 ~ 2L,
      !is.na(STDAGE) & STDAGE >= 80  ~ 1L,
      (is.na(STDAGE) | STDAGE == 0) & max_dia >= 24 ~ 1L,
      TRUE ~ 0L),
    s_structure = case_when(sd_dia >= 8 ~ 2L, sd_dia >= 5 ~ 1L, TRUE ~ 0L),
    s_canopy    = case_when(ba_total >= 150 ~ 2L, ba_total >= 100 ~ 1L, TRUE ~ 0L),
    s_deadwood  = case_when(snag_tpa >= snag_thresh_2 ~ 2L,
                            snag_tpa >= snag_thresh_1 ~ 1L, TRUE ~ 0L),
    s_height    = case_when(
      !is.na(potapov_rh95) & potapov_rh95 >= 25 ~ 2L,
      !is.na(potapov_rh95) & potapov_rh95 >= 18 ~ 1L,
      TRUE ~ 0L),
    v51_total = s_ba_large + s_maturity + s_structure + s_canopy + s_deadwood + s_height,
    v51_class = case_when(
      v51_total >= 8 ~ "OG", v51_total >= 6 ~ "LS",
      v51_total >= 4 ~ "Transitioning LS", TRUE ~ "Not LSOG")
  )

cat(sprintf("Unified v5.1 plots in 2019-2023: %d\n", nrow(unified)))

PIXEL_AC <- 0.222394   # 30m x 30m = 900 m^2 = 0.222394 acres

results <- list()

for (cfg in TM_CONFIG) {
  cat(sprintf("\n=== TreeMap %d Maine ===\n", cfg$year))

  vat <- read.dbf(cfg$vat_dbf, as.is = TRUE)
  setDT(vat)
  cat(sprintf("vat: %d rows\n", nrow(vat)))

  # Load Maine raster
  cat("loading ME raster...\n")
  r <- terra::rast(cfg$me_rast)
  cat(sprintf("raster: %d x %d cells\n", ncol(r), nrow(r)))

  # Get TM_ID frequencies via freq() - returns table of unique values + counts
  cat("computing pixel frequencies (TM_ID -> count)...\n")
  fr <- terra::freq(r, digits = 0)
  fr <- as.data.table(fr)
  setnames(fr, c("layer","TM_ID","Count"))
  fr <- fr[!is.na(TM_ID) & TM_ID > 0]
  cat(sprintf("unique TM_IDs in ME: %d, total pixels: %d\n",
              nrow(fr), sum(fr$Count)))

  # Join TM_ID -> PLT_CN
  fr <- merge(fr, vat[, .(TM_ID, PLT_CN, FORTYPCD)], by = "TM_ID", all.x = TRUE)

  # Convert PLT_CN to character for matching with unified
  fr[, PLT_CN := as.character(PLT_CN)]
  unified$CN <- as.character(unified$CN)

  # Lookup v5.1 class
  lookup <- as.data.table(unified)[, .(CN, v51_class, v51_total)]
  setnames(lookup, "CN", "PLT_CN")
  fr <- merge(fr, lookup, by = "PLT_CN", all.x = TRUE)

  fr[, v51_class := ifelse(is.na(v51_class), "Unknown (PLT_CN not in unified)", v51_class)]

  # Aggregate pixel counts per class
  agg <- fr[, .(n_TM_IDs = .N,
                 pixels = sum(Count, na.rm = TRUE),
                 acres = sum(Count, na.rm = TRUE) * PIXEL_AC),
             by = v51_class]
  agg[, pct := 100 * pixels / sum(pixels)]

  cat(sprintf("\nLSOG class shares (TreeMap %d, ME):\n", cfg$year))
  print(agg)

  # Compute "all LSOG" share treating Unknown as Not LSOG
  pct_lsog <- 100 * sum(agg[v51_class %in% c("Transitioning LS","LS","OG"), pixels]) /
                  sum(agg$pixels)
  pct_lsog_no_unknown <- 100 * sum(agg[v51_class %in% c("Transitioning LS","LS","OG"), pixels]) /
                  sum(agg[v51_class != "Unknown (PLT_CN not in unified)", pixels])
  cat(sprintf("\nAll-LSOG share (incl. Unknown): %.2f%%\n", pct_lsog))
  cat(sprintf("All-LSOG share (excl. Unknown): %.2f%%\n", pct_lsog_no_unknown))

  agg$year <- cfg$year
  agg$state <- "ME"
  results[[length(results)+1]] <- as.data.frame(agg)
}

all_results <- bind_rows(results)
write_csv(all_results, "/users/PUOM0008/crsfaaron/LSOG/output_treemap/treemap_me_lsog.csv")
cat("\nSaved output_treemap/treemap_me_lsog.csv\n")
print(all_results)
