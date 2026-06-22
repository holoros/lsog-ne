# =============================================================================
# Phase 27: Why is LSOG where it is? Overlay the LSOG map with disturbance
# probability and slope (a harvest-accessibility proxy) over the Maine AOI.
# (Aaron's CONUS harvest-probability model has no data over the northern Maine
# unorganized townships, so slope stands in for harvestability/accessibility.)
# Hypothesis: LSOG persists disproportionately on steeper, less accessible ground
# and where natural disturbance is more likely. Output: ~/LSOG/output_phase27/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table); library(ggplot2); library(ggsci); library(patchwork) })
terraOptions(memfrac=0.6)
PAY<-"/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/zenodo_upload/payload"
ENS<-"/users/PUOM0008/crsfaaron/LSOG/output_phase21/ENSEMBLE_prob_100m.tif"
DIST<-"/fs/scratch/PUOM0008/crsfaaron/TREEMAP_outputs_v5/p_disturbance_2022.tif"
DEM<-"/fs/scratch/PUOM0008/crsfaaron/FIA/asym_agb_analysis/rasters_rs/dem_maine_30m.tif"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase27"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
ens<-rast(ENS); m1<-resample(rast(file.path(PAY,"M1_hagan_class_100m.tif")), ens, method="near")
lsog<-(m1>=2)
onto<-function(path,meth="bilinear"){ r<-rast(path)
  e<-project(as.polygons(ext(ens),crs=crs(ens)),crs(r)); rc<-crop(r,ext(e),snap="out"); project(rc,ens,method=meth) }
dist<-onto(DIST)
# slope (degrees) from the statewide Maine DEM, cropped then projected onto AOI
demr<-rast(DEM); ed<-project(as.polygons(ext(ens),crs=crs(ens)),crs(demr))
demc<-crop(demr, ext(ed), snap="out"); demc[demc < -100 | demc > 9000]<-NA
slp<-terrain(demc, "slope", unit="degrees")
slope<-project(slp, ens, method="bilinear")
slope[slope<0 | slope>89]<-NA
names(dist)<-"dist"; names(slope)<-"slope"
D<-as.data.table(c(ens,lsog,dist,slope)); setnames(D,c("ens","lsog","dist","slope"))
D<-D[!is.na(lsog)&!is.na(dist)&!is.na(slope)]
D[, lsogf:=factor(ifelse(lsog==1,"LSOG","Not LSOG"),levels=c("Not LSOG","LSOG"))]
log("pixels %d (LSOG %d)", nrow(D), sum(D$lsog==1))

summ<-D[, .(n=.N, disturbance_prob=round(mean(dist),3), slope_deg=round(mean(slope),2),
            slope_median=round(median(slope),2)), by=lsogf][order(lsogf)]
fwrite(summ, file.path(OUT,"O1_drivers_by_lsog.csv")); print(summ)
cors<-data.table(driver=c("disturbance prob","slope"),
  spearman_with_ensemble=round(c(cor(D$ens,D$dist,method="spearman"),cor(D$ens,D$slope,method="spearman")),3))
fwrite(cors, file.path(OUT,"O2_ensemble_driver_cor.csv")); print(cors)
# LSOG enrichment by slope tercile (accessibility) and disturbance tercile
terc<-function(x){q<-unique(quantile(x,c(0,1/3,2/3,1),na.rm=TRUE)); if(length(q)<4) return(factor(rep("med",length(x)),levels=c("low","med","high"))); cut(x,q,include.lowest=TRUE,labels=c("low","med","high"))}
D[, slope_t:=terc(slope)][, dist_t:=terc(dist)]
en_s<-D[, .(lsog_rate=round(100*mean(lsog),1)), by=slope_t][order(slope_t)]
en_d<-D[, .(lsog_rate=round(100*mean(lsog),1)), by=dist_t][order(dist_t)]
fwrite(en_s, file.path(OUT,"O3_lsograte_by_slope.csv")); fwrite(en_d, file.path(OUT,"O4_lsograte_by_disturbance.csv"))
cat("LSOG rate by slope tercile:\n"); print(en_s); cat("LSOG rate by disturbance tercile:\n"); print(en_d)

set.seed(1); S<-D[sample(.N, min(.N,120000))]
pair<-c("Not LSOG"="#9aa0a6","LSOG"="#1B9E9E")
mk<-function(y,lab,ymax=NA){ ggplot(S, aes(lsogf, get(y), fill=lsogf))+
  geom_violin(scale="width",trim=TRUE,color=NA,alpha=0.85)+geom_boxplot(width=0.16,outlier.shape=NA,fill="white",alpha=0.6)+
  scale_fill_manual(values=pair,guide="none")+coord_cartesian(ylim=c(NA,ymax))+
  labs(title=lab,x=NULL,y=NULL)+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),plot.title=element_text(size=10,face="bold")) }
p<-mk("dist","(a) Disturbance probability")+mk("slope","(b) Slope, degrees (accessibility proxy)",ymax=quantile(S$slope,0.98,na.rm=TRUE))+
  plot_annotation(title="LSOG concentrates on steeper, less accessible, more disturbance-prone ground",
                  theme=theme(plot.title=element_text(face="bold",size=11)))
ggsave(file.path(OUT,"Fig_drivers.png"), p, width=7.2, height=4.0, dpi=300)
ggsave(file.path(OUT,"Fig_drivers_thumb.jpg"), p, width=7.2, height=4.0, dpi=70)
cat("PHASE 27 DONE\n")
