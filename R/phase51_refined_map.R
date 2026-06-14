# Phase 51: refined definitive LSOG map. Smoother Maine outline, and the named
# reference reserves Hagan-style work focuses on overlaid: the MNAP/TNC ecological
# reserve network, Baxter State Park CFI, and Big Reed Forest Reserve labeled.
suppressPackageStartupMessages({ library(terra) }); terraOptions(memfrac=0.6)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase46")
SHP<-file.path(B,"data/validation_restricted/shp")
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
emean<-rast(file.path(OUT,"ENSEMBLE_mean_P_100m.tif")); names(emean)<-"P"
esd  <-rast(file.path(OUT,"ENSEMBLE_sd_P_100m.tif"));   names(esd)<-"SD"
res<-project(vect(file.path(SHP,"MNAP_TNC_reserves.shp")), crs(emean))
bax<-project(vect(file.path(SHP,"Baxter_SFMA.shp")),       crs(emean))
fia<-project(vect(file.path(SHP,"FIA_ME_true.shp")),       crs(emean))
bigreed<-res[res$EcoRName=="Big Reed Forest Reserve",]
log("reserves=%d  baxter=%d  bigreed plots=%d", nrow(res), nrow(bax), nrow(bigreed))

## smoother Maine outline from FIA + reserve + baxter points
allpts<-rbind(fia[,0], res[,0], bax[,0])
hull<-buffer(hull(aggregate(allpts), type="concave_ratio", param=0.62, allowHoles=FALSE), 1500)
cl<-function(r) mask(crop(r,hull),hull)
pc<-cl(emean); uc<-cl(esd)
sv<-values(esd,mat=FALSE); sv<-sv[is.finite(sv)]
brc<-crds(centroids(aggregate(bigreed))); baxc<-crds(centroids(aggregate(bax)))

palP<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
palU<-colorRampPalette(c("#ffffe5","#fee391","#fe9929","#cc4c02","#662506"))(100)
ovl<-function(){
  plot(res, add=TRUE, col=NA, border="#08519c", lwd=0.4)
  points(res, pch=16, cex=0.18, col="#0b3d91")
  points(bax, pch=17, cex=0.25, col="#b35806")
  points(bigreed, pch=16, cex=0.35, col="black")
  lines(hull, col="grey25", lwd=0.8)
}
png(file.path(OUT,"Fig_refined_map.png"), width=2700, height=1850, res=210)
par(mfrow=c(1,2), mar=c(0.6,0.6,2.4,4.2), xpd=NA)
plot(pc, col=palP, range=c(0,1), axes=FALSE, box=FALSE, mar=c(0.6,0.6,2.4,4.2),
     main="(a) Ensemble probability of LSOG", cex.main=1.0,
     plg=list(title="P(LSOG)", title.cex=0.8, cex=0.8))
ovl(); text(brc[1], brc[2], "Big Reed", pos=4, cex=0.85, font=2, col="black")
text(baxc[1], baxc[2], "Baxter", pos=4, cex=0.8, font=2, col="#7a3b04")
legend("bottomleft", c("ecological reserves","Baxter SFMA CFI","Big Reed Reserve"),
       pch=c(16,17,16), col=c("#0b3d91","#b35806","black"), pt.cex=c(0.7,0.8,0.95), cex=0.78, bty="n")
plot(uc, col=palU, range=c(0,max(sv)), axes=FALSE, box=FALSE, mar=c(0.6,0.6,2.4,4.2),
     main="(b) Across-model uncertainty (SD)", cex.main=1.0,
     plg=list(title="SD", title.cex=0.8, cex=0.8))
lines(hull, col="grey25", lwd=0.8)
dev.off()
log("PHASE 51 DONE")
