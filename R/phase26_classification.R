# =============================================================================
# Phase 26: A repeatable, multi-axis classification of TRUE LSOG, anchored in FIA.
# True LSOG must satisfy several axes, not one canopy proxy:
#   A1 live structure  : large-tree basal area (DIA>=16 in) >= 30 ft2/ac
#   A2 dead wood       : standing-dead (snag) basal area (DIA>=5 in) >= 5 ft2/ac
#   A3 composition     : >=50% of live BA in shade-tolerant, long-lived species
#   A4 continuity      : no recent cutting (TRTCD!=10) and natural origin (STDORGCD!=1)
# Design-based FIA area (rFIA) meeting each axis alone and meeting >=1..4 axes
# (the "true-LSOG funnel"), with 95% CI; which axis is limiting. Deterministic
# function of FIA -> fully repeatable. Output: ~/LSOG/output_phase26/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table); library(ggplot2); library(ggsci); library(patchwork) })
DB<-"/users/PUOM0008/crsfaaron/fia_data"; OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase26"
dir.create(OUT,showWarnings=FALSE,recursive=TRUE); log<-function(...) cat(sprintf(...),"\n")
me<-readFIA(DB, states="ME")
# late-successional, long-lived species (Acadian): hemlock, red/black/white spruce,
# white-cedar, sugar maple, beech, yellow birch, white pine, red oak
LATE<-c(261,97,95,94,241,318,531,371,129,833)
tr<-as.data.table(me$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA,
      BA=0.005454*DIA^2*TPA_UNADJ)]
liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2 & DIA>=5]
agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE),
             BA_large=sum(BA[DIA>=16],na.rm=TRUE),
             BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)), by=.(PLT_CN,CONDID)]
sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
agg<-merge(agg, sn, by=c("PLT_CN","CONDID"), all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
cond<-as.data.table(me$COND)
cond<-merge(cond, agg, by=c("PLT_CN","CONDID"), all.x=TRUE)
for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)), (v):=0]
cond[, a1 := as.integer(BA_large>=30)]
cond[, a2 := as.integer(BA_snag>=5)]
cond[, a3 := as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
cond[, a4 := as.integer((is.na(TRTCD1)|TRTCD1!=10) & (is.na(STDORGCD)|STDORGCD!=1))]
cond[, nmet := a1+a2+a3+a4]
cond[, c1:=as.integer(nmet>=1)][, c2:=as.integer(nmet>=2)][, c3:=as.integer(nmet>=3)][, c4:=as.integer(nmet>=4)]
me$COND<-as.data.frame(cond)
log("conds %d; axis prevalence A1 %.2f A2 %.2f A3 %.2f A4 %.2f; all-4 %.3f",
    nrow(cond),mean(cond$a1),mean(cond$a2),mean(cond$a3),mean(cond$a4),mean(cond$c4))

grab<-function(a){a<-as.data.table(a);ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1];av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a<-a[YEAR==max(YEAR)]; list(area=a[[ar]], se=sqrt(a[[av]]))}
den<-grab(rFIA::area(me, variance=TRUE))$area
row<-function(lab,a){g<-grab(a);pct<-100*g$area/den;se<-100*g$se/den
  data.table(metric=lab, pct=round(pct,2), lo=round(pmax(0,pct-1.96*se),2), hi=round(pct+1.96*se,2))}
axis_tab<-rbindlist(list(
  row("A1 live structure alone",       rFIA::area(me,areaDomain=a1==1,variance=TRUE)),
  row("A2 dead wood alone",            rFIA::area(me,areaDomain=a2==1,variance=TRUE)),
  row("A3 composition alone",          rFIA::area(me,areaDomain=a3==1,variance=TRUE)),
  row("A4 continuity alone",           rFIA::area(me,areaDomain=a4==1,variance=TRUE))))
fwrite(axis_tab, file.path(OUT,"L1_axis_alone.csv")); print(axis_tab)
funnel<-rbindlist(list(
  row(">=1 axis", rFIA::area(me,areaDomain=c1==1,variance=TRUE)),
  row(">=2 axes", rFIA::area(me,areaDomain=c2==1,variance=TRUE)),
  row(">=3 axes", rFIA::area(me,areaDomain=c3==1,variance=TRUE)),
  row("all 4 axes (true LSOG)", rFIA::area(me,areaDomain=c4==1,variance=TRUE))))
fwrite(funnel, file.path(OUT,"L2_funnel.csv")); print(funnel)
# limiting axis: among conds meeting >=3, which axis is missing most often
m3<-cond[nmet==3]; miss<-data.table(axis=c("A1 live structure","A2 dead wood","A3 composition","A4 continuity"),
  missing_share=round(100*c(mean(m3$a1==0),mean(m3$a2==0),mean(m3$a3==0),mean(m3$a4==0)),1))
fwrite(miss, file.path(OUT,"L3_limiting_axis.csv")); print(miss)

# ---- figure: the true-LSOG funnel + axis-alone ----
funnel[, step:=factor(metric, levels=metric)]
pA<-ggplot(funnel, aes(step, pct))+geom_col(fill="#3b4994", width=0.65)+
  geom_errorbar(aes(ymin=lo,ymax=hi), width=0.2)+
  geom_text(aes(label=sprintf("%.1f%%",pct)), vjust=-0.6, size=3)+
  labs(title="(a) The true-LSOG funnel", subtitle="design-based % of Maine forestland meeting increasing numbers of axes",
       x=NULL, y="% of forestland")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),axis.text.x=element_text(angle=15,hjust=1),
        plot.subtitle=element_text(size=8,color="grey35"))
axis_tab[, ax:=factor(metric, levels=metric)]
pB<-ggplot(axis_tab, aes(ax, pct))+geom_col(fill="#1B9E9E", width=0.65)+
  geom_errorbar(aes(ymin=lo,ymax=hi), width=0.2)+
  geom_text(aes(label=sprintf("%.0f%%",pct)), vjust=-0.6, size=3)+
  labs(title="(b) Each axis alone", subtitle="live structure (large trees) is the scarcest axis and the most common one missing; continuity via FIA treatment codes is permissive (legacy harvest undercounted)",
       x=NULL, y="% of forestland")+theme_minimal(base_size=10)+
  theme(plot.background=element_rect(fill="white",color=NA),axis.text.x=element_text(angle=15,hjust=1),
        plot.subtitle=element_text(size=8,color="grey35"))
ggsave(file.path(OUT,"Fig_classification.png"), pA/pB, width=6.6, height=7.2, dpi=300)
ggsave(file.path(OUT,"Fig_classification_thumb.jpg"), pA/pB, width=6.6, height=7.2, dpi=70)
cat("PHASE 26 DONE\n")
