# Figure 1 re-render (2026-10-19): legibility pass on R/phase41_datamap.R.
# FIA plots drawn ONLY at public, perturbed FUZZ.LAT/FUZZ.LON. No shapefiles written.
# Changes vs phase41: no in-figure title/subtitle (caption carries it), legend added,
# UTM 19N projection, larger type, scale bar and north arrow. 6.5 x 7.6 in, 300 dpi.
suppressPackageStartupMessages({library(sf);library(data.table);library(ggplot2);library(ggspatial)})
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/2026-11-14_fig123-rerender/out"
# November 14, 2026: draw the 3,125 forested plots of evaluation 232301 scored in the analysis (Table 1), at the PUBLIC
# coordinates of the FIA DataMart PLOT table. Only the plot identifiers are read from the label file.
cn<-fread("/users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv",select="PLT_CN",colClasses="character")
pl<-fread("/users/PUOM0008/crsfaaron/fia_data/ME_PLOT.csv",select=c("CN","LAT","LON"),colClasses=list(character="CN"))
xy<-pl[CN %in% cn$PLT_CN & !is.na(LAT), .(PLT_CN=CN, lat=LAT, lon=LON)]
fia<-st_transform(st_as_sf(xy,coords=c("lon","lat"),crs=4269),26919)
erm<-fread(file.path(RES,"ERM_ME_Plots.csv"),encoding="Latin-1"); nAll<-nrow(erm); nResAll<-length(unique(erm$EcoRName)); erm<-erm[!is.na(as.numeric(Latitude))]
ermsf<-st_transform(st_as_sf(erm[,.(EcoRName,lat=as.numeric(Latitude),lon=as.numeric(Longitude))],coords=c("lon","lat"),crs=4269),26919)
bx<-fread(file.path(RES,"baxter_coords_clean.csv"))
bxsf<-st_transform(st_as_sf(bx,coords=c("lon","lat"),crs=4269),26919)
me<-st_transform(st_as_sf(maps::map("state","maine",plot=FALSE,fill=TRUE)),26919)
br<-ermsf[ermsf$EcoRName=="Big Reed Forest Reserve",]; oth<-ermsf[ermsf$EcoRName!="Big Reed Forest Reserve",]
nF<-nrow(fia); nE<-nrow(oth); nR<-length(unique(oth$EcoRName)); nB<-nrow(bxsf); nBR<-nrow(br)
lab<-c(F=sprintf("US Forest Service FIA plots, public coordinates (n = %s)",format(nF,big.mark=",")),
       E=sprintf("MNAP/TNC reserve plots (n = %s, %d reserves)",format(nE,big.mark=","),nR),
       B=sprintf("Baxter SFMA CFI plots (n = %d)",nB),
       R=sprintf("Big Reed Forest Reserve plots (n = %d)",nBR))
pts<-rbind(cbind(st_coordinates(fia),k="F"),cbind(st_coordinates(oth),k="E"),cbind(st_coordinates(bxsf),k="B"),cbind(st_coordinates(br),k="R"))
pts<-data.frame(X=as.numeric(pts[,1]),Y=as.numeric(pts[,2]),k=factor(pts[,3],levels=c("F","E","B","R")))
pts<-pts[order(pts$k),]
cr<-st_coordinates(st_centroid(st_union(br)))
p<-ggplot()+geom_sf(data=me,fill="grey97",color="grey35",linewidth=0.35)+
  geom_point(data=pts,aes(X,Y,color=k,shape=k,size=k,alpha=k))+
  annotate("text",x=cr[1]+12000,y=cr[2]+4000,label="Big Reed",hjust=0,size=3.6,color="#B2182B",fontface="bold")+
  scale_color_manual(values=c(F="grey45",E="#1B9E9E",B="#E18727",R="#B2182B"),labels=lab,name=NULL)+
  scale_shape_manual(values=c(F=16,E=16,B=17,R=18),labels=lab,name=NULL)+
  scale_size_manual(values=c(F=0.45,E=1.4,B=1.6,R=2.6),labels=lab,name=NULL)+
  scale_alpha_manual(values=c(F=0.6,E=0.9,B=0.95,R=1),labels=lab,name=NULL)+
  guides(color=guide_legend(ncol=1,override.aes=list(size=c(2.2,2.6,2.8,3.4),alpha=1)))+
  annotation_scale(location="br",width_hint=0.25,text_cex=0.9,style="ticks",line_width=0.6)+
  annotation_north_arrow(location="tl",height=unit(1.0,"cm"),width=unit(0.8,"cm"),style=north_arrow_orienteering(text_size=8))+
  coord_sf(crs=26919,datum=4326,expand=TRUE)+
  scale_x_continuous(breaks=seq(-71,-67,1))+scale_y_continuous(breaks=seq(43,47,1))+
  theme_bw(base_size=12)+
  theme(panel.grid=element_line(color="grey92",linewidth=0.3),axis.title=element_blank(),
        axis.text=element_text(size=10.5,color="grey20"),legend.position="bottom",
        legend.text=element_text(size=10.5),legend.key.height=unit(0.45,"cm"),
        legend.margin=margin(2,2,2,2),plot.margin=margin(4,8,4,4))
ggsave(file.path(OUT,"2026-11-14_fig1-datamap_REVIEW.png"),p,width=6.5,height=7.6,dpi=300,device=ragg::agg_png,bg="white")
ggsave(file.path(OUT,"2026-11-14_fig1-datamap_REVIEW.pdf"),p,width=6.5,height=7.6,bg="white")
cat(sprintf("counts FIA %d | ERM %d in %d | Baxter %d | BigReed %d | ERM rows in file %d in %d reserves\n",nF,nE,nR,nB,nBR,nAll,nResAll)); cat("FIG1 DONE\n")
