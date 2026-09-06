# attributes.R --------------------------------------------------------------
#
# Plot attributes from a tree list. Both builders return the same SI schema, so
# a Maine FIA plot and a New Brunswick CLI plot become comparable objects and
# the remaining differences are in the instruments rather than hidden in the
# data preparation.
#
# The schema carries every jurisdiction convention as its own named column
# rather than one column computed differently by jurisdiction. That is the
# design decision that makes the differences inspectable: ba_large_508 and
# ba_large_500 are both present on every plot, so the 0.8 cm floor difference
# between Maine and New Brunswick is a choice of column and not a branch buried
# in a scoring function.
#
# No coordinate is read or required anywhere in this file.

#' Weighted standard deviation with a frequency correction
#'
#' Internal. Computes the expansion weighted standard deviation of live
#' diameter, the Maine convention for the structure axis, matching the TPA
#' weighted \code{sd_dia} at \code{scripts/jobA_design_based_rfia.R} line 149.
#' Records with a missing value or a nonpositive weight are dropped, and fewer
#' than two remaining records return \code{NA}.
#'
#' @param x numeric, diameter in the caller's unit (inches from
#'   \code{plot_attributes_fia}, cm from \code{plot_attributes_cli})
#' @param w numeric, per tree expansion weight in trees ac-1 or stems ha-1
#' @return numeric scalar, the weighted standard deviation in the unit of
#'   \code{x}
#' @keywords internal
#' @noRd
.wt_sd <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  x <- x[ok]; w <- w[ok]
  n <- length(x)
  if (n < 2) return(NA_real_)
  mu <- sum(w * x) / sum(w)
  v <- sum(w * (x - mu)^2) / (sum(w) * (n - 1) / n)
  sqrt(v)
}

#' Column names of the canonical SI attribute schema
#'
#' Internal. The fourteen attribute names every plot carries, whichever
#' jurisdiction it came from. Basal areas are in m2 ha-1, diameters in cm,
#' snag densities in stems ha-1, \code{ba_late_prop} is a proportion, and the
#' two counts are record counts.
#'
#' @return character vector of column names
#' @keywords internal
#' @noRd
.attr_schema <- function() c(
  "ba_large_508", "ba_large_500", "ba_large_406", "ba_total", "ba_snag_127",
  "sd_dia_weighted", "sd_dia_unweighted", "max_dia", "qmd",
  "snag_density_127", "snag_density_nofloor", "ba_late_prop", "n_live", "n_snag"
)

#' An empty attribute record
#'
#' Internal. Returns the schema as a named list of \code{NA} with the two
#' record counts set to zero, which is what an empty tree list produces.
#'
#' @return a named list on the canonical SI schema
#' @keywords internal
#' @noRd
.empty_attrs <- function() {
  out <- as.list(rep(NA_real_, length(.attr_schema())))
  names(out) <- .attr_schema()
  out$n_live <- 0; out$n_snag <- 0
  out
}

