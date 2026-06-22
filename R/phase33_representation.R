# =============================================================================
# Phase 33: is true-LSOG REPRESENTED across ecoregions and forest types in the
# Northeast (the triad question), regardless of which state carries it? Design-
# based true-LSOG (all four axes, LCMS continuity) share within each forest-type
# group and each Bailey ecoregion section, pooled across ME/NH/VT/NY.
# Output: ~/LSOG/output_phase31/ (R5_*, R6_*)
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table) })
terraOptions(memfrac=0.5)
WD <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"; DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/output_phase31"
yrs0 <- 1985:2023; HEAVY <- c(2,6,7,8,9,13); LATE <- c(261,97,95,94,241,318,531,371,129,833)
states <- c("ME","NH","VT","NY"); tiledir <- function(st) if (st=="ME") file.path(WD,"aoi") else file.path(WD, paste0("aoi_",st))
log <- function(...) cat(sprintf(...), "\n")

ftgrp <- function(f){
  g <- rep("Other", length(f))
  g[f>=101 & f<=119] <- "White/red/jack pine"
  g[f>=121 & f<=129] <- "Spruce/fir"
  g[f>=381 & f<=399] <- "Other softwood"
  g[f>=401 & f<=409] <- "Oak/pine"
  g[f>=501 & f<=599] <- "Oak/hickory"
  g[f>=701 & f<=722] <- "Elm/ash/cottonwood"
  g[f>=801 & f<=809] <- "Maple/beech/birch"
  g[f>=901 & f<=909] <- "Aspen/birch"
  g
}

