# instruments.R -------------------------------------------------------------
#
# The seven instruments. Each takes a data frame of canonical SI plot
# attributes and returns per-axis scores, a total, and a class, so two
# instruments can be run over one plot table and compared column by column.
#
# Every function names the jurisdiction convention it applies rather than
# inferring one, because the whole point of the package is that the conventions
# differ and the difference is the finding.

#' Require columns on a plot table
#'
#' Internal. Stops with a message naming the calling instrument and the
#' missing columns, so a schema mismatch fails before any axis is scored.
#'
#' @param x data frame of plot attributes
#' @param cols character, required column names
#' @param fn character, the calling function's name for the message
#' @return \code{TRUE} invisibly
#' @keywords internal
#' @noRd
.need <- function(x, cols, fn) {
  miss <- setdiff(cols, names(x))
  if (length(miss))
    stop(fn, " needs these columns and they are missing: ",
         paste(miss, collapse = ", "))
  invisible(TRUE)
}

#' Class label from a total score
#'
#' Internal. Maps a total score to \code{"not_lsog"}, \code{"transitioning"}
#' at or above the qualifying cut, \code{"late_successional"} at two points
#' above it, and \code{"old_growth"} at or above the old growth cut where the
#' instrument defines one.
#'
#' @param total integer, total score in points
#' @param cut_any integer, the qualifying cut in points
#' @param cut_og integer, the old growth cut in points, \code{NA} when the
#'   instrument has none
#' @return character vector of class labels
#' @keywords internal
#' @noRd
.classify <- function(total, cut_any, cut_og) {
  cls <- rep("not_lsog", length(total))
  cls[total >= cut_any] <- "transitioning"
  cls[total >= cut_any + 2L] <- "late_successional"
  if (!is.na(cut_og)) cls[total >= cut_og] <- "old_growth"
  cls
}

#' Maine published six axis card (v5.1)
#'
#' Scores each plot on the instrument behind the statewide any LSOG figure of
#' 14.66 percent, quoted as 14.7 percent, from
#' \code{scripts/jobA_design_based_rfia.R} lines 109 to 160. Maximum 12, any
#' LSOG at 4 or more, old growth at 8 or more (lines 156 to 160). The six axes
#' and their thresholds in source units are large tree basal area at 40 and 80
#' ft2 ac-1 (line 112), stand age at 80 and 120 yr with a maximum diameter
#' fallback at 24 in capped at one point (lines 125 to 127), TPA weighted
#' standard deviation of diameter at 5 and 8 in (line 149), total basal area
#' at 100 and 150 ft2 ac-1 (line 150), snag density above the 5 in floor
#' (lines 151 and 152), and Potapov GLAD 2019 RH95 canopy height at 18 and 25
#' m (line 153).
#'
#' The deadwood axis is the only quantile set threshold in any instrument here.
#' Supply \code{snag_t1} and \code{snag_t2} in stems ha-1, or leave them
#' \code{NULL} to take the Maine run record values through
#' \code{me_v51_snag_quantiles}, which documents that they are a run record
#' and not a code line.
#'
#' @param x data frame of SI plot attributes, needing \code{ba_large_508} and
#'   \code{ba_total} in m2 ha-1, \code{sd_dia_weighted} in cm,
#'   \code{snag_density_127} in stems ha-1, and optionally \code{stand_age} in
#'   years, \code{max_dia} in cm, and \code{canopy_ht_m} in m, where an absent
#'   optional column scores zero on its axis
#' @param snag_t1,snag_t2 numeric, deadwood thresholds in stems ha-1, or
#'   \code{NULL} for the run record values
#' @return a data frame with axis scores \code{s_ba}, \code{s_mat},
#'   \code{s_str}, \code{s_can}, \code{s_dw}, and \code{s_ht} in points,
#'   \code{total_score} in points, the integer flags \code{any_lsog} and
#'   \code{old_growth}, and the character \code{lsog_class}
#' @examples
#' x <- data.frame(ba_large_508 = c(0, 12, 25), ba_total = c(15, 30, 40),
#'                 sd_dia_weighted = c(8, 14, 22),
#'                 snag_density_127 = c(0, 80, 150),
#'                 stand_age = c(40, 90, 130), canopy_ht_m = c(12, 20, 27))
#' score_me_v51(x)
#' @export
score_me_v51 <- function(x, snag_t1 = NULL, snag_t2 = NULL) {
  .need(x, c("ba_large_508", "ba_total", "sd_dia_weighted", "snag_density_127"),
        "score_me_v51")
  ba  <- .thr("me_v51", "s_ba")
  mat <- .thr("me_v51", "s_mat")
  fb  <- .thr("me_v51", "s_mat_fallback")
  str <- .thr("me_v51", "s_str")
  can <- .thr("me_v51", "s_can")
  ht  <- .thr("me_v51", "s_ht")

  if (is.null(snag_t1) || is.null(snag_t2)) {
    q <- me_v51_snag_quantiles()
    snag_t1 <- tpa_to_stems_ha(q[["score1"]])
    snag_t2 <- tpa_to_stems_ha(q[["score2"]])
  }

  age <- if ("stand_age" %in% names(x)) x$stand_age else rep(NA_real_, nrow(x))
  md  <- if ("max_dia" %in% names(x)) x$max_dia else rep(NA_real_, nrow(x))
  cht <- if ("canopy_ht_m" %in% names(x)) x$canopy_ht_m else rep(NA_real_, nrow(x))

  out <- data.frame(
    s_ba  = axis_large_tree_ba(x$ba_large_508, ba[["t1"]], ba[["t2"]]),
    s_mat = axis_maturity_age(age, md, mat[["t1"]], mat[["t2"]], fb[["t1"]]),
    s_str = axis_structure(x$sd_dia_weighted, str[["t1"]], str[["t2"]]),
    s_can = axis_canopy_ba(x$ba_total, can[["t1"]], can[["t2"]]),
    s_dw  = axis_deadwood(x$snag_density_127, snag_t1, snag_t2),
    s_ht  = axis_canopy_height(cht, ht[["t1"]], ht[["t2"]])
  )
  out$total_score <- rowSums(out)
  out$any_lsog    <- as.integer(out$total_score >= 4L)
  out$old_growth  <- as.integer(out$total_score >= 8L)
  out$lsog_class  <- .classify(out$total_score, 4L, 8L)
  out
}

