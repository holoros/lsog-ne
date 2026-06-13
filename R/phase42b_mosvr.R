# Phase 42b: MOSVR pilot, robust (formula+data.frame interface, tryCatch).
suppressPackageStartupMessages({ library(e1071); library(terra); library(data.table) })
set.seed(20260613)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase42"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT) & !is.na(v5_total)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
me[, lcms_tsd:=ifelse(is.na(terra::extract(yod,pv)[,2])|terra::extract(yod,pv)[,2]==0, 40, 2023-terra::extract(yod,pv)[,2])]
dat<-data.frame(y=me$v5_total, potapov_rh95=me$potapov_rh95, lcms_tsd=me$lcms_tsd)
dat<-dat[complete.cases(dat),]; dat<-dat[sample(nrow(dat), min(nrow(dat),2500)),]
log("training rows %d  y range %d-%d", nrow(dat), min(dat$y), max(dat$y))
folds<-sample(rep(1:5, length.out=nrow(dat)))
cv_obj<-function(cost,gamma,eps){
  ph<-rep(NA_real_, nrow(dat))
  for(k in 1:5){ tr<-folds!=k
    m<-tryCatch(svm(y~potapov_rh95+lcms_tsd, data=dat[tr,], type="eps-regression",
                    kernel="radial", cost=cost, gamma=gamma, epsilon=eps), error=function(e) NULL)
    if(!is.null(m)) ph[!tr]<-as.numeric(predict(m, dat[!tr,])) }
  ok<-is.finite(ph); if(sum(ok)<100) return(c(rmse=NA,sys=NA,slope=NA,bias_hi=NA))
  rmse<-sqrt(mean((dat$y[ok]-ph[ok])^2))
  sl<-as.numeric(coef(lm(dat$y[ok]~ph[ok]))[2]); sys<-abs(1-sl)
  hi<-dat$y>=quantile(dat$y,0.9)
  bias_hi<-mean((ph-dat$y)[hi&ok])
  c(rmse=rmse,sys=sys,slope=sl,bias_hi=bias_hi)
}
grid<-expand.grid(cost=c(1,4,16), gamma=c(0.25,1,4), eps=c(0.1,0.5))
res<-rbindlist(lapply(1:nrow(grid), function(i){
  o<-cv_obj(grid$cost[i],grid$gamma[i],grid$eps[i])
  log("  cost=%.0f gamma=%.2f eps=%.1f -> rmse=%.3f sys=%.3f", grid$cost[i],grid$gamma[i],grid$eps[i],o["rmse"],o["sys"])
  data.table(cost=grid$cost[i],gamma=grid$gamma[i],eps=grid$eps[i],
             rmse=round(o["rmse"],3),sys=round(o["sys"],3),slope=round(o["slope"],3),bias_hi=round(o["bias_hi"],3)) }))
res<-res[is.finite(rmse)&is.finite(sys)]
fwrite(res, file.path(OUT,"M1_grid_objectives.csv"))
res[, dominated:=FALSE]
for(i in 1:nrow(res)) for(j in 1:nrow(res)) if(i!=j)
  if(isTRUE(res$rmse[j]<=res$rmse[i] & res$sys[j]<=res$sys[i] & (res$rmse[j]<res$rmse[i]|res$sys[j]<res$sys[i]))) res$dominated[i]<-TRUE
pareto<-res[dominated==FALSE][order(rmse)]; fwrite(pareto, file.path(OUT,"M2_pareto.csv"))
to<-res[which.min(rmse)]
pr<-copy(pareto); pr[, rn:=(rmse-min(rmse))/(max(rmse)-min(rmse)+1e-9)][, sn:=(sys-min(sys))/(max(sys)-min(sys)+1e-9)]
knee<-pr[which.min(sqrt(rn^2+sn^2))]
log("Total-error-optimal: rmse=%.3f sys=%.3f slope=%.3f high-end bias=%.3f", to$rmse,to$sys,to$slope,to$bias_hi)
log("MO compromise (knee):  rmse=%.3f sys=%.3f slope=%.3f high-end bias=%.3f", knee$rmse,knee$sys,knee$slope,knee$bias_hi)
fwrite(rbind(cbind(soln="total-error-optimal",to[,.(rmse,sys,slope,bias_hi)]),
             cbind(soln="MO compromise",knee[,.(rmse,sys,slope,bias_hi)])), file.path(OUT,"M3_compare.csv"))
print(pareto[, .(cost,gamma,eps,rmse,sys,slope,bias_hi)])
cat("PHASE 42b DONE\n")