#' Plot attributes from an FIA tree list
#'
#' Takes tree records in FIA units and returns the canonical SI attribute set,
#' so that a Maine plot and a New Brunswick plot become comparable objects and
#' the remaining differences sit in the instruments rather than in the data
#' preparation. Live trees are \code{STATUSCD == 1} at or above
#' \code{dia_floor_in}, matching \code{build_unified_plot_table.r} lines 49 and
#' 52. Snags are \code{STATUSCD == 2}, and both the 5 in (12.7 cm) floor Maine
#' uses (\code{scripts/jobA_design_based_rfia.R} lines 151 and 152) and the
#' unfloored count New Brunswick uses
#' (\code{scripts/cardinal/nb_cli_lsog_fullscope.py} line 183) are returned, so
#' either convention can be scored.
#'
#' Three large tree basal areas are returned side by side, above 20 in (50.8
#' cm, the Maine floor at \code{build_unified_plot_table.r} line 53), above 50
#' cm (the New Brunswick floor at \code{nb_cli_lsog_fullscope.py} line 412),
#' and above 16 in (40.64 cm, the strict rule's A1 floor at
#' \code{scripts/jobB_four_axis_no_proxy.R} line 145). Both the expansion
#' weighted and the unweighted standard deviation of live diameter are returned
#' for the same reason. Per tree basal area uses \code{ba_fia} and is converted
#' once through \code{ft2ac_to_m2ha}.
#'
#' @param dia_in numeric, FIA \code{DIA}, diameter at breast height in inches
#' @param tpa numeric, FIA \code{TPA_UNADJ}, expansion factor in trees ac-1
#' @param statuscd integer, FIA \code{STATUSCD}, 1 live and 2 dead
#' @param spcd optional integer, FIA \code{SPCD}, needed only for the A3
#'   composition axis, and \code{ba_late_prop} is \code{NA} when it is absent
#' @param dia_floor_in numeric, live tree inclusion floor in inches, default
#'   1.0 in
#' @return a named list on the canonical SI schema with \code{ba_large_508},
#'   \code{ba_large_500}, \code{ba_large_406}, \code{ba_total}, and
#'   \code{ba_snag_127} in m2 ha-1, \code{sd_dia_weighted},
#'   \code{sd_dia_unweighted}, \code{max_dia}, and \code{qmd} in cm,
#'   \code{snag_density_127} and \code{snag_density_nofloor} in stems ha-1,
#'   \code{ba_late_prop} as a proportion of live basal area, and \code{n_live}
#'   and \code{n_snag} as record counts
#' @examples
#' a <- plot_attributes_fia(dia_in = c(22, 9, 6, 7),
#'                          tpa = c(6.018, 6.018, 6.018, 6.018),
#'                          statuscd = c(1L, 1L, 1L, 2L),
#'                          spcd = c(97L, 12L, 97L, 12L))
#' a$ba_large_508
#' a$ba_late_prop
#' @export
plot_attributes_fia <- function(dia_in, tpa, statuscd, spcd = NULL,
                                dia_floor_in = 1.0) {
  stopifnot(length(dia_in) == length(tpa), length(dia_in) == length(statuscd))
  out <- .empty_attrs()
  if (!length(dia_in)) return(out)

  live <- !is.na(statuscd) & statuscd == 1 & !is.na(dia_in) & dia_in >= dia_floor_in
  dead <- !is.na(statuscd) & statuscd == 2 & !is.na(dia_in)

  ba_tree <- ba_fia(dia_in, tpa)                       # ft2 ac-1
  sum_ba <- function(sel) ft2ac_to_m2ha(sum(ba_tree[sel], na.rm = TRUE))

  out$ba_total     <- sum_ba(live)
  out$ba_large_508 <- sum_ba(live & dia_in >= 20)      # 20 in, the Maine floor
  out$ba_large_500 <- sum_ba(live & in_to_cm(dia_in) >= 50)
  out$ba_large_406 <- sum_ba(live & dia_in >= 16)      # A1 floor
  out$ba_snag_127  <- sum_ba(dead & dia_in >= 5)

  out$sd_dia_weighted   <- in_to_cm(.wt_sd(dia_in[live], tpa[live]))
  out$sd_dia_unweighted <- if (sum(live) >= 2) in_to_cm(stats::sd(dia_in[live])) else NA_real_
  out$max_dia <- if (any(live)) in_to_cm(max(dia_in[live], na.rm = TRUE)) else NA_real_

  if (any(live) && sum(tpa[live], na.rm = TRUE) > 0) {
    d <- in_to_cm(dia_in[live]); w <- tpa[live]
    out$qmd <- sqrt(sum(w * d^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
  }

  out$snag_density_127     <- tpa_to_stems_ha(sum(tpa[dead & dia_in >= 5], na.rm = TRUE))
  out$snag_density_nofloor <- tpa_to_stems_ha(sum(tpa[dead], na.rm = TRUE))
  out$n_live <- sum(live); out$n_snag <- sum(dead)

  if (!is.null(spcd)) {
    late <- spcd %in% late_species()$spcd
    ba_live_total <- sum(ba_tree[live], na.rm = TRUE)
    out$ba_late_prop <- if (ba_live_total > 0)
      sum(ba_tree[live & late], na.rm = TRUE) / ba_live_total else NA_real_
  }
  out
}

#' Plot attributes from a New Brunswick CLI tree list
#'
#' Takes tree records in metric units and returns the same canonical SI
#' attribute set as \code{plot_attributes_fia}. Live status is
#' \code{c("L", "LS")} and snag status is \code{"DS"}, matching
#' \code{scripts/cardinal/nb_cli_lsog_fullscope.py} lines 185 and 186. Note
#' that the wider vocabulary in \code{cardinal_nb_magplot.py} lines 45 and 46
#' admits more codes, which changes which trees enter without changing any
#' threshold. Per tree basal area uses \code{ba_metric} and needs no
#' conversion. The unweighted standard deviation of diameter is the New
#' Brunswick structure convention (\code{nb_cli_lsog_fullscope.py} line 181)
#' and the weighted one is returned alongside it so that the Maine convention
#' can be applied to the same plot.
#'
#' @param dbh_cm numeric, diameter at breast height in cm
#' @param stems_ha numeric, expansion factor in stems ha-1
#' @param status character, CLI tree status code
#' @param live_codes character, statuses counted as live, default
#'   \code{c("L", "LS")}
#' @param dead_codes character, statuses counted as snags, default
#'   \code{"DS"}
#' @return a named list on the canonical SI schema, in the units given for
#'   \code{plot_attributes_fia}, and \code{ba_late_prop} is always \code{NA} since
#'   the CLI builder carries no species set
#' @examples
#' a <- plot_attributes_cli(dbh_cm = c(56, 23, 15, 18),
#'                          stems_ha = c(14.87, 14.87, 14.87, 14.87),
#'                          status = c("L", "L", "LS", "DS"))
#' a$ba_large_500
#' a$snag_density_nofloor
#' @export
plot_attributes_cli <- function(dbh_cm, stems_ha, status,
                                live_codes = c("L", "LS"),
                                dead_codes = c("DS")) {
  stopifnot(length(dbh_cm) == length(stems_ha), length(dbh_cm) == length(status))
  out <- .empty_attrs()
  if (!length(dbh_cm)) return(out)

  live <- status %in% live_codes & !is.na(dbh_cm) & dbh_cm > 0
  dead <- status %in% dead_codes

  ba_tree <- ba_metric(dbh_cm, stems_ha)               # already m2 ha-1
  sum_ba <- function(sel) sum(ba_tree[sel], na.rm = TRUE)

  out$ba_total     <- sum_ba(live)
  out$ba_large_500 <- sum_ba(live & dbh_cm >= 50)      # the New Brunswick floor
  out$ba_large_508 <- sum_ba(live & dbh_cm >= 50.8)
  out$ba_large_406 <- sum_ba(live & dbh_cm >= 40.64)
  out$ba_snag_127  <- sum_ba(dead & !is.na(dbh_cm) & dbh_cm >= 12.7)

  out$sd_dia_unweighted <- if (sum(live) >= 2) stats::sd(dbh_cm[live]) else NA_real_
  out$sd_dia_weighted   <- .wt_sd(dbh_cm[live], stems_ha[live])
  out$max_dia <- if (any(live)) max(dbh_cm[live], na.rm = TRUE) else NA_real_

  if (any(live) && sum(stems_ha[live], na.rm = TRUE) > 0) {
    d <- dbh_cm[live]; w <- stems_ha[live]
    out$qmd <- sqrt(sum(w * d^2, na.rm = TRUE) / sum(w, na.rm = TRUE))
  }

  out$snag_density_127     <- sum(stems_ha[dead & !is.na(dbh_cm) & dbh_cm >= 12.7], na.rm = TRUE)
  out$snag_density_nofloor <- sum(stems_ha[dead], na.rm = TRUE)
  out$n_live <- sum(live); out$n_snag <- sum(dead)
  out
}