#' New Brunswick published five axis card
#'
#' Scores each plot on the instrument behind the New Brunswick any LSOG figure
#' of 31.47 percent, from \code{scripts/cardinal/nb_cli_lsog_fullscope.py}
#' lines 179 to 187. Maximum 10, any LSOG at 4 or more, old growth at 8 or more
#' (lines 436 and 437). The five axes and their thresholds are large tree
#' basal area at 9.18 and 18.4 m2 ha-1 (line 179), quadratic mean diameter at
#' 20.3 and 30.5 cm (line 180), unweighted standard deviation of diameter at
#' 12.7 and 20.3 cm (line 181), total basal area at 22.96 and 34.4 m2 ha-1
#' (line 182), and snag density with no diameter floor at 44.5 and 89 stems
#' ha-1 (line 183). It carries no canopy height axis of any kind, which is
#' worth stating plainly whenever this work is compared against a canopy
#' height classifier.
#'
#' @param x data frame of SI plot attributes, needing \code{ba_large_500} and
#'   \code{ba_total} in m2 ha-1, \code{qmd} and \code{sd_dia_unweighted} in
#'   cm, and \code{snag_density_nofloor} in stems ha-1
#' @return a data frame with axis scores \code{sc_balarge}, \code{sc_mat},
#'   \code{sc_struct}, \code{sc_canopy}, and \code{sc_dead} in points,
#'   \code{total_score} in points, the integer flags \code{any_lsog} and
#'   \code{old_growth}, and the character \code{lsog_class}
#' @examples
#' x <- data.frame(ba_large_500 = c(0, 12, 25), qmd = c(15, 25, 35),
#'                 sd_dia_unweighted = c(8, 14, 22), ba_total = c(15, 30, 40),
#'                 snag_density_nofloor = c(0, 60, 120))
#' score_nb_v51(x)
#' @export
score_nb_v51 <- function(x) {
  .need(x, c("ba_large_500", "qmd", "sd_dia_unweighted", "ba_total",
             "snag_density_nofloor"), "score_nb_v51")
  ba  <- .thr("nb_v51", "sc_balarge")
  mat <- .thr("nb_v51", "sc_mat")
  str <- .thr("nb_v51", "sc_struct")
  can <- .thr("nb_v51", "sc_canopy")
  dw  <- .thr("nb_v51", "sc_dead")

  out <- data.frame(
    sc_balarge = axis_large_tree_ba(x$ba_large_500, ba[["t1"]], ba[["t2"]]),
    sc_mat     = axis_maturity_qmd(x$qmd, mat[["t1"]], mat[["t2"]]),
    sc_struct  = axis_structure(x$sd_dia_unweighted, str[["t1"]], str[["t2"]]),
    sc_canopy  = axis_canopy_ba(x$ba_total, can[["t1"]], can[["t2"]]),
    sc_dead    = axis_deadwood(x$snag_density_nofloor, dw[["t1"]], dw[["t2"]])
  )
  out$total_score <- rowSums(out)
  out$any_lsog    <- as.integer(out$total_score >= 4L)
  out$old_growth  <- as.integer(out$total_score >= 8L)
  out$lsog_class  <- .classify(out$total_score, 4L, 8L)
  out
}

