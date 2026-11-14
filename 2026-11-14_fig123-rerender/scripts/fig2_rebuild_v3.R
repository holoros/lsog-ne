# November 14, 2026: panel titles now give shares on the common footprint for all three maps (they mixed own-grid and common-footprint shares); kappa printed.
# Figure 2 rebuild from source rasters (2026-10-19). Reproduces R/phase45_ensemble.R
# (which read output_phase10, output_phase12, output_phase45, now gone) from the
# surviving inputs, checks the published shares, then renders a journal map.
#  Hagan:   output_phase10_rerun_20260815/hagan_class_100m_rerun.tif, class >= 2
#  Canopy:  Potapov 2019 RH95 projected to the Hagan grid as in phase12; the phase12
#           layer was a monotone logistic of RH95 thresholded at the area-matched 14.0%,
#           so the flagged set is the top 14.0% of RH95 cells (identical ranking)
#  ORNL:    CONUS_mature_old_growth_strata_0100m.tif, strata == 4 (old growth)
#  Hull:    concave hull of FIA plots at PUBLIC (fuzzed) coordinates, 2 km buffer, as phase45
suppressPackageStartupMessages({library(terra);library(sf);library(ggplot2);library(tidyterra);library(ggspatial);library(patchwork)})
terraOptions(memfrac=0.7)
B <- "/users/PUOM0008/crsfaaron/LSOG"; O <- file.path(B,"2026-11-14_fig123-rerender/out")
log <- function(...) {cat(sprintf(...),"\n"); flush.console()}
tmpl <- rast(file.path(B,"output_phase10_rerun_20260815/hagan_class_100m_rerun.tif"))
hagL <- ifel(tmpl >= 2, 1, 0)
tmpl_ll <- project(rast(ext(tmpl),resolution=500,crs=crs(tmpl)), "EPSG:4326")
pot <- crop(rast(file.path(B,"data/rasters/potapov_2019/Forest_height_2019_NAM.tif")), ext(tmpl_ll), snap="out")
rh95 <- project(pot, tmpl, method="bilinear"); rh95[rh95>60 | rh95<0] <- NA
cv <- values(rh95,mat=FALSE); cv <- cv[is.finite(cv)]
thr <- as.numeric(quantile(cv, 1-0.140)); canL <- ifel(rh95 >= thr, 1, 0)
ornC <- rast(file.path(B,"2026-10-19_fig12-rerender/data/ornl_strata_0100m_lzw.tif"))
orn <- project(crop(ornC, project(as.polygons(ext(tmpl),crs=crs(tmpl)), crs(ornC)), snap="out"), tmpl, method="near")
orn <- ifel(orn==255, NA, orn); ornOG <- ifel(orn==4, 1, 0)
ok <- !is.na(hagL) & !is.na(canL) & !is.na(ornOG)
H <- mask(hagL,ok,maskvalue=FALSE); C <- mask(canL,ok,maskvalue=FALSE); Ob <- mask(ornOG,ok,maskvalue=FALSE)
N <- H+C+Ob
pm <- function(r) 100*as.numeric(global(r,"mean",na.rm=TRUE))
t3 <- as.numeric(global(N==3,"sum",na.rm=TRUE)); fl <- as.numeric(global(N>=1,"sum",na.rm=TRUE))
log("UNMASKED shares: Hagan %.1f canopy %.1f ORNL OG %.1f", pm(hagL), pm(canL), pm(ornOG))
log("CHECK shares: Hagan %.1f | canopy %.1f | ORNL OG %.1f | all-three of flagged %.1f  (published 21.9 / 14.0 / 36.1 / 2.7)",
    pm(H), pm(C), pm(Ob), 100*t3/fl)
