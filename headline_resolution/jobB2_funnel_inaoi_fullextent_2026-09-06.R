#!/usr/bin/env Rscript
# =============================================================================
# jobB2_funnel_inaoi.R
#
# PROVENANCE, 30 July 2026. Until today this script existed only on Cardinal and
# in the frozen sha256-verified mirror at
# cardinal_scripts/headline_resolution/jobB2_funnel_inaoi.R, with no reviewed
# counterpart under version control. It was a committed producer living outside
# the repository, which is precisely the gap the prebuild gate exists to close.
# This file is that counterpart. It is the frozen mirror plus two reviewed
# additions and nothing else: a FALLBACK_RULE declaration over the retained
# contaminated A4 comparator, and an explicit per-state EVALID pin with an
# assertion, replacing the head-of-sorted-set evaluation pick. Both are ported by
# hand from the reviewed jobB_four_axis_no_proxy.R, because jobB2 is a variant of
# jobB (its original header even carried jobB's name) and the two flagged lines
# are identical in both. The pinned EVALIDs are read back from this script's own
# committed run log, so the numbers it produces are unchanged. The frozen mirror
# is left untouched, as the record of what actually ran on 29 July 2026.
#
# Recomputation of the strict four-axis LSOG score for ME, NH, VT, NY with the
# FIA age/treatment proxy fallback on axis A4 DISABLED.
#
# THE DEFECT BEING CORRECTED
# --------------------------
# ~/LSOG/R/phase31b_regional.R line 55 reads:
#
#     cond[, a4 := ifelse(in_aoi==1, as.integer(yodh==0), a4_fia)]
#
# in_aoi is 1 only where the plot falls on the LCMS time-since-disturbance
# raster and returns a non-NA year-of-detection. Where it does not, A4 silently
# falls back to a4_fia, the FIA TRTCD1 / STDORGCD treatment-and-origin proxy:
#
#     cond[, a4_fia := as.integer((is.na(TRTCD1)|TRTCD1!=10) &
#                                 (is.na(STDORGCD)|STDORGCD!=1))]
#
# That proxy is the one the methods manuscript explicitly rejects as too
# permissive (it passes roughly 90% of Maine conditions). Conditions with no
# LCMS determination therefore pass A4 at the permissive rate rather than being
# reported as undefined, and every downstream quantity that consumes the a4
# vector inherits the contamination, including the strict four-axis headline.
#
# Note also that plots with missing LON/LAT are dropped before the raster
# extract and land in the same fallback branch.
#
# WHAT THIS SCRIPT DOES
# ---------------------
# Computes, per state, four variants of A4 and of the strict four-axis score:
#
#   contaminated : a4 = LCMS in AOI, FIA proxy outside AOI  (reproduces the
#                  published 40.1% A4 and 3.1% four-axis for Maine)
#   conditional  : a4 = LCMS, restricted to the in-AOI domain; the estimate is
#                  a share of in-AOI forestland and is the definition-faithful
#                  quantity
#   lower        : a4 = LCMS in AOI, FAIL outside AOI; share of ALL forestland
#                  (undefined treated as not passing)
#   upper        : a4 = LCMS in AOI, PASS outside AOI; share of ALL forestland
#                  (undefined treated as passing; the honest upper bracket)
#
# and reports the design-based share of forestland that is undefined because it
# sits outside the LCMS area of interest.
#
# It also reports a THREE-AXIS strict score (A1 and A2 and A3, no continuity
# axis at all), which has no LCMS dependence and is available as a fallback
# framing, plus the axis-alone rates and the full funnel.
#
# Variance: rFIA::area(variance=TRUE) for quantities expressed as a share of
# all forestland, matching phase31b so the numbers are directly comparable.
# For quantities expressed as a share of a SUBSET of forestland (the in-AOI
# conditional estimates) a proper post-stratified ratio-of-totals estimator
# with the numerator/denominator covariance retained is used, because dividing
# a total's standard error by a fixed denominator overstates the interval.
# That same proper ratio estimator is reported alongside the rFIA numbers for
# the headline quantities so the two can be compared.
#
# Environment: module purge; module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 \
#                            proj/9.2.1 R/4.4.0
#              R_LIBS_USER=/users/PUOM0008/crsfaaron/R/cardinal/4.4.0:\
#                          /users/PUOM0008/crsfaaron/R/cardinal_libs/4.4.0
#
# FIA true plot coordinates are used server side only and are NEVER written to
# any output. Every output file in this script is a state-level aggregate.
# =============================================================================