#' Maine small area estimation label card
#'
#' Scores each plot on the Maine label card from
#' \code{data/mosvr_joint/step1_me_v51_score.R} lines 75 to 84. Maximum 11,
#' any LSOG at 4 or more (line 84). Differs from the Maine published card in
#' two load bearing ways. The deadwood axis is on a fixed pair of 18 and 36
#' trees ac-1 (line 80), set in New Brunswick units and back converted per
#' that script's own header at line 11, rather than a per state quantile. And
#' the maturity axis drops stand age entirely and becomes a pass or fail
#' maximum diameter axis at 24 in (line 77), which is what takes the maximum
#' from 12 to 11. The remaining axes are large tree basal area at 40 and 80
#' ft2 ac-1 (line 76), TPA weighted standard deviation of diameter at 5 and 8
#' in (line 78), total basal area at 100 and 150 ft2 ac-1 (line 79), and
#' Potapov GLAD canopy height at 18 and 25 m (line 81).
#'
#' @param x data frame of SI plot attributes, needing \code{ba_large_508} and
#'   \code{ba_total} in m2 ha-1, \code{max_dia} and \code{sd_dia_weighted} in
#'   cm, \code{snag_density_127} in stems ha-1, and optionally
#'   \code{canopy_ht_m} in m
#' @return a data frame with axis scores \code{s_ba}, \code{s_mat},
#'   \code{s_str}, \code{s_can}, \code{s_dw}, and \code{s_ht} in points,
#'   \code{total_score} in points, the integer flags \code{any_lsog} and
#'   \code{old_growth}, and the character \code{lsog_class}
#' @examples
#' x <- data.frame(ba_large_508 = c(0, 12, 25), ba_total = c(15, 30, 40),
#'                 max_dia = c(40, 55, 70), sd_dia_weighted = c(8, 14, 22),
#'                 snag_density_127 = c(0, 50, 100), canopy_ht_m = c(12, 20, 27))
#' score_me_sae_card(x)
#' @export
score_me_sae_card <- function(x) {
  .need(x, c("ba_large_508", "max_dia", "sd_dia_weighted", "ba_total",
             "snag_density_127"), "score_me_sae_card")
  ba <- .thr("me_sae", "s_ba"); mat <- .thr("me_sae", "s_mat")
  str <- .thr("me_sae", "s_str"); can <- .thr("me_sae", "s_can")
  dw <- .thr("me_sae", "s_dw"); ht <- .thr("me_sae", "s_ht")
  cht <- if ("canopy_ht_m" %in% names(x)) x$canopy_ht_m else rep(NA_real_, nrow(x))

  out <- data.frame(
    s_ba  = axis_large_tree_ba(x$ba_large_508, ba[["t1"]], ba[["t2"]]),
    s_mat = axis_maturity_maxdia(x$max_dia, mat[["t1"]]),
    s_str = axis_structure(x$sd_dia_weighted, str[["t1"]], str[["t2"]]),
    s_can = axis_canopy_ba(x$ba_total, can[["t1"]], can[["t2"]]),
    s_dw  = axis_deadwood(x$snag_density_127, dw[["t1"]], dw[["t2"]]),
    s_ht  = axis_canopy_height(cht, ht[["t1"]], ht[["t2"]])
  )
  out$total_score <- rowSums(out)
  out$any_lsog    <- as.integer(out$total_score >= 4L)
  out$old_growth  <- as.integer(out$total_score >= 8L)
  out$lsog_class  <- .classify(out$total_score, 4L, 8L)
  out
}

