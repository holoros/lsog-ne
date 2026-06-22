# =============================================================================
# Phase 40: Baxter SFMA CFI as a third independent reference and a continuity test.
# Baxter SFMA is structurally mature (98% of plots pass the large-tree axis) but
# actively managed. Does Hagan's canopy map flag it as LSOG (commission on managed
# big-tree forest), and does our LCMS continuity layer separate managed-mature
# from continuous old growth? Output: ~/LSOG/output_phase40/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table) })
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase40"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
log<-function(...) cat(sprintf(...),"\n")
hag<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")
b<-fread(file.path(RES,"baxter_coords_clean.csv"))
v<-vect(b, geom=c("lon","lat"), crs="EPSG:4269")
b[, hag_code:=terra::extract(hag, project(v,crs(hag)))[,2]]
b[, lcms_yod:=terra::extract(yod, project(v,crs(yod)))[,2]]
b[, potapov_rh95:=terra::extract(pot, project(v,crs(pot)))[,2]]
inA<-b[!is.na(hag_code)]
log("Baxter plots: %d  | inside Hagan AOI: %d", nrow(b), nrow(inA))
log("Hagan flags LSOG at Baxter (managed-mature): %.0f%%", 100*mean(inA$hag_code %in% c(2,3,4)))
log("Potapov median canopy height at Baxter: %.1f m", median(b$potapov_rh95, na.rm=TRUE))
log("LCMS: %% of Baxter with stand-replacing/harvest disturbance 1985-2023: %.0f%%",
    100*mean(b$lcms_yod>0, na.rm=TRUE))
dist<-b[lcms_yod>0]; log("   median time since disturbance where disturbed: %.0f yr", median(2023-dist$lcms_yod))
# the four-axis logic: structure passes (98% from tree scoring) but continuity (A4) fails where disturbed
log("Continuity axis (A4) pass at Baxter (no LCMS heavy disturbance): %.0f%%", 100*mean(b$lcms_yod==0 | is.na(b$lcms_yod)))
fwrite(b, file.path(OUT,"B1_baxter_map_sample.csv"))
cat("PHASE 40 DONE\n")
