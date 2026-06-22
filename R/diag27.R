suppressPackageStartupMessages(library(terra))
ens<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase21/ENSEMBLE_prob_100m.tif")
onto<-function(p,m="bilinear"){r<-rast(p)
  e<-project(as.polygons(ext(ens),crs=crs(ens)),crs(r))
  rc<-crop(r,ext(e),snap="out"); project(rc,ens,method=m)}
ps<-c("/fs/scratch/PUOM0008/crsfaaron/conus_hcs/output/phase5/p_harvest_any_TM2016.tif",
      "/fs/scratch/PUOM0008/crsfaaron/TREEMAP_outputs_v5/p_disturbance_2022.tif",
      "/fs/scratch/PUOM0008/crsfaaron/fia_locator/dem_case_study/srtm30_me_slope_pct.tif")
for(p in ps){
  x<-tryCatch(onto(p),error=function(e)conditionMessage(e))
  if(inherits(x,"SpatRaster")) cat(basename(p)," nonNA=",sum(!is.na(values(x)))," rng=",paste(round(minmax(x),3),collapse=".."),"\n")
  else cat(basename(p)," ERROR: ",x,"\n")
}
