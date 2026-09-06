#' lsogscore: late successional and old growth scoring instruments for Maine and New Brunswick
#'
#' One tested implementation of every late successional and old growth (LSOG)
#' scoring instrument used in the Maine and New Brunswick analysis, in place of
#' the seven scattered R and Python implementations that preceded it. Every
#' threshold is stored once in \code{lsog_thresholds} in the units its source
#' code used, carries the file and line it came from, and is converted at a
#' single boundary, so a jurisdiction difference is visible rather than
#' silently harmonized. No plot coordinate is read, written, or required.
#'
#' The package has four layers. Unit conversions (\code{ft2ac_to_m2ha},
#' \code{in_to_cm}, \code{tpa_to_stems_ha}, \code{ba_fia}, \code{ba_metric})
#' form the one conversion boundary. Attribute builders
#' (\code{plot_attributes_fia}, \code{plot_attributes_cli}) turn a tree list
#' from either jurisdiction into one SI schema. Axis primitives
#' (\code{score_step} and the \code{axis_} wrappers) turn an attribute and two
#' thresholds into a score. Instruments (\code{score_me_v51},
#' \code{score_nb_v51}, \code{score_me_sae_card}, \code{score_nb_sae_card},
#' \code{score_core4}, \code{score_core5}, \code{score_strict_four_axis}) apply
#' the registry, and \code{score_all_instruments} with \code{instrument_deltas}
#' runs them side by side over one plot table.
#'
#' @keywords internal
"_PACKAGE"
