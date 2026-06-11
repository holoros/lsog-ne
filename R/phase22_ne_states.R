# =============================================================================
# Phase 22: New England regional context. Design-based older-forest area and
# trend for ME, NH, VT, MA, CT, RI (older forest = stand age >= 120 yr, and
# large-tree basal area >= 30 ft2/ac in trees >= 16 in). Same rFIA approach as
# phase16. Outputs: ~/LSOG/output_phase22/  (table + small-multiples figure)
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table); library(ggplot2); library(ggsci) })
DB  <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase22"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
states <- c("ME","NH","VT","MA","CT","RI")
log <- function(...) cat(sprintf(...),"\n")
grab <- function(a){ a<-as.data.table(a); ar<-intersect(c("AREA_TOTAL","AREA"),names(a))[1]; av<-intersect(c("AREA_TOTAL_VAR","AREA_VAR"),names(a))[1]
  a[, .(YEAR, area_ac=get(ar), area_ac_se=sqrt(get(av)))] }
slope_ci <- function(g){ g<-g[!is.na(area_perc)]; if(nrow(g)<3) return(list(NA,NA,NA))
  w<-1/(g$area_perc_se^2+1e-9); m<-lm(area_perc~YEAR,data=g,weights=w); s<-summary(m)$coefficients["YEAR",]
  list(unname(s[1]), unname(s[1]-1.96*s[2]), unname(s[1]+1.96*s[2])) }

all_ts <- list(); all_sum <- list()
for(s in states){
  log("=== %s ===", s)
  fia <- tryCatch(readFIA(DB, states=s), error=function(e){log("read fail %s: %s",s,conditionMessage(e)); NULL})
  if(is.null(fia)) next
  tr <- as.data.table(fia$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ), .(PLT_CN,CONDID,BA=0.005454*DIA^2*TPA_UNADJ, DIA)]
  lt <- tr[DIA>=16, .(BA_large=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
  cond <- as.data.table(fia$COND); cond <- merge(cond, lt, by=c("PLT_CN","CONDID"), all.x=TRUE)
  cond[is.na(BA_large), BA_large:=0]
  cond[, oldstruct := as.integer(BA_large>=30)]
  cond[, age120 := as.integer(!is.na(STDAGE) & STDAGE>=120)]
  fia$COND <- as.data.frame(cond)
  denom <- grab(rFIA::area(fia, variance=TRUE))[, .(YEAR, denom_ac=area_ac)]
  mk <- function(a,l){ g<-merge(grab(a), denom, by="YEAR")
    g[, `:=`(area_perc=100*area_ac/denom_ac, area_perc_se=100*area_ac_se/denom_ac)]
    g[, `:=`(perc_lo=pmax(0,area_perc-1.96*area_perc_se), perc_hi=area_perc+1.96*area_perc_se, domain=l, state=s)]; g }
  g1 <- mk(rFIA::area(fia, areaDomain=age120==1, variance=TRUE), "Stand age >= 120 yr")
  g2 <- mk(rFIA::area(fia, areaDomain=oldstruct==1, variance=TRUE), "Large-tree BA >= 30 ft2/ac")
  ts <- rbindlist(list(g1,g2), fill=TRUE); all_ts[[s]] <- ts
  for(dm in unique(ts$domain)){ gg<-ts[domain==dm]; sl<-slope_ci(gg); yr<-max(gg$YEAR)
    all_sum[[paste(s,dm)]] <- data.table(state=s, domain=dm, year=yr,
      pct=gg[YEAR==yr]$area_perc, lo=gg[YEAR==yr]$perc_lo, hi=gg[YEAR==yr]$perc_hi,
      slope=sl[[1]], slope_lo=sl[[2]], slope_hi=sl[[3]])
    log("  %-26s %s: %.2f%% [%.2f, %.2f]  slope %.4f/yr", dm, yr, gg[YEAR==yr]$area_perc, gg[YEAR==yr]$perc_lo, gg[YEAR==yr]$perc_hi, sl[[1]]) }
  rm(fia); gc()
}
TS <- rbindlist(all_ts, fill=TRUE); SUM <- rbindlist(all_sum, fill=TRUE)
fwrite(TS,  file.path(OUT,"NE_oldforest_timeseries.csv"))
fwrite(SUM, file.path(OUT,"NE_oldforest_summary.csv"))
print(SUM[, .(state,domain,pct=round(pct,2),lo=round(lo,2),hi=round(hi,2),slope=round(slope,4))])

# ---- figure: small-multiples by state, both domains, with CI ribbons ----
TS[, state := factor(state, levels=states)]
p <- ggplot(TS, aes(YEAR, area_perc, color=domain, fill=domain)) +
  geom_ribbon(aes(ymin=perc_lo,ymax=perc_hi), alpha=0.15, color=NA) +
  geom_line(linewidth=0.8) +
  facet_wrap(~state, scales="free_y", ncol=3) +
  scale_color_manual(values=c("Stand age >= 120 yr"="#3b4994","Large-tree BA >= 30 ft2/ac"="#1B9E9E"), name=NULL) +
  scale_fill_manual(values=c("Stand age >= 120 yr"="#3b4994","Large-tree BA >= 30 ft2/ac"="#1B9E9E"), name=NULL) +
  labs(title="Older forest is stable to increasing across New England (FIA design-based)",
       x="inventory year", y="% of forestland") +
  theme_minimal(base_size=10) + theme(legend.position="top",
    plot.background=element_rect(fill="white",color=NA), strip.text=element_text(face="bold"))
ggsave(file.path(OUT,"Fig_ne_states.png"), p, width=8.4, height=5.6, dpi=300)
ggsave(file.path(OUT,"Fig_ne_states_thumb.jpg"), p, width=8.4, height=5.6, dpi=70)
cat("PHASE 22 DONE\n")
