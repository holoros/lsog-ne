suppressPackageStartupMessages(library(terra))
B<-"/users/PUOM0008/crsfaaron/LSOG"
ornl<-rast(file.path(B,"output_phase6/ORNL_strata_seven_islands_100m.tif"))
cat("== ORNL strata (seven islands) values ==\n"); print(table(values(ornl,mat=FALSE),useNA="no"))
ornlC<-rast(file.path(B,"data/rasters/ornl_2498/CONUS_mature_old_growth_strata_0100m.tif"))
cat("\n== ORNL CONUS strata legend (cats) ==\n"); print(cats(ornlC))
cat(" dim",paste(dim(ornlC),collapse="x")," ext",paste(round(as.vector(ext(ornlC))),collapse=" "),"\n")
hag<-rast(file.path(B,"output_phase10/C_hagan_class_100m.tif"))
can<-rast(file.path(B,"output_phase12/M2_v51gedi_pLSOG_100m.tif"))
cat("\n== Hagan class table ==\n"); print(table(values(hag,mat=FALSE),useNA="no"))
cv<-values(can,mat=FALSE); cv<-cv[!is.na(cv)]
cat("\n== canopy pLSOG quantiles ==\n"); print(round(quantile(cv,c(.5,.8,.85,.86,.9)),3))
cat("frac >=0.5:",round(mean(cv>=0.5),3)," >=0.6:",round(mean(cv>=0.6),3),"\n")
# find threshold giving 14.0%
thr<-as.numeric(quantile(cv, 1-0.140)); cat("threshold for 14.0% prevalence:",round(thr,3),"\n")
