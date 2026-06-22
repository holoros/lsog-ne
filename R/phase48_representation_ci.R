# Phase 48: design-based true-LSOG representation by forest type and ecoregion
# WITH 95% CIs (ratio-estimator delta method, states pooled as independent strata),
# plus design-based "% disturbed since 1985" by state with CI. Adapts phase33.
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table) })
terraOptions(memfrac=0.5)
WD<-"/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"; DB<-"/users/PUOM0008/crsfaaron/fia_data"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase48"; dir.create(OUT,showWarnings=FALSE)
yrs0<-1985:2023; HEAVY<-c(2,6,7,8,9,13); LATE<-c(261,97,95,94,241,318,531,371,129,833)
states<-c("ME","NH","VT","NY"); tiledir<-function(st) if(st=="ME") file.path(WD,"aoi") else file.path(WD,paste0("aoi_",st))
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
ECO<-vect(file.path(WD,"ecoregion","us_eco_l3.shp")); namecol<-intersect(c("US_L3NAME","L3_KEY","NA_L3NAME"),names(ECO))[1]
ftgrp<-function(f){ g<-rep("Other",length(f))
  g[f>=101&f<=119]<-"White/red/jack pine"; g[f>=121&f<=129]<-"Spruce/fir"; g[f>=381&f<=399]<-"Other softwood"
  g[f>=401&f<=409]<-"Oak/pine"; g[f>=501&f<=599]<-"Oak/hickory"; g[f>=701&f<=722]<-"Elm/ash/cottonwood"
  g[f>=801&f<=809]<-"Maple/beech/birch"; g[f>=901&f<=909]<-"Aspen/birch"; g }
# variance column extractor (rFIA naming varies)
getcol<-function(d,cands){ nm<-intersect(cands,names(d)); if(length(nm)) d[[nm[1]]] else rep(NA_real_,nrow(d)) }
pp<-function(a){ a<-as.data.table(a); a<-a[YEAR==max(YEAR)]
  a[, AR:=getcol(a,c("AREA_TOTAL","AREA"))]
  a[, VR:=getcol(a,c("AREA_TOTAL_VAR","AREA_VAR"))]
  if(all(is.na(a$VR))){ se<-getcol(a,c("AREA_TOTAL_SE","AREA_SE")); a[, VR:=se^2] }
  a }

