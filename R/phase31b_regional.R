# =============================================================================
# Phase 31b: four-state LCMS time-since-disturbance continuity + true-LSOG funnel.
# Generalizes phase 31 from Maine to ME, NH, VT, NY so the multi-axis
# classification is regional rather than Maine-only. Same axis definitions;
# A4 = no stand-replacing/harvest disturbance in LCMS 1985-2023 at the plot.
# Output: ~/LSOG/output_phase31/ (regional CSVs + figure)
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table); library(ggplot2); library(patchwork) })
terraOptions(memfrac=0.5)
WD <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"
DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase31"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...), "\n")
yrs0 <- 1985:2023
HEAVY <- c(2,6,7,8,9,13)
LATE <- c(261,97,95,94,241,318,531,371,129,833)
states <- c("ME","NH","VT","NY")
tiledir <- function(st) if (st=="ME") file.path(WD,"aoi") else file.path(WD, paste0("aoi_",st))

axis_all <- list(); funnel_all <- list(); limit_all <- list(); cn_all <- list()

grab<-function(a){a<-as.data.table(a);ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1];av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a<-a[YEAR==max(YEAR)]; list(area=a[[ar]], se=sqrt(a[[av]]))}

for (st in states) {
  log("==== %s ====", st)
  fls <- file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0)); fls <- fls[file.exists(fls)]
  yrs <- as.integer(gsub(".*lcms_|\\.tif","", fls))
  stk <- rast(fls)
  yod <- rast(stk, nlyr=1); values(yod) <- 0
  for (i in seq_along(yrs)) yod <- max(yod, (stk[[i]] %in% HEAVY) * yrs[i], na.rm=TRUE)
  yodf <- focal(yod, w=3, fun="max", na.policy="omit")
  if (st=="ME") { names(yod)<-"yod_heavy"; writeRaster(yod, file.path(OUT,"ME_LCMS_yod_heavy_100m.tif"), overwrite=TRUE, datatype="INT2U") }

  fia <- readFIA(DB, states=st)
  tr <- as.data.table(fia$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA, BA=0.005454*DIA^2*TPA_UNADJ)]
  liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2 & DIA>=5]
  agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE), BA_large=sum(BA[DIA>=16],na.rm=TRUE),
               BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)), by=.(PLT_CN,CONDID)]
  sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
  agg<-merge(agg, sn, by=c("PLT_CN","CONDID"), all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
  cond<-as.data.table(fia$COND); cond<-merge(cond, agg, by=c("PLT_CN","CONDID"), all.x=TRUE)
  for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)), (v):=0]
  cond[, a1 := as.integer(BA_large>=30)]
  cond[, a2 := as.integer(BA_snag>=5)]
  cond[, a3 := as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
  cond[, a4_fia := as.integer((is.na(TRTCD1)|TRTCD1!=10) & (is.na(STDORGCD)|STDORGCD!=1))]

  plt <- as.data.table(fia$PLOT)[, .(CN, LON, LAT)][!is.na(LON)&!is.na(LAT)]
  pv <- project(vect(plt, geom=c("LON","LAT"), crs="EPSG:4269"), crs(yodf))
  plt[, yodh := terra::extract(yodf, pv)[,2]]
  plt[, in_aoi := as.integer(!is.na(yodh))]
  cond <- merge(cond, plt[, .(PLT_CN=CN, yodh, in_aoi)], by="PLT_CN", all.x=TRUE)
  cond[is.na(in_aoi), in_aoi:=0]
  cond[, a4 := ifelse(in_aoi==1, as.integer(yodh==0), a4_fia)]
  cond[, nmet := a1+a2+a3+a4]
  cond[, c1:=as.integer(nmet>=1)][, c2:=as.integer(nmet>=2)][, c3:=as.integer(nmet>=3)][, c4:=as.integer(nmet>=4)]
  fia$COND <- as.data.frame(cond)

  den<-grab(rFIA::area(fia, variance=TRUE))$area
  row<-function(lab,a){g<-grab(a);pct<-100*g$area/den;se<-100*g$se/den
    data.table(state=st, metric=lab, pct=round(pct,2), lo=round(pmax(0,pct-1.96*se),2), hi=round(pct+1.96*se,2))}
  axis_all[[st]] <- rbindlist(list(
    row("A1 live structure", rFIA::area(fia,areaDomain=a1==1,variance=TRUE)),
    row("A2 dead wood",      rFIA::area(fia,areaDomain=a2==1,variance=TRUE)),
    row("A3 composition",    rFIA::area(fia,areaDomain=a3==1,variance=TRUE)),
    row("A4 continuity",     rFIA::area(fia,areaDomain=a4==1,variance=TRUE))))
  funnel_all[[st]] <- rbindlist(list(
    row(">=1 axis", rFIA::area(fia,areaDomain=c1==1,variance=TRUE)),
    row(">=2 axes", rFIA::area(fia,areaDomain=c2==1,variance=TRUE)),
    row(">=3 axes", rFIA::area(fia,areaDomain=c3==1,variance=TRUE)),
    row("true LSOG (all 4)", rFIA::area(fia,areaDomain=c4==1,variance=TRUE))))
  m3<-cond[nmet==3]
  limit_all[[st]] <- data.table(state=st, axis=c("A1 live structure","A2 dead wood","A3 composition","A4 continuity"),
    missing_share=round(100*c(mean(m3$a1==0),mean(m3$a2==0),mean(m3$a3==0),mean(m3$a4==0)),1))
  inA<-cond[in_aoi==1]
  cn_all[[st]] <- data.table(state=st, conds_in_aoi=nrow(inA),
    pct_heavy_disturbed=round(100*mean(inA$yodh>0),1),
    median_tsd_yr=round(median((2023-inA$yodh)[inA$yodh>0]),0),
    a4_fia_pct=round(100*mean(inA$a4_fia),1), a4_lcms_pct=round(100*mean(inA$a4),1))
  rm(stk, yod, yodf); gc()
}
axis_tab<-rbindlist(axis_all); funnel<-rbindlist(funnel_all); limit<-rbindlist(limit_all); cn<-rbindlist(cn_all)
fwrite(axis_tab, file.path(OUT,"R1_axis_alone_4state.csv"))
fwrite(funnel,   file.path(OUT,"R2_funnel_4state.csv"))
fwrite(limit,    file.path(OUT,"R3_limiting_4state.csv"))
fwrite(cn,       file.path(OUT,"R4_continuity_summary_4state.csv"))
print(funnel); print(cn)