#' New Brunswick small area estimation label card
#'
#' Scores each plot on the New Brunswick label card from
#' \code{nb_public_v51_pipeline_v2.py} lines 86 to 100. Maximum 11, any LSOG
#' at 4 or more (lines 99 and 100). Scores maturity on maximum diameter at
#' 60.96 cm (line 89) rather than QMD, which is what makes it comparable with
#' the Maine label card, and reads ETH GlobalCanopyHeight 10 m 2020 at 18 and
#' 25 m (lines 93 and 94, with the uint8 nodata sentinel 255 nulled at line
#' 77) where Maine reads Potapov GLAD under the same column name. The remaining
#' axes are large tree basal area at 9.18 and 18.4 m2 ha-1 (line 88),
#' unweighted standard deviation of diameter at 12.7 and 20.32 cm (line 90),
#' total basal area at 22.96 and 34.44 m2 ha-1 (line 91), and snag density
#' with no diameter floor at 44.5 and 89 stems ha-1 (line 92).
#'
#' @param x data frame of SI plot attributes, needing \code{ba_large_500} and
#'   \code{ba_total} in m2 ha-1, \code{max_dia} and \code{sd_dia_unweighted}
#'   in cm, \code{snag_density_nofloor} in stems ha-1, and optionally
#'   \code{canopy_ht_m} in m
#' @return a data frame with axis scores \code{s_ba}, \code{s_mat},
#'   \code{s_str}, \code{s_can}, \code{s_dw}, and \code{s_ht} in points,
#'   \code{total_score} in points, the integer flags \code{any_lsog} and
#'   \code{old_growth}, and the character \code{lsog_class}
#' @examples
#' x <- data.frame(ba_large_500 = c(0, 12, 25), ba_total = c(15, 30, 40),
#'                 max_dia = c(40, 55, 70), sd_dia_unweighted = c(8, 14, 22),
#'                 snag_density_nofloor = c(0, 60, 120), canopy_ht_m = c(12, 20, 27))
#' score_nb_sae_card(x)
#' @export
score_nb_sae_card <- function(x) {
  .need(x, c("ba_large_500", "max_dia", "sd_dia_unweighted", "ba_total",
             "snag_density_nofloor"), "score_nb_sae_card")
  ba <- .thr("nb_sae", "s_ba"); mat <- .thr("nb_sae", "s_mat")
  str <- .thr("nb_sae", "s_str"); can <- .thr("nb_sae", "s_can")
  dw <- .thr("nb_sae", "s_dw"); ht <- .thr("nb_sae", "s_ht")
  cht <- if ("canopy_ht_m" %in% names(x)) x$canopy_ht_m else rep(NA_real_, nrow(x))

  out <- data.frame(
    s_ba  = axis_large_tree_ba(x$ba_large_500, ba[["t1"]], ba[["t2"]]),
    s_mat = axis_maturity_maxdia(x$max_dia, mat[["t1"]]),
    s_str = axis_structure(x$sd_dia_unweighted, str[["t1"]], str[["t2"]]),
    s_can = axis_canopy_ba(x$ba_total, can[["t1"]], can[["t2"]]),
    s_dw  = axis_deadwood(x$snag_density_nofloor, dw[["t1"]], dw[["t2"]]),
    s_ht  = axis_canopy_height(cht, ht[["t1"]], ht[["t2"]])
  )
  out$total_score <- rowSums(out)
  out$any_lsog    <- as.integer(out$total_score >= 4L)
  out$old_growth  <- as.integer(out$total_score >= 8L)
  out$lsog_class  <- .classify(out$total_score, 4L, 8L)
  out
}

