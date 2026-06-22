# Phase 46: finalize MOSVR, global Sobol sensitivity, multi-model LSOG probability
# ensemble with per-pixel uncertainty. Predictors: Potapov canopy height + LCMS
# time-since-disturbance. Five structurally diverse learners.
suppressPackageStartupMessages({
  library(randomForest); library(ranger); library(e1071); library(nnet)
  library(terra); library(data.table)
})
set.seed(20260613); terraOptions(memfrac=0.6)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase46"); dir.create(OUT,showWarnings=FALSE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}

## ---- training data ----
yod<-rast(file.path(B,"output_phase31/ME_LCMS_yod_heavy_100m.tif"))
uni<-fread(file.path(B,"output_unified/lsog_ne_plot_table.csv"), colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT) & !is.na(v5_total)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
ext_yod<-terra::extract(yod, pv)[,2]
me[, lcms_tsd := ifelse(is.na(ext_yod)|ext_yod==0, 40, 2023-ext_yod)]
dat<-me[!is.na(potapov_rh95) & !is.na(lcms_tsd) & !is.na(v5_total)]
dat[, anylsog := as.integer(v5_total>=4)]          # any-LSOG (TLS+LS+OG)
dat<-as.data.frame(dat[, .(anylsog, v5_total, potapov_rh95, lcms_tsd)])
log("n=%d  any-LSOG prevalence=%.3f  v5_total range %d-%d", nrow(dat),
    mean(dat$anylsog), min(dat$v5_total), max(dat$v5_total))
ns<-min(table(dat$anylsog)); samp<-c(ns,ns)

## ---- fit five learners ----
rf1 <- randomForest(factor(anylsog)~potapov_rh95+lcms_tsd, data=dat, ntree=600,
                    sampsize=samp, strata=factor(dat$anylsog))                 # M1 balanced RF
rg2 <- ranger(factor(anylsog)~potapov_rh95+lcms_tsd, data=dat, probability=TRUE,
              num.trees=600, class.weights=c(1,sum(dat$anylsog==0)/sum(dat$anylsog==1)))  # M2 prob forest
gl3 <- glm(anylsog~potapov_rh95+lcms_tsd, data=dat, family=binomial,
           weights=ifelse(dat$anylsog==1, sum(dat$anylsog==0)/sum(dat$anylsog==1), 1))     # M3 weighted logistic
sv4 <- svm(factor(anylsog)~potapov_rh95+lcms_tsd, data=dat, probability=TRUE,
           kernel="radial", cost=4, gamma=0.5, class.weights=c("0"=1,"1"=sum(dat$anylsog==0)/sum(dat$anylsog==1))) # M4 SVM
# M5 MOSVR: multi-objective compromise operating point (cost=1, gamma=1, eps=0.5) on v5_total
sv5 <- svm(v5_total~potapov_rh95+lcms_tsd, data=dat, type="eps-regression",
           kernel="radial", cost=1, gamma=1, epsilon=0.5)
# calibrate MOSVR score -> P(any-LSOG) by logistic of anylsog on in-sample predicted score
cal5 <- glm(dat$anylsog ~ predict(sv5, dat), family=binomial)
log("fitted M1-M5. MOSVR cal coefs: %.3f %.3f", coef(cal5)[1], coef(cal5)[2])

## ---- prediction functions returning P(LSOG) ----
pf_rf  <- function(model,data,...) predict(model,data,type="prob")[,"1"]
pf_rg  <- function(model,data,...) predict(model,data)$predictions[,"1"]
pf_glm <- function(model,data,...) predict(model,data,type="response")
pf_svm <- function(model,data,...){ p<-predict(model,data,probability=TRUE); attr(p,"probabilities")[,"1"] }
pf_mo  <- function(model,data,...){ s<-predict(model,data); as.numeric(predict(cal5, newdata=data.frame(`predict(sv5, dat)`=s, check.names=FALSE), type="response")) }

