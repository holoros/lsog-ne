# Phase 30: drivers overlay = HCS harvest probability + slope (cost/logistics constraint) + disturbance
suppressPackageStartupMessages({library(terra);library(data.table);library(ggplot2);library(patchwork)})
terraOptions(memfrac=0.6)
PAY<-"/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/zenodo_upload/payload"
ENS<-"/users/PUOM0008/crsfaaron/LSOG/output_phase21/ENSEMBLE_prob_100m.tif"
DIST<-"/fs/scratch/PUOM0008/crsfaaron/TREEMAP_outputs_v5/p_disturbance_2022.tif"
DEM<-"/fs/scratch/PUOM0008/crsfaaron/FIA/asym_agb_analysis/rasters_rs/dem_maine_30m.tif"
H<-"/fs/scratch/PUOM0008/crsfaaron/conus_hcs/data/analytic/maps_conus_v5_fullCONUS"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase30";dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...)cat(sprintf(...),"\n")
ens<-rast(ENS);m1<-resample(rast(file.path(PAY,"M1_hagan_class_100m.tif")),ens,method="near");lsog<-(m1>=2)
onto<-function(path){r<-rast(path);e<-project(as.polygons(ext(ens),crs=crs(ens)),crs(r));rc<-crop(r,ext(e),snap="out");project(rc,ens,method="bilinear")}
cc<-onto(file.path(H,"conus_p_clearcut_annual_240m_2024_conus.tif"))
pa<-onto(file.path(H,"conus_p_partial_annual_240m_2024_conus.tif"))
hany<-cc+pa
dist<-onto(DIST)
demr<-rast(DEM);ed<-project(as.polygons(ext(ens),crs=crs(ens)),crs(demr));demc<-crop(demr,ext(ed),snap="out")
slp<-terrain(demc,"slope",unit="degrees");slope<-project(slp,ens,method="bilinear");slope[slope<0|slope>89]<-NA
names(hany)<-"hany";names(dist)<-"dist";names(slope)<-"slope"
D<-as.data.table(c(lsog,hany,dist,slope));setnames(D,c("lsog","hany","dist","slope"))
D<-D[!is.na(lsog)&!is.na(hany)&!is.na(dist)&!is.na(slope)]
D[,lsogf:=ifelse(lsog==1,"LSOG","Not LSOG")]
summ<-D[,.(n=.N,p_harvest_any=round(mean(hany),4),p_harvest_med=round(median(hany),4),
  slope_deg=round(mean(slope),2),slope_med=round(median(slope),2),disturbance=round(mean(dist),3)),by=lsogf][order(lsogf)]
fwrite(summ,file.path(OUT,"O1_means_by_lsog.csv"));print(summ)
terc<-function(x){q<-unique(quantile(x,c(0,1/3,2/3,1),na.rm=TRUE));if(length(q)<4)return(factor(rep("med",length(x)),levels=c("low","med","high")));cut(x,q,include.lowest=TRUE,labels=c("low","med","high"))}
D[,h_t:=terc(hany)][,s_t:=terc(slope)][,d_t:=terc(dist)]
eh<-D[,.(driver="harvest probability",rate=round(100*mean(lsog),1)),by=.(t=h_t)][order(t)]
es<-D[,.(driver="slope (cost/logistics)",rate=round(100*mean(lsog),1)),by=.(t=s_t)][order(t)]
ed<-D[,.(driver="disturbance probability",rate=round(100*mean(lsog),1)),by=.(t=d_t)][order(t)]
en<-rbindlist(list(eh,es,ed));fwrite(en,file.path(OUT,"O2_lsograte_by_tercile.csv"));print(en)
# ---- figure: 3-panel LSOG share by tercile ----
en[,t:=factor(t,levels=c("low","med","high"))]
en[,driver:=factor(driver,levels=c("harvest probability","slope (cost/logistics)","disturbance probability"))]
th<-theme_minimal(base_size=11)+theme(plot.title=element_text(face="bold",size=11),strip.text=element_text(face="bold",size=10),plot.background=element_rect(fill="white",color=NA),panel.grid.minor=element_blank(),legend.position="none")
p<-ggplot(en,aes(x=t,y=rate,fill=driver))+geom_col(width=0.7)+facet_wrap(~driver)+
  geom_text(aes(label=paste0(rate,"%")),vjust=-0.3,size=3.1)+
  scale_fill_manual(values=c("harvest probability"="#E64B35","slope (cost/logistics)"="#3C5488","disturbance probability"="#00A087"))+
  labs(title="Mapped LSOG is more merchantable AND on more constrained terrain",x="tercile (low to high)",y="% of forest mapped as LSOG")+
  expand_limits(y=max(en$rate)*1.15)+th
ggsave(file.path(OUT,"Fig_drivers.png"),p,width=8.4,height=3.4,dpi=300)
ggsave(file.path(OUT,"Fig_drivers_thumb.jpg"),p,width=8.4,height=3.4,dpi=70)
log("LSOG vs nonLSOG: harvestprob %.4f/%.4f | slope %.2f/%.2f deg | disturbance %.3f/%.3f",
  D[lsog==1,mean(hany)],D[lsog==0,mean(hany)],D[lsog==1,median(slope)],D[lsog==0,median(slope)],D[lsog==1,mean(dist)],D[lsog==0,mean(dist)])
cat("PHASE30 DONE\n")
