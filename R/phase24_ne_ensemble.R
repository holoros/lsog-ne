# =============================================================================
# Phase 24: a refined, robust NEW ENGLAND LSOG map by a multi-definition ENSEMBLE.
# Each TreeMap2022 pixel carries an imputed FIA plot (CN). For that plot we take
# three transparent LSOG definitions and average their membership into an
# agreement score, with the cross-definition SD as an uncertainty layer:
#   d1 structural LSOG class (FIA v5 structural class != "Not LSOG")
#   d2 stand age >= 120 yr
#   d3 large-tree basal area (>=16 in) >= 30 ft2/ac
# Efficient: build a per-VALUE lookup, then subst the cropped TreeMap once.
# Output: ~/LSOG/output_phase24/  (rasters, NE hex gpkg, figure, summary)
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(sf); library(data.table); library(foreign)
  library(ggplot2); library(ggsci); library(patchwork) })
terraOptions(memfrac=0.6)
LSOG<-"/users/PUOM0008/crsfaaron/LSOG"
TM  <-"/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif"
VATF<-"/fs/scratch/PUOM0008/crsfaaron/reference_rasters/TREEMAP/TM2022/TreeMap2022_CONUS.tif.vat.dbf"
PLOTS<-file.path(LSOG,"output_unified/lsog_ne_plot_table.csv")
OUT <-file.path(LSOG,"output_phase24"); dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")

# ---- per-plot (CN) three-definition memberships ----
pt<-fread(PLOTS, colClasses=list(character="CN"))
pt[, d1 := as.integer(!is.na(v5_class) & v5_class!="Not LSOG")]
pt[, d2 := as.integer(!is.na(STDAGE) & STDAGE>=120)]
pt[, d3 := as.integer(!is.na(ba_large) & ba_large>=30)]
pt[, ens := (d1+d2+d3)/3]
pt[, unc := apply(cbind(d1,d2,d3),1,sd)]
pcn<-pt[, .(CN, ens, unc)]
log("plots %d; mean ens %.3f; any-def prevalence d1 %.2f d2 %.2f d3 %.2f",
    nrow(pt), mean(pt$ens), mean(pt$d1), mean(pt$d2), mean(pt$d3))

# ---- VAT: TreeMap VALUE -> CN ----
v<-as.data.table(read.dbf(VATF, as.is=TRUE)); setnames(v, names(v), toupper(names(v)))
vc<-intersect(c("VALUE","TM_ID"),names(v))[1]; cc<-intersect(c("CN","PLT_CN"),names(v))[1]
vat<-data.table(VALUE=as.integer(v[[vc]]), CN=sprintf("%.0f", as.numeric(v[[cc]])))
vat<-merge(vat, pcn, by="CN", all.x=TRUE)
vat<-vat[!is.na(VALUE)]
log("VAT values %d; with ens %d", nrow(vat), sum(!is.na(vat$ens)))

# ---- crop TreeMap to New England (bbox in EPSG:5070) ----
tm<-rast(TM)
ne_ll<-vect(ext(-74.0,-66.8,40.9,47.6), crs="EPSG:4326")
ne_5070<-project(ne_ll, crs(tm))
tmc<-crop(tm, ext(ne_5070), snap="out"); levels(tmc)<-NULL
log("cropped NE TreeMap: %s cells (%.0f x %.0f)", format(ncell(tmc),big.mark=","), nrow(tmc), ncol(tmc))

# ---- subst VALUE -> ens and unc ----
em<-vat[!is.na(ens), .(VALUE, ens)]; um<-vat[!is.na(unc), .(VALUE, unc)]
ens_r<-subst(tmc, from=em$VALUE, to=em$ens, others=NA); names(ens_r)<-"ens"
unc_r<-subst(tmc, from=um$VALUE, to=um$unc, others=NA); names(unc_r)<-"unc"
writeRaster(ens_r, file.path(OUT,"NE_ensemble_agreement_30m.tif"), overwrite=TRUE)
writeRaster(unc_r, file.path(OUT,"NE_ensemble_uncertainty_30m.tif"), overwrite=TRUE)
# aggregate to ~1 km for fast hex zonal + display
ens_k<-aggregate(ens_r, 33, mean, na.rm=TRUE); unc_k<-aggregate(unc_r, 33, mean, na.rm=TRUE)

# ---- NE hex grid (~25 km) and zonal means ----
poly<-st_as_sf(as.polygons(ext(ens_k), crs=crs(ens_k)))
hex<-st_sf(geometry=st_make_grid(poly, cellsize=25000, square=FALSE))
hex$hexid<-seq_len(nrow(hex))
hexv<-vect(hex)
hex$ens<-terra::extract(ens_k, hexv, fun=mean, na.rm=TRUE)[,2]
hex$unc<-terra::extract(unc_k, hexv, fun=mean, na.rm=TRUE)[,2]
hex<-hex[!is.na(hex$ens),]
st_write(hex, file.path(OUT,"NE_ensemble_hex.gpkg"), delete_dsn=TRUE, quiet=TRUE)
log("hex cells with data: %d; mean ens %.3f; mean unc %.3f", nrow(hex), mean(hex$ens), mean(hex$unc))

# ---- summary stats ----
pv<-values(ens_r); uv<-values(unc_r); ok<-!is.na(pv)
summ<-data.table(
  metric=c("forested NE pixels (30m)","mean agreement","median agreement","% pixels high-agreement (>=0.67)",
           "% pixels all-three-agree (==1)","mean uncertainty","% pixels high-uncertainty (>=0.4)"),
  value=c(sum(ok), round(mean(pv[ok]),3), round(median(pv[ok]),3),
          round(100*mean(pv[ok]>=2/3),2), round(100*mean(pv[ok]>=0.999),2),
          round(mean(uv[ok],na.rm=TRUE),3), round(100*mean(uv[ok]>=0.4,na.rm=TRUE),2)))
fwrite(summ, file.path(OUT,"NE1_ensemble_summary.csv")); print(summ)

# ---- figure: NE ensemble agreement + uncertainty (hex) ----
th<-theme_minimal(base_size=11)+theme(panel.grid=element_blank(),axis.text=element_blank(),
  axis.title=element_blank(),plot.title=element_text(face="bold",size=11),
  legend.key.width=unit(0.35,"cm"),plot.background=element_rect(fill="white",color=NA))
pA<-ggplot(hex)+geom_sf(aes(fill=ens),color=NA)+scale_fill_gsea(name="agreement\nscore (0-1)",limits=c(0,1))+
  labs(title="(a) New England multi-definition ensemble LSOG agreement")+th
pB<-ggplot(hex)+geom_sf(aes(fill=unc),color=NA)+scale_fill_gsea(name="uncertainty\n(SD)")+
  labs(title="(b) Ensemble uncertainty layer")+th
ggsave(file.path(OUT,"Fig_ne_ensemble.png"), pA/pB+patchwork::plot_layout(ncol=1), width=6.6, height=9, dpi=300)
ggsave(file.path(OUT,"Fig_ne_ensemble_thumb.jpg"), pA/pB+patchwork::plot_layout(ncol=1), width=6.6, height=9, dpi=70)
cat("PHASE 24 DONE\n")
