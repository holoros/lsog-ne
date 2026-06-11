# =============================================================================
# Phase 23: How much older forest in Maine is already protected, and by whom?
# Design-based FIA estimate of older forest (stand age >= 120 yr; large-tree
# BA >= 30 ft2/ac) by OWNERSHIP GROUP and RESERVED status (RESERVCD = legally
# withheld from harvest, the FIA proxy for protected/conserved). No external
# data needed. Literal areaDomain expressions (rFIA NSE). Output: output_phase23/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table) })
DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT<- "/users/PUOM0008/crsfaaron/LSOG/output_phase23"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
me <- readFIA(DB, states="ME")
tr <- as.data.table(me$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ), .(PLT_CN,CONDID,BA=0.005454*DIA^2*TPA_UNADJ,DIA)]
lt <- tr[DIA>=16, .(BA_large=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
cond <- as.data.table(me$COND); cond <- merge(cond, lt, by=c("PLT_CN","CONDID"), all.x=TRUE)
cond[is.na(BA_large), BA_large:=0]
cond[, oldstruct := as.integer(BA_large>=30)]
cond[, age120 := as.integer(!is.na(STDAGE) & STDAGE>=120)]
cond[, reserved := as.integer(RESERVCD==1)]
cond[, priv := as.integer(OWNGRPCD==40)]
cond[, pub  := as.integer(OWNGRPCD %in% c(10,20,30))]
me$COND <- as.data.frame(cond)
grab <- function(a){ a<-as.data.table(a); ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1]; av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a[, .(YEAR, area_ac=get(ar), se=sqrt(get(av)))] }
latest <- function(a){ g<-grab(a); g[YEAR==max(YEAR)] }
row <- function(lab, a, denom){ x<-latest(a); pct<-100*x$area_ac/denom; se<-100*x$se/denom
  data.table(metric=lab, area_ac=round(x$area_ac), pct_of_class=round(pct,1),
    lo=round(pmax(0,pct-1.96*se),1), hi=round(pct+1.96*se,1)) }

all_for <- latest(rFIA::area(me, variance=TRUE))$area_ac
den_old <- latest(rFIA::area(me, areaDomain=age120==1, variance=TRUE))$area_ac
den_st  <- latest(rFIA::area(me, areaDomain=oldstruct==1, variance=TRUE))$area_ac
log("All forest %.0f ac; older(age>=120) %.0f ac; large-tree %.0f ac", all_for, den_old, den_st)

tab_age <- rbindlist(list(
  row("Older forest reserved (protected)",  rFIA::area(me, areaDomain=age120==1 & reserved==1, variance=TRUE), den_old),
  row("Older forest on private land",       rFIA::area(me, areaDomain=age120==1 & priv==1,     variance=TRUE), den_old),
  row("Older forest on public land",        rFIA::area(me, areaDomain=age120==1 & pub==1,      variance=TRUE), den_old),
  row("Older forest private AND reserved",  rFIA::area(me, areaDomain=age120==1 & priv==1 & reserved==1, variance=TRUE), den_old),
  row("Older forest public AND reserved",   rFIA::area(me, areaDomain=age120==1 & pub==1 & reserved==1,  variance=TRUE), den_old)
))
fwrite(tab_age, file.path(OUT,"C1_olderforest_protection_age120.csv")); cat("== age>=120 (% of older forest) ==\n"); print(tab_age)

tab_st <- rbindlist(list(
  row("Large-tree forest reserved (protected)", rFIA::area(me, areaDomain=oldstruct==1 & reserved==1, variance=TRUE), den_st),
  row("Large-tree forest on private land",      rFIA::area(me, areaDomain=oldstruct==1 & priv==1,     variance=TRUE), den_st),
  row("Large-tree forest on public land",       rFIA::area(me, areaDomain=oldstruct==1 & pub==1,      variance=TRUE), den_st),
  row("Large-tree forest private AND reserved", rFIA::area(me, areaDomain=oldstruct==1 & priv==1 & reserved==1, variance=TRUE), den_st)
))
fwrite(tab_st, file.path(OUT,"C2_largetree_protection.csv")); cat("== large-tree (% of large-tree forest) ==\n"); print(tab_st)

resv <- latest(rFIA::area(me, areaDomain=reserved==1, variance=TRUE))$area_ac
fwrite(data.table(metric="All forest reserved (% of forestland)", value=round(100*resv/all_for,2)),
       file.path(OUT,"C3_overall_reserved.csv"))
log("All Maine forest reserved: %.2f%% of forestland", 100*resv/all_for)
cat("PHASE 23 DONE\n")
