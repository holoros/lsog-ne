# =============================================================================
# Phase 14: Is LSOG "rapidly disappearing"? An independent temporal test.
#
# Hagan's premise is rapid LSOG loss (1.37%/yr overall, 2.19%/yr on commercial
# timberland). We test it with two independent lines over the same unorganized
# townships (AOI):
#   (A) TreeMap-imputed LSOG area for 2016, 2020, 2022 (native 30 m, no mode
#       collapse), classes from the v5.1/v4 FIA structural lookup.
#   (B) FIADB v5.1/v3 plot-panel LSOG share trend (the design-based stock).
#
# Caveats are explicit: TreeMap year differences blend real change with FIA-panel
# vintage and imputation-model updates; Hagan's "loss" is GFW canopy-disturbance
# flux on LSOG pixels, not a remeasured stock. These measure different things.
#
# Outputs: ~/LSOG/output_phase14/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table); library(foreign) })
terraOptions(memfrac=0.7)
LSOG <- "/users/PUOM0008/crsfaaron/LSOG"
P10R <- file.path(LSOG,"output_phase10/C_hagan_class_100m.tif")
LUT  <- file.path(LSOG,"output_treemap/hybrid_v5_v4_lookup.csv")
PLOTS<- file.path(LSOG,"output_unified/lsog_ne_plot_table.csv")
OUT  <- file.path(LSOG,"output_phase14"); dir.create(file.path(OUT,"fig"),showWarnings=FALSE,recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
CODE <- c("Not LSOG"=1L,"Transitioning LS"=2L,"LS"=3L,"OG"=4L)
HA30 <- 0.09   # 30 m pixel = 900 m2 = 0.09 ha

TM <- list(
 "2016"=list(tif="/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2016/TreeMap2016.tif",
             vat="/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2016/TreeMap2016.tif.vat.dbf"),
 "2020"=list(tif="/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2020/TreeMap2020_CONUS.tif",
             vat="/fs/scratch/PUOM0008/crsfaaron/TREEMAP_restore/TM2020/TreeMap2020_CONUS.tif.vat.dbf"),
 "2022"=list(tif="/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif",
             vat="/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif.vat.dbf"))

lut <- fread(LUT, colClasses=list(character="PLT_CN")); lut[, code := CODE[hybrid_class]]
tmpl <- rast(P10R)

vat_codes <- function(vatfile){
  v <- as.data.table(read.dbf(vatfile, as.is=TRUE)); setnames(v, names(v), toupper(names(v)))
  vc <- intersect(c("VALUE","TM_ID"),names(v))[1]; cc <- intersect(c("CN","PLT_CN"),names(v))[1]
  v <- data.table(VALUE=as.integer(v[[vc]]), PLT_CN=sprintf("%.0f", as.numeric(v[[cc]])))
  merge(v, lut[,.(PLT_CN,code)], by="PLT_CN", all.x=TRUE)
}

rows <- list()
for(yr in names(TM)){
  log("=== TreeMap %s ===", yr)
  tm <- rast(TM[[yr]]$tif)
  tmc <- crop(tm, project(rast(ext(tmpl),res=250,crs=crs(tmpl)), crs(tm)), snap="out")
  levels(tmc) <- NULL
  # restrict to AOI: resample 100 m Hagan raster (non-NA = AOI) onto the 30 m TreeMap grid
  aoi_tm <- project(tmpl, tmc, method="near")
  tmc <- mask(tmc, aoi_tm)
  fr <- as.data.table(freq(tmc, digits=0)); setnames(fr, c("layer","VALUE","count"))
  fr <- fr[!is.na(VALUE)]; fr[, VALUE := as.integer(VALUE)]
  vc <- vat_codes(TM[[yr]]$vat)
  fr <- merge(fr, vc[,.(VALUE,code)], by="VALUE", all.x=TRUE)
  fr[, cls := factor(fcoalesce(names(CODE)[match(code,CODE)], "Unknown"),
                     levels=c("Not LSOG","Transitioning LS","LS","OG","Unknown"))]
  agg <- fr[, .(ha = sum(count)*HA30), by=cls][order(cls)]
  known <- agg[cls!="Unknown", sum(ha)]
  anyL <- agg[cls %in% c("Transitioning LS","LS","OG"), sum(ha)]
  lsog <- agg[cls %in% c("LS","OG"), sum(ha)]
  rows[[yr]] <- data.table(year=as.integer(yr), known_ha=known, unknown_ha=agg[cls=="Unknown",ha],
    any_LSOG_ha=anyL, any_LSOG_pct=100*anyL/known, LS_OG_ha=lsog, LS_OG_pct=100*lsog/known)
  log("  any-LSOG %.2f%% (%.0f ha), LS+OG %.2f%% of known %.0f ha", 100*anyL/known, anyL, 100*lsog/known, known)
  print(agg)
}
ts <- rbindlist(rows); fwrite(ts, file.path(OUT,"T1_treemap_lsog_timeseries.csv")); print(ts)

# implied annual change from TreeMap (2016->2022)
r_any <- 100*((ts[year==2022]$any_LSOG_pct/ts[year==2016]$any_LSOG_pct)^(1/6)-1)
r_lsog<- 100*((ts[year==2022]$LS_OG_pct  /ts[year==2016]$LS_OG_pct  )^(1/6)-1)
log("TreeMap implied annual change 2016-2022: any-LSOG %+.2f%%/yr, LS+OG %+.2f%%/yr", r_any, r_lsog)

# ---- FIADB plot-panel trend (v5.1, ME, all available panels) ----
pl <- fread(PLOTS, colClasses=list(character="CN"))[state=="ME"]
fia <- pl[, .(n=.N, any_LSOG_pct=100*mean(v5_class!="Not LSOG"),
              LS_OG_pct=100*mean(v5_class %in% c("LS","OG"))), by=eval_period][order(eval_period)]
fwrite(fia, file.path(OUT,"T2_fiadb_v51_trend_ME.csv")); print(fia)

# ---- synthesis table ----
synth <- data.table(
  line=c("Hagan premise (study area)","Hagan premise (commercial timberland)",
         "TreeMap any-LSOG 2016-2022","TreeMap LS+OG 2016-2022",
         "FIADB v5.1 any-LSOG (latest 2 panels)"),
  annual_change_pct=c(-1.37,-2.19, r_any, r_lsog,
     { a<-fia[eval_period=="2014-2018"]$any_LSOG_pct; b<-fia[eval_period=="2019-2023"]$any_LSOG_pct
       if(length(a)&&length(b)) 100*((b/a)^(1/5)-1) else NA_real_ }))
fwrite(synth, file.path(OUT,"T3_change_synthesis.csv")); print(synth)

# ---- figure: TreeMap + FIADB trend ----
png(file.path(OUT,"fig","trend.png"), 1500, 900, res=150)
par(mar=c(4.5,4.5,3,1))
plot(ts$year, ts$any_LSOG_pct, type="b", pch=19, lwd=2, col="#6AAE3D",
     xlim=c(2000,2023), ylim=c(0,max(c(ts$any_LSOG_pct,fia$any_LSOG_pct),na.rm=TRUE)*1.15),
     xlab="Year", ylab="any-LSOG (% of forest)", main="Is LSOG disappearing? Independent temporal lines (Maine UT)")
points(ts$year, ts$LS_OG_pct, type="b", pch=17, lwd=2, col="#1A3D28")
fia_yr <- as.integer(substr(fia$eval_period,6,9))
points(fia_yr, fia$any_LSOG_pct, type="b", pch=15, lwd=2, lty=2, col="#2c7fb8")
legend("topleft", c("TreeMap any-LSOG","TreeMap LS+OG","FIADB v5.1 any-LSOG (ME)"),
       col=c("#6AAE3D","#1A3D28","#2c7fb8"), pch=c(19,17,15), lwd=2, bty="n")
dev.off()
png(file.path(OUT,"fig","trend_thumb.png"), 760, 460, res=80)
par(mar=c(4,4,2.5,1)); plot(ts$year, ts$any_LSOG_pct, type="b", pch=19, col="#6AAE3D",
  ylim=c(0,max(ts$any_LSOG_pct)*1.3), xlab="Year", ylab="any-LSOG %", main="TreeMap LSOG trend, Maine UT")
points(ts$year, ts$LS_OG_pct, type="b", pch=17, col="#1A3D28"); dev.off()
log("DONE Phase 14.")
