#!/usr/bin/env Rscript
# =============================================================================
# jobD_pooled_representation.R
#
# Pooled four-state true-LSOG (strict four-axis) representation by forest-type
# group and by EPA Level III ecoregion, recomputed on the adopted basis.
#
# WHY THIS SCRIPT EXISTS
# ----------------------
# Main-text Table 4 (ecoregion) and Appendix S1 Table S6 (forest-type group),
# and the prose at manuscript P64/P65 and SI P58, were produced by
# ~/LSOG/R/phase48_representation_ci.R (26 April 2026). That script carries two
# defects relative to the basis adopted 29 July 2026:
#
#   1. A4 PROXY CONTAMINATION. phase48 line
#        cond[, a4 := ifelse(in_aoi==1, as.integer(yodh==0), a4_fia)]
#      falls back to the FIA TRTCD1 / STDORGCD treatment-and-origin proxy
#      wherever the LCMS time-since-disturbance raster returns no value. That
#      proxy passes roughly 90% of Maine conditions and the methods manuscript
#      explicitly rejects it. jobB_four_axis_no_proxy.R / jobB2_funnel_inaoi.R
#      corrected this for the per-state headlines; the pooled representation
#      tables were never re-run.
#   2. VARIANCE. phase48 pooled AREA and VAR across states and then applied a
#      delta-method ratio that drops the numerator/denominator covariance.
#
# WHAT THIS SCRIPT DOES
# ---------------------
# Recomputes the pooled quantities with jobB2's A4 rule (LCMS only, undefined
# outside the AOI) and jobA/jobB2's post-stratified ratio-of-totals estimator
# with the numerator/denominator covariance retained, pooling the four states
# as independent strata. Both FIA evaluations (x2301 and x2401) and both
# denominators (in-AOI conditional, and all forestland with undefined treated
# as failing) are computed so the adopted variant is selected on evidence
# rather than assumed. Per-state totals are emitted alongside as a check
# against the adopted headline set (ME 2.51, NH 11.28, VT 15.13, NY 12.38).
#
# FIA true plot coordinates are read server side only, used for the LCMS and
# ecoregion extractions, and immediately discarded. No coordinate and no
# per-plot record is written to any output. Every output file is an aggregate.
# =============================================================================

suppressPackageStartupMessages({ library(terra); library(rFIA); library(data.table) })
terraOptions(memfrac = 0.5)

WD  <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"
DB  <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/pooled_areas"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
log <- function(...) { cat(sprintf(...), "\n"); flush.console() }

AC2HA  <- 0.40468564224
yrs0   <- 1985:2023
HEAVY  <- c(2, 6, 7, 8, 9, 13)
LATE   <- c(261, 97, 95, 94, 241, 318, 531, 371, 129, 833)
states <- c("ME", "NH", "VT", "NY")
EVALIDS <- list(ME = c(232301, 232401), NH = c(332301, 332401),
                VT = c(502301, 502401), NY = c(362301, 362401))
tiledir <- function(st) if (st == "ME") file.path(WD, "aoi") else file.path(WD, paste0("aoi_", st))

ECO <- vect(file.path(WD, "ecoregion", "us_eco_l3.shp"))
namecol <- intersect(c("US_L3NAME", "L3_KEY", "NA_L3NAME"), names(ECO))[1]

ftgrp <- function(f) { g <- rep("Other", length(f))
  g[f >= 101 & f <= 119] <- "White/red/jack pine"; g[f >= 121 & f <= 129] <- "Spruce/fir"
  g[f >= 381 & f <= 399] <- "Other softwood";      g[f >= 401 & f <= 409] <- "Oak/pine"
  g[f >= 501 & f <= 599] <- "Oak/hickory";         g[f >= 701 & f <= 722] <- "Elm/ash/cottonwood"
  g[f >= 801 & f <= 809] <- "Maple/beech/birch";   g[f >= 901 & f <= 909] <- "Aspen/birch"; g }

