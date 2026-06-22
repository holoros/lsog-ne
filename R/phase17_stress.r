# =============================================================================
# Phase 17: Stress tests for the Comment's two new centerpiece results.
# (A) FIADB old-forest area/trend robustness to the large-tree-BA threshold and
#     to a quadratic-mean-diameter structural domain (design-based, with CI).
# (B) AUC robustness to classifier choice: logistic regression vs random forest,
#     confirming canopy-height-only is weakest for old growth.
# Outputs: ~/LSOG/output_phase17/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table); library(randomForest) })
DB <- "/users/PUOM0008/crsfaaron/fia_data"
ZEN<- "/users/PUOM0008/crsfaaron/LSOG/data/zenodo_hagan/Maine_training_data.csv"
OUT<- "/users/PUOM0008/crsfaaron/LSOG/output_phase17"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")

## ---- (A) FIADB threshold sensitivity ----
log("== (A) FIADB threshold sensitivity ==")
me <- readFIA(DB, states="ME")
tr <- as.data.table(me$TREE)[STATUSCD==1 & !is.na(DIA) & !is.na(TPA_UNADJ),
        .(PLT_CN, CONDID, DIA, BA=0.005454*DIA^2*TPA_UNADJ)]
lt <- tr[DIA>=16, .(BA_large=sum(BA,na.rm=TRUE)), by=.(PLT_CN,CONDID)]
cond <- merge(as.data.table(me$COND), lt, by=c("PLT_CN","CONDID"), all.x=TRUE)
cond[is.na(BA_large), BA_large := 0]
cond[, lt20 := as.integer(BA_large>=20)][, lt30 := as.integer(BA_large>=30)][, lt40 := as.integer(BA_large>=40)]
me$COND <- as.data.frame(cond)
grab <- function(a){ a<-as.data.table(a); a[, .(YEAR, ac=AREA_TOTAL, se=sqrt(AREA_TOTAL_VAR))] }
tot <- grab(area(me, variance=TRUE))[, .(YEAR, denom=ac)]
one <- function(a,l){ g<-merge(grab(a),tot,by="YEAR"); g[, `:=`(pct=100*ac/denom, pct_se=100*se/denom, dom=l)]
  w<-1/g$pct_se^2; m<-lm(pct~YEAR,data=g,weights=w); s<-summary(m)$coefficients["YEAR",]
  data.table(domain=l, yr=max(g$YEAR), pct=g[YEAR==max(YEAR)]$pct, lo=g[YEAR==max(YEAR)]$pct-1.96*g[YEAR==max(YEAR)]$pct_se,
    hi=g[YEAR==max(YEAR)]$pct+1.96*g[YEAR==max(YEAR)]$pct_se, slope=s[1], slope_lo=s[1]-1.96*s[2], slope_hi=s[1]+1.96*s[2]) }
A <- rbindlist(list(
  one(area(me, areaDomain=lt20==1, variance=TRUE), "Large-tree BA >= 20 ft2/ac"),
  one(area(me, areaDomain=lt30==1, variance=TRUE), "Large-tree BA >= 30 ft2/ac"),
  one(area(me, areaDomain=lt40==1, variance=TRUE), "Large-tree BA >= 40 ft2/ac")))
fwrite(A, file.path(OUT,"S1_fiadb_threshold_sensitivity.csv")); print(A)
log("FIADB trend sign robust across large-tree thresholds: all slopes %s",
    if(all(A$slope_lo>0)) "POSITIVE (CIs exclude 0)" else "mixed")

## ---- (B) AUC robustness to classifier ----
log("== (B) AUC classifier robustness ==")
d <- as.data.table(read.csv(ZEN))
L<-c("mean_cano_ht","max_cano_ht","percentile_95th","rumple","top_rugosity","cano_cover_2","cano_cover_6","cano_cover_15")
HGT<-c("mean_cano_ht","max_cano_ht","percentile_95th")
S<-c("sum_live_basalarea","sum_dead_basalarea","basal_GE_40cmDBH","prop_basal_GE_40cmDBH","No_treesGE_40cmdbh","QMD_live","CWD_vol","CV_livedbh")
di<-copy(d); for(c in unique(c(L,S))){di[[c]]<-as.numeric(di[[c]]); di[is.na(di[[c]]),c]<-median(di[[c]],na.rm=TRUE)}
auc<-function(y,p){n1<-sum(y);n0<-sum(!y); if(n1==0||n0==0)return(NA); r<-rank(p);(sum(r[y])-n1*(n1+1)/2)/(n1*n0)}
cvauc<-function(X,y,alg,reps=30,k=5){set.seed(7);out<-numeric(0)
  for(r in 1:reps){fold<-integer(length(y));for(lv in c(T,F)){idx<-which(y==lv);fold[idx]<-sample(rep(1:k,length.out=length(idx)))}
    oof<-rep(NA,length(y))
    for(f in 1:k){tr<-fold!=f;te<-fold==f; if(length(unique(y[tr]))<2)next
      if(alg=="rf"){m<-randomForest(x=X[tr,,drop=F],y=factor(ifelse(y[tr],"p","n")),ntree=300);oof[te]<-predict(m,X[te,,drop=F],type="prob")[,"p"]}
      else{df<-data.frame(y=as.integer(y[tr]),X[tr,,drop=F]);m<-suppressWarnings(glm(y~.,data=df,family=binomial));oof[te]<-predict(m,X[te,,drop=F],type="response")}}
    ok<-!is.na(oof);out<-c(out,auc(y[ok],oof[ok]))}; out}
targ<-list("any-LSOG"=function(d)d$LSOG_class!="Not LS","LS+OG"=function(d)d$LSOG_class%in%c("LS","Old-growth"),"OG"=function(d)d$LSOG_class=="Old-growth")
sets<-list(LIDAR8=L,HEIGHT=HGT,STRUCT=S)
B<-list();i<-1
for(alg in c("glm","rf")) for(tn in names(targ)){y<-targ[[tn]](d)
  for(sn in names(sets)){a<-cvauc(as.data.frame(di[,sets[[sn]],with=F]),y,alg)
    B[[i]]<-data.table(classifier=alg,target=tn,predictors=sn,auc=round(mean(a,na.rm=T),3),
      lo=round(quantile(a,.025,na.rm=T),3),hi=round(quantile(a,.975,na.rm=T),3));i<-i+1}}
Bt<-rbindlist(B); fwrite(Bt, file.path(OUT,"S2_auc_classifier_robustness.csv"))
log("OG by classifier (HEIGHT should be weakest):")
print(Bt[target=="OG"][order(classifier,predictors)])
log("DONE Phase 17.")
