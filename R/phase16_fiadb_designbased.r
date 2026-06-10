# =============================================================================
# Phase 16: FIA DESIGN-BASED estimate of older-forest area and trend in Maine.
#
# Rationale: TreeMap and GEDI/Potapov are remote-sensing proxies; FIA is the
# actual ground-based structural measurement network with a probability design.
# This produces the authoritative ground-based estimate, with FIA post-stratified
# sampling-error intervals, of how much old/mature forest exists and whether it
# is declining -- the gold standard a canopy-LiDAR map can only approximate.
#
# Uses rFIA design-based estimation (EXPNS + post-stratification + variance).
# Domains (all ground-measured):
#   stand age >= 100 / 120 / 150 yr (mature -> old)
#   structural: live basal area in trees >= 16 in (40 cm) dbh >= 30 ft2/ac
# Reported statewide and within the northern timberland units (Hagan's AOI proxy:
#   Aroostook, Piscataquis, Somerset, Franklin counties), by FIA inventory year.
#
# Outputs: ~/LSOG/output_phase16/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(dplyr); library(data.table) })
DB  <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase16"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")

log("Reading Maine FIADB via rFIA ...")
me <- readFIA(DB, states="ME")
log("PLOT %d  COND %d  TREE %d", nrow(me$PLOT), nrow(me$COND), nrow(me$TREE))

# ---- COND-level structural + region flags (ground-measured) ----
tr <- as.data.table(me$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ),
        .(PLT_CN, CONDID, DIA, TPA_UNADJ, BA=0.005454*DIA^2*TPA_UNADJ)]  # BA ft2/ac per tree
