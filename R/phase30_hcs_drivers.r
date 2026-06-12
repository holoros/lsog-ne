# Phase 30: redo the drivers overlay with the REAL HCS v4 annual harvest-probability
# surfaces (240m, EPSG:5070) instead of the slope accessibility proxy.
suppressPackageStartupMessages({library(terra);library(data.table);library(ggplot2);library(ggsci);library(patchwork)})
terraOptions(memfrac=0.6)
PAY<-"/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/zenodo_upload/payload"
ENS<-"/users/PUOM0008/crsfaaron/LSOG/output_phase21/ENSEMBLE_prob_100m.tif"
DIST<-"/fs/scratch/PUOM0008/crsfaaron/TREEMAP_outputs_v5/p_disturbance_2022.tif"
H<-"/fs/scratch/PUOM0008/crsfaaron/conus_hcs/data/analytic/maps_conus_v5_fullCONUS"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase30";dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...)cat(sprintf(...),"\n")
ens<-rast(ENS);m1<-resample(rast(file.path(PAY,"M1_hagan_class_100m.tif")),ens,method="near");lsog<-(m1>=2)
onto<-function(path){r<-rast(path);e<-project(as.polygons(ext(ens),crs=crs(ens)),crs(r));rc<-crop(r,ext(e),snap="out");project(rc,ens,method="bilinear")}
cc<-onto(file.path(H,"conus_p_clearcut_annual_240m_2024_conus.tif"))
pa<-onto(file.path(H,"conus_p_partial_annual_240m_2024_conus.tif"))
sr<-onto(file.path(H,"conus_p_stand_replacement_annual_240m_2024_conus.tif"))
hany<-cc+pa
dist<-onto(DIST)
names(hany)<-"hany";names(sr)<-"sr";names(dist)<-"dist"
D<-as.data.table(c(lsog,hany,sr,dist));setnames(D,c("lsog","hany","sr","dist"))
D<-D[!is.na(lsog)&!is.na(hany)&!is.na(dist)]
D[,lsogf:=ifelse(lsog==1,"LSOG","Not LSOG")]
summ<-D[,.(n=.N,p_harvest_any=round(mean(hany),4),p_harvest_any_med=round(median(hany),4),
  p_standrepl=round(mean(sr),4),disturbance=round(mean(dist),3)),by=lsogf][order(lsogf)]
fwrite(summ,file.path(OUT,"O1_means_by_lsog.csv"));print(summ)
terc<-function(x){q<-unique(quantile(x,c(0,1/3,2/3,1),na.rm=TRUE));if(length(q)<4)return(factor(rep("med",length(x)),levels=c("low","med","high")));cut(x,q,include.lowest=TRUE,labels=c("low","med","high"))}
D[,h_t:=terc(hany)][,d_t:=terc(dist)]
en_h<-D[,.(lsog_rate=round(100*mean(lsog),1)),by=h_t][order(h_t)]
en_d<-D[,.(lsog_rate=round(100*mean(lsog),1)),by=d_t][order(d_t)]
fwrite(en_h,file.path(OUT,"O2_lsograte_by_harvestprob.csv"));fwrite(en_d,file.path(OUT,"O3_lsograte_by_disturbance.csv"))
cat("LSOG rate by HARVEST-PROB tercile:\n");print(en_h);cat("LSOG rate by DISTURBANCE tercile:\n");print(en_d)
log("median p_harvest_any: LSOG %.4f vs nonLSOG %.4f",D[lsog==1,median(hany)],D[lsog==0,median(hany)])
cors<-cor(D$hany,D$dist,method="spearman")
# ---- figure ----
en_h2<-copy(en_h)[,h_t:=factor(h_t,levels=c("low","med","high"))]
th<-theme_minimal(base_size=11)+theme(plot.title=element_text(face="bold",size=10),legend.position="top",legend.title=element_blank(),plot.background=element_rect(fill="white",color=NA),panel.grid.minor=element_blank())
cols<-c("LSOG"="#E64B35","Not LSOG"="#4DBBD5")
S<-D[sample(.N,min(.N,200000))]
pa1<-ggplot(S,aes(x=hany,fill=lsogf,color=lsogf))+geom_density(alpha=0.35,linewidth=0.5)+
  scale_fill_manual(values=cols)+scale_color_manual(values=cols)+
  coord_cartesian(xlim=c(0,as.numeric(quantile(S$hany,0.98,na.rm=TRUE))))+
  labs(title="(a) Annual harvest probability by class",x="modeled P(harvest), annual",y="density")+th
pb<-ggplot(en_h2,aes(x=h_t,y=lsog_rate))+geom_col(fill="#1A3D28",width=0.7)+
  geom_text(aes(label=paste0(lsog_rate,"%")),vjust=-0.3,size=3.2)+
  labs(title="(b) Mapped-LSOG share by harvest-probability tercile",x="harvest-probability tercile",y="% mapped LSOG")+
  th+theme(legend.position="none")+expand_limits(y=max(en_h2$lsog_rate)*1.12)
p<-pa1+pb+plot_annotation(title="Mapped LSOG sits where modeled harvest probability is highest, not lowest",theme=theme(plot.title=element_text(face="bold",size=12)))
ggsave(file.path(OUT,"Fig_drivers.png"),p,width=7.6,height=4.0,dpi=300)
ggsave(file.path(OUT,"Fig_drivers_thumb.jpg"),p,width=7.6,height=4.0,dpi=70)
cat("PHASE30 DONE\n")
