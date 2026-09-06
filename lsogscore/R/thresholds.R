# thresholds.R --------------------------------------------------------------
#
# The threshold registry. Every number the package uses lives here once, in the
# units its source code used, with the file and line it came from. Nothing
# elsewhere in the package hard-codes a threshold.
#
# Read this table first if you want to know how two instruments differ. Where a
# Maine and a New Brunswick row look different but convert to the same SI value,
# the difference is unit expression. Where they do not converge, the difference
# is real, and the four real ones are flagged in the note column.

.THRESHOLDS <- local({
  r <- function(instrument, axis, variable, jurisdiction, score1, score2, unit,
                max_score, source_file, source_line, note = "") {
    data.frame(
      instrument = instrument, axis = axis, variable = variable,
      jurisdiction = jurisdiction, score1 = score1, score2 = score2,
      unit = unit, max_score = max_score, source_file = source_file,
      source_line = source_line, note = note,
      stringsAsFactors = FALSE
    )
  }

  rbind(
    # --- Maine published six-axis card (v5.1), behind any-LSOG 14.66% --------
    r("me_v51", "s_ba", "ba_large (live BA in trees at or above the large-tree floor)",
      "ME", 40, 80, "ft2_ac", 2,
      "scripts/jobA_design_based_rfia.R", "112",
      "large-tree floor is DIA >= 20 in (50.8 cm), build_unified_plot_table.r:53"),
    r("me_v51", "s_mat", "STDAGE (FIA stand age)",
      "ME", 80, 120, "yr", 2,
      "scripts/jobA_design_based_rfia.R", "125-127",
      "REAL DIFFERENCE: New Brunswick has no stand age and scores maturity on QMD"),
    r("me_v51", "s_mat_fallback", "max_dia, used only where STDAGE is NA or 0",
      "ME", 24, NA, "in", 1,
      "scripts/jobA_design_based_rfia.R", "127",
      "capped at 1 point, declared ceiling 20% of scored plots per state (jobA:134)"),
    r("me_v51", "s_str", "sd_dia (TPA-weighted sd of live DIA)",
      "ME", 5, 8, "in", 2,
      "scripts/jobA_design_based_rfia.R", "149",
      "REAL DIFFERENCE: weighted here, unweighted in New Brunswick"),
    r("me_v51", "s_can", "ba_total (all live trees at or above DIA 1.0 in)",
      "ME", 100, 150, "ft2_ac", 2,
      "scripts/jobA_design_based_rfia.R", "150", ""),
    r("me_v51", "s_dw", "snag_tpa (STATUSCD 2, DIA >= 5.0 in)",
      "ME", NA, NA, "tpa", 2,
      "scripts/jobA_design_based_rfia.R", "151-152",
      paste("REAL DIFFERENCE: per-state quantile, q75 and q90 of nonzero snag_tpa,",
            "not a fixed pair. See me_v51_snag_quantiles().")),
    r("me_v51", "s_ht", "potapov_rh95 (Potapov GLAD 2019 RH95)",
      "ME", 18, 25, "m", 2,
      "scripts/jobA_design_based_rfia.R", "153",
      "REAL DIFFERENCE: the New Brunswick published card has no height axis at all"),

    # --- New Brunswick published five-axis card, behind any-LSOG 31.47% -----
    r("nb_v51", "sc_balarge", "ba_large (live BA in trees at or above the large-tree floor)",
      "NB", 9.18, 18.4, "m2_ha", 2,
      "scripts/cardinal/nb_cli_lsog_fullscope.py", "179",
      "large-tree floor is dbh >= 50 cm (line 412), against Maine's 50.8 cm"),
    r("nb_v51", "sc_mat", "qmd (stems-per-hectare weighted quadratic mean diameter)",
      "NB", 20.3, 30.5, "cm", 2,
      "scripts/cardinal/nb_cli_lsog_fullscope.py", "180",
      "REAL DIFFERENCE: Maine scores maturity on stand age"),
    r("nb_v51", "sc_struct", "sd_dia (unweighted sd of dbh, ddof = 1)",
      "NB", 12.7, 20.3, "cm", 2,
      "scripts/cardinal/nb_cli_lsog_fullscope.py", "181",
      "REAL DIFFERENCE: unweighted here, TPA-weighted in Maine"),
    r("nb_v51", "sc_canopy", "ba_total (all live basal area)",
      "NB", 22.96, 34.4, "m2_ha", 2,
      "scripts/cardinal/nb_cli_lsog_fullscope.py", "182", ""),
    r("nb_v51", "sc_dead", "snag_ha (tree_status DS, no diameter floor)",
      "NB", 44.5, 89, "stems_ha", 2,
      "scripts/cardinal/nb_cli_lsog_fullscope.py", "183",
      paste("REAL DIFFERENCE: no diameter floor on snags, against Maine's 5.0 in floor,",
            "and a fixed pair rather than a per-state quantile")),

    # --- Maine small-area-estimation label card ------------------------------
    r("me_sae", "s_ba", "ba_large (floor DIA >= 20 in)",
      "ME", 40, 80, "ft2_ac", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "76", ""),
    r("me_sae", "s_mat", "max_dia",
      "ME", 24, NA, "in", 1,
      "data/mosvr_joint/step1_me_v51_score.R", "77",
      "drops STDAGE entirely, which is what takes the maximum from 12 to 11"),
    r("me_sae", "s_str", "sd_dia (TPA-weighted)",
      "ME", 5, 8, "in", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "78", ""),
    r("me_sae", "s_can", "ba_total",
      "ME", 100, 150, "ft2_ac", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "79", ""),
    r("me_sae", "s_dw", "snag_tpa (DIA >= 5 in floor)",
      "ME", 18, 36, "tpa", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "80",
      paste("fixed pair replacing the published card's per-state quantile.",
            "Set in New Brunswick units and back-converted, per that script's own",
            "header at line 11, not derived from Maine data")),
    r("me_sae", "s_ht", "canopy_ht_m (Potapov GLAD)",
      "ME", 18, 25, "m", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "81",
      "REAL DIFFERENCE: New Brunswick's label card reads ETH GlobalCanopyHeight under the same column name"),

    # --- New Brunswick small-area-estimation label card ----------------------
    r("nb_sae", "s_ba", "ba_large (floor dbh >= 50 cm)",
      "NB", 9.18, 18.4, "m2_ha", 2,
      "nb_public_v51_pipeline_v2.py", "88", ""),
    r("nb_sae", "s_mat", "max_dia, not QMD",
      "NB", 60.96, NA, "cm", 1,
      "nb_public_v51_pipeline_v2.py", "89",
      "this is the axis CORE4 harmonizes on, and it agrees with Maine exactly"),
    r("nb_sae", "s_str", "sd_dia (unweighted)",
      "NB", 12.7, 20.32, "cm", 2,
      "nb_public_v51_pipeline_v2.py", "90", ""),
    r("nb_sae", "s_can", "ba_total",
      "NB", 22.96, 34.44, "m2_ha", 2,
      "nb_public_v51_pipeline_v2.py", "91", ""),
    r("nb_sae", "s_dw", "snag_ha (no diameter floor)",
      "NB", 44.5, 89, "stems_ha", 2,
      "nb_public_v51_pipeline_v2.py", "92", ""),
    r("nb_sae", "s_ht", "canopy_ht_m (ETH GlobalCanopyHeight 10 m 2020)",
      "NB", 18, 25, "m", 2,
      "nb_public_v51_pipeline_v2.py", "93-94",
      "uint8 nodata sentinel 255 nulled at line 77"),

    # --- Strict four-axis conjunctive rule, behind Maine true LSOG 2.5% ------
    r("strict4", "A1", "BA_large (live BA in trees at or above DIA 16 in)",
      "ME", 30, NA, "ft2_ac", 1,
      "scripts/jobB_four_axis_no_proxy.R", "156",
      "pass or fail, not a score. Floor is DIA >= 16 in (40.64 cm), line 145"),
    r("strict4", "A2", "BA_snag (STATUSCD 2, DIA >= 5 in)",
      "ME", 5, NA, "ft2_ac", 1,
      "scripts/jobB_four_axis_no_proxy.R", "157", "pass or fail"),
    r("strict4", "A3", "BA_late / BA_live over the LATE species set",
      "ME", 0.5, NA, "prop", 1,
      "scripts/jobB_four_axis_no_proxy.R", "158",
      "LATE species vector at line 83, see late_species()"),
    r("strict4", "A4", "yodh (LCMS year of detection, heavy classes, 1985 to 2023)",
      "ME", 0, NA, "yr", 1,
      "scripts/jobB_four_axis_no_proxy.R", "189",
      "passes where yodh == 0 inside the AOI. HEAVY = c(2,6,7,8,9,13), line 81"),

    # --- CORE4, the four comparably measured axes ---------------------------
    r("core4", "s_ba", "ba_large",
      "ME", 40, 80, "ft2_ac", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "76",
      "Maine floor DIA >= 20 in (50.8 cm), New Brunswick floor dbh >= 50 cm. The 0.8 cm gap is real"),
    r("core4", "s_ba", "ba_large",
      "NB", 9.18, 18.4, "m2_ha", 2,
      "scripts/cardinal/nb_instrument_sweep_core4_20260902.py", "101-102", ""),
    r("core4", "s_mat", "max_dia",
      "ME", 24, NA, "in", 1,
      "data/mosvr_joint/step1_me_v51_score.R", "77",
      "0/1 axis. CORE4 uses the max_dia form (CORE4_DIA), not QMD"),
    r("core4", "s_mat", "max_dia",
      "NB", 60.96, NA, "cm", 1,
      "scripts/cardinal/nb_instrument_sweep_20260902.py", "203-204", ""),
    r("core4", "s_str", "sd_dia",
      "ME", 5, 8, "in", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "78",
      "Maine TPA-weighted, New Brunswick unweighted. Real, and not previously tabulated"),
    r("core4", "s_str", "sd_dia",
      "NB", 12.7, 20.32, "cm", 2,
      "scripts/cardinal/nb_instrument_sweep_20260902.py", "198-204", ""),
    r("core4", "s_can", "ba_total",
      "ME", 100, 150, "ft2_ac", 2,
      "data/mosvr_joint/step1_me_v51_score.R", "79", ""),
    r("core4", "s_can", "ba_total",
      "NB", 22.96, 34.44, "m2_ha", 2,
      "scripts/cardinal/nb_instrument_sweep_20260902.py", "198-204", ""),

    # --- CORE5 penalty gate --------------------------------------------------
    r("core5_continuous", "tall_gate", "canopy_ht_m",
      "both", 18, NA, "m", 0,
      "build/saeczi_v1/fit_saeczi_v7_core5_continuous_tolerance.R", "66, 90",
      paste("gate only, contributes no points. Reads Potapov GLAD in Maine and ETH in",
            "New Brunswick under one column name, so the penalty reintroduces the",
            "border-crossing height product in a limited role")),
    r("core5_continuous", "tolerance_gate", "tol_score_ba (Niinemets and Valladares 2006, BA weighted)",
      "both", 2.75, NA, "index", 0,
      "build/saeczi_v1/fit_saeczi_v7_core5_continuous_tolerance.R", "68, 91",
      paste("penalty fires at or below 2.75 on a 0.87 to 5.01 scale.",
            "Jurisdiction calibrations 2.7457 ME and 2.7332 NB, pooled to one value")),
    r("core5_categorical", "tall_gate", "canopy_ht_m",
      "both", 18, NA, "m", 0,
      "build/saeczi_v1/fit_saeczi_v6_core5_production.R", "73, 93",
      "earlier categorical form, superseded by the continuous form for the reported numbers"),
    r("core5_categorical", "tolerance_gate", "pct_ba_intolerant",
      "both", 50, NA, "prop", 0,
      "build/saeczi_v1/fit_saeczi_v6_core5_production.R", "94",
      "intolerant_dominant, Baker 1949 classes as reproduced in Burns and Honkala 1990")
  )
})

