# =============================================================================
# Phase 20: Quantify the harvest flux vs net stock directly from FIA growth,
# removal, and mortality (GRM), for the large-tree pool (DIA >= 16 in) that
# defines older forest, and overall. Makes the "aging replaces harvest" mechanism
# a measurement rather than an inference. Outputs: ~/LSOG/output_phase20/
# =============================================================================
suppressPackageStartupMessages({ library(rFIA); library(data.table) })
DB <- "/users/PUOM0008/crsfaaron/fia_data"
OUT<- "/users/PUOM0008/crsfaaron/LSOG/output_phase20"; dir.create(OUT, showWarnings=FALSE, recursive=TRUE)
log <- function(...) cat(sprintf(...),"\n")
me <- readFIA(DB, states="ME")

show <- function(g, lab){
  g <- as.data.table(g)
  yr <- max(g$YEAR); r <- g[YEAR==yr]
  log("== %s (year %s) ==", lab, yr)
  log("  columns: %s", paste(names(r), collapse=", "))
  fwrite(g, file.path(OUT, paste0(gsub("[^A-Za-z0-9]+","_",lab),".csv")))
  # print the key percent rates if present
  for(cn in grep("PERC|RATE|GROW|REMV|MORT|RECR|CHNG", names(r), value=TRUE))
    log("  %-22s = %s", cn, formatC(as.numeric(r[[cn]][1]), digits=3, format="g"))
}
# overall and large-tree pool growth/removal/mortality
log("Running growMort (all trees) ...")
show(growMort(me, variance=TRUE), "growMort all trees (volume)")
log("Running growMort (large trees DIA>=16in) ...")
show(growMort(me, treeDomain = DIA >= 16, variance=TRUE), "growMort large trees DIA ge 16in")
# basal-area basis if supported
ok <- tryCatch({ show(growMort(me, treeDomain = DIA >= 16, variance=TRUE, component="BAA"), "growMort large trees BAA"); TRUE },
               error=function(e){ log("BAA component not available: %s", conditionMessage(e)); FALSE })
log("DONE Phase 20.")
