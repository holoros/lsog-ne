# =============================================================================
# Phase 42: multi-objective SVR (MOSVR) pilot for LSOG, after Legaard, Simons-
# Legaard & Weiskittel (2020). Single-objective regression attenuates rare high
# values (here the multidimensional LSOG score, where high = old growth). We fit
# SVR over a hyperparameter grid and evaluate TWO objectives by 5-fold CV: total
# error (RMSE) and systematic error / attenuation (departure of the obs~pred
# slope from 1). We map the Pareto front and contrast the total-error-optimal
# solution with a balanced (knee) solution, showing reduced attenuation of the
# rare old-growth end. Output: ~/LSOG/output_phase42/
# =============================================================================
suppressPackageStartupMessages({ library(e1071); library(terra); library(data.table) })
set.seed(20260613)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase42"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")
yod<-rast("/users/PUOM0008/crsfaaron/LSOG/output_phase31/ME_LCMS_yod_heavy_100m.tif")
uni<-fread("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT) & !is.na(v5_total)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
me[, lcms_yod:=terra::extract(yod, pv)[,2]]
me[, lcms_tsd:=ifelse(is.na(lcms_yod)|lcms_yod==0, 40, 2023-lcms_yod)]
me<-me[sample(.N, min(.N, 4000))]   # subsample for SVR speed
X<-scale(as.matrix(me[, .(potapov_rh95, lcms_tsd)])); y<-me$v5_total
folds<-sample(rep(1:5, length.out=nrow(me)))

cv_obj<-function(cost, gamma, eps){
  ph<-numeric(length(y))
  for(k in 1:5){ tr<-folds!=k
    m<-svm(X[tr,], y[tr], type="eps-regression", kernel="radial", cost=cost, gamma=gamma, epsilon=eps)
    ph[!tr]<-predict(m, X[!tr,]) }
  rmse<-sqrt(mean((y-ph)^2))
  sl<-coef(lm(y~ph))[2]            # obs ~ pred slope; <1 = attenuation
  sys<-abs(1-sl)                   # systematic error (attenuation magnitude)
  # high-end underprediction: mean(pred-obs) in top observed decile (negative = underpredict)
  hi<-y>=quantile(y,0.9); bias_hi<-mean(ph[hi]-y[hi])
  c(rmse=rmse, sys=sys, slope=sl, bias_hi=bias_hi)
}
grid<-expand.grid(cost=c(0.5,2,8,32), gamma=c(0.1,0.5,2), eps=c(0.1,0.5,1))
res<-rbindlist(lapply(1:nrow(grid), function(i){
  o<-cv_obj(grid$cost[i],grid$gamma[i],grid$eps[i])
  data.table(cost=grid$cost[i],gamma=grid$gamma[i],eps=grid$eps[i],
             rmse=round(o["rmse"],3),sys=round(o["sys"],3),slope=round(o["slope"],3),bias_hi=round(o["bias_hi"],3)) }))
# Pareto front on (rmse, sys): non-dominated points
res<-res[is.finite(rmse) & is.finite(sys)]
res[, dominated:=FALSE]
for(i in 1:nrow(res)) for(j in 1:nrow(res)) if(i!=j)
  if(isTRUE(res$rmse[j]<=res$rmse[i] & res$sys[j]<=res$sys[i] & (res$rmse[j]<res$rmse[i]|res$sys[j]<res$sys[i]))) res$dominated[i]<-TRUE
pareto<-res[dominated==FALSE][order(rmse)]
fwrite(res, file.path(OUT,"M1_grid_objectives.csv")); fwrite(pareto, file.path(OUT,"M2_pareto.csv"))
to<-res[which.min(rmse)]            # total-error-optimal (single-objective analogue)
# knee = pareto point minimizing normalized distance to ideal
pr<-copy(pareto); pr[, rn:=(rmse-min(rmse))/(max(rmse)-min(rmse)+1e-9)][, sn:=(sys-min(sys))/(max(sys)-min(sys)+1e-9)]
knee<-pr[which.min(sqrt(rn^2+sn^2))]
log("Total-error-optimal: rmse=%.3f sys=%.3f slope=%.3f high-end bias=%.3f", to$rmse,to$sys,to$slope,to$bias_hi)
log("MO compromise (knee): rmse=%.3f sys=%.3f slope=%.3f high-end bias=%.3f", knee$rmse,knee$sys,knee$slope,knee$bias_hi)
log("Pareto front (%d non-dominated of %d):", nrow(pareto), nrow(res)); print(pareto[, .(cost,gamma,eps,rmse,sys,slope,bias_hi)])
fwrite(rbind(cbind(soln="total-error-optimal",to[,.(rmse,sys,slope,bias_hi)]),
             cbind(soln="MO compromise",knee[,.(rmse,sys,slope,bias_hi)])), file.path(OUT,"M3_compare.csv"))
cat("PHASE 42 DONE\n")
