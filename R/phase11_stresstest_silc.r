# =============================================================================
# Phase 11: Stress test the Phase 10 Hagan reproduction + cross-validation, and
# update the SILC (Seven Islands M2V2b) comparison against the published model.
#
# Stress tests:
#   (1) Multi-seed RF ensemble  -> bound wall-to-wall LS+OGL% and plot-level kappa
#                                  under randomForest stochasticity
#   (2) FIA fuzz sensitivity     -> point-sample vs 1 km modal-class buffer
#   (3) Bootstrap CI             -> cross-val shares + kappa (B = 2000)
#   (4) Owner/region not needed; region split by panel
#
# SILC update:
#   (5) Plot-level: v5.1 / v4 / SILC(M2V2b) / reproduced-published-Hagan at the
#       same Pingree FIA plots; kappa between the two Hagan-lineage products
#   (6) Pixel-level: SILC vs Phase10 reproduced-Hagan on the Pingree footprint
#
# Outputs: ~/LSOG/output_phase11/
# =============================================================================
suppressPackageStartupMessages({
  library(randomForest); library(terra); library(sf); library(data.table)
})

ZEN  <- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan"
SHP  <- file.path(ZEN, "AOI_unzipped/AOI_LiDAR_stats.shp")
TD   <- file.path(ZEN, "Maine_training_data.csv")
PLOTS<- "/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv"
P10R <- "/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif"
SILC <- "/users/PUOM0008/crsfaaron/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
OUT  <- "/users/PUOM0008/crsfaaron/LSOG/output_phase11"
dir.create(file.path(OUT, "fig"), showWarnings = FALSE, recursive = TRUE)