## ---- raster stack ----
lcms_tsd<-ifel(is.na(yod)|yod==0, 40, 2023-yod); names(lcms_tsd)<-"lcms_tsd"
pot0<-rast(file.path(B,"data/rasters/potapov_2019/Forest_height_2019_NAM.tif"))
win<-project(as.polygons(ext(yod), crs=crs(yod)), crs(pot0))
pot<-project(crop(pot0, win), yod, method="bilinear"); names(pot)<-"potapov_rh95"
stk<-c(pot, lcms_tsd); names(stk)<-c("potapov_rh95","lcms_tsd")
fmask<-pot>3
log("raster stack ready; forest cells=%d", as.integer(global(fmask,"sum",na.rm=TRUE)[1,1]))

## ---- predict each model, mask to forest ----
predmod<-function(model,fun,nm){
  r<-terra::predict(stk, model, fun=fun, na.rm=TRUE,
                    filename=file.path(OUT,paste0("P_",nm,"_100m.tif")), overwrite=TRUE)
  r<-mask(r, fmask); names(r)<-nm
  v<-values(r,mat=FALSE); v<-v[is.finite(v)]
  log("  %s  mean P=%.3f", nm, mean(v)); r
}
# MOSVR raster: predict score then calibrate (handle name)
mo_ras<-function(){
  s<-terra::predict(stk, sv5, na.rm=TRUE)
  newd<-function(x){ d<-data.frame(x); names(d)<-"predict(sv5, dat)"; d }
  p<-app(s, function(x){ as.numeric(predict(cal5, newdata=setNames(data.frame(x),"predict(sv5, dat)"), type="response")) })
  p<-mask(p, fmask); names(p)<-"MOSVR"; writeRaster(p, file.path(OUT,"P_MOSVR_100m.tif"), overwrite=TRUE)
  v<-values(p,mat=FALSE); v<-v[is.finite(v)]; log("  MOSVR  mean P=%.3f", mean(v)); p
}
P1<-predmod(rf1, pf_rf, "RF_balanced")
P2<-predmod(rg2, pf_rg, "ranger_prob")
P3<-predmod(gl3, pf_glm,"logistic")
P4<-predmod(sv4, pf_svm,"SVM")
P5<-mo_ras()

## ---- ensemble mean + uncertainty ----
ens<-c(P1,P2,P3,P4,P5)
emean<-app(ens, mean, na.rm=TRUE); names(emean)<-"ens_mean"
esd  <-app(ens, sd,   na.rm=TRUE); names(esd)<-"ens_sd"
writeRaster(emean, file.path(OUT,"ENSEMBLE_mean_P_100m.tif"), overwrite=TRUE)
writeRaster(esd,   file.path(OUT,"ENSEMBLE_sd_P_100m.tif"),   overwrite=TRUE)
mv<-values(emean,mat=FALSE); mv<-mv[is.finite(mv)]
sv<-values(esd,mat=FALSE);   sv<-sv[is.finite(sv)]
log("ENSEMBLE mean=%.3f  mean across-model SD=%.3f (max %.3f)", mean(mv), mean(sv), max(sv))
# model agreement: how many models exceed area-matched (design-based 14.1%) threshold
thr<-as.numeric(quantile(mv, 1-0.141))
agree<-app(ens, function(x) sum(x>=thr, na.rm=TRUE)); names(agree)<-"n_models"; agree<-mask(agree,fmask)
writeRaster(agree, file.path(OUT,"ENSEMBLE_agreement_100m.tif"), overwrite=TRUE)

## ---- clip to Maine for figures ----
fia<-project(vect(file.path(B,"data/validation_restricted/shp/FIA_ME_true.shp")), crs(yod))
hull<-buffer(hull(aggregate(fia), type="concave_ratio", param=0.30), 2000)
cl<-function(r) mask(crop(r,hull),hull)
emc<-cl(emean); esc<-cl(esd)
palP<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
palU<-colorRampPalette(c("#f7fcf5","#a1d99b","#41ab5d","#006d2c","#00441b"))(100)
png(file.path(OUT,"Fig_ensemble_prob_uncertainty.png"), width=2300, height=1850, res=210)
par(mfrow=c(1,2), mar=c(1.5,1.5,2.4,3))
plot(emc, col=palP, range=c(0,1), axes=FALSE, main="(a) Multi-model ensemble P(LSOG)", cex.main=1, plg=list(title="P(LSOG)"))
lines(hull,col="grey40",lwd=0.5)
plot(esc, col=palU, range=c(0,max(sv)), axes=FALSE, main="(b) Across-model uncertainty (SD)", cex.main=1, plg=list(title="SD"))
lines(hull,col="grey40",lwd=0.5)
dev.off()

