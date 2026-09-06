# units.R -------------------------------------------------------------------
#
# One conversion boundary for the whole package. Every threshold in
# thresholds.R is stored in the units the source code actually used, and is
# converted here and nowhere else. That is deliberate: the Maine cards score in
# imperial and the New Brunswick cards score in metric, and several of the
# apparent jurisdiction differences are pure unit expression while two of them
# are real. Converting at one place is what lets the package tell those apart.
#
# Canonical internal units are SI: m2 ha-1 for basal area, cm for diameter,
# stems ha-1 for snag density, m for canopy height, years for stand age.

#' Basal area between square feet per acre and square metres per hectare
#'
#' Converts basal area per unit area between the imperial form the Maine
#' scripts use and the SI form the package holds internally. The factor
#' 0.229568 m2 ha-1 per ft2 ac-1 reproduces the mapping that
#' \code{scripts/cardinal_nb_magplot.py} lines 36 and 37 assert in its own
#' comments (40, 80, 100, and 150 ft2 ac-1 to 9.18, 18.37, 22.96, and 34.44
#' m2 ha-1), which is how the New Brunswick scripts document their imperial
#' provenance. \code{m2ha_to_ft2ac} is the exact inverse.
#'
#' @param x numeric, basal area in ft2 ac-1 for \code{ft2ac_to_m2ha} or in
#'   m2 ha-1 for \code{m2ha_to_ft2ac}
#' @return numeric, basal area in m2 ha-1 for \code{ft2ac_to_m2ha} or in
#'   ft2 ac-1 for \code{m2ha_to_ft2ac}
#' @examples
#' ft2ac_to_m2ha(c(40, 80, 100, 150))
#' m2ha_to_ft2ac(ft2ac_to_m2ha(40))
#' @export
ft2ac_to_m2ha <- function(x) x * 0.229568

#' @rdname ft2ac_to_m2ha
#' @export
m2ha_to_ft2ac <- function(x) x / 0.229568

#' Diameter between inches and centimetres
#'
#' Converts a diameter at breast height between the inches the FIA tree table
#' carries and the centimetres the package holds internally, at the exact
#' factor of 2.54 cm in-1. This is the conversion that turns the Maine diameter
#' thresholds of 5, 8, 12, 16, 20, and 24 in into the 12.7, 20.3, 30.5, 40.64,
#' 50.8, and 60.96 cm that the threshold registry carries on the metric side.
#' \code{cm_to_in} is the exact inverse.
#'
#' @param x numeric, diameter in inches for \code{in_to_cm} or in cm for
#'   \code{cm_to_in}
#' @return numeric, diameter in cm for \code{in_to_cm} or in inches for
#'   \code{cm_to_in}
#' @examples
#' in_to_cm(c(5, 8, 12, 16, 20, 24))
#' cm_to_in(50.8)
#' @export
in_to_cm <- function(x) x * 2.54

#' @rdname in_to_cm
#' @export
cm_to_in <- function(x) x / 2.54

#' Stem density between trees per acre and stems per hectare
#'
#' Converts a per area stem count between the FIA trees per acre expansion and
#' the stems per hectare the package holds internally, at 2.4710538 stems ha-1
#' per tree ac-1. This is the conversion behind the Maine label card's snag
#' thresholds of 18 and 36 trees ac-1, which are the New Brunswick 44.5 and 89
#' stems ha-1 back converted, per the header of
#' \code{data/mosvr_joint/step1_me_v51_score.R} line 11.
#' \code{stems_ha_to_tpa} is the exact inverse.
#'
#' @param x numeric, density in trees ac-1 for \code{tpa_to_stems_ha} or in
#'   stems ha-1 for \code{stems_ha_to_tpa}
#' @return numeric, density in stems ha-1 for \code{tpa_to_stems_ha} or in
#'   trees ac-1 for \code{stems_ha_to_tpa}
#' @examples
#' tpa_to_stems_ha(c(18, 36))
#' stems_ha_to_tpa(89)
#' @export
tpa_to_stems_ha <- function(x) x * 2.4710538

#' @rdname tpa_to_stems_ha
#' @export
stems_ha_to_tpa <- function(x) x / 2.4710538

#' Per tree basal area expansion, FIA convention
#'
#' Computes the per acre basal area contributed by one tree record in FIA
#' units. The 0.005454 constant is a rounded pi / (4 * 144), converting a
#' diameter in inches to basal area in square feet, and \code{TPA_UNADJ}
#' expands the tree to a per acre basis. This is the form used throughout the
#' Maine scripts.
#'
#' The rounding matters only in one narrow way and is documented because it has
#' the shape of something a reconciliation could chase for an afternoon. The
#' exact value is 0.005454154, so the FIA convention reads about 28 parts per
#' million low against the metric convention on the same stand, always in the
#' same direction, which means it does not cancel across a large sample. It is
#' four orders of magnitude below the spacing of any threshold in this package,
#' so it changes no score.
#'
#' @param dia_in numeric, diameter at breast height in inches
#' @param tpa numeric, trees per acre expansion factor (FIA \code{TPA_UNADJ}),
#'   in trees ac-1
#' @return numeric, basal area in ft2 ac-1
#' @examples
#' ba_fia(20, 1)
#' ft2ac_to_m2ha(ba_fia(20, 1))
#' @export
ba_fia <- function(dia_in, tpa) 0.005454 * dia_in^2 * tpa

#' Per tree basal area expansion, metric convention
#'
#' Computes the per hectare basal area contributed by one tree record in
#' metric units. pi / 40000 converts a diameter in centimetres to basal area in
#' square metres, and stems per hectare expands to a per hectare basis. This is
#' the form used throughout the New Brunswick scripts. On the same tree it agrees
#' with \code{ba_fia} to about 28 parts per million and not better, for the
#' reason given there.
#'
#' @param dbh_cm numeric, diameter at breast height in cm
#' @param stems_ha numeric, stems per hectare expansion factor, in stems ha-1
#' @return numeric, basal area in m2 ha-1
#' @examples
#' ba_metric(50.8, tpa_to_stems_ha(1))
#' @export
ba_metric <- function(dbh_cm, stems_ha) (pi / 40000) * dbh_cm^2 * stems_ha

#' Convert a threshold in a named unit to the canonical SI unit
#'
#' Internal. Returns the value unchanged when it is already canonical and
#' errors on an unknown unit label so that a typo in the registry fails loudly.
#'
#' @param value numeric, the threshold in its native unit
#' @param unit character, one of \code{"ft2_ac"}, \code{"m2_ha"}, \code{"in"},
#'   \code{"cm"}, \code{"tpa"}, \code{"stems_ha"}, \code{"m"}, \code{"yr"},
#'   \code{"prop"}, or \code{"index"}
#' @return numeric, the threshold in m2 ha-1, cm, stems ha-1, m, years, a
#'   proportion, or an index value as the unit dictates
#' @keywords internal
#' @noRd
.to_si <- function(value, unit) {
  if (is.null(unit) || is.na(unit)) return(value)
  switch(unit,
    "ft2_ac"    = ft2ac_to_m2ha(value),
    "m2_ha"     = value,
    "in"        = in_to_cm(value),
    "cm"        = value,
    "tpa"       = tpa_to_stems_ha(value),
    "stems_ha"  = value,
    "m"         = value,
    "yr"        = value,
    "prop"      = value,
    "index"     = value,
    stop("unknown unit: ", unit)
  )
}
