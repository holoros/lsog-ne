suppressPackageStartupMessages({library(rFIA);library(dplyr);library(data.table);library(sf)})
DB<-"/users/PUOM0008/crsfaaron/fia_data"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase29";dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...)cat(sprintf(...),"\n")
me<-readFIA(DB,states="ME")
tr<-as.data.table(me$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ),.(PLT_CN,CONDID,DIA,BA=0.005454*DIA^2*TPA_UNADJ)]
lt<-tr[DIA>=16,.(BA_large=sum(BA,na.rm=TRUE)),by=.(PLT_CN,CONDID)]
cond<-as.data.table(me$COND);cond<-merge(cond,lt,by=c("PLT_CN","CONDID"),all.x=TRUE)
cond[is.na(BA_large),BA_large:=0]
cond[,oldstruct:=as.integer(BA_large>=30)]
cond[,age120:=as.integer(!is.na(STDAGE)&STDAGE>=120)]
cond[,age100:=as.integer(!is.na(STDAGE)&STDAGE>=100)]
me$COND<-as.data.frame(cond)
aoi<-st_read("/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan/AOI_unzipped/AOI_LiDAR_stats.shp",quiet=TRUE)
aoi<-st_transform(st_sf(geometry=st_union(aoi)),4326);aoi$id<-1L
log("AOI area: %.0f ha",as.numeric(sum(st_area(aoi)))/1e4)
grab<-function(a){a<-as.data.table(a);ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1];av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a[,.(YEAR,area_ac=get(ar),area_ac_se=sqrt(get(av)))]}
den<-grab(area(me,polys=aoi,variance=TRUE))[,.(YEAR,denom_ac=area_ac)]
mkp<-function(g,lab){g<-merge(g,den,by="YEAR")
  g[,`:=`(area_perc=100*area_ac/denom_ac,area_perc_se=100*area_ac_se/denom_ac,domain=lab,region="UT (AOI-clip)")]
  g[,`:=`(perc_lo=pmax(0,area_perc-1.96*area_perc_se),perc_hi=area_perc+1.96*area_perc_se)];g}
res<-rbindlist(list(
  mkp(grab(area(me,polys=aoi,areaDomain=age120==1,variance=TRUE)),"Stand age >= 120 yr"),
  mkp(grab(area(me,polys=aoi,areaDomain=age100==1,variance=TRUE)),"Stand age >= 100 yr"),
  mkp(grab(area(me,polys=aoi,areaDomain=oldstruct==1,variance=TRUE)),"Large-tree BA >= 30 ft2/ac")
),fill=TRUE)
fwrite(res,file.path(OUT,"T1_ut_aoi_trend.csv"))
slope<-function(g){g<-g[!is.na(area_perc)];w<-1/(g$area_perc_se^2);s<-summary(lm(area_perc~YEAR,g,weights=w))$coefficients["YEAR",];sprintf("%.4f [%.4f, %.4f]",s[1],s[1]-1.96*s[2],s[1]+1.96*s[2])}
cat("\n=== AOI-clipped (Hagan UT footprint) ===\n")
for(d in unique(res$domain))cat(sprintf("%-28s first=%.2f last=%.2f slope/yr=%s\n",d,res[domain==d][order(YEAR)][1]$area_perc,res[domain==d][order(-YEAR)][1]$area_perc,slope(res[domain==d])))
cat("PHASE29 DONE\n")
