# Phase 11b: finish the steps that follow the (already-saved) multi-seed ensemble.
# Fixes the fuzz-buffer call (terra::extract buffer= unsupported here) and runs
# bootstrap CI + SILC update + pixel crosstab. Fast: no AOI grid re-read.
suppressPackageStartupMessages({ library(terra); library(sf); library(data.table) })

PLOTS<- "/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv"
P10R <- "/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif"
SILC <- "/users/PUOM0008/crsfaaron/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
OUT  <- "/users/PUOM0008/crsfaaron/LSOG/output_phase11"
log <- function(...) cat(sprintf(...), "\n")
kappa_bin <- function(v, h){ n<-length(v); a<-sum(v&h); b<-sum(v&!h); c<-sum(!v&h); d<-sum(!v&!h)
  po<-(a+d)/n; pe<-((a+b)/n)*((a+c)/n)+((c+d)/n)*((b+d)/n); (po-pe)/(1-pe) }

dt <- fread(PLOTS, colClasses=list(character="CN")); me <- dt[state=="ME"]
r10 <- terra::rast(P10R)
mlat <- me[eval_period=="2019-2023"]
ptsAOI <- terra::vect(sf::st_transform(sf::st_as_sf(mlat, coords=c("LON","LAT"), crs=4326), terra::crs(r10)))

# (2) FUZZ: point sample vs 1 km modal buffer (buffer points to polygons first)
pt_val <- terra::extract(r10, ptsAOI)[,2]
bufpoly <- terra::buffer(ptsAOI, width=1000)
exb <- terra::extract(r10, bufpoly)                      # ID + value (one row per cell)
modal <- function(x){ x<-x[!is.na(x)]; if(!length(x)) NA_integer_ else as.integer(names(sort(table(x),decreasing=TRUE))[1]) }
buf_val <- tapply(exb[,2], exb$ID, modal)[as.character(seq_len(nrow(mlat)))]
fz <- data.table(v5=mlat$v5_class, pt=pt_val, buf=as.integer(buf_val))[!is.na(pt)]
fuzz <- data.table(
  scheme=c("point_sample","1km_modal_buffer"),
  n=c(nrow(fz), sum(!is.na(fz$buf))),
  hagan_any_pct=c(100*mean(fz$pt %in% 2:4), 100*mean(fz$buf %in% 2:4, na.rm=TRUE)),
  kappa_any=c(kappa_bin(fz$v5!="Not LSOG", fz$pt %in% 2:4),
              kappa_bin(fz$v5[!is.na(fz$buf)]!="Not LSOG", fz$buf[!is.na(fz$buf)] %in% 2:4)),
  kappa_lsog=c(kappa_bin(fz$v5 %in% c("LS","OG"), fz$pt %in% 3:4),
               kappa_bin(fz$v5[!is.na(fz$buf)] %in% c("LS","OG"), fz$buf[!is.na(fz$buf)] %in% 3:4)))
fwrite(fuzz, file.path(OUT, "S2_fuzz_sensitivity.csv"))
log("Fuzz: point kappa_any=%.3f (n=%d) vs 1km-modal kappa_any=%.3f (n=%d)",
    fuzz$kappa_any[1], fuzz$n[1], fuzz$kappa_any[2], fuzz$n[2])

# (3) BOOTSTRAP CI
bd <- fz[!is.na(pt)]; B<-2000; set.seed(99)
bs <- rbindlist(lapply(1:B, function(i){ d<-bd[sample.int(nrow(bd),replace=TRUE)]
  data.table(v51_any=100*mean(d$v5!="Not LSOG"), hagan_any=100*mean(d$pt %in% 2:4),
             v51_lsog=100*mean(d$v5 %in% c("LS","OG")), hagan_lsog=100*mean(d$pt %in% 3:4),
             kappa_any=kappa_bin(d$v5!="Not LSOG", d$pt %in% 2:4)) }))
ci <- bs[, .(metric=names(.SD), mean=sapply(.SD,mean), lo=sapply(.SD,quantile,0.025), hi=sapply(.SD,quantile,0.975))]
fwrite(ci, file.path(OUT,"S3_bootstrap_ci.csv"))
log("Bootstrap kappa_any %.3f [%.3f, %.3f]; v5.1 any %.1f [%.1f,%.1f]; Hagan any %.1f [%.1f,%.1f]",
    ci[metric=="kappa_any",mean],ci[metric=="kappa_any",lo],ci[metric=="kappa_any",hi],
    ci[metric=="v51_any",mean],ci[metric=="v51_any",lo],ci[metric=="v51_any",hi],
    ci[metric=="hagan_any",mean],ci[metric=="hagan_any",lo],ci[metric=="hagan_any",hi])

