# =============================================================================
# Phase 31: LCMS-based time-since-disturbance continuity axis for the true-LSOG
# funnel. Replaces the FIA-treatment-code A4 (phase 26), which is permissive and
# undercounts legacy/partial harvest, with a Landsat-era (1985-2023) LCMS
# continuity test. LCMS v2024-10 annual "Change" cause-of-change classes:
#   1 Wind 2 Hurricane 3 Snow/Ice 4 Desiccation 5 Inundation 6 Prescribed Fire
#   7 Wildfire 8 Mechanical 9 Tree Removal 10 Defoliation 11 SPB
#   12 Insect/Disease/Drought 13 Other Loss 14 Successional Growth 15 Stable
#   16 Non-processing.
# Canopy-removing ("heavy") disturbance = {2,6,7,8,9,13}. A4_lcms passes if NO
# heavy disturbance is detected at the plot over the full LCMS record.
# Output: ~/LSOG/output_phase31/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table); library(ggplot2); library(patchwork) })
terraOptions(memfrac=0.55)
WD <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"
DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase31"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...), "\n")

## ---- 1. stack annual LCMS AOI tiles, build year-of-disturbance ----
yrs <- 1985:2023
fls <- file.path(WD, "aoi", sprintf("lcms_%d.tif", yrs))
fls <- fls[file.exists(fls)]; yrs <- as.integer(gsub(".*lcms_|\\.tif","", fls))
log("stacking %d annual LCMS tiles (%d-%d)", length(fls), min(yrs), max(yrs))
stk <- rast(fls)
HEAVY <- c(2,6,7,8,9,13)           # canopy-removing disturbance
ANY   <- 1:13                      # any detected loss/stress
# year-of-most-recent heavy disturbance (0 = none in record)
yod_heavy <- rast(stk, nlyr=1); values(yod_heavy) <- 0
for (i in seq_along(yrs)) {
  hy <- (stk[[i]] %in% HEAVY) * yrs[i]
  yod_heavy <- max(yod_heavy, hy, na.rm=TRUE)
}
yod_any <- rast(stk, nlyr=1); values(yod_any) <- 0
for (i in seq_along(yrs)) {
  ay <- (stk[[i]] %in% ANY) * yrs[i]
  yod_any <- max(yod_any, ay, na.rm=TRUE)
}
tsd_heavy <- ifel(yod_heavy==0, NA, 2023 - yod_heavy)   # years since heavy disturbance
names(yod_heavy)<-"yod_heavy"; names(yod_any)<-"yod_any"; names(tsd_heavy)<-"tsd_heavy"
writeRaster(yod_heavy, file.path(OUT,"ME_LCMS_yod_heavy_100m.tif"), overwrite=TRUE, datatype="INT2U")
writeRaster(tsd_heavy, file.path(OUT,"ME_LCMS_tsd_heavy_100m.tif"), overwrite=TRUE, datatype="INT2S")
# focal max to absorb FIA coordinate fuzzing (3x3 ~ 300 m)
yod_heavy_f <- focal(yod_heavy, w=3, fun="max", na.policy="omit")

## ---- 2. recompute the phase-26 axes, swap A4 to LCMS ----
me <- readFIA(DB, states="ME")
LATE <- c(261,97,95,94,241,318,531,371,129,833)
tr <- as.data.table(me$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA,
        BA=0.005454*DIA^2*TPA_UNADJ)]
liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2 & DIA>=5]
agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE), BA_large=sum(BA[DIA>=16],na.rm=TRUE),
             BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)), by=.(PLT_CN,CONDID)]
sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
agg<-merge(agg, sn, by=c("PLT_CN","CONDID"), all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
cond<-as.data.table(me$COND)
cond<-merge(cond, agg, by=c("PLT_CN","CONDID"), all.x=TRUE)
for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)), (v):=0]
cond[, a1 := as.integer(BA_large>=30)]
cond[, a2 := as.integer(BA_snag>=5)]
cond[, a3 := as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
cond[, a4_fia := as.integer((is.na(TRTCD1)|TRTCD1!=10) & (is.na(STDORGCD)|STDORGCD!=1))]

## ---- 3. extract LCMS continuity at plot coords ----
plt <- as.data.table(me$PLOT)[, .(CN, LON, LAT)]
plt <- plt[!is.na(LON)&!is.na(LAT)]
pv <- vect(plt, geom=c("LON","LAT"), crs="EPSG:4269")
pv <- project(pv, crs(yod_heavy_f))
plt[, yod_heavy := terra::extract(yod_heavy_f, pv)[,2]]
plt[, in_aoi := as.integer(!is.na(yod_heavy))]
plt[, a4_lcms := as.integer(in_aoi==1 & (is.na(yod_heavy) | yod_heavy==0))]
# plots outside the Maine AOI raster (shouldn't happen for ME) keep FIA fallback
cond <- merge(cond, plt[, .(PLT_CN=CN, yod_heavy_plot=yod_heavy, in_aoi, a4_lcms)], by="PLT_CN", all.x=TRUE)
cond[is.na(in_aoi), `:=`(in_aoi=0, a4_lcms=NA)]
# A4 final: use LCMS where available, else FIA-code fallback
cond[, a4 := ifelse(!is.na(a4_lcms), a4_lcms, a4_fia)]
cond[, nmet := a1+a2+a3+a4]
cond[, c1:=as.integer(nmet>=1)][, c2:=as.integer(nmet>=2)][, c3:=as.integer(nmet>=3)][, c4:=as.integer(nmet>=4)]
me$COND <- as.data.frame(cond)
log("A4 prevalence  FIA-code %.3f  vs  LCMS %.3f  (delta %.3f)",
    mean(cond$a4_fia), mean(cond$a4, na.rm=TRUE), mean(cond$a4_fia)-mean(cond$a4,na.rm=TRUE))
log("plots in AOI: %d of %d conds", sum(cond$in_aoi==1), nrow(cond))

## ---- 4. design-based funnel (same machinery as phase 26) ----
grab<-function(a){a<-as.data.table(a);ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1];av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a<-a[YEAR==max(YEAR)]; list(area=a[[ar]], se=sqrt(a[[av]]))}
den<-grab(rFIA::area(me, variance=TRUE))$area
row<-function(lab,a){g<-grab(a);pct<-100*g$area/den;se<-100*g$se/den
  data.table(metric=lab, pct=round(pct,2), lo=round(pmax(0,pct-1.96*se),2), hi=round(pct+1.96*se,2))}
