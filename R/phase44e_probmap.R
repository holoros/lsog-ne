# Phase 44e: LSOG probability surface. Fix: global() lacks "median"/custom fun -> use values().
suppressPackageStartupMessages({ library(randomForest); library(terra) })
terraOptions(memfrac=0.6)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase44"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
rf<-readRDS("/users/PUOM0008/crsfaaron/LSOG/output_phase38/refined_rf.rds")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot0<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")
log("rasters loaded")
lcms_tsd<-ifel(is.na(yod)|yod==0, 40, 2023-yod); names(lcms_tsd)<-"lcms_tsd"
win<-project(as.polygons(ext(yod), crs=crs(yod)), crs(pot0))
pot<-project(crop(pot0, win), yod, method="bilinear"); names(pot)<-"potapov_rh95"
potv<-values(pot, mat=FALSE); potv<-potv[is.finite(potv)]
log("Potapov aligned: non-NA %d median %.1f", length(potv), as.numeric(median(potv)))
stk<-c(pot, lcms_tsd); names(stk)<-c("potapov_rh95","lcms_tsd")
predfun<-function(model, data, ...) predict(model, data, type="prob")[,"LSOG"]
p<-terra::predict(stk, rf, fun=predfun, na.rm=TRUE,
                  filename=file.path(OUT,"ME_LSOG_probability_raw_100m.tif"), overwrite=TRUE)
names(p)<-"p_lsog"
p<-mask(p, pot>3)   # forest only
writeRaster(p, file.path(OUT,"ME_LSOG_probability_100m.tif"), overwrite=TRUE)
pv<-values(p, mat=FALSE); pv<-pv[is.finite(pv)]
log("P(LSOG) non-NA %d  mean %.3f", length(pv), mean(pv))
thr<-as.numeric(quantile(pv, 1-0.141))   # area-matched to design-based 14.1% prevalence
am<-p>=thr
writeRaster(am, file.path(OUT,"ME_LSOG_areamatched_100m.tif"), overwrite=TRUE, datatype="INT1U")
log("area-matched threshold %.3f -> mapped prevalence %.3f", thr, mean(pv>=thr))
pal<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
png(file.path(OUT,"Fig_prob_surface.png"), width=1700, height=1900, res=220)
plot(p, col=pal, range=c(0,1),
     main="LSOG probability surface, Maine\n(refined balanced model: canopy height + LCMS Landsat disturbance)",
     cex.main=0.85)
dev.off()
png(file.path(OUT,"Fig_prob_surface_thumb.png"), width=640, height=720, res=80)
plot(p, col=pal, range=c(0,1), main="P(LSOG)"); dev.off()
cat("PHASE 44e DONE\n")
