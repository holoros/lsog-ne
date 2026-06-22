# =============================================================================
# Phase 43: true-coordinate cross-map test, re-keyed. The FIA.xy CN does not match
# the unified-table CN (different snapshot), so we link on the PUBLIC fuzzed
# coordinates (FIA.xy FUZZ.LAT/LON == unified LAT/LON), then use TRUE.LAT/LON for
# sampling. Does using true coordinates change v5.1-vs-Hagan cross-map kappa?
# Output: ~/LSOG/output_phase37/Q3_truecoord_kappa.csv
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(data.table) })
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
hag<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif")
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase37"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
xy<-unique(fread(file.path(RES,"FIA.xy.csv"), colClasses=list(character="PLT_CN"))[
  STATE=="ME", .(PLT_CN, FUZZ.LAT, FUZZ.LON, TRUE.LAT, TRUE.LON)], by="PLT_CN")
uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))[
  state=="ME", .(LAT, LON, v5_class)]
# round both to 4 decimals for a coordinate join
xy[, k:=paste(round(FUZZ.LAT,4), round(FUZZ.LON,4))]
uni[, k:=paste(round(LAT,4), round(LON,4))]
uni<-unique(uni, by="k")
m<-merge(xy, uni, by="k")[!is.na(TRUE.LAT)]
log("FIA.xy plots linked to unified v5 class by fuzzed coords: %d", nrow(m))
sampr<-function(lat,lon){ p<-vect(cbind(as.numeric(lon),as.numeric(lat))); crs(p)<-"EPSG:4269"
  terra::extract(hag, project(p,crs(hag)))[,2] }
m[, h_true:=sampr(TRUE.LAT,TRUE.LON)][, h_fuzz:=sampr(FUZZ.LAT,FUZZ.LON)]
m[, v5_lsog:=as.integer(v5_class!="Not LSOG")]
kap<-function(a,b){t<-table(a,b); n<-sum(t); if(n==0)return(NA); po<-sum(diag(t))/n; pe<-sum(rowSums(t)*colSums(t))/n^2; (po-pe)/(1-pe)}
fz<-m[!is.na(h_fuzz)]; tr<-m[!is.na(h_true)]
kf<-kap(fz$v5_lsog, as.integer(fz$h_fuzz %in% c(2,3,4)))
kt<-kap(tr$v5_lsog, as.integer(tr$h_true %in% c(2,3,4)))
log("Cross-map kappa v5.1-any vs Hagan-any: FUZZED %.3f (n=%d) -> TRUE %.3f (n=%d)", kf, nrow(fz), kt, nrow(tr))
log("Hagan any-LSOG share at FIA plots: fuzzed %.1f%% true %.1f%%",
    100*mean(fz$h_fuzz %in% c(2,3,4)), 100*mean(tr$h_true %in% c(2,3,4)))
fwrite(data.table(coord=c("fuzzed","true"), n=c(nrow(fz),nrow(tr)), kappa_any=round(c(kf,kt),3)),
       file.path(OUT,"Q3_truecoord_kappa.csv"))
cat("PHASE 43 DONE\n")
