# axes.R --------------------------------------------------------------------
#
# Axis primitives. Each takes a value in canonical SI units and returns an
# integer score. Thresholds are never hard-coded here; they arrive from
# thresholds.R through the instrument functions, so changing a threshold is a
# one-line edit in one file.
#
# NA handling matches the source: the ge() helper at
# scripts/jobA_design_based_rfia.R line 109 forces an NA comparison to FALSE, so
# a missing measurement scores zero rather than propagating NA. That is a real
# modelling choice with a real consequence, since a plot with no snag record
# scores zero on deadwood rather than dropping out, and it is reproduced here
# deliberately.

#' A two step score
#'
#' Returns 2 at or above \code{t2}, 1 at or above \code{t1}, otherwise 0. A
#' \code{t2} of \code{NA} makes the axis a pass or fail axis worth at most one
#' point, which is how the maturity axis behaves on both small area estimation
#' label cards and in CORE4. Every scored axis in the package reduces to this
#' function, and thresholds are never hard coded here. They arrive from
#' \code{lsog_thresholds} through the instrument functions, already converted
#' to SI.
#'
#' A missing value scores zero rather than propagating \code{NA}, matching the
#' \code{ge()} helper at \code{scripts/jobA_design_based_rfia.R} line 109. That
#' is a real modelling choice with a real consequence, since a plot with no
#' snag record scores zero on deadwood rather than dropping out, and it is
#' reproduced here deliberately.
#'
#' @param x numeric vector in the same units as the thresholds
#' @param t1,t2 numeric thresholds in the units of \code{x}, \code{t2} optional
#' @param na_is_zero logical, treat \code{NA} as failing rather than
#'   propagating, default \code{TRUE}
#' @return integer vector of scores, 0, 1, or 2, of the same length as
#'   \code{x}
#' @examples
#' score_step(c(0, 40, 80, 120), 40, 80)
#' score_step(c(NA, 40), 40, 80)
#' score_step(c(10, 30), 24, NA)
#' @export
score_step <- function(x, t1, t2 = NA_real_, na_is_zero = TRUE) {
  ge <- function(v, t) {
    if (is.na(t)) return(rep(FALSE, length(v)))
    out <- v >= t
    if (na_is_zero) out[is.na(out)] <- FALSE
    out
  }
  as.integer(ge(x, t1)) + as.integer(ge(x, t2))
}

#' Axis primitives on canonical SI attributes
#'
#' Thin named wrappers around \code{score_step}, one per axis, so that an
#' instrument definition reads as the card it implements. Each takes a value in
#' canonical SI units and the two thresholds for the instrument in the same
#' units. The thresholds are not defaults, since they differ by instrument and
#' by jurisdiction, and the instrument functions look them up in
#' \code{lsog_thresholds} and pass them in.
#'
#' \code{axis_maturity_age} is the one wrapper with its own logic. It scores
#' stand age on two thresholds and, where \code{stand_age} is missing or zero,
#' falls back to a pass or fail score on \code{max_dia} capped at one point,
#' per \code{scripts/jobA_design_based_rfia.R} line 127, with a declared
#' ceiling of 20 percent of scored plots per state at line 134.
#' \code{axis_maturity_maxdia} is that fallback used as the whole axis, which
#' is the label card and CORE4 form.
#'
#' @param ba_large numeric, live basal area in trees at or above the large
#'   tree floor, in m2 ha-1
#' @param stand_age numeric, FIA \code{STDAGE} in years
#' @param max_dia numeric, maximum live tree diameter in cm, used by
#'   \code{axis_maturity_age} only where \code{stand_age} is missing or zero
#' @param t1_age,t2_age numeric, age thresholds in years
#' @param t_fallback numeric, the \code{max_dia} fallback threshold in cm,
#'   \code{NA} to disable the fallback
#' @param qmd numeric, quadratic mean diameter of live trees in cm
#' @param sd_dia numeric, standard deviation of live diameter in cm, weighted
#'   or unweighted as the instrument dictates
#' @param ba_total numeric, total live basal area in m2 ha-1
#' @param snag_density numeric, snag density in stems ha-1
#' @param canopy_ht numeric, canopy height in m
#' @param t1,t2 numeric thresholds in the units of the axis value
#' @return integer vector of axis scores, 0, 1, or 2
#' @examples
#' thr <- lsog_thresholds("nb_v51")
#' ba <- thr[thr$axis == "sc_balarge", ]
#' axis_large_tree_ba(c(5, 10, 20), ba$score1_si, ba$score2_si)
#' axis_maturity_age(c(90, NA, 0), max_dia = c(30, 70, 50),
#'                   t1_age = 80, t2_age = 120, t_fallback = 60.96)
#' axis_maturity_maxdia(c(50, 70), 60.96)
#' @name lsog_axes
NULL