suppressPackageStartupMessages({
  library(terra); library(rFIA); library(data.table)
})
terraOptions(memfrac = 0.5)

WD  <- "/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD"
DB  <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/LSOG/headline_resolution/fullextent_2026-09-06"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

log <- function(...) { cat(sprintf(...), "\n"); flush.console() }

yrs0   <- 1985:2023
HEAVY  <- c(2, 6, 7, 8, 9, 13)                       # LCMS stand-replacing / harvest classes
LATE   <- c(261, 97, 95, 94, 241, 318, 531, 371, 129, 833)
states <- c("ME", "NH", "VT", "NY")
tiledir <- function(st) file.path(WD, paste0("aoi_full_", st))

# --- rFIA area() extractor (identical to phase31b's grab()) -----------------
grab <- function(a) {
  a <- as.data.table(a)
  ar <- intersect(c("AREA_TOTAL", "AREA"), names(a))[1]
  av <- intersect(c("AREA_TOTAL_VAR", "AREA_VAR"), names(a))[1]
  a <- a[YEAR == max(YEAR)]
  list(area = a[[ar]][1], se = sqrt(a[[av]][1]))
}

# --- proper post-stratified ratio-of-totals estimator ------------------------
# Retains the covariance between numerator and denominator, which the legacy
# scripts drop. num and den are condition-level 0/1 indicator column names.
# Returns percent and its standard error.
ratio_est <- function(cond, ppsa, pop, num, den) {
  j <- merge(cond[, .(PLT_CN, CONDID, CONDPROP_UNADJ,
                      y_ind = as.numeric(get(num)), x_ind = as.numeric(get(den)))],
             ppsa, by = "PLT_CN")
  j <- merge(j, pop, by = "STRATUM_CN")
  j[is.na(y_ind), y_ind := 0]; j[is.na(x_ind), x_ind := 0]
  j[, y := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * y_ind]
  j[, x := CONDPROP_UNADJ * ADJ_FACTOR_SUBP * x_ind]
  # aggregate conditions to the plot, the sampling unit
  p <- j[, .(y = sum(y), x = sum(x)), by = .(STRATUM_CN, EXPNS, PLT_CN)]
  h <- p[, .(n = .N, ybar = mean(y), xbar = mean(x),
             vy = var(y), vx = var(x), cxy = if (.N > 1) cov(y, x) else 0),
         by = .(STRATUM_CN, EXPNS)]
  h[is.na(vy), vy := 0][is.na(vx), vx := 0][is.na(cxy), cxy := 0]
  TY <- sum(h$EXPNS * h$n * h$ybar)
  TX <- sum(h$EXPNS * h$n * h$xbar)
  if (!is.finite(TX) || TX <= 0) return(list(pct = NA_real_, se = NA_real_,
                                             num_acres = TY, den_acres = TX))
  R  <- TY / TX
  varR <- sum(h$EXPNS^2 * h$n * (h$vy - 2 * R * h$cxy + R^2 * h$vx)) / TX^2
  list(pct = 100 * R, se = 100 * sqrt(max(varR, 0)),
       num_acres = TY, den_acres = TX)
}

axis_all <- list(); funnel_all <- list(); head_all <- list(); cover_all <- list()

