# Phase 47: stress test of headline conclusions under perturbed analytical choices.
# Plot-table only (fast). Perturbs v5 thresholds, axis inclusion, and FIA panel,
# and checks (a) regional ordering "Maine lowest", (b) true-LSOG rarity,
# (c) design-based any-LSOG share stability.
suppressPackageStartupMessages({ library(data.table) })
set.seed(20260613)
B<-"/users/PUOM0008/crsfaaron/LSOG"; OUT<-file.path(B,"output_phase47"); dir.create(OUT,showWarnings=FALSE)
log<-function(...) {cat(sprintf(...),"\n"); flush.console()}
uni<-fread(file.path(B,"output_unified/lsog_ne_plot_table.csv"), colClasses=list(character="CN"))
uni<-uni[!is.na(v5_total) & state %in% c("ME","NH","VT","NY")]
log("plots: %s", paste(capture.output(print(table(uni$state))), collapse=" "))

## EXPNS design-based weighting if available, else unweighted plot share
hasw <- "EXPNS" %in% names(uni)
share_by_state <- function(dt, flagcol){
  if(hasw) dt[, .(share=100*sum(get(flagcol)*EXPNS, na.rm=TRUE)/sum(EXPNS, na.rm=TRUE)), by=state]
  else     dt[, .(share=100*mean(get(flagcol), na.rm=TRUE)), by=state]
}

## ---- Stress 1: integrated any-LSOG threshold (TLS cutoff) ----
res<-list()
for(thr in c(3,4,5)){
  uni[, flag := as.integer(v5_total>=thr)]
  s<-share_by_state(uni,"flag")[order(share)]
  me_rank<-which(s$state=="ME"); me_share<-s[state=="ME",share]
  res[[paste0("anyLSOG_thr",thr)]]<-data.table(test=sprintf("any-LSOG cutoff v5>=%d",thr),
      ME=round(me_share,1), ME_rank_of_4=me_rank, ME_lowest=(me_rank==1),
      ordering=paste(s$state,collapse="<"))
}
## ---- Stress 2: true-LSOG (all-axis) cutoff ----
for(thr in c(7,8,9)){
  uni[, flag := as.integer(v5_total>=thr)]
  s<-share_by_state(uni,"flag")[order(share)]
  res[[paste0("trueLSOG_thr",thr)]]<-data.table(test=sprintf("true-LSOG cutoff v5>=%d",thr),
      ME=round(s[state=="ME",share],1), ME_rank_of_4=which(s$state=="ME"),
      ME_lowest=(which(s$state=="ME")==1), ordering=paste(s$state,collapse="<"))
}
## ---- Stress 3: drop the canopy (Potapov) dimension from the score ----
if("s_canopy_height" %in% names(uni)){
  uni[, v5_nocanopy := v5_total - ifelse(is.na(s_canopy_height),0,s_canopy_height)]
  for(thr in c(4)){ uni[, flag := as.integer(v5_nocanopy>=thr)]
    s<-share_by_state(uni,"flag")[order(share)]
    res[["drop_canopy"]]<-data.table(test="any-LSOG, canopy dim removed (v5_nocanopy>=4)",
        ME=round(s[state=="ME",share],1), ME_rank_of_4=which(s$state=="ME"),
        ME_lowest=(which(s$state=="ME")==1), ordering=paste(s$state,collapse="<")) }
}
## ---- Stress 4: FIA panel / eval period ----
if("eval_period" %in% names(uni)){
  for(p in unique(uni$eval_period)){
    sub<-uni[eval_period==p]; if(nrow(sub)<500) next
    sub[, flag := as.integer(v5_total>=4)]
    s<-share_by_state(sub,"flag")[order(share)]
    if(!"ME" %in% s$state) next
    res[[paste0("panel_",p)]]<-data.table(test=sprintf("any-LSOG by panel %s",p),
        ME=round(s[state=="ME",share],1), ME_rank_of_4=which(s$state=="ME"),
        ME_lowest=(which(s$state=="ME")==1), ordering=paste(s$state,collapse="<"))
  }
}
## ---- Stress 5: bootstrap CI for ME any-LSOG share (1000 reps, plot resample) ----
me<-uni[state=="ME"]; me[, flag := as.integer(v5_total>=4)]
bs<-replicate(1000, { idx<-sample(nrow(me),replace=TRUE)
  if(hasw) 100*sum(me$flag[idx]*me$EXPNS[idx])/sum(me$EXPNS[idx]) else 100*mean(me$flag[idx]) })
log("ME any-LSOG bootstrap mean %.1f [%.1f, %.1f]", mean(bs), quantile(bs,.025), quantile(bs,.975))

out<-rbindlist(res, fill=TRUE)
fwrite(out, file.path(OUT,"ST1_threshold_panel_stress.csv"))
fwrite(data.table(metric="ME_anyLSOG_boot", mean=round(mean(bs),1),
   lo=round(quantile(bs,.025),1), hi=round(quantile(bs,.975),1), weighted=hasw),
   file.path(OUT,"ST2_bootstrap.csv"))
log("Maine-lowest holds in %d of %d threshold/panel tests", sum(out$ME_lowest,na.rm=TRUE), nrow(out))
print(out)
cat("PHASE 47 DONE\n")