#' @rdname lsog_axes
#' @export
axis_large_tree_ba <- function(ba_large, t1, t2) score_step(ba_large, t1, t2)

#' @rdname lsog_axes
#' @export
axis_maturity_age <- function(stand_age, max_dia = NULL,
                              t1_age, t2_age, t_fallback = NA_real_) {
  s <- score_step(stand_age, t1_age, t2_age)
  missing_age <- is.na(stand_age) | stand_age == 0
  if (!is.na(t_fallback) && !is.null(max_dia) && any(missing_age)) {
    # The fallback is capped at one point, per jobA line 127.
    s[missing_age] <- score_step(max_dia[missing_age], t_fallback, NA_real_)
  }
  s
}

#' @rdname lsog_axes
#' @export
axis_maturity_qmd <- function(qmd, t1, t2) score_step(qmd, t1, t2)

#' @rdname lsog_axes
#' @export
axis_maturity_maxdia <- function(max_dia, t1) score_step(max_dia, t1, NA_real_)

#' @rdname lsog_axes
#' @export
axis_structure <- function(sd_dia, t1, t2) score_step(sd_dia, t1, t2)

#' @rdname lsog_axes
#' @export
axis_canopy_ba <- function(ba_total, t1, t2) score_step(ba_total, t1, t2)

#' @rdname lsog_axes
#' @export
axis_deadwood <- function(snag_density, t1, t2) score_step(snag_density, t1, t2)

#' @rdname lsog_axes
#' @export
axis_canopy_height <- function(canopy_ht, t1, t2) score_step(canopy_ht, t1, t2)

#' Look up the SI threshold pair for one axis
#'
#' Internal. Pulls the converted thresholds for one instrument, axis, and
#' jurisdiction from \code{lsog_thresholds} as a named pair. Errors rather
#' than guessing when zero or several rows match, so a typo in an instrument
#' definition fails loudly. Rows with jurisdiction \code{"both"} match any
#' requested jurisdiction.
#'
#' @param instrument character, instrument name
#' @param axis character, axis name within the instrument
#' @param jurisdiction optional character, \code{"ME"} or \code{"NB"}, used to
#'   disambiguate only when the axis carries one row per jurisdiction
#' @return named numeric vector \code{c(t1, t2)} in SI units (m2 ha-1, cm,
#'   stems ha-1, m, years, proportion, or index as the axis dictates)
#' @keywords internal
#' @noRd
.thr <- function(instrument, axis, jurisdiction = NULL) {
  x <- lsog_thresholds(instrument)
  x <- x[x$axis == axis, , drop = FALSE]
  if (!is.null(jurisdiction) && nrow(x) > 1) {
    j <- x[x$jurisdiction %in% c(jurisdiction, "both"), , drop = FALSE]
    if (nrow(j)) x <- j
  }
  if (nrow(x) != 1)
    stop("expected exactly one threshold row for ", instrument, "/", axis,
         if (!is.null(jurisdiction)) paste0("/", jurisdiction) else "",
         ", found ", nrow(x))
  c(t1 = x$score1_si[1], t2 = x$score2_si[1])
}
