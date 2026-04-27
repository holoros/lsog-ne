# Phase 8 ME 2020 only with verbose diagnostics
suppressPackageStartupMessages({
  library(terra); library(data.table); library(foreign)
  library(sf); library(maps)
})

OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_treemap"
all_v4 <- fread(file.path(OUT, "all_v4_lookup.csv"),
                 colClasses = list(character = "PLT_CN"))

state_sf <- sf::st_as_sf(maps::map("state", regions = "maine",
                                    plot = FALSE, fill = TRUE))
state_v <- terra::vect(state_sf)

vat <- as.data.table(read.dbf("/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif.vat.dbf",
                                as.is = TRUE))
cat("vat$PLT_CN class before:", class(vat$PLT_CN), "\n")
cat("vat$PLT_CN sample:", head(vat$PLT_CN, 3), "\n")

vat[, PLT_CN_chr := sprintf("%.0f", as.numeric(PLT_CN))]
cat("vat$PLT_CN_chr sample:", head(vat$PLT_CN_chr, 3), "\n")

# DIAGNOSTIC: subset to ME plots in lookup
me_pcs <- all_v4[state == "ME"]$PLT_CN
cat("ME lookup PLT_CN count:", length(me_pcs), "\n")
cat("vat PLT_CN_chr in ME lookup:", sum(vat$PLT_CN_chr %in% me_pcs), "\n")

conus_rast <- terra::rast("/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif")
poly_proj <- terra::project(state_v, terra::crs(conus_rast))
rc <- terra::crop(conus_rast, poly_proj)
rc <- terra::mask(rc, poly_proj)

fr <- as.data.table(terra::freq(rc, digits = 0))
setnames(fr, c("layer","TM_ID","Count"))
fr <- fr[!is.na(TM_ID) & TM_ID > 0]
fr[, TM_ID := as.integer(TM_ID)]
cat("\nfr nrow:", nrow(fr), "fr$TM_ID class:", class(fr$TM_ID), "\n")

# vat use
vat_use <- vat[, .(TM_ID = as.integer(TM_ID), PLT_CN = PLT_CN_chr)]
cat("vat_use$TM_ID class:", class(vat_use$TM_ID), "\n")
cat("vat_use$PLT_CN class:", class(vat_use$PLT_CN), "\n")

fr2 <- merge(fr, vat_use, by = "TM_ID", all.x = TRUE)
cat("\nAfter TM_ID merge: fr2 nrow =", nrow(fr2), "\n")
cat("fr2$PLT_CN sample:", head(fr2$PLT_CN, 5), "\n")
cat("Non-NA PLT_CN:", sum(!is.na(fr2$PLT_CN)), "of", nrow(fr2), "\n")

# Lookup merge
fr3 <- merge(fr2, all_v4[, .(PLT_CN, v4_class)], by = "PLT_CN", all.x = TRUE)
cat("\nAfter PLT_CN merge: fr3 nrow =", nrow(fr3), "\n")
cat("Non-NA v4_class:", sum(!is.na(fr3$v4_class)), "of", nrow(fr3), "\n")
cat("v4_class table:\n")
print(table(fr3$v4_class, useNA = "ifany"))

# If working: aggregate
fr3[, v4_class := fifelse(is.na(v4_class), "Unknown", v4_class)]
agg <- fr3[, .(n_TM_IDs = .N,
                pixels = sum(Count, na.rm = TRUE),
                acres = sum(Count, na.rm = TRUE) * 0.222394),
            by = v4_class]
agg[, pct := round(100 * pixels / sum(pixels), 2)]
agg[, year := 2020]; agg[, state := "ME"]
print(agg)
fwrite(agg, file.path(OUT, "treemap_ME_2020_v2_debug.csv"))