#' CORE4, the four comparably measured axes
#'
#' Scores each plot on large tree basal area, maturity on maximum diameter,
#' structural diversity, and canopy basal area. Maximum 7, qualifying at 3 or
#' more. The deadwood axis is dropped because the two jurisdictions' snag
#' protocols differ by more than an order of magnitude, and the canopy height
#' axis is dropped because its source product differs by jurisdiction. Neither
#' exclusion is cosmetic, since the instrument sweep puts the deadwood
#' convention alone at 31.47 against 9.75 percent in New Brunswick and 14.66
#' against 20.93 percent in Maine.
#'
#' This function is the first written definition of CORE4. The instrument's
#' axis columns were previously carried precomputed in
#' \code{samp_dat_core4_DATA_2026-09-02.csv}, and an exhaustive search of the
#' workspace, of the Cardinal allocation, and of the processing server found no
#' script that builds them. The thresholds encoded here are those of the two
#' small area estimation label cards, which is the specification the sweep and
#' the fitted models used. On the Maine side they are
#' \code{data/mosvr_joint/step1_me_v51_score.R} lines 76 to 79, namely 40 and
#' 80 ft2 ac-1, 24 in, 5 and 8 in, and 100 and 150 ft2 ac-1. On the New
#' Brunswick side they are 9.18 and 18.4 m2 ha-1 from
#' \code{scripts/cardinal/nb_instrument_sweep_core4_20260902.py} lines 101 and
#' 102, and 60.96 cm, 12.7 and 20.32 cm, and 22.96 and 34.44 m2 ha-1 from
#' \code{scripts/cardinal/nb_instrument_sweep_20260902.py} lines 198 to 204.
#' Two conventions still differ by jurisdiction and are preserved rather than
#' harmonized, the large tree floor (50.8 cm in Maine against 50 cm in New
#' Brunswick) and the structure weighting (TPA weighted in Maine, unweighted
#' in New Brunswick).
#'
#' @param x data frame of SI plot attributes, needing \code{ba_large_508},
#'   \code{ba_large_500}, and \code{ba_total} in m2 ha-1 and \code{max_dia},
#'   \code{sd_dia_weighted}, and \code{sd_dia_unweighted} in cm
#' @param jurisdiction character vector, \code{"ME"} or \code{"NB"} per row,
#'   controlling only which large tree floor and which structure convention
#'   apply
#' @return a data frame with axis scores \code{s_ba}, \code{s_mat},
#'   \code{s_str}, and \code{s_can} in points, the total \code{core4} in
#'   points, and the integer flag \code{any_lsog}
#' @examples
#' x <- data.frame(ba_large_508 = c(0, 12, 25), ba_large_500 = c(0, 12.5, 25),
#'                 max_dia = c(40, 55, 70),
#'                 sd_dia_weighted = c(8, 14, 22), sd_dia_unweighted = c(9, 15, 24),
#'                 ba_total = c(15, 30, 40))
#' score_core4(x, jurisdiction = c("ME", "NB", "ME"))
#' @export
score_core4 <- function(x, jurisdiction) {
  .need(x, c("ba_large_508", "ba_large_500", "max_dia", "sd_dia_weighted",
             "sd_dia_unweighted", "ba_total"), "score_core4")
  stopifnot(length(jurisdiction) == nrow(x))
  jm <- jurisdiction == "ME"

  ba_me <- .thr("core4", "s_ba", "ME"); ba_nb <- .thr("core4", "s_ba", "NB")
  mat_me <- .thr("core4", "s_mat", "ME"); mat_nb <- .thr("core4", "s_mat", "NB")
  st_me <- .thr("core4", "s_str", "ME"); st_nb <- .thr("core4", "s_str", "NB")
  cn_me <- .thr("core4", "s_can", "ME"); cn_nb <- .thr("core4", "s_can", "NB")

  ba_large <- ifelse(jm, x$ba_large_508, x$ba_large_500)
  sd_dia   <- ifelse(jm, x$sd_dia_weighted, x$sd_dia_unweighted)

  s_ba <- integer(nrow(x)); s_mat <- integer(nrow(x))
  s_str <- integer(nrow(x)); s_can <- integer(nrow(x))
  if (any(jm)) {
    s_ba[jm]  <- axis_large_tree_ba(ba_large[jm], ba_me[["t1"]], ba_me[["t2"]])
    s_mat[jm] <- axis_maturity_maxdia(x$max_dia[jm], mat_me[["t1"]])
    s_str[jm] <- axis_structure(sd_dia[jm], st_me[["t1"]], st_me[["t2"]])
    s_can[jm] <- axis_canopy_ba(x$ba_total[jm], cn_me[["t1"]], cn_me[["t2"]])
  }
  if (any(!jm)) {
    s_ba[!jm]  <- axis_large_tree_ba(ba_large[!jm], ba_nb[["t1"]], ba_nb[["t2"]])
    s_mat[!jm] <- axis_maturity_maxdia(x$max_dia[!jm], mat_nb[["t1"]])
    s_str[!jm] <- axis_structure(sd_dia[!jm], st_nb[["t1"]], st_nb[["t2"]])
    s_can[!jm] <- axis_canopy_ba(x$ba_total[!jm], cn_nb[["t1"]], cn_nb[["t2"]])
  }

  out <- data.frame(s_ba = s_ba, s_mat = s_mat, s_str = s_str, s_can = s_can)
  out$core4    <- out$s_ba + out$s_mat + out$s_str + out$s_can
  out$any_lsog <- as.integer(out$core4 >= 3L)
  out
}

