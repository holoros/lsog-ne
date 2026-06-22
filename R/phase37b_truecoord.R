# Phase 37b: does using TRUE FIA coordinates change v5.1-vs-Hagan cross-map kappa?
suppressPackageStartupMessages({ library(terra); library(data.table) })
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
hag<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase10/C_hagan_class_100m.tif")
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase37"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
xy<-unique(fread(file.path(RES,"FIA.xy.csv"), colClasses=list(character="PLT_CN"))[, .(PLT_CN,FUZZ.LAT,FUZZ.LON,TRUE.LAT,TRUE.LON)])
uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))[state=="ME", .(PLT_CN=CN,v5_class)]
m<-merge(xy,uni,by="PLT_CN")[!is.na(TRUE.LAT)&!is.na(FUZZ.LAT)]
log("ME plots with v5 class + coords: %d", nrow(m))
samp<-function(lat,lon){ p<-vect(cbind(as.numeric(lon),as.numeric(lat))); crs(p)<-"EPSG:4269"
  terra::extract(project(p,crs(hag)), )  # placeholder
}
sampr<-function(lat,lon){ p<-vect(cbind(as.numeric(lon),as.numeric(lat))); crs(p)<-"EPSG:4269"
  p<-project(p,crs(hag)); terra::extract(hag,p)[,2] }
m[, h_true:=sampr(TRUE.LAT,TRUE.LON)][, h_fuzz:=sampr(FUZZ.LAT,FUZZ.LON)]
m[, v5_lsog:=as.integer(v5_class!="Not LSOG")]
kap<-function(a,b){t<-table(a,b); n<-sum(t); if(n==0)return(NA); po<-sum(diag(t))/n; pe<-sum(rowSums(t)*colSums(t))/n^2; (po-pe)/(1-pe)}
fz<-m[!is.na(h_fuzz)]; tr<-m[!is.na(h_true)]
kf<-kap(fz$v5_lsog, as.integer(fz$h_fuzz %in% c(2,3,4)))
kt<-kap(tr$v5_lsog, as.integer(tr$h_true %in% c(2,3,4)))
log("Cross-map kappa v5.1-any vs Hagan-any: FUZZED %.3f (n=%d) -> TRUE %.3f (n=%d)", kf, nrow(fz), kt, nrow(tr))
# also Hagan any-LSOG share at true vs fuzzed (does fuzzing bias the share?)
log("Hagan any-LSOG share at FIA plots: fuzzed %.1f%%  true %.1f%%",
    100*mean(fz$h_fuzz %in% c(2,3,4)), 100*mean(tr$h_true %in% c(2,3,4)))
fwrite(data.table(coord=c("fuzzed","true"), n=c(nrow(fz),nrow(tr)), kappa_any=round(c(kf,kt),3)),
       file.path(OUT,"Q3_truecoord_kappa.csv"))
cat("PHASE 37b DONE\n")