## figure: four-state funnel + continuity comparison
funnel[, state:=factor(state, levels=c("ME","NH","VT","NY"))]
funnel[, step:=factor(metric, levels=c(">=1 axis",">=2 axes",">=3 axes","true LSOG (all 4)"))]
pA<-ggplot(funnel, aes(step, pct, fill=state))+geom_col(position=position_dodge(0.8), width=0.75)+
  geom_errorbar(aes(ymin=lo,ymax=hi), position=position_dodge(0.8), width=0.25)+
  scale_fill_manual(values=c(ME="#3b4994",NH="#1B9E9E",VT="#7E6148",NY="#E18727"))+
  labs(title="(a) The true-LSOG funnel across four states (LCMS continuity axis)",
       subtitle="design-based % of forestland meeting increasing numbers of axes; A4 = no Landsat-era stand-replacing disturbance (1985-2023)",
       x=NULL, y="% of forestland")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),plot.subtitle=element_text(size=7,color="grey35"))
cn[, state:=factor(state, levels=c("ME","NH","VT","NY"))]
pB<-ggplot(cn, aes(state, pct_heavy_disturbed, fill=state))+geom_col(width=0.65, show.legend=FALSE)+
  geom_text(aes(label=sprintf("%.0f%%",pct_heavy_disturbed)), vjust=-0.5, size=3)+
  scale_fill_manual(values=c(ME="#3b4994",NH="#1B9E9E",VT="#7E6148",NY="#E18727"))+
  labs(title="(b) Forest with Landsat-detected stand-replacing/harvest disturbance since 1985",
       subtitle="the working-forest disturbance signal: highest in Maine, lower in the aging forests of NH/VT/NY",
       x=NULL, y="% of forestland disturbed")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),plot.subtitle=element_text(size=7,color="grey35"))
ggsave(file.path(OUT,"Fig_funnel_4state.png"), pA/pB, width=7.2, height=7.6, dpi=300)
ggsave(file.path(OUT,"Fig_funnel_4state_thumb.jpg"), pA/pB, width=7.2, height=7.6, dpi=70)
cat("PHASE 31b DONE\n")