#' CORE5, CORE4 with the shade tolerance penalty
#'
#' Subtracts one point from a CORE4 score where a plot is both tall canopied
#' and low in shade tolerance, the interaction that lets a fast growing
#' intolerant stand read as structurally mature while genuinely young. The
#' penalty is subtractive and never additive, so the maximum stays at 7 and
#' the cut stays at 3, and the rejected additive alternative is on the record
#' at \code{build/saeczi_v1/fit_saeczi_v6_core5_production.R} lines 29 to 39.
#' Plots with no tolerance value are never penalized, per line 85 of the same
#' file.
#'
#' Two forms exist. The continuous form, which is what produced the reported
#' figures, gates on canopy height at or above 18 m and on the basal area
#' weighted Niinemets and Valladares (2006) tolerance index at or below 2.75
#' on its 0.87 to 5.01 scale, from
#' \code{build/saeczi_v1/fit_saeczi_v7_core5_continuous_tolerance.R} lines 66,
#' 68, 90, and 91. The jurisdiction calibrations of 2.7457 for Maine and 2.7332
#' for New Brunswick were pooled to that one value. The categorical form gates
#' on the same 18 m and on the percentage of basal area in intolerant species
#' at or above 50 (Baker 1949 classes as reproduced in Burns and Honkala
#' 1990), from \code{fit_saeczi_v6_core5_production.R} lines 73, 93, and 94.
#' Default is continuous. Either gate reads \code{canopy_ht_m}, which holds
#' Potapov GLAD in Maine and ETH GlobalCanopyHeight in New Brunswick, so the
#' penalty reintroduces the border crossing height product in a limited role.
#'
#' @param core4 integer vector, CORE4 scores in points, as returned by
#'   \code{score_core4}
#' @param canopy_ht_m numeric, canopy height in m
#' @param tolerance numeric, \code{tol_score_ba} (index, 0.87 to 5.01) for the
#'   continuous form or \code{pct_ba_intolerant} (percent of live basal area)
#'   for the categorical form
#' @param form character, \code{"continuous"} or \code{"categorical"}
#' @return a data frame with \code{core5} in points, the integer
#'   \code{penalty} (0 or 1), and the integer flag \code{any_lsog}
#' @examples
#' score_core5(core4 = c(3L, 3L, 3L, 3L), canopy_ht_m = c(20, 20, 15, 20),
#'             tolerance = c(2.5, 3.5, 2.5, NA))
#' score_core5(core4 = c(3L, 3L), canopy_ht_m = c(20, 20),
#'             tolerance = c(60, 40), form = "categorical")
#' @export
score_core5 <- function(core4, canopy_ht_m, tolerance,
                        form = c("continuous", "categorical")) {
  form <- match.arg(form)
  inst <- if (form == "continuous") "core5_continuous" else "core5_categorical"
  tall_t <- .thr(inst, "tall_gate")[["t1"]]
  tol_t  <- .thr(inst, "tolerance_gate")[["t1"]]

  tall <- !is.na(canopy_ht_m) & canopy_ht_m >= tall_t
  low_tol <- if (form == "continuous") {
    !is.na(tolerance) & tolerance <= tol_t
  } else {
    !is.na(tolerance) & tolerance >= tol_t
  }
  # Plots with no tolerance value are never penalized, per v6 line 85.
  penalty <- as.integer(tall & low_tol)
  out <- data.frame(core5 = core4 - penalty, penalty = penalty)
  out$any_lsog <- as.integer(out$core5 >= 3L)
  out
}

