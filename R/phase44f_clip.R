# Phase 44f: clip saved P(LSOG) raster to a Maine land outline (concave hull of FIA ME plots).
suppressPackageStartupMessages({ library(terra) })
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase44"
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
p<-rast(file.path(OUT,"ME_LSOG_probability_100m.tif")); names(p)<-"p_lsog"
fia<-vect("/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted/shp/FIA_ME_true.shp")
fia<-project(fia, crs(p))
hull<-hull(aggregate(fia), type="concave_ratio", param=0.30, allowHoles=FALSE)
hull<-buffer(hull, 2000)                       # 2 km pad so coastal land isn't clipped
log("hull area km2 %.0f", expanse(hull, unit="km")[1])
pc<-mask(crop(p, hull), hull)
writeRaster(pc, file.path(OUT,"ME_LSOG_probability_clipped_100m.tif"), overwrite=TRUE)
pv<-values(pc, mat=FALSE); pv<-pv[is.finite(pv)]
log("clipped P(LSOG) non-NA %d mean %.3f", length(pv), mean(pv))
pal<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
png(file.path(OUT,"Fig_prob_surface.png"), width=1500, height=1900, res=220)
par(mar=c(1.5,1.5,1.5,1))
plot(pc, col=pal, range=c(0,1), axes=FALSE, mar=c(1.5,1.5,1.5,4),
     plg=list(title="P(LSOG)", title.cex=0.9, cex=0.9))
lines(hull, col="grey30", lwd=0.6)
dev.off()
cat("PHASE 44f DONE\n")
