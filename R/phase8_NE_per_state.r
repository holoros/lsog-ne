# Phase 8 NE per-state runner (called from shell loop)
# Reads pre-cropped state TIFF, joins to vat.dbf + v4 lookup, writes per-state CSV
suppressPackageStartupMessages({
  library(terra); library(data.table); library(foreign)
})
args <- commandArgs(trailingOnly = TRUE)
state_short <- args[1]; year <- as.integer(args[2])
rast_path <- args[3]
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_treemap"

vat <- as.data.table(read.dbf(sprintf(
  "/users/PUOM0008/crsfaaron/TREEMAP/TM%d/TreeMap%d_CONUS.tif.vat.dbf", year, year),
  as.is = TRUE))
all_v4 <- fread(file.path(OUT, "all_v4_lookup.csv"),
                 colClasses = list(character = "PLT_CN"))

r <- terra::rast(rast_path)
fr <- as.data.table(terra::freq(r, digits = 0))
setnames(fr, c("layer","TM_ID","Count"))
fr <- fr[!is.na(TM_ID) & TM_ID > 0]
fr[, TM_ID := as.integer(TM_ID)]
cat(sprintf("%s %d: unique TM_IDs %d, pixels %d\n",
             state_short, year, nrow(fr), sum(fr$Count)))

vat_use <- vat[, .(TM_ID = as.integer(TM_ID),
                    PLT_CN = sprintf("%.0f", as.numeric(PLT_CN)))]
fr <- merge(fr, vat_use, by = "TM_ID", all.x = TRUE)
fr <- merge(fr, all_v4[, .(PLT_CN, v4_class)], by = "PLT_CN", all.x = TRUE)
fr[, v4_class := fifelse(is.na(v4_class), "Unknown", v4_class)]

agg <- fr[, .(n_TM_IDs = .N,
               pixels = sum(Count, na.rm = TRUE),
               acres = sum(Count, na.rm = TRUE) * 0.222394),
           by = v4_class]
agg[, pct := round(100 * pixels / sum(pixels), 2)]
agg[, year := year]
agg[, state := state_short]
print(agg)

out_csv <- sprintf("%s/treemap_%s_%d_v2.csv", OUT, state_short, year)
fwrite(agg, out_csv)
cat(sprintf("saved %s\n", basename(out_csv)))