#' The strict four axis conjunctive rule
#'
#' Flags a plot as true LSOG only if it passes all four axes of
#' \code{scripts/jobB_four_axis_no_proxy.R} lines 142 to 197. This is not a
#' score and has no cut. It is the instrument behind the reported Maine figure
#' of 2.5 percent, and none of its four axes reads a canopy height product.
#' A1 is live basal area in trees at or above 16 in (40.64 cm, line 145) at or
#' above 30 ft2 ac-1 (line 156). A2 is snag basal area, \code{STATUSCD} 2 at
#' or above 5 in, at or above 5 ft2 ac-1 (line 157). A3 is the share of live
#' basal area in the \code{late_species} set at or above 0.5 (line 158, the
#' species vector at line 83). A4 passes where the LCMS year of heavy
#' disturbance detection is zero inside the area of interest (line 189, the
#' heavy classes 2, 6, 7, 8, 9, and 13 at line 81). A missing value fails its
#' axis.
#'
#' @param x data frame needing \code{ba_large_406} and \code{ba_snag_127} in
#'   m2 ha-1 and \code{ba_late_prop} as a proportion
#' @param yodh integer, LCMS year of detection for the heavy disturbance
#'   classes, zero where no heavy disturbance was detected between 1985 and
#'   2023
#' @return a data frame with the integer axis flags \code{A1}, \code{A2},
#'   \code{A3}, and \code{A4} and the integer flag \code{true_lsog}
#' @examples
#' x <- data.frame(ba_large_406 = c(10, 5), ba_snag_127 = c(2, 2),
#'                 ba_late_prop = c(0.7, 0.7))
#' score_strict_four_axis(x, yodh = c(0L, 0L))
#' @export
score_strict_four_axis <- function(x, yodh) {
  .need(x, c("ba_large_406", "ba_snag_127", "ba_late_prop"),
        "score_strict_four_axis")
  a1 <- .thr("strict4", "A1")[["t1"]]
  a2 <- .thr("strict4", "A2")[["t1"]]
  a3 <- .thr("strict4", "A3")[["t1"]]

  f <- function(v, t) { o <- v >= t; o[is.na(o)] <- FALSE; as.integer(o) }
  out <- data.frame(
    A1 = f(x$ba_large_406, a1),
    A2 = f(x$ba_snag_127, a2),
    A3 = f(x$ba_late_prop, a3),
    A4 = as.integer(!is.na(yodh) & yodh == 0)
  )
  out$true_lsog <- as.integer(out$A1 & out$A2 & out$A3 & out$A4)
  out
}