allc <- list()
for (st in states) {
  fls <- file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0)); fls <- fls[file.exists(fls)]
  yrs <- as.integer(gsub(".*lcms_|\\.tif","", fls)); stk <- rast(fls)
  yod <- rast(stk, nlyr=1); values(yod) <- 0
  for (i in seq_along(yrs)) yod <- max(yod, (stk[[i]] %in% HEAVY) * yrs[i], na.rm=TRUE)
  yodf <- focal(yod, w=3, fun="max", na.policy="omit")
  fia <- readFIA(DB, states=st)
  tr <- as.data.table(fia$TREE)[!is.na(DIA)&!is.na(TPA_UNADJ), .(PLT_CN,CONDID,STATUSCD,SPCD,DIA, BA=0.005454*DIA^2*TPA_UNADJ)]
  liv<-tr[STATUSCD==1]; dead<-tr[STATUSCD==2 & DIA>=5]
  agg<-liv[, .(BA_live=sum(BA,na.rm=TRUE), BA_large=sum(BA[DIA>=16],na.rm=TRUE), BA_late=sum(BA[SPCD %in% LATE],na.rm=TRUE)), by=.(PLT_CN,CONDID)]
  sn<-dead[, .(BA_snag=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]; agg<-merge(agg,sn,by=c("PLT_CN","CONDID"),all.x=TRUE); agg[is.na(BA_snag),BA_snag:=0]
  cond<-as.data.table(fia$COND); cond<-merge(cond, agg, by=c("PLT_CN","CONDID"), all.x=TRUE)
  for(v in c("BA_live","BA_large","BA_late","BA_snag")) cond[is.na(get(v)), (v):=0]
  cond[, a1:=as.integer(BA_large>=30)][, a2:=as.integer(BA_snag>=5)][, a3:=as.integer(BA_live>0 & BA_late/BA_live>=0.5)]
  cond[, a4_fia:=as.integer((is.na(TRTCD1)|TRTCD1!=10) & (is.na(STDORGCD)|STDORGCD!=1))]
  P<-as.data.table(fia$PLOT); ecn<-intersect(c("ECOSUBCD","ecosubcd"), names(P))
  P[, ECO := if(length(ecn)) as.character(get(ecn[1])) else NA_character_]
  plt<-P[, .(CN,LON,LAT,ECO)][!is.na(LON)&!is.na(LAT)]
  pv<-project(vect(plt[, .(CN,LON,LAT)],geom=c("LON","LAT"),crs="EPSG:4269"),crs(yodf)); plt[, yodh:=terra::extract(yodf,pv)[,2]]
  plt[, in_aoi:=as.integer(!is.na(yodh))]
  cond<-merge(cond, plt[, .(PLT_CN=CN,yodh,in_aoi,ECO)], by="PLT_CN", all.x=TRUE); cond[is.na(in_aoi),in_aoi:=0]
  cond[, a4:=ifelse(in_aoi==1, as.integer(yodh==0), a4_fia)]
  cond[, c4:=as.integer(a1+a2+a3+a4>=4)]
  cond[, FORTGRP := ftgrp(FORTYPCD)]
  cond[, ECOSEC := gsub("[a-z]$","", trimws(as.character(ECO)))]
  cond[, STATEAB := st]
  fia$COND <- as.data.frame(cond)
  # design-based true-LSOG share within each forest-type group and ecoregion section
  num_ft <- as.data.table(rFIA::area(fia, areaDomain=c4==1, grpBy=FORTGRP))
  den_ft <- as.data.table(rFIA::area(fia, grpBy=FORTGRP))
  num_es <- as.data.table(rFIA::area(fia, areaDomain=c4==1, grpBy=ECOSEC))
  den_es <- as.data.table(rFIA::area(fia, grpBy=ECOSEC))
  allc[[st]] <- list(num_ft=num_ft[YEAR==max(YEAR)], den_ft=den_ft[YEAR==max(YEAR)],
                     num_es=num_es[YEAR==max(YEAR)], den_es=den_es[YEAR==max(YEAR)],
                     cond=cond[, .(STATEAB,FORTGRP,ECOSEC,c4)])
  rm(stk,yod,yodf); gc()
}
# pool across states: sum AREA_TOTAL for numerator and denominator by stratum
poolsum <- function(key, which){
  rbindlist(lapply(states, function(s){ d<-as.data.table(allc[[s]][[which]]);
    acol<-intersect(c("AREA_TOTAL","AREA"),names(d))[1]; d[, .(strat=get(key), area=get(acol))] }))[
    , .(area=sum(area,na.rm=TRUE)), by=strat]
}
ft_num<-poolsum("FORTGRP","num_ft"); ft_den<-poolsum("FORTGRP","den_ft")
es_num<-poolsum("ECOSEC","num_es"); es_den<-poolsum("ECOSEC","den_es")
ft<-merge(ft_den, ft_num, by="strat", all.x=TRUE, suffixes=c("_tot","_lsog")); ft[is.na(area_lsog),area_lsog:=0]
ft[, true_lsog_pct:=round(100*area_lsog/area_tot,2)][, area_lsog_kac:=round(area_lsog/1000,1)]
es<-merge(es_den, es_num, by="strat", all.x=TRUE, suffixes=c("_tot","_lsog")); es[is.na(area_lsog),area_lsog:=0]
es[, true_lsog_pct:=round(100*area_lsog/area_tot,2)][, area_lsog_kac:=round(area_lsog/1000,1)]
setorder(ft, -area_tot); setorder(es, -area_tot)
fwrite(ft[, .(forest_type_group=strat, total_kac=round(area_tot/1000,0), true_lsog_pct, true_lsog_kac=area_lsog_kac)], file.path(OUT,"R5_truelsog_by_foresttype.csv"))
fwrite(es[, .(ecoregion_section=strat, total_kac=round(area_tot/1000,0), true_lsog_pct, true_lsog_kac=area_lsog_kac)], file.path(OUT,"R6_truelsog_by_ecoregion.csv"))
# representation: count strata with any true LSOG
condall<-rbindlist(lapply(states, function(s) allc[[s]]$cond))
rep_ft<-condall[, .(any_truelsog=as.integer(sum(c4)>0), n=.N), by=FORTGRP]
rep_es<-condall[, .(any_truelsog=as.integer(sum(c4)>0), n=.N), by=ECOSEC]
log("forest-type groups with true LSOG present: %d of %d", sum(rep_ft$any_truelsog), nrow(rep_ft))
log("ecoregion sections with true LSOG present: %d of %d", sum(rep_es$any_truelsog), nrow(rep_es))
print(ft[, .(strat, total_kac=round(area_tot/1000,0), true_lsog_pct, area_lsog_kac)])
print(es[, .(strat, total_kac=round(area_tot/1000,0), true_lsog_pct, area_lsog_kac)])
cat("PHASE 33 DONE\n")