# (5) SILC plot-level update
silc <- terra::rast(SILC); levels(silc) <- NULL
ptsS <- terra::vect(sf::st_transform(sf::st_as_sf(me, coords=c("LON","LAT"), crs=4326), terra::crs(silc)))
me[, silc_val := terra::extract(silc, ptsS)[,2]]
ptsH <- terra::vect(sf::st_transform(sf::st_as_sf(me, coords=c("LON","LAT"), crs=4326), terra::crs(r10)))
me[, hagan_val := terra::extract(r10, ptsH)[,2]]
ping <- me[silc_val %in% 1:4 & eval_period=="2019-2023"]
log("Pingree latest-panel plots with SILC value: %d", nrow(ping))
silc_share <- data.table(source=c("v5.1 (FIA)","v4 (FIA)","SILC M2V2b","Reproduced-Hagan"), n=nrow(ping),
  any_LSOG_pct=c(100*mean(ping$v5_class!="Not LSOG"),100*mean(ping$v4_class!="Not LSOG"),
                 100*mean(ping$silc_val %in% 2:4),100*mean(ping$hagan_val %in% 2:4,na.rm=TRUE)),
  LS_OG_pct=c(100*mean(ping$v5_class %in% c("LS","OG")),100*mean(ping$v4_class %in% c("LS","OG")),
              100*mean(ping$silc_val %in% 3:4),100*mean(ping$hagan_val %in% 3:4,na.rm=TRUE)))
fwrite(silc_share, file.path(OUT,"S5_silc_plot_shares.csv"))
pin2 <- ping[!is.na(hagan_val)]
silc_kappa <- data.table(
  comparison=c("SILC vs Reproduced-Hagan (any-LSOG)","SILC vs Reproduced-Hagan (LS+OG)",
               "v5.1 vs SILC (any-LSOG)","v5.1 vs Reproduced-Hagan (any-LSOG)"),
  n=c(nrow(pin2),nrow(pin2),nrow(ping),nrow(pin2)),
  kappa=c(kappa_bin(pin2$silc_val %in% 2:4, pin2$hagan_val %in% 2:4),
          kappa_bin(pin2$silc_val %in% 3:4, pin2$hagan_val %in% 3:4),
          kappa_bin(ping$v5_class!="Not LSOG", ping$silc_val %in% 2:4),
          kappa_bin(pin2$v5_class!="Not LSOG", pin2$hagan_val %in% 2:4)))
fwrite(silc_kappa, file.path(OUT,"S5_silc_kappa.csv"))
fwrite(me[,.(CN,eval_period,LAT,LON,v4_class,v5_class,silc_val,hagan_val)], file.path(OUT,"S5_me_plots_silc_hagan.csv"))
log("SILC vs Reproduced-Hagan any-LSOG kappa=%.3f (n=%d); v5.1 vs SILC any kappa=%.3f",
    silc_kappa$kappa[1], silc_kappa$n[1], silc_kappa$kappa[3])

# (6) SILC pixel-level vs reproduced-Hagan
ok <- tryCatch({
  h_on_s <- terra::project(r10, silc, method="near")
  df <- as.data.frame(c(silc, h_on_s)); names(df) <- c("silc","hagan")
  df <- df[!is.na(df$silc) & !is.na(df$hagan) & df$silc %in% 1:4, ]
  hg <- c("1"="Not LSOG","2"="Transitioning LS","3"="LS","4"="OGL")
  ct <- table(SILC=hg[as.character(df$silc)], Hagan=hg[as.character(df$hagan)])
  fwrite(as.data.table(as.table(ct)), file.path(OUT,"S6_silc_vs_hagan_pixel_crosstab.csv"))
  fwrite(data.table(level="pixel", n=nrow(df),
    kappa_any=kappa_bin(df$silc %in% 2:4, df$hagan %in% 2:4),
    kappa_lsog=kappa_bin(df$silc %in% 3:4, df$hagan %in% 3:4)),
    file.path(OUT,"S6_silc_vs_hagan_pixel_kappa.csv"))
  log("Pixel SILC vs reproduced-Hagan: n=%d kappa_any=%.3f", nrow(df),
      kappa_bin(df$silc %in% 2:4, df$hagan %in% 2:4)); TRUE
}, error=function(e){ log("Pixel step skipped: %s", conditionMessage(e)); FALSE })

# figure: multi-seed distribution (from saved ensemble)
ens <- fread(file.path(OUT,"S1_multiseed_ensemble.csv"))
png(file.path(OUT,"fig","S1_lsogl_distribution.png"), 1200, 900, res=150)
hist(ens$ww_lsogl_pct, breaks=8, col="#2c7fb8", border="white",
     xlab="Wall-to-wall LS+OGL (% of AOI)", main="Phase 11: RF stochasticity, 20 seeds")
abline(v=3.9, col="red", lwd=2, lty=2); abline(v=mean(ens$ww_lsogl_pct), col="black", lwd=2)
legend("topright", c("Published 3.9%","Ensemble mean"), col=c("red","black"), lty=c(2,1), lwd=2, bty="n")
dev.off()
png(file.path(OUT,"fig","S1_lsogl_distribution_thumb.png"), 600, 450, res=72)
hist(ens$ww_lsogl_pct, breaks=8, col="#2c7fb8", border="white", xlab="LS+OGL %", main="RF stochasticity")
abline(v=3.9, col="red", lwd=2, lty=2); dev.off()
log("DONE Phase 11b.")