#' Run every instrument over one plot table
#'
#' The comparison this package exists to make. Returns one row per plot with
#' the total and qualifying flag from each instrument side by side, so the
#' spread across definitions is visible on the same plots rather than across
#' separate papers. CORE4 always runs. CORE5 runs in its continuous form when
#' \code{tolerance} is supplied and \code{x} carries \code{canopy_ht_m}. The
#' published card for each row's jurisdiction runs as \code{score_me_v51} or
#' \code{score_nb_v51}. The strict rule runs when \code{yodh} is supplied.
#'
#' @param x data frame of SI plot attributes carrying the union of the columns
#'   the individual instruments need, in the units stated for each
#' @param jurisdiction character vector, \code{"ME"} or \code{"NB"} per row
#' @param yodh optional integer vector for the strict rule, as for
#'   \code{score_strict_four_axis}
#' @param tolerance optional numeric vector, \code{tol_score_ba} (index), for
#'   CORE5
#' @return a data frame with \code{jurisdiction}, \code{core4} and
#'   \code{core4_any}, \code{core5}, \code{core5_any}, and
#'   \code{core5_penalty} when CORE5 ran, \code{published_total} and
#'   \code{published_any} from the jurisdiction's published card, and
#'   \code{strict4_any} when the strict rule ran, with totals in points and flags as
#'   integers
#' @examples
#' x <- data.frame(ba_large_508 = c(0, 12, 25), ba_large_500 = c(0, 12.5, 25),
#'                 max_dia = c(40, 55, 70), qmd = c(15, 25, 35),
#'                 sd_dia_weighted = c(8, 14, 22), sd_dia_unweighted = c(9, 15, 24),
#'                 ba_total = c(15, 30, 40), snag_density_127 = c(0, 80, 150),
#'                 snag_density_nofloor = c(0, 100, 200),
#'                 stand_age = c(40, NA, 130), canopy_ht_m = c(12, 20, 27))
#' s <- score_all_instruments(x, jurisdiction = c("ME", "NB", "ME"),
#'                            tolerance = c(3.1, 2.4, 3.6))
#' s
#' instrument_deltas(s)
#' @export
score_all_instruments <- function(x, jurisdiction, yodh = NULL, tolerance = NULL) {
  n <- nrow(x)
  out <- data.frame(jurisdiction = jurisdiction, stringsAsFactors = FALSE)

  c4 <- score_core4(x, jurisdiction)
  out$core4 <- c4$core4
  out$core4_any <- c4$any_lsog

  if (!is.null(tolerance) && "canopy_ht_m" %in% names(x)) {
    c5 <- score_core5(c4$core4, x$canopy_ht_m, tolerance)
    out$core5 <- c5$core5
    out$core5_any <- c5$any_lsog
    out$core5_penalty <- c5$penalty
  }

  me <- jurisdiction == "ME"
  if (any(me)) {
    m <- score_me_v51(x[me, , drop = FALSE])
    out$published_total <- NA_integer_; out$published_any <- NA_integer_
    out$published_total[me] <- m$total_score
    out$published_any[me] <- m$any_lsog
  }
  if (any(!me)) {
    b <- score_nb_v51(x[!me, , drop = FALSE])
    if (!"published_total" %in% names(out)) {
      out$published_total <- NA_integer_; out$published_any <- NA_integer_
    }
    out$published_total[!me] <- b$total_score
    out$published_any[!me] <- b$any_lsog
  }

  if (!is.null(yodh)) {
    s4 <- score_strict_four_axis(x, yodh)
    out$strict4_any <- s4$true_lsog
  }
  out
}

#' Where two instruments disagree
#'
#' Given the output of \code{score_all_instruments}, reports the qualifying
#' rate under each instrument and the pairwise disagreement against CORE4,
#' which is the number a methods discussion turns on. Rates are computed over
#' the rows where the instrument produced a flag, and the disagreement over
#' the rows where both it and CORE4 did.
#'
#' @param scores the data frame returned by \code{score_all_instruments}
#' @return a data frame with \code{instrument}, \code{n} (plots with a flag),
#'   \code{rate_pct} (qualifying rate in percent), and
#'   \code{disagree_vs_core4_pct} (percent of plots on which the flag differs
#'   from CORE4)
#' @examples
#' s <- data.frame(core4_any = c(1L, 0L, 1L, 0L), published_any = c(1L, 1L, 0L, 0L))
#' instrument_deltas(s)
#' @export
instrument_deltas <- function(scores) {
  flags <- grep("_any$", names(scores), value = TRUE)
  base <- if ("core4_any" %in% flags) "core4_any" else flags[1]
  do.call(rbind, lapply(flags, function(f) {
    v <- scores[[f]]
    b <- scores[[base]]
    ok <- !is.na(v)
    both <- ok & !is.na(b)
    data.frame(
      instrument = sub("_any$", "", f),
      n = sum(ok),
      rate_pct = if (sum(ok)) round(100 * mean(v[ok]), 4) else NA_real_,
      disagree_vs_core4_pct = if (sum(both)) round(100 * mean(v[both] != b[both]), 4) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
}