# Instrument-level facts: maximum score, qualifying cut, and the old-growth cut
# where the instrument defines one.
.INSTRUMENTS <- data.frame(
  instrument = c("me_v51", "nb_v51", "me_sae", "nb_sae", "core4",
                 "core5_continuous", "core5_categorical", "strict4"),
  n_axes = c(6L, 5L, 6L, 6L, 4L, 5L, 5L, 4L),
  max_score = c(12L, 10L, 11L, 11L, 7L, 7L, 7L, 4L),
  cut_any_lsog = c(4L, 4L, 4L, 4L, 3L, 3L, 3L, 4L),
  cut_old_growth = c(8L, 8L, 8L, 8L, NA, NA, NA, NA),
  conjunctive = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE),
  height_in_score = c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
  height_as_gate = c(FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, FALSE),
  source_file = c(
    "scripts/jobA_design_based_rfia.R",
    "scripts/cardinal/nb_cli_lsog_fullscope.py",
    "data/mosvr_joint/step1_me_v51_score.R",
    "nb_public_v51_pipeline_v2.py",
    "no builder exists, see note",
    "build/saeczi_v1/fit_saeczi_v7_core5_continuous_tolerance.R",
    "build/saeczi_v1/fit_saeczi_v6_core5_production.R",
    "scripts/jobB_four_axis_no_proxy.R"),
  source_line = c("156-160", "436-437", "84", "99-100", "", "92", "94", "193, 197"),
  stringsAsFactors = FALSE
)