comp_by_group <- function(cond, ppsa, pop, ycol, xcol, gcol) {
  j <- merge(cond[, .(PLT_CN, CONDID, CONDPROP_UNADJ, g = as.character(get(gcol)),
                      y_ind = as.numeric(get(ycol)), x_ind = as.numeric(get(xcol)))],
             ppsa, by = "PLT_CN")
  j <- merge(j, pop, by = "STRATUM_CN")
  j[is.na(y_ind), y_ind := 0]; j[is.na(x_ind), x_ind := 0]
  j[is.na(g), g := "Unknown"]
  j[, y0 := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * y_ind]
  j[, x0 := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * x_ind]
  gs <- sort(unique(j$g))
  rbindlist(lapply(gs, function(gg) {
    p <- j[, .(y = sum(y0 * (g == gg)), x = sum(x0 * (g == gg))),
           by = .(STRATUM_CN, EXPNS, PLT_CN)]
    h <- p[, .(n = .N, ybar = mean(y), xbar = mean(x), vy = var(y), vx = var(x),
               cxy = if (.N > 1) cov(y, x) else 0), by = .(STRATUM_CN, EXPNS)]
    h[is.na(vy), vy := 0][is.na(vx), vx := 0][is.na(cxy), cxy := 0]
    data.table(grp = gg,
               TY  = sum(h$EXPNS * h$n * h$ybar),   TX  = sum(h$EXPNS * h$n * h$xbar),
               VY  = sum(h$EXPNS^2 * h$n * h$vy),   VX  = sum(h$EXPNS^2 * h$n * h$vx),
               CXY = sum(h$EXPNS^2 * h$n * h$cxy))
  }))
}

finish <- function(d) {
  d <- copy(d)
  d[, R := fifelse(TX > 0, TY / TX, NA_real_)]
  d[, varR := fifelse(TX > 0, (VY - 2 * R * CXY + R^2 * VX) / TX^2, NA_real_)]
  d[, pct := 100 * R]
  d[, se  := 100 * sqrt(pmax(varR, 0))]
  d[, lo  := pmax(0, pct - 1.96 * se)]
  d[, hi  := pct + 1.96 * se]
  d[, forest_kha    := TX * AC2HA / 1000]
  d[, truelsog_kha  := TY * AC2HA / 1000]
  d
}

comps <- list()

for (st in states) {
  log("==== %s ====", st)
  fls <- file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0)); fls <- fls[file.exists(fls)]
  yrs <- as.integer(gsub(".*lcms_|\\.tif", "", fls))
  log("  LCMS layers: %d (%d-%d)", length(fls), min(yrs), max(yrs))
  stk <- rast(fls)
  yod <- rast(stk, nlyr = 1); values(yod) <- 0
  for (i in seq_along(yrs)) yod <- max(yod, (stk[[i]] %in% HEAVY) * yrs[i], na.rm = TRUE)
  yodf <- focal(yod, w = 3, fun = "max", na.policy = "omit")

  fia <- readFIA(DB, states = st)
  tr <- as.data.table(fia$TREE)[!is.na(DIA) & !is.na(TPA_UNADJ),
         .(PLT_CN, CONDID, STATUSCD, SPCD, DIA, BA = 0.005454 * DIA^2 * TPA_UNADJ)]
  liv <- tr[STATUSCD == 1]; dead <- tr[STATUSCD == 2 & DIA >= 5]
  agg <- liv[, .(BA_live  = sum(BA, na.rm = TRUE),
                 BA_large = sum(BA[DIA >= 16], na.rm = TRUE),
                 BA_late  = sum(BA[SPCD %in% LATE], na.rm = TRUE)), by = .(PLT_CN, CONDID)]
  sn <- dead[, .(BA_snag = sum(BA, na.rm = TRUE)), by = .(PLT_CN, CONDID)]
  agg <- merge(agg, sn, by = c("PLT_CN", "CONDID"), all.x = TRUE)
  agg[is.na(BA_snag), BA_snag := 0]

  cond <- as.data.table(fia$COND)
  cond <- merge(cond, agg, by = c("PLT_CN", "CONDID"), all.x = TRUE)
  for (v in c("BA_live", "BA_large", "BA_late", "BA_snag")) cond[is.na(get(v)), (v) := 0]
  cond[, a1 := as.integer(BA_large >= 30)]
  cond[, a2 := as.integer(BA_snag  >= 5)]
  cond[, a3 := as.integer(BA_live > 0 & BA_late / BA_live >= 0.5)]

  plt <- as.data.table(fia$PLOT)[, .(CN, LON, LAT)][!is.na(LON) & !is.na(LAT)]
  pts <- vect(plt, geom = c("LON", "LAT"), crs = "EPSG:4269")
  pv  <- project(pts, crs(yodf)); plt[, yodh := terra::extract(yodf, pv)[, 2]]
  plt[, in_aoi := as.integer(!is.na(yodh))]
  pe  <- project(pts, crs(ECO));  plt[, ECO_L3 := terra::extract(ECO[, namecol], pe)[[2]]]
  cond <- merge(cond, plt[, .(PLT_CN = CN, yodh, in_aoi, ECO_L3)], by = "PLT_CN", all.x = TRUE)
  cond[is.na(in_aoi), in_aoi := 0L]
  cond[is.na(ECO_L3), ECO_L3 := "Unknown"]
  rm(plt, pts, pv, pe, stk, yod, yodf); gc()

  cond[, a4_lcms := ifelse(in_aoi == 1, as.integer(yodh == 0), NA_integer_)]
  cond[, a123    := as.integer(a1 == 1 & a2 == 1 & a3 == 1)]
  cond[, forest  := as.integer(COND_STATUS_CD == 1)]
  cond[, c4_lcms := as.integer(a123 == 1 & !is.na(a4_lcms) & a4_lcms == 1)]
  cond[, FORTGRP := ftgrp(FORTYPCD)]
  cond[, allgrp  := "ALL"]
  cond[, y_true  := as.integer(forest == 1 & c4_lcms == 1)]
  cond[, x_aoi   := as.integer(forest == 1 & in_aoi == 1)]
  cond[, x_all   := forest]

  for (ev in EVALIDS[[st]]) {
    ppsa <- as.data.table(fia$POP_PLOT_STRATUM_ASSGN)[EVALID == ev, .(PLT_CN, STRATUM_CN)]
    pop  <- as.data.table(fia$POP_STRATUM)[EVALID == ev,
              .(STRATUM_CN = CN, EXPNS, ADJ_FACTOR_SUBP)]
    if (!nrow(ppsa)) { log("  EVALID %d absent, skipped", ev); next }
    for (dom in c("aoi", "all")) {
      xcol <- if (dom == "aoi") "x_aoi" else "x_all"
      for (gname in c("allgrp", "FORTGRP", "ECO_L3")) {
        cc <- comp_by_group(cond, ppsa, pop, "y_true", xcol, gname)
        cc[, `:=`(state = st, evalid = ev, domain = dom, grouping = gname)]
        comps[[length(comps) + 1]] <- cc
      }
    }
    log("  EVALID %d done", ev)
  }
  rm(cond, fia, tr, liv, dead, agg, sn); gc()
  saveRDS(comps, file.path(OUT, "jobD_components_partial.rds"))
}

