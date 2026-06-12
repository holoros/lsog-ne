# =============================================================================
# Phase 34: true-LSOG representation by ECOREGION. FIA tables here carry no
# ecoregion field, so we spatially join FIA plot coordinates to EPA Level III
# ecoregions and recompute design-based true-LSOG (all four axes, LCMS A4) share
# within each ecoregion across ME/NH/VT/NY. Output: ~/LSOG/output_phase31/R7_*
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table) })
terraOptions(memfrac=0.5)
WD <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"; DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase31"
ECO <- vect(file.path(WD,"ecoregion","us_eco_l3.shp"))
namecol <- intersect(c("US_L3NAME","L3_KEY","NA_L3NAME"), names(ECO))[1]
yrs0 <- 1985:2023; HEAVY <- c(2,6,7,8,9,13); LATE <- c(261,97,95,94,241,318,531,371,129,833)
states <- c("ME","NH","VT","NY"); tiledir <- function(st) if (st=="ME") file.path(WD,"aoi") else file.path(WD, paste0("aoi_",st))
log <- function(...) cat(sprintf(...), "\n")
ftgrp <- function(f){ g<-rep("Other",length(f))
  g[f>=101&f<=119]<-"White/red/jack pine"; g[f>=121&f<=129]<-"Spruce/fir"; g[f>=381&f<=399]<-"Other softwood"
  g[f>=401&f<=409]<-"Oak/pine"; g[f>=501&f<=599]<-"Oak/hickory"; g[f>=701&f<=722]<-"Elm/ash/cottonwood"
  g[f>=801&f<=809]<-"Maple/beech/birch"; g[f>=901&f<=909]<-"Aspen/birch"; g }

num_l<-list(); den_l<-list(); presence<-list()
for (st in states) {
  fls<-file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0)); fls<-fls[file.exists(fls)]
  yrs<-as.integer(gsub(".*lcms_|\\.tif","", fls)); stk<-rast(fls)
  yod<-rast(stk,nlyr=1); values(yod)<-0
  for (i in seq_along(yrs)) yod<-max(yod,(stk[[i]] %in% HEAVY)*yrs[i],na.rm=TRUE)
  yodf<-focal(yod,w=3,fun="max",na.policy="omit")
  fia<-readFIA(DB,states=st)
  tr<-as.data.table(fia$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA,BA=0.005454*DIA^2*TPA_UNADJ)]
  liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2&DIA>=5]
  agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE),BA_large=sum(BA[DIA>=16],na.rm=TRUE),BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)),by=.(PLT_CN,CONDID)]
  sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)),by=.(PLT_CN,CONDID)]; agg<-merge(agg,sn,by=c("PLT_CN","CONDID"),all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
  cond<-as.data.table(fia$COND); cond<-merge(cond,agg,by=c("PLT_CN","CONDID"),all.x=TRUE)
  for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)),(v):=0]
  cond[, a1:=as.integer(BA_large>=30)][, a2:=as.integer(BA_snag>=5)][, a3:=as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
  cond[, a4_fia:=as.integer((is.na(TRTCD1)|TRTCD1!=10)&(is.na(STDORGCD)|STDORGCD!=1))]
  plt<-as.data.table(fia$PLOT)[, .(CN,LON,LAT)][!is.na(LON)&!is.na(LAT)]
  pts<-vect(plt,geom=c("LON","LAT"),crs="EPSG:4269")
  pv<-project(pts,crs(yodf)); plt[, yodh:=terra::extract(yodf,pv)[,2]]; plt[, in_aoi:=as.integer(!is.na(yodh))]
  pe<-project(pts,crs(ECO)); ex<-terra::extract(ECO[,namecol], pe); plt[, ECO_L3:=ex[[2]]]
  cond<-merge(cond,plt[, .(PLT_CN=CN,yodh,in_aoi,ECO_L3)],by="PLT_CN",all.x=TRUE); cond[is.na(in_aoi),in_aoi:=0]
  cond[, a4:=ifelse(in_aoi==1,as.integer(yodh==0),a4_fia)][, c4:=as.integer(a1+a2+a3+a4>=4)]
  cond[, ECO_L3:=ifelse(is.na(ECO_L3),"Unknown",ECO_L3)]
  fia$COND<-as.data.frame(cond)
  num<-as.data.table(rFIA::area(fia,areaDomain=c4==1,grpBy=ECO_L3)); num<-num[YEAR==max(YEAR)]
  den<-as.data.table(rFIA::area(fia,grpBy=ECO_L3)); den<-den[YEAR==max(YEAR)]
  ac<-function(d){a<-intersect(c("AREA_TOTAL","AREA"),names(d))[1]; d[, .(ECO_L3, area=get(a))]}
  num_l[[st]]<-ac(num); den_l[[st]]<-ac(den)
  presence[[st]]<-cond[, .(c4=sum(c4),n=.N), by=ECO_L3]
  rm(stk,yod,yodf); gc()
}
pool<-function(L) rbindlist(L)[, .(area=sum(area,na.rm=TRUE)), by=ECO_L3]
n<-pool(num_l); d<-pool(den_l)
es<-merge(d,n,by="ECO_L3",all.x=TRUE,suffixes=c("_tot","_lsog")); es[is.na(area_lsog),area_lsog:=0]
es[, true_lsog_pct:=round(100*area_lsog/area_tot,2)][, total_kac:=round(area_tot/1000,0)][, true_lsog_kac:=round(area_lsog/1000,1)]
es<-es[total_kac>=50]; setorder(es,-area_tot)
fwrite(es[, .(ecoregion_L3=ECO_L3,total_kac,true_lsog_pct,true_lsog_kac)], file.path(OUT,"R7_truelsog_by_ecoregion_L3.csv"))
pres<-rbindlist(presence)[, .(c4=sum(c4),n=sum(n)), by=ECO_L3][n>=20]
log("ecoregions (>=20 plots) with true LSOG present: %d of %d", sum(pres$c4>0), nrow(pres))
print(es[, .(ECO_L3,total_kac,true_lsog_pct,true_lsog_kac)])
cat("PHASE 34 DONE\n")
