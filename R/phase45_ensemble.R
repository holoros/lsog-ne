# Phase 45: three-map remote-sensing ensemble for the Comment.
# Independent RS operationalizations ONLY:
#   (1) Hagan airborne LiDAR classifier      class >= 2 = any-LSOG
#   (2) Potapov/GEDI spaceborne canopy height pLSOG >= area-matched threshold
#   (3) ORNL/Bruening mature+old-growth       strata >= 3 (mature or old-growth)
# TreeMap is EXCLUDED here (it is an FIA imputation -> design-based anchor, Section 5).
suppressPackageStartupMessages({ library(terra) })
terraOptions(memfrac=0.6)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase45"); dir.create(OUT,showWarnings=FALSE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}

hag<-rast(file.path(B,"output_phase10/C_hagan_class_100m.tif"))
can<-rast(file.path(B,"output_phase12/M2_v51gedi_pLSOG_100m.tif"))
orn<-rast(file.path(B,"output_phase45/ORNL_strata_aoi_100m.tif"))
orn<-ifel(orn==255, NA, orn)

hagL<-ifel(hag>=2, 1, 0)
cv<-values(can,mat=FALSE); cv<-cv[is.finite(cv)]
thr<-as.numeric(quantile(cv, 1-0.140)); canL<-ifel(can>=thr, 1, 0)
ornMOG<-ifel(orn>=3, 1, 0)        # mature + old-growth
ornOG <-ifel(orn==4, 1, 0)        # old-growth only
log("prevalence  Hagan %.3f | canopy %.3f (thr %.3f) | ORNL MOG %.3f | ORNL OG %.3f",
    as.numeric(global(hagL,"mean",na.rm=TRUE)), as.numeric(global(canL,"mean",na.rm=TRUE)), thr,
    as.numeric(global(ornMOG,"mean",na.rm=TRUE)), as.numeric(global(ornOG,"mean",na.rm=TRUE)))

# common footprint where all three present. ORNL old-growth (strata==4) is the
# comparable class; ORNL mature+OG (65%) is reported in text as further definitional spread.
ok<- !is.na(hagL) & !is.na(canL) & !is.na(ornOG)
H<-mask(hagL,ok,maskvalue=FALSE); C<-mask(canL,ok,maskvalue=FALSE); O<-mask(ornOG,ok,maskvalue=FALSE)
nmeth<-H+C+O; names(nmeth)<-"nmethods"
writeRaster(nmeth, file.path(OUT,"E_nmethods_3RS_100m.tif"), overwrite=TRUE, datatype="INT1U")
tb<-as.numeric(global(nmeth==0,"sum",na.rm=TRUE)); t1<-as.numeric(global(nmeth==1,"sum",na.rm=TRUE))
t2<-as.numeric(global(nmeth==2,"sum",na.rm=TRUE)); t3<-as.numeric(global(nmeth==3,"sum",na.rm=TRUE))
flagged<-t1+t2+t3
log("n-methods agreeing on LSOG: 0=%.0f 1=%.0f 2=%.0f 3=%.0f", tb,t1,t2,t3)
log("of union-flagged hectares: all-three %.1f%% | single-method %.1f%%", 100*t3/flagged, 100*t1/flagged)

# pairwise kappa helper
kap<-function(x,y){ a<-as.numeric(global(x==1&y==1,"sum",na.rm=TRUE)); b<-as.numeric(global(x==1&y==0,"sum",na.rm=TRUE))
  c_<-as.numeric(global(x==0&y==1,"sum",na.rm=TRUE)); d<-as.numeric(global(x==0&y==0,"sum",na.rm=TRUE)); n<-a+b+c_+d
  po<-(a+d)/n; pe<-((a+b)*(a+c_)+(c_+d)*(b+d))/n^2; c(kappa=(po-pe)/(1-pe), jaccard=a/(a+b+c_)) }
kHC<-kap(H,C); kHO<-kap(H,O); kCO<-kap(C,O)
log("kappa  Hagan-canopy %.3f | Hagan-ORNL %.3f | canopy-ORNL %.3f", kHC[1],kHO[1],kCO[1])
write.csv(data.frame(
  metric=c("hagan_prev","canopy_prev","ornl_mog_prev","ornl_og_prev",
           "kappa_hag_can","kappa_hag_ornl","kappa_can_ornl",
           "allthree_pct_of_flagged","single_pct_of_flagged"),
  value=round(c(as.numeric(global(H,"mean",na.rm=TRUE)),as.numeric(global(C,"mean",na.rm=TRUE)),
    as.numeric(global(O,"mean",na.rm=TRUE)),as.numeric(global(mask(ornOG,ok,maskvalue=FALSE),"mean",na.rm=TRUE)),
    kHC[1],kHO[1],kCO[1],100*t3/flagged,100*t1/flagged),3)),
  file.path(OUT,"E1_threemap_stats.csv"), row.names=FALSE)

# clip to Maine and render 4-panel (3 maps + consensus)
fia<-project(vect(file.path(B,"data/validation_restricted/shp/FIA_ME_true.shp")), crs(hag))
hull<-buffer(hull(aggregate(fia), type="concave_ratio", param=0.30), 2000)
cl<-function(r) mask(crop(r,hull),hull)
Hc<-cl(H); Cc<-cl(C); Oc<-cl(O); Nc<-cl(nmeth)
png(file.path(OUT,"Fig_ensemble.png"), width=3000, height=1750, res=205)
par(mfrow=c(1,4), mar=c(1,1,2.6,1)); bin<-c("grey88","#1b7837")
plot(Hc,col=bin,legend=FALSE,axes=FALSE,main="(a) Airborne LiDAR\n(Hagan) 21.9%",cex.main=1); lines(hull,col="grey40",lwd=0.5)
plot(Cc,col=bin,legend=FALSE,axes=FALSE,main="(b) Spaceborne canopy ht\n(Potapov/GEDI) 14.0%",cex.main=1); lines(hull,col="grey40",lwd=0.5)
plot(Oc,col=bin,legend=FALSE,axes=FALSE,main=sprintf("(c) ORNL old-growth\n(Bruening) %.1f%%",100*as.numeric(global(O,"mean",na.rm=TRUE))),cex.main=1); lines(hull,col="grey40",lwd=0.5)
plot(Nc,col=c("grey90","#fee08b","#fc8d59","#1a9850"),legend=FALSE,axes=FALSE,main="(d) Number of maps agreeing\non LSOG (0-3)",cex.main=1); lines(hull,col="grey40",lwd=0.5)
legend("bottomleft",fill=c("#1a9850","#fc8d59","#fee08b","grey90"),legend=c("3 maps","2 maps","1 map","0 maps"),bty="n",cex=1)
dev.off()
cat("PHASE 45 DONE\n")
