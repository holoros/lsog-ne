# Phase 46b: ensemble + uncertainty + Sobol + MOSVR, reusing saved M1-M3 rasters
# and predicting the SVM-based models (M4 SVM, M5 MOSVR) via a fast 2D predictor
# lookup grid (two predictors -> 10k SVM evaluations instead of 10M).
suppressPackageStartupMessages({
  library(randomForest); library(ranger); library(e1071); library(terra); library(data.table)
})
set.seed(20260613); terraOptions(memfrac=0.6)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase46"); dir.create(OUT,showWarnings=FALSE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}

## ---- training data ----
yod<-rast(file.path(B,"output_phase31/ME_LCMS_yod_heavy_100m.tif"))
uni<-fread(file.path(B,"output_unified/lsog_ne_plot_table.csv"), colClasses=list(character="CN"))
me<-uni[state=="ME" & !is.na(potapov_rh95) & !is.na(LAT) & !is.na(v5_total)]
pv<-project(vect(me, geom=c("LON","LAT"), crs="EPSG:4326"), crs(yod))
ex<-terra::extract(yod, pv)[,2]
me[, lcms_tsd := ifelse(is.na(ex)|ex==0, 40, 2023-ex)]
dat<-as.data.frame(me[!is.na(potapov_rh95)&!is.na(lcms_tsd), .(anylsog=as.integer(v5_total>=4), v5_total, potapov_rh95, lcms_tsd)])
w1<-sum(dat$anylsog==0)/sum(dat$anylsog==1)
log("n=%d prevalence=%.3f", nrow(dat), mean(dat$anylsog))

## ---- refit SVM-based models ----
sv4 <- svm(factor(anylsog)~potapov_rh95+lcms_tsd, data=dat, probability=TRUE, kernel="radial",
           cost=4, gamma=0.5, class.weights=c("0"=1,"1"=w1))
sv5 <- svm(v5_total~potapov_rh95+lcms_tsd, data=dat, type="eps-regression", kernel="radial",
           cost=1, gamma=1, epsilon=0.5)
dat$mo_score <- as.numeric(predict(sv5, dat))
cal5 <- glm(anylsog ~ mo_score, data=dat, family=binomial)
log("refit M4 (SVM) and M5 (MOSVR); MOSVR cal slope %.3f", coef(cal5)[2])

## ---- 2D predictor lookup grid ----
rh<-range(dat$potapov_rh95); td<-range(dat$lcms_tsd)
ngx<-220; ngy<-160
gx<-seq(rh[1],rh[2],length.out=ngx); gy<-seq(td[1],td[2],length.out=ngy)
grid<-expand.grid(potapov_rh95=gx, lcms_tsd=gy)
pr4<-attr(predict(sv4, grid, probability=TRUE),"probabilities"); p4<-pr4[, "1"]
s5<-as.numeric(predict(sv5, grid)); p5<-as.numeric(predict(cal5, newdata=data.frame(mo_score=s5), type="response"))
stopifnot(length(p4)==ngx*ngy, length(p5)==ngx*ngy)   # expand.grid order: potapov_rh95 varies fastest
log("lookup grid built (%dx%d), p4 len %d", ngx, ngy, length(p4))

## ---- raster stack + fast lookup map ----
lcms_tsd<-ifel(is.na(yod)|yod==0, 40, 2023-yod)
pot0<-rast(file.path(B,"data/rasters/potapov_2019/Forest_height_2019_NAM.tif"))
win<-project(as.polygons(ext(yod), crs=crs(yod)), crs(pot0))
pot<-project(crop(pot0, win), yod, method="bilinear")
fmask<-pot>3
cv<-values(pot,mat=FALSE); tv<-values(lcms_tsd,mat=FALSE)
ii<-pmin(pmax(findInterval(cv,gx),1),ngx); jj<-pmin(pmax(findInterval(tv,gy),1),ngy)
ok<-is.finite(cv)&is.finite(tv)
lin<-(jj-1L)*ngx + ii                                  # linear index, expand.grid order (potapov fastest)
mk<-function(pv){ v<-rep(NA_real_,length(cv)); v[ok]<-pv[lin[ok]]; r<-setValues(pot,v); mask(r,fmask) }
P4<-mk(p4); names(P4)<-"SVM"; writeRaster(P4, file.path(OUT,"P_SVM_100m.tif"), overwrite=TRUE)
P5<-mk(p5); names(P5)<-"MOSVR"; writeRaster(P5, file.path(OUT,"P_MOSVR_100m.tif"), overwrite=TRUE)
v4<-values(P4,mat=FALSE);v4<-v4[is.finite(v4)]; v5<-values(P5,mat=FALSE);v5<-v5[is.finite(v5)]
log("  SVM mean P=%.3f   MOSVR mean P=%.3f", mean(v4), mean(v5))

