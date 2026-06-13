# Phase 44c: LSOG probability surface, with corrected Potapov reprojection.
suppressPackageStartupMessages({ library(randomForest); library(terra) })
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase44"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
rf<-readRDS("/users/PUOM0008/crsfaaron/LSOG/output_phase38/refined_rf.rds")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot0<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")
lcms_tsd<-ifel(is.na(yod)|yod==0, 40, 2023-yod); names(lcms_tsd)<-"lcms_tsd"
win<-project(as.polygons(ext(yod), crs=crs(yod)), crs(pot0))
pot<-project(crop(pot0, win), yod, method="bilinear"); names(pot)<-"potapov_rh95"   # reproject + align in one step
log("Potapov aligned: non-NA %.0f, median %.1f m", as.numeric(global(!is.na(pot),"sum")), as.numeric(global(pot,"median",na.rm=TRUE)))
stk<-c(pot, lcms_tsd)
p<-terra::predict(stk, rf, type="prob", index=2, na.rm=TRUE); names(p)<-"p_lsog"
p<-mask(p, pot>3)   # forest only
writeRaster(p, file.path(OUT,"ME_LSOG_probability_100m.tif"), overwrite=TRUE)
log("P(LSOG) non-NA %.0f  mean %.3f", as.numeric(global(!is.na(p),"sum")), as.numeric(global(p,"mean",na.rm=TRUE)))
thr<-as.numeric(global(p, fun=function(x) quantile(x, 1-0.141, na.rm=TRUE))[1,1])
writeRaster(p>=thr, file.path(OUT,"ME_LSOG_areamatched_100m.tif"), overwrite=TRUE, datatype="INT1U")
log("area-matched threshold %.2f -> mapped prevalence %.3f", thr, as.numeric(global(p>=thr,"mean",na.rm=TRUE)))
pal<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
png(file.path(OUT,"Fig_prob_surface.png"), width=1700, height=1900, res=220)
plot(p, col=pal, range=c(0,1), main="LSOG probability surface, Maine\n(refined balanced model: canopy height + LCMS Landsat disturbance)", cex.main=0.85)
dev.off()
png(file.path(OUT,"Fig_prob_surface_thumb.png"), width=620, height=700, res=80)
plot(p, col=pal, range=c(0,1), main="LSOG probability"); dev.off()
cat("PHASE 44c DONE\n")
