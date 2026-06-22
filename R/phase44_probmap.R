# =============================================================================
# Phase 44: LSOG probability-surface map. Apply the refined balanced model
# (canopy height + LCMS Landsat disturbance) over the Maine 100 m grid to produce
# a continuous P(LSOG) surface, the honest primary product rather than a hard
# class. Also show a binary map at the design-based area-matched threshold.
# Output: ~/LSOG/output_phase44/
# =============================================================================
suppressPackageStartupMessages({ library(randomForest); library(terra); library(ggplot2); library(tidyterra) })
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase44"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
rf<-readRDS("/users/PUOM0008/crsfaaron/LSOG/output_phase38/refined_rf.rds")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
pot0<-rast("/users/PUOM0008/crsfaaron/LSOG/data/rasters/potapov_2019/Forest_height_2019_NAM.tif")
# build predictor stack on the LCMS grid
lcms_tsd<-ifel(is.na(yod)|yod==0, 40, 2023-yod); names(lcms_tsd)<-"lcms_tsd"
pot<-resample(crop(pot0, project(as.polygons(ext(yod),crs=crs(yod)), crs(pot0))), yod, method="bilinear")
pot<-project(pot, yod); names(pot)<-"potapov_rh95"
stk<-c(pot, lcms_tsd)
# mask to forest (canopy height > 3 m) to avoid water/non-forest
stk<-mask(stk, pot>3, maskvalues=c(FALSE,NA))
p<-terra::predict(stk, rf, type="prob", index=2, na.rm=TRUE)
names(p)<-"p_lsog"
writeRaster(p, file.path(OUT,"ME_LSOG_probability_100m.tif"), overwrite=TRUE)
log("P(LSOG) surface written. mean %.2f", as.numeric(global(p,"mean",na.rm=TRUE)))
# binary at area-matched threshold (from phase39 ~0.98; recompute target prevalence 0.141)
qs<-global(p, fun=function(x) quantile(x, 1-0.141, na.rm=TRUE))
thr_area<-as.numeric(qs[1,1])
bin<-p>=thr_area; names(bin)<-"lsog_area_matched"
writeRaster(bin, file.path(OUT,"ME_LSOG_areamatched_100m.tif"), overwrite=TRUE, datatype="INT1U")
log("area-matched threshold %.2f -> mapped prevalence %.3f", thr_area, as.numeric(global(bin,"mean",na.rm=TRUE)))
# figure: probability surface
th<-theme_minimal(base_size=10)+theme(panel.grid=element_blank(),axis.text=element_blank(),
  axis.title=element_blank(),plot.background=element_rect(fill="white",color=NA),legend.key.width=unit(0.3,"cm"))
g<-ggplot()+geom_spatraster(data=p)+
  scale_fill_gradientn(colors=c("#4575b4","#74add1","#fee090","#f46d43","#a50026"), na.value="white", name="P(LSOG)")+
  labs(title="LSOG probability surface, Maine",
       subtitle="refined balanced model: canopy height + LCMS Landsat disturbance/continuity")+th
ggsave(file.path(OUT,"Fig_prob_surface.png"), g, width=7.2, height=7.0, dpi=300)
ggsave(file.path(OUT,"Fig_prob_surface_thumb.jpg"), g, width=7.2, height=7.0, dpi=70)
cat("PHASE 44 DONE\n")