#' The threshold registry
#'
#' Returns every threshold the package applies, one row per axis per
#' jurisdiction, in the units its source code used, with the SI equivalent
#' computed at the single conversion boundary in \code{.to_si} and the source
#' file and line the number came from. Nothing elsewhere in the package hard
#' codes a threshold. Where a Maine and a New Brunswick row look different but
#' converge in SI, the difference is unit expression. Where they do not
#' converge, the difference is real, and the \code{note} column flags each of
#' those, namely the maturity construct (stand age at
#' \code{scripts/jobA_design_based_rfia.R} lines 125 to 127 against quadratic
#' mean diameter at \code{scripts/cardinal/nb_cli_lsog_fullscope.py} line 180),
#' the structure weighting (line 149 against line 181 of the same two files),
#' the snag definition (lines 151 and 152 against line 183), and the absence of
#' any height axis in New Brunswick.
#'
#' The one row with no literal value is the Maine published card's deadwood
#' axis, which is set from a per state quantile rather than a code line. See
#' \code{me_v51_snag_quantiles}.
#'
#' @param instrument optional character vector of instrument names, one or more
#'   of \code{"me_v51"}, \code{"nb_v51"}, \code{"me_sae"}, \code{"nb_sae"},
#'   \code{"strict4"}, \code{"core4"}, \code{"core5_continuous"}, and
#'   \code{"core5_categorical"}. \code{NULL} returns every row.
#' @return a data frame with columns \code{instrument}, \code{axis},
#'   \code{variable}, \code{jurisdiction}, \code{score1}, \code{score2},
#'   \code{unit}, \code{max_score}, \code{source_file}, \code{source_line},
#'   \code{note}, and the converted \code{score1_si} and \code{score2_si} in
#'   m2 ha-1, cm, stems ha-1, m, years, a proportion, or an index value as the
#'   \code{unit} column dictates
#' @examples
#' lsog_thresholds("nb_v51")[, c("axis", "score1", "score2", "unit", "score1_si")]
#' nrow(lsog_thresholds())
#' @export
lsog_thresholds <- function(instrument = NULL) {
  x <- .THRESHOLDS
  if (!is.null(instrument)) {
    x <- x[x$instrument %in% instrument, , drop = FALSE]
    if (!nrow(x)) stop("no such instrument: ", paste(instrument, collapse = ", "))
  }
  x$score1_si <- vapply(seq_len(nrow(x)),
                        function(i) .to_si(x$score1[i], x$unit[i]), numeric(1))
  x$score2_si <- vapply(seq_len(nrow(x)),
                        function(i) .to_si(x$score2[i], x$unit[i]), numeric(1))
  rownames(x) <- NULL
  x
}

