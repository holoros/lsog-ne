# =============================================================================
# Phase 35: sensitivity of true-LSOG to the A4 (LCMS continuity) definition.
# A reviewer will ask whether true-LSOG ~2-3% is an artifact of how we draw the
# continuity line. We vary three choices and recompute the design-based
# true-LSOG (all four axes) share per state:
#   base     : heavy disturbance {wind,Rx fire,wildfire,mechanical,tree removal,other loss},
#              full record 1985-2023, 3x3 focal (absorbs FIA fuzzing)
#   strict_SR: stand-replacing only {hurricane,wildfire,mechanical,tree removal}
#              (drops Rx fire + other loss), full record, 3x3 focal
#   recent20 : base classes, but only disturbance in the last 20 yr (2004-2023)
#   local    : base classes, full record, NO focal (plot pixel only; stricter)
#   anyloss  : ANY detected loss/stress {1..13}, full record, 3x3 focal (most strict)
# Output: ~/LSOG/output_phase31/R8_a4_sensitivity.csv
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table) })
terraOptions(memfrac=0.5)
WD <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"; DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase31"
yrs0 <- 1985:2023; LATE <- c(261,97,95,94,241,318,531,371,129,833)
states <- c("ME","NH","VT","NY"); tiledir <- function(st) if (st=="ME") file.path(WD,"aoi") else file.path(WD, paste0("aoi_",st))
log <- function(...) cat(sprintf(...), "\n")
variants <- list(
  base     = list(cls=c(2,6,7,8,9,13), ylo=1985, focal=3),
  strict_SR= list(cls=c(2,7,8,9),      ylo=1985, focal=3),
  recent20 = list(cls=c(2,6,7,8,9,13), ylo=2004, focal=3),
  local    = list(cls=c(2,6,7,8,9,13), ylo=1985, focal=1),
  anyloss  = list(cls=1:13,            ylo=1985, focal=3)
)
res <- list()
for (st in states) {
  log("==== %s ====", st)
  fls<-file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0)); fls<-fls[file.exists(fls)]
  yrs<-as.integer(gsub(".*lcms_|\\.tif","", fls)); stk<-rast(fls)
  # structural axes (deterministic, computed once)
  fia<-readFIA(DB,states=st)
  tr<-as.data.table(fia$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA,BA=0.005454*DIA^2*TPA_UNADJ)]
  liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2&DIA>=5]
  agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE),BA_large=sum(BA[DIA>=16],na.rm=TRUE),BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)),by=.(PLT_CN,CONDID)]
  sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)),by=.(PLT_CN,CONDID)]; agg<-merge(agg,sn,by=c("PLT_CN","CONDID"),all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
  cond0<-as.data.table(fia$COND); cond0<-merge(cond0,agg,by=c("PLT_CN","CONDID"),all.x=TRUE)
  for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond0[is.na(get(v)),(v):=0]
  cond0[, a1:=as.integer(BA_large>=30)][, a2:=as.integer(BA_snag>=5)][, a3:=as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
  cond0[, a4_fia:=as.integer((is.na(TRTCD1)|TRTCD1!=10)&(is.na(STDORGCD)|STDORGCD!=1))]
  plt<-as.data.table(fia$PLOT)[, .(CN,LON,LAT)][!is.na(LON)&!is.na(LAT)]
  pts<-project(vect(plt,geom=c("LON","LAT"),crs="EPSG:4269"),crs(stk))
  for (vn in names(variants)) {
    v<-variants[[vn]]
    dist<-rast(stk,nlyr=1); values(dist)<-0
    for (i in seq_along(yrs)) if (yrs[i]>=v$ylo) dist<-max(dist, (stk[[i]] %in% v$cls), na.rm=TRUE)
    dd<-if (v$focal>1) focal(dist,w=v$focal,fun="max",na.policy="omit") else dist
    pv<-data.table(PLT_CN=plt$CN, disturbed=terra::extract(dd,pts)[,2])
    cond<-merge(copy(cond0), pv, by="PLT_CN", all.x=TRUE)
    cond[, in_aoi:=as.integer(!is.na(disturbed))]
    cond[, a4:=ifelse(in_aoi==1, as.integer(disturbed==0), a4_fia)]
    cond[, c4:=as.integer(a1+a2+a3+a4>=4)]
    fia$COND<-as.data.frame(cond)
    den<-as.data.table(rFIA::area(fia,variance=TRUE)); den<-den[YEAR==max(YEAR)]
    da<-intersect(c("AREA_TOTAL","AREA"),names(den))[1]; denom<-den[[da]]
    a<-as.data.table(rFIA::area(fia,areaDomain=c4==1,variance=TRUE)); a<-a[YEAR==max(YEAR)]
    av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
    pct<-100*a[[da]]/denom; se<-100*sqrt(a[[av]])/denom
    res[[paste(st,vn)]]<-data.table(state=st, variant=vn,
      a4_pass_pct=round(100*mean(cond[in_aoi==1]$a4),1),
      true_lsog_pct=round(pct,2), lo=round(max(0,pct-1.96*se),2), hi=round(pct+1.96*se,2))
    log("  %-9s A4=%.1f%%  trueLSOG=%.2f%%", vn, 100*mean(cond[in_aoi==1]$a4), pct)
  }
  rm(stk); gc()
}
out<-rbindlist(res)
fwrite(out, file.path(OUT,"R8_a4_sensitivity.csv")); print(out)
cat("PHASE 35 DONE\n")
