# =============================================================================
# Phase 28: a Landsat-based CONTINUITY layer for true-LSOG mapping.
# The temporal-continuity axis (the "old" in old growth) is the one a canopy
# sensor cannot see but the Landsat record can. Using Hansen Global Forest Change
# lossyear (2001-2023, the same GFW lineage the original analysis used), we build
# a disturbance-since-2001 layer over the Maine AOI and intersect it with the
# mapped LSOG: how much canopy-mapped LSOG shows Landsat-detected stand-replacing
# disturbance (failing strict continuity), and where the intact-continuity LSOG is.
# Output: ~/LSOG/output_phase28/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(sf); library(data.table); library(ggplot2); library(ggsci); library(patchwork) })
terraOptions(memfrac=0.6)
PAY<-"/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/zenodo_upload/payload"
ENS<-"/users/PUOM0008/crsfaaron/LSOG/output_phase21/ENSEMBLE_prob_100m.tif"
LY<-"/users/PUOM0008/crsfaaron/Disturbance/validation_data/GFC/gfc_lossyear_conus.vrt"
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase28"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
ens<-rast(ENS); m1<-resample(rast(file.path(PAY,"M1_hagan_class_100m.tif")), ens, method="near")
lsog<-(m1>=2)
ly<-rast(LY)
# crop Hansen lossyear to AOI (in its own CRS), make binary stand-replacing loss since 2001
e<-project(as.polygons(ext(ens),crs=crs(ens)),crs(ly)); lyc<-crop(ly,ext(e),snap="out")
disturbed30<-(lyc>0)                                   # any stand-replacing canopy loss 2001-2023
# fraction of each 100 m AOI cell disturbed (project the 0/1 to ens grid by averaging)
distfrac<-project(disturbed30, ens, method="bilinear"); names(distfrac)<-"distfrac"
writeRaster(distfrac, file.path(OUT,"AOI_landsat_lossfrac_100m.tif"), overwrite=TRUE)
intact<-(distfrac < 0.10)                              # <10% of cell disturbed = intact continuity
contLSOG<-(lsog & intact)                              # LSOG that also passes Landsat continuity
writeRaster(contLSOG, file.path(OUT,"LSOG_continuity_intact_100m.tif"), overwrite=TRUE, datatype="INT1U")

D<-as.data.table(c(lsog, distfrac)); setnames(D,c("lsog","distfrac"))
D<-D[!is.na(lsog)&!is.na(distfrac)]
summ<-D[, .(n=.N, mean_loss_frac=round(mean(distfrac),3),
            pct_any_loss=round(100*mean(distfrac>0.001),1),
            pct_disturbed_ge10=round(100*mean(distfrac>=0.10),1)),
        by=.(lsog=ifelse(lsog==1,"LSOG","Not LSOG"))][order(lsog)]
fwrite(summ, file.path(OUT,"CN1_continuity_summary.csv")); print(summ)
# of mapped LSOG, share intact vs disturbed (continuity pass/fail)
ls<-D[lsog==1]; share<-data.table(class=c("intact (passes continuity)","disturbed since 2001 (fails)"),
  pct=round(100*c(mean(ls$distfrac<0.10), mean(ls$distfrac>=0.10)),1))
fwrite(share, file.path(OUT,"CN2_lsog_continuity_share.csv")); print(share)
log("Of canopy-mapped LSOG, %.1f%% shows Landsat stand-replacing disturbance since 2001 (fails strict continuity).",
    100*mean(ls$distfrac>=0.10))

# ---- figure: (a) hex map of intact-continuity LSOG fraction; (b) continuity share ----
hx<-st_read("/users/PUOM0008/crsfaaron/zenodo_staging/lsog_uncertainty/v1_2_newfiles/hex_lsog_by_method.gpkg", quiet=TRUE)
hxv<-vect(hx)
hx$cont<-terra::extract(as.numeric(contLSOG), hxv, fun=mean, na.rm=TRUE)[,2]
hx$lossf<-terra::extract(distfrac, hxv, fun=mean, na.rm=TRUE)[,2]
th<-theme_minimal(base_size=10)+theme(panel.grid=element_blank(),axis.text=element_blank(),axis.title=element_blank(),
  plot.title=element_text(face="bold",size=10),plot.background=element_rect(fill="white",color=NA),legend.key.width=unit(0.3,"cm"))
pA<-ggplot(hx)+geom_sf(aes(fill=lossf),color=NA)+scale_fill_gsea(name="Landsat\nloss frac\n2001-23")+
  labs(title="(a) Landsat-detected disturbance since 2001")+th
pB<-ggplot(hx)+geom_sf(aes(fill=cont),color=NA)+scale_fill_gsea(name="intact-\ncontinuity\nLSOG frac")+
  labs(title="(b) LSOG passing the Landsat continuity test")+th
ggsave(file.path(OUT,"Fig_continuity.png"), pA/pB, width=4.8, height=8, dpi=300)
ggsave(file.path(OUT,"Fig_continuity_thumb.jpg"), pA/pB, width=4.8, height=8, dpi=70)
cat("PHASE 28 DONE\n")