#' Provenance for one axis or one instrument
#'
#' Returns the source file, source line, and note for every threshold row of
#' one instrument, optionally narrowed to one axis. This is the function to
#' call when the question is where a number came from rather than what it is.
#'
#' @param instrument character, one instrument name as accepted by
#'   \code{lsog_thresholds}
#' @param axis optional character, one or more axis names within that
#'   instrument, for example \code{"s_dw"} or \code{"sc_dead"}
#' @return a data frame with columns \code{instrument}, \code{axis},
#'   \code{jurisdiction}, \code{source_file}, \code{source_line}, and
#'   \code{note}
#' @examples
#' threshold_provenance("nb_v51", "sc_dead")
#' threshold_provenance("strict4")
#' @export
threshold_provenance <- function(instrument, axis = NULL) {
  x <- lsog_thresholds(instrument)
  if (!is.null(axis)) x <- x[x$axis %in% axis, , drop = FALSE]
  x[, c("instrument", "axis", "jurisdiction", "source_file", "source_line", "note")]
}

#' Instrument level facts
#'
#' Returns the number of axes, the maximum score, the qualifying cut, the old
#' growth cut where the instrument defines one, whether the instrument is
#' conjunctive, and whether canopy height enters the score, enters only as a
#' gate, or is absent, for each of the eight instrument forms. The cuts and
#' maxima are those the source scripts state, at
#' \code{scripts/jobA_design_based_rfia.R} lines 156 to 160,
#' \code{scripts/cardinal/nb_cli_lsog_fullscope.py} lines 436 and 437,
#' \code{data/mosvr_joint/step1_me_v51_score.R} line 84,
#' \code{nb_public_v51_pipeline_v2.py} lines 99 and 100,
#' \code{build/saeczi_v1/fit_saeczi_v7_core5_continuous_tolerance.R} line 92,
#' \code{build/saeczi_v1/fit_saeczi_v6_core5_production.R} line 94, and
#' \code{scripts/jobB_four_axis_no_proxy.R} lines 193 and 197. CORE4 has no
#' builder script, and its row says so.
#'
#' @return a data frame with one row per instrument and columns
#'   \code{instrument}, \code{n_axes}, \code{max_score}, \code{cut_any_lsog},
#'   \code{cut_old_growth}, \code{conjunctive}, \code{height_in_score},
#'   \code{height_as_gate}, \code{source_file}, and \code{source_line}, all
#'   scores in points
#' @examples
#' instrument_summary()[, c("instrument", "max_score", "cut_any_lsog")]
#' @export
instrument_summary <- function() .INSTRUMENTS