lt <- tr[DIA>=16, .(BA_large=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
cond <- as.data.table(me$COND)
cond <- merge(cond, lt, by=c("PLT_CN","CONDID"), all.x=TRUE)
cond[is.na(BA_large), BA_large := 0]
cond[, oldstruct := as.integer(BA_large >= 30)]
cond[, north := as.integer(COUNTYCD %in% c(3,21,25,7))]   # Aroostook,Piscataquis,Somerset,Franklin
cond[, age100 := as.integer(!is.na(STDAGE) & STDAGE>=100)]
cond[, age120 := as.integer(!is.na(STDAGE) & STDAGE>=120)]
cond[, age150 := as.integer(!is.na(STDAGE) & STDAGE>=150)]
me$COND <- as.data.frame(cond)
log("COND with large-tree BA>=30 ft2/ac: %d (%.1f%%); northern conds: %d",
    sum(cond$oldstruct), 100*mean(cond$oldstruct), sum(cond$north))

# rFIA areaDomain restricts the population and returns AREA_TOTAL (domain acres);
# we form the percent against the proper forest-area denominator and propagate the SE.
grab <- function(a){ a<-as.data.table(a)
  ar <- intersect(c("AREA_TOTAL","AREA"), names(a))[1]
  av <- intersect(c("AREA_TOTAL_VAR","AREA_VAR"), names(a))[1]
  a[, .(YEAR, area_ac=get(ar), area_ac_se=sqrt(get(av)))] }

tot_state <- grab(area(me, variance=TRUE))[, .(YEAR, denom_ac=area_ac)]
tot_north <- grab(area(me, areaDomain = north==1, variance=TRUE))[, .(YEAR, denom_ac=area_ac)]
log("Total ME forest (latest yr): %.0f ac; northern units: %.0f ac",
    tot_state[YEAR==max(YEAR)]$denom_ac, tot_north[YEAR==max(YEAR)]$denom_ac)

mk <- function(a, l, r, denom){ g<-merge(grab(a), denom, by="YEAR")
  g[, `:=`(area_perc=100*area_ac/denom_ac, area_perc_se=100*area_ac_se/denom_ac)]
  g[, `:=`(perc_lo=pmax(0,area_perc-1.96*area_perc_se), perc_hi=area_perc+1.96*area_perc_se, domain=l, region=r)]
  log("[%s | %-14s] yr %s: %.2f%% (95%% CI %.2f-%.2f), %.0f ac", l, r, max(g$YEAR),
      g[YEAR==max(YEAR)]$area_perc, g[YEAR==max(YEAR)]$perc_lo, g[YEAR==max(YEAR)]$perc_hi, g[YEAR==max(YEAR)]$area_ac); g }

res <- rbindlist(list(
  mk(area(me, areaDomain = age100==1,               variance=TRUE), "Stand age >= 100 yr","statewide", tot_state),
  mk(area(me, areaDomain = age120==1,               variance=TRUE), "Stand age >= 120 yr","statewide", tot_state),
  mk(area(me, areaDomain = age150==1,               variance=TRUE), "Stand age >= 150 yr","statewide", tot_state),
  mk(area(me, areaDomain = oldstruct==1,            variance=TRUE), "Large-tree BA >= 30 ft2/ac (>=16in)","statewide", tot_state),
  mk(area(me, areaDomain = age100==1 & north==1,    variance=TRUE), "Stand age >= 100 yr","northern units", tot_north),
  mk(area(me, areaDomain = age120==1 & north==1,    variance=TRUE), "Stand age >= 120 yr","northern units", tot_north),
  mk(area(me, areaDomain = age150==1 & north==1,    variance=TRUE), "Stand age >= 150 yr","northern units", tot_north),
  mk(area(me, areaDomain = oldstruct==1 & north==1, variance=TRUE), "Large-tree BA >= 30 ft2/ac (>=16in)","northern units", tot_north)
), fill=TRUE)
fwrite(res, file.path(OUT,"T1_designbased_oldforest_trend.csv"))

# total forestland area trend (context: is forest itself shrinking?)
tot <- grab(area(me, variance=TRUE))[, domain:="All forestland"][, region:="statewide"]
fwrite(tot, file.path(OUT,"T2_total_forest_area_trend.csv")); print(tot)

# trend slope + 95% CI (weighted least squares on year) for the headline domains
slope_ci <- function(g){ g<-g[!is.na(area_perc)]; if(nrow(g)<3) return(c(NA,NA,NA))
  w<-1/(g$area_perc_se^2); m<-lm(area_perc~YEAR, data=g, weights=w); s<-summary(m)$coefficients["YEAR",]
  c(slope=unname(s[1]), lo=unname(s[1]-1.96*s[2]), hi=unname(s[1]+1.96*s[2])) }
trend <- res[, as.list(slope_ci(.SD)), by=.(domain,region)]
setnames(trend, c("domain","region","slope_pct_per_yr","slope_lo","slope_hi"))
fwrite(trend, file.path(OUT,"T3_trend_slopes.csv")); print(trend)
log("Note: Hagan claimed LSOG loss of 1.37 to 2.19 percent per year (relative); FIA design-based slopes above are absolute percent-of-forest area per year.")

# ---- figure: design-based old-forest % over time with 95% CI ----
png(file.path(OUT,"fig_fiadb_trend.png"), 1600, 950, res=150)
par(mar=c(4.5,4.5,3,1))
sw <- res[region=="statewide"]
cols <- c("Stand age >= 100 yr"="#2c7fb8","Stand age >= 120 yr"="#1A3D28",
          "Stand age >= 150 yr"="#6a51a3","Large-tree BA >= 30 ft2/ac (>=16in)"="#C5A55A")
ylim <- c(0, max(sw$perc_hi,na.rm=TRUE)*1.1)
plot(NA, xlim=range(sw$YEAR), ylim=ylim, xlab="FIA inventory year",
     ylab="% of forestland (design-based)", main="Maine FIA design-based older-forest area, with 95% CI")
for(dn in names(cols)){ g<-sw[domain==dn][order(YEAR)]
  arrows(g$YEAR, g$perc_lo, g$YEAR, g$perc_hi, angle=90, code=3, length=0.03, col=cols[dn])
  lines(g$YEAR, g$area_perc, col=cols[dn], lwd=2); points(g$YEAR, g$area_perc, pch=19, col=cols[dn]) }
legend("topleft", names(cols), col=cols, lwd=2, pch=19, bty="n", cex=0.9)
dev.off()
png(file.path(OUT,"fig_fiadb_trend_thumb.png"), 800, 500, res=80)
par(mar=c(4,4,2.5,1)); g<-sw[domain=="Stand age >= 120 yr"][order(YEAR)]
plot(g$YEAR, g$area_perc, type="b", pch=19, col="#1A3D28", ylim=c(0,max(g$perc_hi)*1.2),
     xlab="Year", ylab="% old forest", main="ME FIA design-based, age>=120 (95% CI)")
arrows(g$YEAR,g$perc_lo,g$YEAR,g$perc_hi,angle=90,code=3,length=0.03,col="#1A3D28"); dev.off()
log("DONE Phase 16.")