## ---- assemble ensemble from all five ----
P1<-mask(rast(file.path(OUT,"P_RF_balanced_100m.tif")),fmask); names(P1)<-"RF"
P2<-mask(rast(file.path(OUT,"P_ranger_prob_100m.tif")),fmask); names(P2)<-"ranger"
P3<-mask(rast(file.path(OUT,"P_logistic_100m.tif")),fmask);    names(P3)<-"logistic"
ens<-c(P1,P2,P3,P4,P5)
emean<-app(ens,mean,na.rm=TRUE); esd<-app(ens,sd,na.rm=TRUE)
writeRaster(emean, file.path(OUT,"ENSEMBLE_mean_P_100m.tif"), overwrite=TRUE)
writeRaster(esd,   file.path(OUT,"ENSEMBLE_sd_P_100m.tif"),   overwrite=TRUE)
mv<-values(emean,mat=FALSE);mv<-mv[is.finite(mv)]; sv<-values(esd,mat=FALSE);sv<-sv[is.finite(sv)]
mns<-sapply(list(P1,P2,P3,P4,P5),function(r){x<-values(r,mat=FALSE);mean(x[is.finite(x)])})
log("model means: RF %.3f ranger %.3f logistic %.3f SVM %.3f MOSVR %.3f", mns[1],mns[2],mns[3],mns[4],mns[5])
log("ENSEMBLE mean=%.3f  across-model SD mean=%.3f max=%.3f", mean(mv), mean(sv), max(sv))
fwrite(data.table(model=c("RF","ranger","logistic","SVM","MOSVR","ensemble"),
   mean_P=round(c(mns,mean(mv)),3)), file.path(OUT,"S3_model_means.csv"))

## ---- clip + 2-panel figure ----
fia<-project(vect(file.path(B,"data/validation_restricted/shp/FIA_ME_true.shp")), crs(yod))
hull<-buffer(hull(aggregate(fia),type="concave_ratio",param=0.30),2000); cl<-function(r) mask(crop(r,hull),hull)
emc<-cl(emean); esc<-cl(esd)
palP<-colorRampPalette(c("#4575b4","#74add1","#fee090","#f46d43","#a50026"))(100)
palU<-colorRampPalette(c("#ffffe5","#fee391","#fe9929","#cc4c02","#662506"))(100)
png(file.path(OUT,"Fig_ensemble_prob_uncertainty.png"), width=2350, height=1850, res=210)
par(mfrow=c(1,2), mar=c(1.5,1.5,2.6,4))
plot(emc,col=palP,range=c(0,1),axes=FALSE,main="(a) Multi-model ensemble P(LSOG)",cex.main=1,plg=list(title="P(LSOG)"));lines(hull,col="grey40",lwd=0.5)
plot(esc,col=palU,range=c(0,max(sv)),axes=FALSE,main="(b) Across-model uncertainty (SD of 5 models)",cex.main=1,plg=list(title="SD"));lines(hull,col="grey40",lwd=0.5)
dev.off()

## ---- global Sobol (Saltelli/Jansen) on the ensemble ----
# Sobol over the cheap-to-evaluate members (logistic + two SVM-based), representative of the ensemble response
gl3<-glm(anylsog~potapov_rh95+lcms_tsd,data=dat,family=binomial,weights=ifelse(dat$anylsog==1,w1,1))
epred<-function(X){ p4<-attr(predict(sv4,X,probability=TRUE),"probabilities")[,"1"]
  p5<-as.numeric(predict(cal5,newdata=data.frame(mo_score=as.numeric(predict(sv5,X))),type="response"))
  p3<-predict(gl3,X,type="response"); rowMeans(cbind(p3,p4,p5)) }
n<-3000; su<-function(n)data.frame(potapov_rh95=runif(n,rh[1],rh[2]),lcms_tsd=runif(n,td[1],td[2]))
A<-su(n);Bm<-su(n);yA<-epred(A);yB<-epred(Bm);VY<-var(c(yA,yB))
sob<-rbindlist(lapply(c("potapov_rh95","lcms_tsd"),function(v){AB<-A;AB[[v]]<-Bm[[v]];yAB<-epred(AB)
  data.table(predictor=v,S1=round(mean(yB*(yAB-yA))/VY,3),ST=round(mean((yA-yAB)^2)/(2*VY),3))}))
fwrite(sob, file.path(OUT,"S1_sobol_indices.csv")); log("Sobol: %s",paste(apply(sob,1,paste,collapse="="),collapse="  "))
png(file.path(OUT,"Fig_sobol.png"),width=1500,height=1100,res=200)
barplot(t(as.matrix(sob[,.(S1,ST)])),beside=TRUE,names.arg=c("canopy height","time since\ndisturbance"),
  col=c("#4575b4","#a50026"),ylim=c(0,1),ylab="Sobol index",main="Global sensitivity of ensemble P(LSOG)")
legend("topright",c("First-order S1","Total-order ST"),fill=c("#4575b4","#a50026"),bty="n");dev.off()
cat("PHASE 46b DONE\n")