#' Realized Maine snag quantiles for the published six axis card
#'
#' Returns the two deadwood thresholds for the Maine published card, in trees
#' per acre. The Maine deadwood axis is the only quantile set threshold in any
#' of the instruments. \code{build_unified_plot_table.r} lines 60 to 62 set the
#' pair to the 75th and 90th percentiles of nonzero \code{snag_tpa} within each
#' state, with a hard fallback to 10 and 20 trees ac-1 when fewer than eleven
#' plots carry a nonzero value. The realized Maine values of 30 and 54 trees
#' ac-1 are not in any code line, since they come from the run record, and
#' \code{fit_saeczi_v2_core4.R} line 10 independently quotes the 74 stems ha-1
#' figure that 30 trees ac-1 converts to.
#'
#' Call this rather than hard coding, and recompute from data when you have it.
#'
#' @param snag_tpa optional numeric vector of plot snag density in trees ac-1, and
#'   when supplied the quantiles are recomputed from it rather than returned
#'   from the run record
#' @return a named numeric vector \code{c(score1, score2)} of the two
#'   thresholds in trees ac-1, with a \code{source} attribute saying where they
#'   came from
#' @examples
#' me_v51_snag_quantiles()
#' attr(me_v51_snag_quantiles(), "source")
#' me_v51_snag_quantiles(c(rep(0, 20), 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60))
#' @export
me_v51_snag_quantiles <- function(snag_tpa = NULL) {
  if (is.null(snag_tpa)) {
    out <- c(score1 = 30, score2 = 54)
    attr(out, "source") <- paste(
      "run record, not a code line. 30 and 54 trees ac-1, which is 74 and 133",
      "stems ha-1. Recompute from data where possible.")
    return(out)
  }
  nz <- snag_tpa[!is.na(snag_tpa) & snag_tpa > 0]
  if (length(nz) < 11) {
    out <- c(score1 = 10, score2 = 20)
    attr(out, "source") <- "fallback, fewer than 11 nonzero plots (build_unified_plot_table.r:60-62)"
    return(out)
  }
  out <- c(score1 = round(unname(stats::quantile(nz, 0.75))),
           score2 = round(unname(stats::quantile(nz, 0.90))))
  attr(out, "source") <- "recomputed from supplied snag_tpa"
  out
}

