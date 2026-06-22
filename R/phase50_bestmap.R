# Phase 50: definitive LSOG probability map. Takes the five-model ensemble
# (phase46b), calibrates the binary class to the design-based any-LSOG area
# (14.1%), archives the calibrated raster, and renders a clean 3-panel figure
# clipped to Maine: (a) ensemble probability, (b) across-model uncertainty,
# (c) design-based-calibrated any-LSOG class.
suppressPackageStartupMessages({ library(terra) }); terraOptions(memfrac=0.6)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase46")
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
emean<-rast(file.path(OUT,"ENSEMBLE_mean_P_100m.tif")); names(emean)<-"P"
esd  <-rast(file.path(OUT,"ENSEMBLE_sd_P_100m.tif"));   names(esd)<-"SD"
mv<-values(emean,mat=FALSE); mv<-mv[is.finite(mv)]
PREV<-0.141                                   # design-based any-LSOG prevalence
thr<-as.numeric(quantile(mv, 1-PREV))
bin<-emean>=thr; names(bin)<-"anylsog"
writeRaster(bin, file.path(OUT,"ENSEMBLE_anylsog_designcalibrated_100m.tif"), overwrite=TRUE, datatype="INT1U")
AC<-2.4710538/1e3   # 100m cell -> kacres? 1 cell=1ha=2.471 ac; /1e3 -> kac
ncell_lsog<-as.numeric(global(bin,"sum",na.rm=TRUE)[1,1]); ntot<-length(mv)
log("calibration threshold %.3f -> mapped any-LSOG prevalence %.3f (%.0f K ac)",
    thr, ncell_lsog/ntot, ncell_lsog*2.4710538/1000)

## clip to Maine outline (concave hull of true FIA coords)
fia<-project(vect(file.path(B,"data/validation_restricted/shp/FIA_ME_true.shp")), crs(emean))
hull<-buffer(hull(aggregate(fia),type="concave_ratio",param=0.30),2000); cl<-function(r) mask(crop(r,hull),hull)
pc<-cl(emean); uc<-cl(esd); bc<-cl(bin)
palP<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
palU<-colorRampPalette(c("#ffffe5","#fee391","#fe9929","#cc4c02","#662506"))(100)
sv<-values(esd,mat=FALSE); sv<-sv[is.finite(sv)]
png(file.path(OUT,"Fig_bestmap.png"), width=3050, height=1750, res=205)
par(mfrow=c(1,3), mar=c(1.4,1.4,2.6,3.4))
plot(pc,col=palP,range=c(0,1),axes=FALSE,main="(a) Ensemble P(LSOG)\nfive learners",cex.main=1,plg=list(title="P(LSOG)"));lines(hull,col="grey40",lwd=0.5)
plot(uc,col=palU,range=c(0,max(sv)),axes=FALSE,main="(b) Across-model uncertainty\nSD of 5 models",cex.main=1,plg=list(title="SD"));lines(hull,col="grey40",lwd=0.5)
plot(bc,col=c("grey88","#1b7837"),axes=FALSE,legend=FALSE,main="(c) Any-LSOG class\ncalibrated to design-based 14.1%",cex.main=1);lines(hull,col="grey40",lwd=0.5)
legend("bottomleft",fill=c("#1b7837","grey88"),legend=c("LSOG","non-LSOG"),bty="n",cex=1.0)
dev.off()
log("PHASE 50 DONE")