for (st in states) {
  log("======== %s ========", st)

  # ---- LCMS year-of-detection for stand-replacing / harvest disturbance ----
  fls <- file.path(tiledir(st), sprintf("lcms_%d.tif", yrs0))
  fls <- fls[file.exists(fls)]
  yrs <- as.integer(gsub(".*lcms_|\\.tif", "", fls))
  log("  LCMS layers found: %d (%d-%d)", length(fls), min(yrs), max(yrs))
  stk <- rast(fls)
  yod <- rast(stk, nlyr = 1); values(yod) <- 0
  for (i in seq_along(yrs)) yod <- max(yod, (stk[[i]] %in% HEAVY) * yrs[i], na.rm = TRUE)
  yodf <- focal(yod, w = 3, fun = "max", na.policy = "omit")

  # ---- FIA, most recent evaluation ----------------------------------------
  fia <- readFIA(DB, states = st)
  tr  <- as.data.table(fia$TREE)[!is.na(DIA) & !is.na(TPA_UNADJ),
          .(PLT_CN, CONDID, STATUSCD, SPCD, DIA, BA = 0.005454 * DIA^2 * TPA_UNADJ)]
  liv  <- tr[STATUSCD == 1]; dead <- tr[STATUSCD == 2 & DIA >= 5]
  agg <- liv[, .(BA_live  = sum(BA, na.rm = TRUE),
                 BA_large = sum(BA[DIA >= 16], na.rm = TRUE),
                 BA_late  = sum(BA[SPCD %in% LATE], na.rm = TRUE)),
             by = .(PLT_CN, CONDID)]
  sn <- dead[, .(BA_snag = sum(BA, na.rm = TRUE)), by = .(PLT_CN, CONDID)]
  agg <- merge(agg, sn, by = c("PLT_CN", "CONDID"), all.x = TRUE)
  agg[is.na(BA_snag), BA_snag := 0]

  cond <- as.data.table(fia$COND)
  cond <- merge(cond, agg, by = c("PLT_CN", "CONDID"), all.x = TRUE)
  for (v in c("BA_live", "BA_large", "BA_late", "BA_snag")) cond[is.na(get(v)), (v) := 0]

  cond[, a1 := as.integer(BA_large >= 30)]
  cond[, a2 := as.integer(BA_snag  >= 5)]
  cond[, a3 := as.integer(BA_live > 0 & BA_late / BA_live >= 0.5)]
  cond[, a4_fia := as.integer((is.na(TRTCD1) | TRTCD1 != 10) &
                              (is.na(STDORGCD) | STDORGCD != 1))]

  # ---- LCMS AOI membership -------------------------------------------------
  # Coordinates are used here and discarded. Nothing derived from LON/LAT other
  # than the in_aoi flag and the year-of-detection leaves this loop.
  plt <- as.data.table(fia$PLOT)[, .(CN, LON, LAT)][!is.na(LON) & !is.na(LAT)]
  pv  <- project(vect(plt, geom = c("LON", "LAT"), crs = "EPSG:4269"), crs(yodf))
  plt[, yodh := terra::extract(yodf, pv)[, 2]]
  plt[, in_aoi := as.integer(!is.na(yodh))]
  cond <- merge(cond, plt[, .(PLT_CN = CN, yodh, in_aoi)], by = "PLT_CN", all.x = TRUE)
  cond[is.na(in_aoi), in_aoi := 0L]     # includes plots with no coordinates
  rm(plt, pv); gc()

  # ---- the four A4 variants ------------------------------------------------
  # FALLBACK_RULE: a4_contam is the RETAINED CONTAMINATED COMPARATOR and is the
  # object of study in this script, not its result. It reproduces phase31b's
  # published rule verbatim (LCMS year-of-detection wins inside the AOI, the
  # rejected FIA TRTCD1 / STDORGCD proxy fills in outside it) for the sole
  # purpose of quantifying how far the published 40.1% A4 and 3.1% four-axis
  # Maine figures moved because of that substitution. It is never the adopted
  # estimate. The definition-faithful quantity is a4_lcms, which is NA outside
  # the AOI and is reported on an in-AOI denominator; a4_lower and a4_upper
  # bracket the undefined share; the adopted Maine four-axis value is 2.5%
  # [1.9, 3.1] from a4_lcms, not from this line. The fallback rate is measured
  # and printed for every state in cover_all below as pct_conds_in_aoi and
  # a4_fia_pct_conds_outside, and the design-based undefined share is reported
  # as "outside LCMS AOI (undefined)" in axis_all, so this comparator states its
  # own contamination rate rather than hiding it.
  cond[, a4_contam := ifelse(in_aoi == 1, as.integer(yodh == 0), a4_fia)]  # published
  cond[, a4_lcms   := ifelse(in_aoi == 1, as.integer(yodh == 0), NA_integer_)]
  cond[, a4_lower  := ifelse(in_aoi == 1, as.integer(yodh == 0), 0L)]
  cond[, a4_upper  := ifelse(in_aoi == 1, as.integer(yodh == 0), 1L)]

  cond[, a123 := as.integer(a1 == 1 & a2 == 1 & a3 == 1)]                  # three-axis strict
  cond[, c4_contam := as.integer(a123 == 1 & a4_contam == 1)]
  cond[, c4_lower  := as.integer(a123 == 1 & a4_lower  == 1)]
  cond[, c4_upper  := as.integer(a123 == 1 & a4_upper  == 1)]
  cond[, c4_lcms   := as.integer(a123 == 1 & a4_lcms   == 1)]              # NA outside AOI
  cond[, nmet_contam := a1 + a2 + a3 + a4_contam]
  cond[, nmet_lower  := a1 + a2 + a3 + a4_lower]
  cond[, forest := as.integer(COND_STATUS_CD == 1)]

  fia$COND <- as.data.frame(cond)

  # ---- design-based shares of ALL forestland, via rFIA ---------------------
  den <- grab(rFIA::area(fia, variance = TRUE))$area
  row <- function(lab, a, grp) {
    g <- grab(a); pct <- 100 * g$area / den; se <- 100 * g$se / den
    data.table(state = st, group = grp, metric = lab,
               pct = round(pct, 2),
               lo = round(pmax(0, pct - 1.96 * se), 2),
               hi = round(pct + 1.96 * se, 2),
               se = round(se, 3), denom = "all forestland")
  }

  axis_all[[st]] <- rbindlist(list(
    row("A1 live structure", rFIA::area(fia, areaDomain = a1 == 1, variance = TRUE), "axis"),
    row("A2 dead wood",      rFIA::area(fia, areaDomain = a2 == 1, variance = TRUE), "axis"),
    row("A3 composition",    rFIA::area(fia, areaDomain = a3 == 1, variance = TRUE), "axis"),
    row("A4 contaminated (published)", rFIA::area(fia, areaDomain = a4_contam == 1, variance = TRUE), "axis"),
    row("A4 undefined = fail",         rFIA::area(fia, areaDomain = a4_lower  == 1, variance = TRUE), "axis"),
    row("A4 undefined = pass",         rFIA::area(fia, areaDomain = a4_upper  == 1, variance = TRUE), "axis"),
    row("A4 FIA proxy alone",          rFIA::area(fia, areaDomain = a4_fia    == 1, variance = TRUE), "axis"),
    row("outside LCMS AOI (undefined)", rFIA::area(fia, areaDomain = in_aoi == 0, variance = TRUE), "coverage"),
    row("inside LCMS AOI",              rFIA::area(fia, areaDomain = in_aoi == 1, variance = TRUE), "coverage")
  ))

  funnel_all[[st]] <- rbindlist(list(
    row(">=1 axis (contaminated)",  rFIA::area(fia, areaDomain = nmet_contam >= 1, variance = TRUE), "funnel_contam"),
    row(">=2 axes (contaminated)",  rFIA::area(fia, areaDomain = nmet_contam >= 2, variance = TRUE), "funnel_contam"),
    row(">=3 axes (contaminated)",  rFIA::area(fia, areaDomain = nmet_contam >= 3, variance = TRUE), "funnel_contam"),
    row("all 4 (contaminated)",     rFIA::area(fia, areaDomain = c4_contam == 1,   variance = TRUE), "funnel_contam"),
    row(">=1 axis (undef=fail)",    rFIA::area(fia, areaDomain = nmet_lower >= 1,  variance = TRUE), "funnel_lower"),
    row(">=2 axes (undef=fail)",    rFIA::area(fia, areaDomain = nmet_lower >= 2,  variance = TRUE), "funnel_lower"),
    row(">=3 axes (undef=fail)",    rFIA::area(fia, areaDomain = nmet_lower >= 3,  variance = TRUE), "funnel_lower"),
    row("all 4 (undef=fail)",       rFIA::area(fia, areaDomain = c4_lower == 1,    variance = TRUE), "funnel_lower"),
    row("all 4 (undef=pass)",       rFIA::area(fia, areaDomain = c4_upper == 1,    variance = TRUE), "funnel_upper"),
    row("three-axis strict A1A2A3", rFIA::area(fia, areaDomain = a123 == 1,        variance = TRUE), "three_axis")
  ))

  # ---- proper post-stratified ratio estimates ------------------------------
  # including the conditional (in-AOI denominator) quantities, which cannot be
  # expressed as a share of all forestland.
  ev <- as.data.table(fia$POP_EVAL)
  evt <- as.data.table(fia$POP_EVAL_TYP)
  cur <- evt[EVAL_TYP == "EXPCURR", EVAL_CN]

  # EVAL_RULE: the EXPCURR evaluation is named per state below, not taken as the
  # first row of a set sorted on END_INVYR. Exactly one POP_EVAL row must survive
  # the filter, and the panel label is derived from that row's inventory years
  # instead of being written out anywhere.
  #
  # These four EVALIDs are the ones the committed 29 July 2026 run of THIS script
  # actually used, read back from its own log
  # headline_resolution/jobB2_12959552.out lines 3, 40, 77 and 114, which record
  # ME 232401 (2020-2024), NH 332401 (2018-2024), VT 502401 (2018-2024) and
  # NY 362401 (2018-2024). They are the same four evaluations jobB pinned, so
  # pinning them reproduces the committed jobB2 funnel and in-AOI tables exactly
  # and removes the drift, rather than changing any number.
  #
  # REPORTING NOTE: these are the END_INVYR 2024 evaluations, so PANEL below is
  # one panel step later than the 2019-2023 (ME) and 2017-2023 (NH, VT, NY)
  # windows carried by the any-LSOG set from jobC_forestland_base_ablation.py.
  # Label these numbers with PANEL, never with a window borrowed from that set.
  EVAL_PIN <- c(ME = 232401L, NH = 332401L, VT = 502401L, NY = 362401L)
  if (!st %in% names(EVAL_PIN))
    stop(sprintf("jobB2: no evaluation pinned for state %s; add it to EVAL_PIN", st))
  evsel <- ev[CN %in% cur & EVALID == EVAL_PIN[[st]]]
  if (nrow(evsel) != 1L)
    stop(sprintf(paste0("jobB2 %s: the pinned evaluation %d matched %d ",
                        "POP_EVAL rows, expected exactly 1. Candidates in this ",
                        "database: %s"),
                 st, EVAL_PIN[[st]], nrow(evsel),
                 paste(sort(ev[CN %in% cur]$EVALID), collapse = ", ")))
  EVU   <- evsel$EVALID
  PANEL <- paste0(evsel$START_INVYR, "-", evsel$END_INVYR)
  log("  ratio estimator using EVALID %s, panel %s (START_INVYR %s, END_INVYR %s)",
      EVU, PANEL, evsel$START_INVYR, evsel$END_INVYR)

  ppsa <- as.data.table(fia$POP_PLOT_STRATUM_ASSGN)[EVALID == EVU, .(PLT_CN, STRATUM_CN)]
  pop  <- as.data.table(fia$POP_STRATUM)[EVALID == EVU,
            .(STRATUM_CN = CN, EXPNS, ADJ_FACTOR_SUBP)]

  cnd <- copy(cond)
  cnd[, f_all      := forest]
  cnd[, f_in       := as.integer(forest == 1 & in_aoi == 1)]
  cnd[, n_a4c      := as.integer(forest == 1 & a4_contam == 1)]
  cnd[, n_a4_in    := as.integer(forest == 1 & in_aoi == 1 & a4_lcms == 1)]
  cnd[, n_a4_lower := as.integer(forest == 1 & a4_lower == 1)]
  cnd[, n_c4c      := as.integer(forest == 1 & c4_contam == 1)]
  cnd[, n_c4_in    := as.integer(forest == 1 & in_aoi == 1 & c4_lcms == 1)]
  cnd[, n_c4_lower := as.integer(forest == 1 & c4_lower == 1)]
  cnd[, n_c4_upper := as.integer(forest == 1 & c4_upper == 1)]
  cnd[, n_a123     := as.integer(forest == 1 & a123 == 1)]
  cnd[, nmet_in    := a1 + a2 + a3 + a4_lcms]
  cnd[, n_ge1_in   := as.integer(forest == 1 & in_aoi == 1 & nmet_in >= 1)]
  cnd[, n_ge2_in   := as.integer(forest == 1 & in_aoi == 1 & nmet_in >= 2)]
  cnd[, n_ge3_in   := as.integer(forest == 1 & in_aoi == 1 & nmet_in >= 3)]
  for (v in grep("^(n_|f_)", names(cnd), value = TRUE)) cnd[is.na(get(v)), (v) := 0L]

  spec <- list(
    list("A4 contaminated (published rule)",      "n_a4c",      "f_all"),
    list("A4 LCMS, in-AOI denominator",           "n_a4_in",    "f_in"),
    list("A4 LCMS, all forestland, undef=fail",   "n_a4_lower", "f_all"),
    list("four-axis contaminated (published)",    "n_c4c",      "f_all"),
    list("four-axis LCMS, in-AOI denominator",    "n_c4_in",    "f_in"),
    list(">=1 axis, in-AOI denominator",          "n_ge1_in",   "f_in"),
    list(">=2 axes, in-AOI denominator",          "n_ge2_in",   "f_in"),
    list(">=3 axes, in-AOI denominator",          "n_ge3_in",   "f_in"),
    list("four-axis all forestland, undef=fail",  "n_c4_lower", "f_all"),
    list("four-axis all forestland, undef=pass",  "n_c4_upper", "f_all"),
    list("three-axis strict (no LCMS)",           "n_a123",     "f_all"),
    list("share of forestland inside LCMS AOI",   "f_in",       "f_all")
  )
  hh <- rbindlist(lapply(spec, function(s) {
    r <- ratio_est(cnd, ppsa, pop, s[[2]], s[[3]])
    data.table(state = st, metric = s[[1]],
               denom = if (s[[3]] == "f_in") "in-AOI forestland" else "all forestland",
               pct = round(r$pct, 2), se = round(r$se, 3),
               lo = round(pmax(0, r$pct - 1.96 * r$se), 2),
               hi = round(r$pct + 1.96 * r$se, 2),
               num_acres = round(r$num_acres, 0), den_acres = round(r$den_acres, 0))
  }))
  head_all[[st]] <- hh
  print(hh)

  # ---- unweighted condition counts, for comparability with the 29.5 figure --
  inA <- cond[in_aoi == 1]
  cover_all[[st]] <- data.table(
    state = st, evalid_used = EVU,
    conds_total = nrow(cond), conds_in_aoi = nrow(inA),
    conds_forest = cond[forest == 1, .N],
    conds_forest_in_aoi = cond[forest == 1 & in_aoi == 1, .N],
    pct_conds_in_aoi = round(100 * nrow(inA) / nrow(cond), 1),
    a4_lcms_pct_conds = round(100 * mean(inA$a4_lcms, na.rm = TRUE), 1),
    a4_fia_pct_conds  = round(100 * mean(inA$a4_fia,  na.rm = TRUE), 1),
    a4_fia_pct_conds_outside = round(100 * mean(cond[in_aoi == 0]$a4_fia, na.rm = TRUE), 1)
  )
  print(cover_all[[st]])

  rm(stk, yod, yodf, fia, cond, cnd, tr, liv, dead, agg, sn); gc()
}

fwrite(rbindlist(axis_all),   file.path(OUT, "jobB2_axis_alone_4state.csv"))
fwrite(rbindlist(funnel_all), file.path(OUT, "jobB2_funnel_4state.csv"))
fwrite(rbindlist(head_all),   file.path(OUT, "jobB2_headline_ratio_4state.csv"))
fwrite(rbindlist(cover_all),  file.path(OUT, "jobB2_aoi_coverage_4state.csv"))

cat("\n===== AXIS ALONE =====\n");  print(rbindlist(axis_all))
cat("\n===== FUNNEL =====\n");      print(rbindlist(funnel_all))
cat("\n===== HEADLINES =====\n");   print(rbindlist(head_all))
cat("\n===== AOI COVERAGE =====\n");print(rbindlist(cover_all))
cat("JOBB_DONE\n")