allc<-list()
for(st in states){
  fls<-file.path(tiledir(st),sprintf("lcms_%d.tif",yrs0)); fls<-fls[file.exists(fls)]
  yrs<-as.integer(gsub(".*lcms_|\\.tif","",fls)); stk<-rast(fls)
  yod<-rast(stk,nlyr=1); values(yod)<-0
  for(i in seq_along(yrs)) yod<-max(yod,(stk[[i]] %in% HEAVY)*yrs[i],na.rm=TRUE)
  yodf<-focal(yod,w=3,fun="max",na.policy="omit")
  fia<-readFIA(DB,states=st)
  tr<-as.data.table(fia$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA,BA=0.005454*DIA^2*TPA_UNADJ)]
  liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2&DIA>=5]
  agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE),BA_large=sum(BA[DIA>=16],na.rm=TRUE),BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)),by=.(PLT_CN,CONDID)]
  sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)),by=.(PLT_CN,CONDID)]; agg<-merge(agg,sn,by=c("PLT_CN","CONDID"),all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
  cond<-as.data.table(fia$COND); cond<-merge(cond,agg,by=c("PLT_CN","CONDID"),all.x=TRUE)
  for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)),(v):=0]
  cond[, a1:=as.integer(BA_large>=30)][, a2:=as.integer(BA_snag>=5)][, a3:=as.integer(BA_live>0&BA_late/BA_live>=0.5)]
  cond[, a4_fia:=as.integer((is.na(TRTCD1)|TRTCD1!=10)&(is.na(STDORGCD)|STDORGCD!=1))]
  P<-as.data.table(fia$PLOT); ecn<-intersect(c("ECOSUBCD","ecosubcd"),names(P)); P[, ECO:=if(length(ecn)) as.character(get(ecn[1])) else NA_character_]
  plt<-P[, .(CN,LON,LAT,ECO)][!is.na(LON)&!is.na(LAT)]
  pv<-project(vect(plt[, .(CN,LON,LAT)],geom=c("LON","LAT"),crs="EPSG:4269"),crs(yodf)); plt[, yodh:=terra::extract(yodf,pv)[,2]]
  plt[, in_aoi:=as.integer(!is.na(yodh))]
  pe<-project(vect(plt[, .(CN,LON,LAT)],geom=c("LON","LAT"),crs="EPSG:4269"),crs(ECO)); ex<-terra::extract(ECO[,namecol],pe); plt[, ECO_L3:=ex[[2]]]
  cond<-merge(cond,plt[, .(PLT_CN=CN,yodh,in_aoi,ECO_L3)],by="PLT_CN",all.x=TRUE); cond[is.na(in_aoi),in_aoi:=0]
  cond[, ECO_L3:=ifelse(is.na(ECO_L3),"Unknown",ECO_L3)]
  cond[, a4:=ifelse(in_aoi==1,as.integer(yodh==0),a4_fia)]
  cond[, c4:=as.integer(a1+a2+a3+a4>=4)]
  cond[, disturbed:=as.integer(in_aoi==1 & yodh>0)]
  cond[, FORTGRP:=ftgrp(FORTYPCD)][, STATEAB:=st]
  fia$COND<-as.data.frame(cond)
  allc[[st]]<-list(
    num_ft=pp(rFIA::area(fia, areaDomain=c4==1,       grpBy=FORTGRP, variance=TRUE, totals=TRUE)),
    den_ft=pp(rFIA::area(fia,                          grpBy=FORTGRP, variance=TRUE, totals=TRUE)),
    num_es=pp(rFIA::area(fia, areaDomain=c4==1,       grpBy=ECO_L3,  variance=TRUE, totals=TRUE)),
    den_es=pp(rFIA::area(fia,                          grpBy=ECO_L3,  variance=TRUE, totals=TRUE)),
    dist_num=pp(rFIA::area(fia, areaDomain=disturbed==1, variance=TRUE, totals=TRUE)),
    dist_den=pp(rFIA::area(fia, areaDomain=in_aoi==1,     variance=TRUE, totals=TRUE)))
  log("%s done", st); rm(stk,yod,yodf); gc()
}
# pool numerator/denominator AREA and VAR across states (independent strata)
pool<-function(which,key){ rbindlist(lapply(states,function(s){d<-allc[[s]][[which]]
  if(is.null(key)) d[, .(strat="all",AR,VR)] else d[, .(strat=get(key),AR,VR)]}))[, .(AR=sum(AR,na.rm=TRUE),VR=sum(VR,na.rm=TRUE)),by=strat] }
ci_ratio<-function(num,den){ # returns pct, lo, hi via delta method
  m<-merge(den,num,by="strat",all.x=TRUE,suffixes=c("_d","_n")); m[is.na(AR_n),`:=`(AR_n=0,VR_n=0)]
  m[, pct:=100*AR_n/AR_d]
  m[, se:=100*sqrt(pmax(VR_n,0)/AR_d^2 + AR_n^2*pmax(VR_d,0)/AR_d^4)]
  m[, lo:=pmax(0,pct-1.96*se)][, hi:=pct+1.96*se]; m }
ft<-ci_ratio(num=pool("num_ft","FORTGRP"),den=pool("den_ft","FORTGRP"))
es<-ci_ratio(num=pool("num_es","ECO_L3"), den=pool("den_es","ECO_L3"))
di<-ci_ratio(num=pool("dist_num",NULL),   den=pool("dist_den",NULL))
fmt<-function(d) d[, .(strat, total_kac=round(AR_d/1000,0), pct=round(pct,1), lo=round(lo,1), hi=round(hi,1))][order(-total_kac)]
fwrite(fmt(ft), file.path(OUT,"C1_foresttype_ci.csv")); fwrite(fmt(es), file.path(OUT,"C2_ecoregion_ci.csv"))
log("=== forest type ==="); print(fmt(ft)); log("=== ecoregion ==="); print(fmt(es))
# disturbance by state with CI (per-state, design-based)
dist_state<-rbindlist(lapply(states,function(s){n<-allc[[s]]$dist_num; d<-allc[[s]]$dist_den
  pct<-100*sum(n$AR)/sum(d$AR); se<-100*sqrt(sum(n$VR)/sum(d$AR)^2 + sum(n$AR)^2*sum(d$VR)/sum(d$AR)^4)
  data.table(state=s,pct=round(pct,1),lo=round(max(0,pct-1.96*se),1),hi=round(pct+1.96*se,1))}))
fwrite(dist_state, file.path(OUT,"C3_disturbed_by_state_ci.csv")); log("=== disturbed since 1985 ==="); print(dist_state)
cat("PHASE 48 DONE\n")
