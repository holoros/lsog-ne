suppressPackageStartupMessages(library(terra))
B<-"/users/PUOM0008/crsfaaron/LSOG"
fs<-c("output_phase13/CONSENSUS_nmethods_100m.tif",
      "output_phase13/M4_treemap_class_100m.tif",
      "output_phase10/C_hagan_class_100m.tif",
      "output_phase12/M2_v51gedi_pLSOG_100m.tif",
      "output_phase21/ENSEMBLE_uncertainty_100m.tif")
for(f in fs){
  r<-rast(file.path(B,f))
  cat("\n==",f,"==\n")
  cat(" dim",paste(dim(r),collapse="x"),"| EPSG",crs(r,describe=TRUE)$code,"\n")
  cat(" ext",paste(round(as.vector(ext(r))),collapse=" "),"\n")
  v<-values(r,mat=FALSE); v<-v[!is.na(v)]
  cat(" n nonNA",length(v),"| range",round(min(v),3),round(max(v),3),"\n")
  if(length(unique(v))<=8) print(table(round(v,3)))
}