# hull from the PUBLIC DataMart coordinates of the 3,125 scored plots (the October shapefile of public positions is no longer on disk)
cn <- data.table::fread(file.path(B,"2026-11-13_definition-map-sensitivity/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv"), select="PLT_CN", colClasses="character")
pl <- data.table::fread("/users/PUOM0008/crsfaaron/fia_data/ME_PLOT.csv", select=c("CN","LAT","LON"), colClasses=list(character="CN"))
pl <- pl[CN %in% cn$PLT_CN & !is.na(LAT)]
fia <- vect(st_transform(st_as_sf(pl, coords=c("LON","LAT"), crs=4269), crs(tmpl)))
hull <- buffer(hull(aggregate(fia), type="concave_ratio", param=0.30), 2000)
cl <- function(r) mask(crop(r,hull),hull)
lv <- c("Not flagged","Flagged as LSOG")
fac <- function(r) { r <- cl(r); levels(r) <- data.frame(id=0:1, cls=lv); r }
Hc <- fac(H); Cc <- fac(C); Oc <- fac(Ob)
Nc <- cl(N); levels(Nc) <- data.frame(id=0:3, cls=c("0","1","2","3"))
hs <- st_as_sf(hull)
E <- ext(trim(Nc)); xl <- c(E$xmin-2000, E$xmax+2000); yl <- c(E$ymin-2000, E$ymax+2000)
bin <- c("Not flagged"="grey85","Flagged as LSOG"="#1b7837")
seqp <- c("0"="grey88","1"="#c7e9c0","2"="#41ab5d","3"="#00441b")
base <- function(r, pal, ttl, deco=FALSE) {
  p <- ggplot() + geom_spatraster(data=r, maxcell=4e6) +
    scale_fill_manual(values=pal, na.value="white", na.translate=FALSE, name=NULL, drop=FALSE) +
        coord_sf(crs=crs(tmpl), datum=4326, expand=FALSE, xlim=xl, ylim=yl) +
    scale_x_continuous(breaks=seq(-71,-67,1)) + scale_y_continuous(breaks=seq(44,47.5,0.5)) +
    labs(title=ttl) + theme_bw(base_size=9) +
    theme(panel.grid=element_line(colour="grey92",linewidth=0.2), axis.text=element_text(size=7.5,colour="grey20"),
          plot.title=element_text(size=9.5), legend.text=element_text(size=8.5), legend.key.size=unit(0.35,"cm"))
  if (deco) p <- p + annotation_scale(location="br", width_hint=0.3, text_cex=0.7, style="ticks", line_width=0.5) +
    annotation_north_arrow(location="tl", height=unit(0.7,"cm"), width=unit(0.55,"cm"),
                           style=north_arrow_orienteering(text_size=6))
  p
}
pa <- base(Hc, bin, sprintf("(a) Airborne lidar (Hagan),\n%.1f%% flagged", pm(H)), deco=TRUE)
pb <- base(Cc, bin, sprintf("(b) Spaceborne canopy height\n(Potapov/GEDI), %.1f%% flagged", pm(C)))
pc <- base(Oc, bin, sprintf("(c) ORNL old growth (Bruening),\n%.1f%% flagged", pm(Ob)))
pd <- base(Nc, seqp, "(d) Number of maps agreeing\non LSOG") + labs(fill="Maps agreeing")
fig <- (pa + pb + pc + pd) + plot_layout(ncol=2, guides="collect") & theme(legend.position="bottom")
ggsave(file.path(O,"2026-11-14_fig2-threemap-agreement-rebuilt_REVIEW.png"), fig, width=6.5, height=7.6, dpi=300, device=ragg::agg_png, bg="white")
ggsave(file.path(O,"2026-11-14_fig2-threemap-agreement-rebuilt_REVIEW.pdf"), fig, width=6.5, height=7.6, bg="white")
kap <- function(a,b){ x <- as.numeric(global(a*b,"sum",na.rm=TRUE)); n <- as.numeric(global(ok,"sum",na.rm=TRUE)); pa_ <- as.numeric(global(a,"sum",na.rm=TRUE))/n; pb_ <- as.numeric(global(b,"sum",na.rm=TRUE))/n
  po <- x/n + (1-pa_-pb_+x/n); pe <- pa_*pb_+(1-pa_)*(1-pb_); (po-pe)/(1-pe) }
log("COMMON footprint cells %.0f | kappa Hagan-canopy %.3f | Hagan-ORNL %.3f | canopy-ORNL %.3f | RH95 threshold %.2f m", as.numeric(global(ok,"sum",na.rm=TRUE)), kap(H,C), kap(H,Ob), kap(C,Ob), thr)
log("FIG2 DONE")
