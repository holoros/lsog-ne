# =============================================================================
# Phase 19: Comprehensive ownership-resolved FIA design-based stress test.
# Tests whether the stable-to-increasing older-forest stock holds ON PRIVATE
# COMMERCIAL TIMBERLAND specifically (the case relevant to certification and to
# Hagan's reported 2.19%/yr commercial-timberland loss), plus a definition sweep.
# Outputs: ~/LSOG/output_phase19/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table) })
DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT<- "/users/PUOM0008/crsfaaron/LSOG/output_phase19"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
me <- readFIA(DB, states="ME")
tr <- as.data.table(me$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ), .(PLT_CN,CONDID,DIA,BA=0.005454*DIA^2*TPA_UNADJ)]
lt <- tr[DIA>=16, .(BA_large=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
cond <- merge(as.data.table(me$COND), lt, by=c("PLT_CN","CONDID"), all.x=TRUE)
cond[is.na(BA_large), BA_large:=0]
cond[, `:=`(age120=as.integer(!is.na(STDAGE)&STDAGE>=120), lt30=as.integer(BA_large>=30),
            ownpriv=as.integer(OWNGRPCD==40), ownpub=as.integer(OWNGRPCD %in% c(10,20,30)))]
me$COND <- as.data.frame(cond)
log("Private (OWNGRPCD=40) conds: %d (%.1f%%); public: %d", sum(cond$ownpriv), 100*mean(cond$ownpriv), sum(cond$ownpub))

grab <- function(a){a<-as.data.table(a); a[,.(YEAR, ac=AREA_TOTAL, se=sqrt(AREA_TOTAL_VAR))]}
denP <- grab(area(me, areaDomain=ownpriv==1, variance=TRUE))[,.(YEAR,den=ac)]
denU <- grab(area(me, areaDomain=ownpub==1,  variance=TRUE))[,.(YEAR,den=ac)]
mk <- function(a,lab,reg,den){ g<-merge(grab(a),den,by="YEAR"); g[,`:=`(pct=100*ac/den,pse=100*se/den)]
  g<-g[is.finite(pct)]; w<-1/g$pse^2; m<-lm(pct~YEAR,data=g,weights=w); s<-summary(m)$coefficients["YEAR",]
  d<-data.table(domain=lab,owner=reg,yr=max(g$YEAR),pct=g[YEAR==max(YEAR)]$pct,
    lo=g[YEAR==max(YEAR)]$pct-1.96*g[YEAR==max(YEAR)]$pse, hi=g[YEAR==max(YEAR)]$pct+1.96*g[YEAR==max(YEAR)]$pse,
    slope=s[1], slope_lo=s[1]-1.96*s[2], slope_hi=s[1]+1.96*s[2])
  log("[%-22s | %-7s] %.2f%% [%.2f,%.2f]; trend %+.3f/yr [%+.3f,%+.3f]", lab,reg,d$pct,d$lo,d$hi,d$slope,d$slope_lo,d$slope_hi); d }
res <- rbindlist(list(
  mk(area(me, areaDomain=age120==1 & ownpriv==1, variance=TRUE), "Stand age >= 120 yr","private",denP),
  mk(area(me, areaDomain=age120==1 & ownpub==1,  variance=TRUE), "Stand age >= 120 yr","public", denU),
  mk(area(me, areaDomain=lt30==1   & ownpriv==1, variance=TRUE), "Large-tree BA >= 30","private",denP),
  mk(area(me, areaDomain=lt30==1   & ownpub==1,  variance=TRUE), "Large-tree BA >= 30","public", denU)))
fwrite(res, file.path(OUT,"S1_oldforest_by_ownership.csv"))
log("On PRIVATE land, trend slopes: %s",
    if(all(res[owner=='private']$slope_lo>0)) "POSITIVE (CIs exclude 0) -- stock rising on private timberland too" else "mixed")
# figure: private vs public, age>=120, over time
png(file.path(OUT,"fig_ownership_trend.png"),1300,820,res=150)
a1<-grab(area(me,areaDomain=age120==1 & ownpriv==1,variance=TRUE)); a1<-merge(a1,denP,by="YEAR"); a1[,`:=`(p=100*ac/den,se=100*se/den)]
a2<-grab(area(me,areaDomain=age120==1 & ownpub==1,variance=TRUE)); a2<-merge(a2,denU,by="YEAR"); a2[,`:=`(p=100*ac/den,se=100*se/den)]
par(mar=c(4.5,4.5,3,1)); plot(NA,xlim=range(a1$YEAR),ylim=c(0,max(a2$p+2*a2$se,na.rm=TRUE)*1.1),
  xlab="FIA inventory year",ylab="% old forest (age >= 120, design-based)",main="Maine old forest by ownership, with 95% CI")
for(dd in list(list(a1,"#B22234","private (commercial)"),list(a2,"#1A3D28","public"))){g<-dd[[1]][order(YEAR)]
  arrows(g$YEAR,g$p-1.96*g$se,g$YEAR,g$p+1.96*g$se,angle=90,code=3,length=0.03,col=dd[[2]]); lines(g$YEAR,g$p,col=dd[[2]],lwd=2);points(g$YEAR,g$p,pch=19,col=dd[[2]])}
legend("topleft",c("private (commercial)","public"),col=c("#B22234","#1A3D28"),lwd=2,pch=19,bty="n"); dev.off()
log("DONE Phase 19.")