LIDAR_COLS <- c("mean_cano_ht","max_cano_ht","percentile_95th","rumple",
                "top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
DBF_COLS   <- c("mn_cn_h","mx_cn_h","prcn_95","rumple","tp_rgst","cn_cv_2","cn_cv_6","cn_c_15")
relabel <- c("Not LS"="Not LSOG","Trans LS"="Transitioning LS","LS"="LS","Old-growth"="OGL")
log <- function(...) cat(sprintf(...), "\n")

kappa_bin <- function(v, h){            # v,h logical vectors
  n<-length(v); a<-sum(v&h); b<-sum(v&!h); c<-sum(!v&h); d<-sum(!v&!h)
  po<-(a+d)/n; pe<-((a+b)/n)*((a+c)/n)+((c+d)/n)*((b+d)/n)
  (po-pe)/(1-pe)
}

# ---- training data ----
td <- read.csv(TD)[, c("LSOG_class", LIDAR_COLS)]
td$LSOG_class <- as.factor(td$LSOG_class)

# ---- AOI grid: attributes for areas + geometry for plot join ----
log("Reading AOI grid ...")
v <- terra::vect(SHP)
att <- as.data.table(as.data.frame(v))
setnames(att, DBF_COLS, LIDAR_COLS)
cc <- complete.cases(att[, ..LIDAR_COLS])
Xaoi <- as.data.frame(att[cc, ..LIDAR_COLS])
log("AOI complete-case hectares: %d", nrow(Xaoi))

# ---- FIA ME plots joined to AOI to obtain each plot's hectare metrics ----
dt <- fread(PLOTS, colClasses = list(character = "CN"))
me <- dt[state == "ME"]
pts <- sf::st_transform(sf::st_as_sf(me, coords=c("LON","LAT"), crs=4326), terra::crs(v))
vsf <- sf::st_as_sf(v)                       # for st_join
names(vsf)[match(DBF_COLS, names(vsf))] <- LIDAR_COLS
j <- sf::st_join(pts, vsf[, c(LIDAR_COLS)], join = sf::st_within)
me_aoi <- cbind(me, sf::st_drop_geometry(j)[, LIDAR_COLS])
me_aoi <- as.data.table(me_aoi)
me_aoi[, in_aoi := complete.cases(me_aoi[, ..LIDAR_COLS])]
log("ME plots inside AOI (have hectare metrics): %d", sum(me_aoi$in_aoi))
Xplot <- as.data.frame(me_aoi[in_aoi == TRUE, ..LIDAR_COLS])
lp <- me_aoi$in_aoi & me_aoi$eval_period == "2019-2023"   # latest-panel in-AOI mask on me_aoi

# =============================================================================
# (1) Multi-seed RF ensemble
# =============================================================================
SEEDS <- 1:20
ens <- rbindlist(lapply(SEEDS, function(s){
  set.seed(s)
  rf <- randomForest(LSOG_class ~ ., data=td, mtry=2, ntree=500, importance=FALSE)
  pa <- relabel[as.character(predict(rf, Xaoi))]
  any_pct <- 100*mean(pa != "Not LSOG"); lsogl_pct <- 100*mean(pa %in% c("LS","OGL"))
  ogl_pct <- 100*mean(pa == "OGL"); lsogl_ha <- sum(pa %in% c("LS","OGL"))
  # plot-level latest panel
  pp <- relabel[as.character(predict(rf, Xplot))]
  mlat <- me_aoi[in_aoi==TRUE]; mlat[, hg := pp]
  mlat <- mlat[eval_period=="2019-2023"]
  k_any <- kappa_bin(mlat$v5_class!="Not LSOG", mlat$hg!="Not LSOG")
  k_lso <- kappa_bin(mlat$v5_class %in% c("LS","OG"), mlat$hg %in% c("LS","OGL"))
  oob_bin <- mean((td$LSOG_class!="Not LS") == (rf$predicted!="Not LS"))
  data.table(seed=s, oob_binary_acc=100*oob_bin, ww_any_pct=any_pct,
             ww_lsogl_pct=lsogl_pct, ww_ogl_pct=ogl_pct, ww_lsogl_ha=lsogl_ha,
             plot_hagan_any_pct=100*mean(mlat$hg!="Not LSOG"),
             kappa_any=k_any, kappa_lsog=k_lso)
}))
fwrite(ens, file.path(OUT, "S1_multiseed_ensemble.csv"))
ssum <- ens[, .(metric=c("oob_binary_acc","ww_any_pct","ww_lsogl_pct","ww_ogl_pct","ww_lsogl_ha","kappa_any","kappa_lsog"),
                mean=c(mean(oob_binary_acc),mean(ww_any_pct),mean(ww_lsogl_pct),mean(ww_ogl_pct),mean(ww_lsogl_ha),mean(kappa_any),mean(kappa_lsog)),
                sd  =c(sd(oob_binary_acc),sd(ww_any_pct),sd(ww_lsogl_pct),sd(ww_ogl_pct),sd(ww_lsogl_ha),sd(kappa_any),sd(kappa_lsog)),
                min =c(min(oob_binary_acc),min(ww_any_pct),min(ww_lsogl_pct),min(ww_ogl_pct),min(ww_lsogl_ha),min(kappa_any),min(kappa_lsog)),
                max =c(max(oob_binary_acc),max(ww_any_pct),max(ww_lsogl_pct),max(ww_ogl_pct),max(ww_lsogl_ha),max(kappa_any),max(kappa_lsog)))]
fwrite(ssum, file.path(OUT, "S1_multiseed_summary.csv"))
log("Multi-seed wall-to-wall LS+OGL%%: mean=%.2f sd=%.3f range=[%.2f, %.2f]  (published 3.9)",
    ssum[metric=="ww_lsogl_pct",mean], ssum[metric=="ww_lsogl_pct",sd],
    ssum[metric=="ww_lsogl_pct",min], ssum[metric=="ww_lsogl_pct",max])
log("Multi-seed kappa_any: mean=%.3f sd=%.3f range=[%.3f, %.3f]",
    ssum[metric=="kappa_any",mean], ssum[metric=="kappa_any",sd],
    ssum[metric=="kappa_any",min], ssum[metric=="kappa_any",max])

# =============================================================================
# (2) FIA fuzz sensitivity: point vs 1 km modal-class buffer (Phase 10 raster)
# =============================================================================
r10 <- terra::rast(P10R)
ptsAOI <- terra::vect(sf::st_transform(sf::st_as_sf(me[eval_period=="2019-2023"],
                       coords=c("LON","LAT"), crs=4326), terra::crs(r10)))
pt_val <- terra::extract(r10, ptsAOI)[,2]
buf_val<- terra::extract(r10, ptsAOI, buffer=1000, fun=function(x){
            x<-x[!is.na(x)]; if(!length(x)) return(NA); as.integer(names(sort(table(x),decreasing=TRUE))[1])})[,2]
fz <- data.table(v5=me[eval_period=="2019-2023"]$v5_class, pt=pt_val, buf=buf_val)
fz <- fz[!is.na(pt)]
fuzz <- data.table(
  scheme=c("point_sample","1km_modal_buffer"),
  n=c(nrow(fz), sum(!is.na(fz$buf))),
  hagan_any_pct=c(100*mean(fz$pt %in% 2:4), 100*mean(fz$buf %in% 2:4, na.rm=TRUE)),
  kappa_any=c(kappa_bin(fz$v5!="Not LSOG", fz$pt %in% 2:4),
              kappa_bin(fz$v5[!is.na(fz$buf)]!="Not LSOG", fz$buf[!is.na(fz$buf)] %in% 2:4)),
  kappa_lsog=c(kappa_bin(fz$v5 %in% c("LS","OG"), fz$pt %in% 3:4),
               kappa_bin(fz$v5[!is.na(fz$buf)] %in% c("LS","OG"), fz$buf[!is.na(fz$buf)] %in% 3:4)))
fwrite(fuzz, file.path(OUT, "S2_fuzz_sensitivity.csv"))
log("Fuzz: point kappa_any=%.3f vs 1km-modal kappa_any=%.3f", fuzz$kappa_any[1], fuzz$kappa_any[2])

# =============================================================================
# (3) Bootstrap CI on cross-val (latest panel, point sample)
# =============================================================================
bd <- fz[!is.na(pt)]
B <- 2000; set.seed(99)
bs <- rbindlist(lapply(1:B, function(i){
  ix <- sample.int(nrow(bd), replace=TRUE); d <- bd[ix]
  data.table(v51_any=100*mean(d$v5!="Not LSOG"), hagan_any=100*mean(d$pt %in% 2:4),
             v51_lsog=100*mean(d$v5 %in% c("LS","OG")), hagan_lsog=100*mean(d$pt %in% 3:4),
             kappa_any=kappa_bin(d$v5!="Not LSOG", d$pt %in% 2:4))
}))
ci <- bs[, .(metric=names(.SD), mean=sapply(.SD,mean),
             lo=sapply(.SD,quantile,0.025), hi=sapply(.SD,quantile,0.975))]
fwrite(ci, file.path(OUT, "S3_bootstrap_ci.csv"))
log("Bootstrap: v5.1 any %.1f [%.1f,%.1f]  Hagan any %.1f [%.1f,%.1f]  kappa_any %.3f [%.3f,%.3f]",
    ci[metric=="v51_any",mean],ci[metric=="v51_any",lo],ci[metric=="v51_any",hi],
    ci[metric=="hagan_any",mean],ci[metric=="hagan_any",lo],ci[metric=="hagan_any",hi],
    ci[metric=="kappa_any",mean],ci[metric=="kappa_any",lo],ci[metric=="kappa_any",hi])

# =============================================================================
# (5) SILC plot-level update: v5.1 / v4 / SILC(M2V2b) / reproduced-Hagan
# =============================================================================
silc <- terra::rast(SILC); levels(silc) <- NULL
ptsS <- terra::vect(sf::st_transform(sf::st_as_sf(me, coords=c("LON","LAT"), crs=4326), terra::crs(silc)))
me[, silc_val := terra::extract(silc, ptsS)[,2]]
# reproduced-Hagan at same plots (Phase 10 raster)
ptsH <- terra::vect(sf::st_transform(sf::st_as_sf(me, coords=c("LON","LAT"), crs=4326), terra::crs(r10)))
me[, hagan_val := terra::extract(r10, ptsH)[,2]]
ping <- me[silc_val %in% 1:4 & eval_period=="2019-2023"]
log("Pingree latest-panel plots with SILC value: %d", nrow(ping))
hg_lab <- c("1"="Not LSOG","2"="Transitioning LS","3"="LS","4"="OGL")
silc_share <- data.table(
  source=c("v5.1 (FIA)","v4 (FIA)","SILC M2V2b","Reproduced-Hagan"),
  n=nrow(ping),
  any_LSOG_pct=c(100*mean(ping$v5_class!="Not LSOG"),100*mean(ping$v4_class!="Not LSOG"),
                 100*mean(ping$silc_val %in% 2:4),100*mean(ping$hagan_val %in% 2:4, na.rm=TRUE)),
  LS_OG_pct=c(100*mean(ping$v5_class %in% c("LS","OG")),100*mean(ping$v4_class %in% c("LS","OG")),
              100*mean(ping$silc_val %in% 3:4),100*mean(ping$hagan_val %in% 3:4, na.rm=TRUE)))
fwrite(silc_share, file.path(OUT, "S5_silc_plot_shares.csv"))
# kappa between the two Hagan-lineage products (SILC vs reproduced published model)
pin2 <- ping[!is.na(hagan_val)]
silc_kappa <- data.table(
  comparison=c("SILC vs Reproduced-Hagan (any-LSOG)","SILC vs Reproduced-Hagan (LS+OG)",
               "v5.1 vs SILC (any-LSOG)","v5.1 vs Reproduced-Hagan (any-LSOG)"),
  n=c(nrow(pin2),nrow(pin2),nrow(ping),nrow(pin2)),
  kappa=c(kappa_bin(pin2$silc_val %in% 2:4, pin2$hagan_val %in% 2:4),
          kappa_bin(pin2$silc_val %in% 3:4, pin2$hagan_val %in% 3:4),
          kappa_bin(ping$v5_class!="Not LSOG", ping$silc_val %in% 2:4),
          kappa_bin(pin2$v5_class!="Not LSOG", pin2$hagan_val %in% 2:4)))
fwrite(silc_kappa, file.path(OUT, "S5_silc_kappa.csv"))
fwrite(me[, .(CN,eval_period,LAT,LON,v4_class,v5_class,silc_val,hagan_val)],
       file.path(OUT, "S5_me_plots_silc_hagan.csv"))
log("SILC vs Reproduced-Hagan any-LSOG kappa = %.3f (n=%d)",
    silc_kappa$kappa[1], silc_kappa$n[1])

# =============================================================================
# (6) SILC pixel-level vs Phase10 reproduced-Hagan on Pingree footprint
# =============================================================================
ok <- tryCatch({
  h_on_s <- terra::project(r10, silc, method="near")
  st <- c(silc, h_on_s); names(st) <- c("silc","hagan")
  df <- as.data.frame(st)
  df <- df[!is.na(df$silc) & !is.na(df$hagan) & df$silc %in% 1:4, ]
  ct <- table(SILC=hg_lab[as.character(df$silc)], Hagan=hg_lab[as.character(df$hagan)])
  fwrite(as.data.table(as.table(ct)), file.path(OUT, "S6_silc_vs_hagan_pixel_crosstab.csv"))
  k_any <- kappa_bin(df$silc %in% 2:4, df$hagan %in% 2:4)
  k_lso <- kappa_bin(df$silc %in% 3:4, df$hagan %in% 3:4)
  fwrite(data.table(level="pixel", n=nrow(df), kappa_any=k_any, kappa_lsog=k_lso),
         file.path(OUT, "S6_silc_vs_hagan_pixel_kappa.csv"))
  log("Pixel-level SILC vs reproduced-Hagan: n=%d kappa_any=%.3f kappa_LSOG=%.3f", nrow(df), k_any, k_lso)
  TRUE
}, error=function(e){ log("Pixel-level step skipped: %s", conditionMessage(e)); FALSE })

# ---- figure: multi-seed wall-to-wall LS+OGL distribution ----
png(file.path(OUT,"fig","S1_lsogl_distribution.png"), 1200, 900, res=150)
hist(ens$ww_lsogl_pct, breaks=10, col="#2c7fb8", border="white",
     xlab="Wall-to-wall LS+OGL (% of AOI)", main="Phase 11: RF stochasticity, 20 seeds")
abline(v=3.9, col="red", lwd=2, lty=2); abline(v=mean(ens$ww_lsogl_pct), col="black", lwd=2)
legend("topright", c("Published 3.9%","Ensemble mean"), col=c("red","black"), lty=c(2,1), lwd=2, bty="n")
dev.off()
png(file.path(OUT,"fig","S1_lsogl_distribution_thumb.png"), 600, 450, res=72)
hist(ens$ww_lsogl_pct, breaks=10, col="#2c7fb8", border="white", xlab="LS+OGL %", main="RF stochasticity")
abline(v=3.9, col="red", lwd=2, lty=2); dev.off()

log("DONE Phase 11.")