## ---- global Sobol sensitivity (Saltelli 2010 estimators), ensemble + per model ----
sobol_fun<-function(predict_ensemble, X){ predict_ensemble(X) }
n<-4000
rng<-function(v) c(min(dat[[v]]), max(dat[[v]]))
rh<-rng("potapov_rh95"); td<-rng("lcms_tsd")
samp_unif<-function(n){ data.frame(potapov_rh95=runif(n,rh[1],rh[2]), lcms_tsd=runif(n,td[1],td[2])) }
A<-samp_unif(n); Bm<-samp_unif(n)
ens_pred<-function(X){ rowMeans(cbind(pf_rf(rf1,X),pf_rg(rg2,X),pf_glm(gl3,X),pf_svm(sv4,X),
                                      as.numeric(predict(cal5,newdata=setNames(data.frame(predict(sv5,X)),"predict(sv5, dat)"),type="response")))) }
yA<-ens_pred(A); yB<-ens_pred(Bm); f0<-mean(c(yA,yB)); VY<-var(c(yA,yB))
sob<-rbindlist(lapply(c("potapov_rh95","lcms_tsd"), function(v){
  AB<-A; AB[[v]]<-Bm[[v]]; yAB<-ens_pred(AB)
  Si <- mean(yB*(yAB-yA))/VY                       # Saltelli 2010 first-order
  STi<- mean((yA-yAB)^2)/(2*VY)                     # total-order (Jansen)
  data.table(predictor=v, S1=round(Si,3), ST=round(STi,3))
}))
fwrite(sob, file.path(OUT,"S1_sobol_indices.csv"))
log("Sobol (ensemble): %s", paste(apply(sob,1,function(r) paste(r,collapse="=")), collapse="  "))
png(file.path(OUT,"Fig_sobol.png"), width=1500, height=1100, res=200)
bp<-barplot(t(as.matrix(sob[,.(S1,ST)])), beside=TRUE, names.arg=c("canopy height","time since\ndisturbance"),
            col=c("#4575b4","#a50026"), ylim=c(0,1), ylab="Sobol index", main="Global sensitivity of ensemble P(LSOG)")
legend("topright", c("First-order S1","Total-order ST"), fill=c("#4575b4","#a50026"), bty="n"); dev.off()

## ---- MOSVR Pareto front (reuse grid) + final operating point ----
folds<-sample(rep(1:5,length.out=nrow(dat)))
cv_obj<-function(cost,gamma,eps){ ph<-rep(NA_real_,nrow(dat))
  for(k in 1:5){ tr<-folds!=k
    m<-tryCatch(svm(v5_total~potapov_rh95+lcms_tsd,data=dat[tr,],type="eps-regression",kernel="radial",cost=cost,gamma=gamma,epsilon=eps),error=function(e)NULL)
    if(!is.null(m)) ph[!tr]<-as.numeric(predict(m,dat[!tr,])) }
  ok<-is.finite(ph); rmse<-sqrt(mean((dat$v5_total[ok]-ph[ok])^2))
  sl<-as.numeric(coef(lm(dat$v5_total[ok]~ph[ok]))[2]); c(rmse=rmse,sys=abs(1-sl),slope=sl) }
grid<-expand.grid(cost=c(1,4,16),gamma=c(0.25,1,4),eps=c(0.1,0.5))
par_res<-rbindlist(lapply(1:nrow(grid),function(i){o<-cv_obj(grid$cost[i],grid$gamma[i],grid$eps[i])
  data.table(cost=grid$cost[i],gamma=grid$gamma[i],eps=grid$eps[i],rmse=round(o["rmse"],3),sys=round(o["sys"],3),slope=round(o["slope"],3))}))
fwrite(par_res, file.path(OUT,"S2_mosvr_pareto_full.csv"))
log("MOSVR final operating point: cost=1 gamma=1 eps=0.5 (compromise)")
cat("PHASE 46 DONE\n")