axis_tab<-rbindlist(list(
  row("A1 live structure alone", rFIA::area(me,areaDomain=a1==1,variance=TRUE)),
  row("A2 dead wood alone",      rFIA::area(me,areaDomain=a2==1,variance=TRUE)),
  row("A3 composition alone",    rFIA::area(me,areaDomain=a3==1,variance=TRUE)),
  row("A4 continuity alone (LCMS)", rFIA::area(me,areaDomain=a4==1,variance=TRUE))))
fwrite(axis_tab, file.path(OUT,"L1_axis_alone_lcms.csv")); print(axis_tab)
funnel<-rbindlist(list(
  row(">=1 axis", rFIA::area(me,areaDomain=c1==1,variance=TRUE)),
  row(">=2 axes", rFIA::area(me,areaDomain=c2==1,variance=TRUE)),
  row(">=3 axes", rFIA::area(me,areaDomain=c3==1,variance=TRUE)),
  row("all 4 axes (true LSOG)", rFIA::area(me,areaDomain=c4==1,variance=TRUE))))
fwrite(funnel, file.path(OUT,"L2_funnel_lcms.csv")); print(funnel)
m3<-cond[nmet==3]; miss<-data.table(axis=c("A1 live structure","A2 dead wood","A3 composition","A4 continuity (LCMS)"),
  missing_share=round(100*c(mean(m3$a1==0),mean(m3$a2==0),mean(m3$a3==0),mean(m3$a4==0)),1))
fwrite(miss, file.path(OUT,"L3_limiting_axis_lcms.csv")); print(miss)

## ---- 5. continuity summary: how much detected disturbance ----
inA <- cond[in_aoi==1]
csum <- data.table(
  metric=c("conds in AOI","% with heavy disturbance 1985-2023","median TSD where disturbed (yr)",
           "A4 pass FIA-code %","A4 pass LCMS %"),
  value=c(nrow(inA),
          round(100*mean(inA$yod_heavy_plot>0),1),
          round(median((2023-inA$yod_heavy_plot)[inA$yod_heavy_plot>0]),0),
          round(100*mean(inA$a4_fia),1),
          round(100*mean(inA$a4),1)))
fwrite(csum, file.path(OUT,"CN_lcms_continuity_summary.csv")); print(csum)

## ---- 6. figure: funnel with LCMS A4 + TSD distribution ----
funnel[, step:=factor(metric, levels=metric)]
pA<-ggplot(funnel, aes(step, pct))+geom_col(fill="#3b4994", width=0.65)+
  geom_errorbar(aes(ymin=lo,ymax=hi), width=0.2)+
  geom_text(aes(label=sprintf("%.1f%%",pct)), vjust=-0.6, size=3)+
  labs(title="(a) The true-LSOG funnel (LCMS continuity axis)",
       subtitle="design-based % of Maine forestland meeting increasing numbers of axes; A4 = no Landsat-era stand-replacing disturbance",
       x=NULL, y="% of forestland")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),axis.text.x=element_text(angle=15,hjust=1),
        plot.subtitle=element_text(size=7,color="grey35"))
tsd <- (2023-inA$yod_heavy_plot)[inA$yod_heavy_plot>0]
pB<-ggplot(data.table(tsd=tsd), aes(tsd))+geom_histogram(binwidth=2, fill="#1B9E9E")+
  labs(title="(b) Time since last stand-replacing disturbance (LCMS), disturbed plots",
       subtitle="partial harvest (Tree Removal) is the dominant LCMS cause in Maine; invisible to binary GFW and to FIA treatment codes",
       x="years since disturbance (1985-2023 record)", y="FIA plots")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),plot.subtitle=element_text(size=7,color="grey35"))
ggsave(file.path(OUT,"Fig_funnel_lcms.png"), pA/pB, width=6.6, height=7.4, dpi=300)
ggsave(file.path(OUT,"Fig_funnel_lcms_thumb.jpg"), pA/pB, width=6.6, height=7.4, dpi=70)
cat("PHASE 31 DONE\n")