#' The A3 late successional species set
#'
#' Returns the ten FIA species codes in the \code{LATE} vector at
#' \code{scripts/jobB_four_axis_no_proxy.R} line 83, in the order the code
#' lists them, with genus, specific epithet, naming authority, and common name.
#' This is the set that produced the reported Maine true LSOG figure of 2.5
#' percent, so it is the definition of record, and it is the set
#' \code{plot_attributes_fia} uses to compute \code{ba_late_prop}.
#'
#' Balsam fir, \emph{Abies balsamea} (L.) Mill., FIA code 12, is not in the
#' set. All ten members are long lived, which balsam fir is not, and that
#' reading also explains the presence of species that are only intermediate in
#' shade tolerance. Whether the exclusion should stand is a specification
#' question, not a coding one.
#'
#' @return a data frame with columns \code{spcd} (integer FIA species code),
#'   \code{genus}, \code{species}, \code{authority}, and \code{common_name}
#' @examples
#' late_species()$spcd
#' 12L %in% late_species()$spcd
#' @export
late_species <- function() {
  data.frame(
    spcd = c(261L, 97L, 95L, 94L, 241L, 318L, 531L, 371L, 129L, 833L),
    genus = c("Tsuga", "Picea", "Picea", "Picea", "Thuja",
              "Acer", "Fagus", "Betula", "Pinus", "Quercus"),
    species = c("canadensis", "rubens", "mariana", "glauca", "occidentalis",
                "saccharum", "grandifolia", "alleghaniensis", "strobus", "rubra"),
    authority = c("(L.) Carriere", "Sarg.", "(Mill.) Britton, Sterns & Poggenb.",
                  "(Moench) Voss", "L.", "Marshall", "Ehrh.", "Britton", "L.", "L."),
    common_name = c("eastern hemlock", "red spruce", "black spruce", "white spruce",
                    "northern white-cedar", "sugar maple", "American beech",
                    "yellow birch", "eastern white pine", "northern red oak"),
    stringsAsFactors = FALSE
  )
}