CO <- rbindlist(comps)
fwrite(CO, file.path(OUT, "jobD_components_raw.csv"))

ps <- finish(CO[grouping == "allgrp"])
fwrite(ps[, .(state, evalid, domain, pct = round(pct, 2), se = round(se, 3),
              lo = round(lo, 2), hi = round(hi, 2),
              forest_kha = round(forest_kha, 1), truelsog_kha = round(truelsog_kha, 1))],
       file.path(OUT, "jobD_perstate_check.csv"))
log("=== per-state four-axis check ===")
print(ps[, .(state, evalid, domain, pct = round(pct,2), lo = round(lo,2), hi = round(hi,2))])

pooled <- function(gname) {
  p <- CO[grouping == gname, .(TY = sum(TY), TX = sum(TX), VY = sum(VY),
                               VX = sum(VX), CXY = sum(CXY)),
          by = .(grouping, evalid_set = ifelse((evalid %/% 100) %% 100 == 23, "x2301", "x2401"),
                 domain, grp)]
  finish(p)[order(evalid_set, domain, -forest_kha)]
}
outc <- function(d) d[, .(evalid_set, domain, group = grp,
                          forest_kha   = round(forest_kha, 0),
                          pct          = round(pct, 1),
                          lo           = round(lo, 1),
                          hi           = round(hi, 1),
                          se           = round(se, 3),
                          truelsog_kha = round(truelsog_kha, 0))]

ft <- pooled("FORTGRP"); es <- pooled("ECO_L3"); al <- pooled("allgrp")
fwrite(outc(ft), file.path(OUT, "jobD_pooled_fortype.csv"))
fwrite(outc(es), file.path(OUT, "jobD_pooled_ecoregion.csv"))
fwrite(outc(al), file.path(OUT, "jobD_pooled_overall.csv"))

log("=== POOLED FOREST TYPE ==="); print(outc(ft))
log("=== POOLED ECOREGION ===");   print(outc(es))
log("=== POOLED OVERALL ===");     print(outc(al))
cat("JOBD DONE\n")
