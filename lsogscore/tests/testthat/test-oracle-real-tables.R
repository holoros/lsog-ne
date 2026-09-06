# Oracle tests against the project's own precomputed tables.
#
# These prove the package reproduces the numbers already in the manuscript
# rather than merely running. They skip when the tables are not present, so the
# suite still passes on a machine that has only the package.
#
# Point LSOGSCORE_ORACLE_DIR at the directory holding the DATA csv files.
# No test in this file reads, prints, or writes a plot coordinate. The New
# Brunswick table carries lon and lat columns and a licensed holder field, so
# the test that uses it selects columns by name and asserts that none of them is
# a coordinate before doing anything else.

oracle_dir <- function() {
  d <- Sys.getenv("LSOGSCORE_ORACLE_DIR", unset = "~/jobs/saeczi_v1")
  path.expand(d)
}
oracle <- function(f) file.path(oracle_dir(), f)
skip_unless <- function(f) {
  if (!file.exists(oracle(f))) testthat::skip(paste("oracle table not present:", f))
}

test_that("the Maine six-axis table reconciles as the sum of its axes", {
  f <- "me_axes_v51_DATA_2026-09-02.csv"
  skip_unless(f)
  d <- utils::read.csv(oracle(f), stringsAsFactors = FALSE)
  axes <- c("s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht")
  expect_true(all(axes %in% names(d)))
  expect_equal(rowSums(d[axes]), d$total_score)
  expect_equal(as.integer(d$total_score >= 4), as.integer(d$any_lsog))
  expect_equal(as.integer(d$total_score >= 8), as.integer(d$og))
  expect_true(all(d$total_score >= 0 & d$total_score <= 11))
})

test_that("the package reproduces the Maine canopy-height axis on every real plot", {
  # The one axis on this table that can be recomputed from a column the table
  # itself carries, so it is a true end-to-end check of the scoring layer
  # against 3,071 real plots rather than against a fixture.
  f <- "me_axes_v51_DATA_2026-09-02.csv"
  skip_unless(f)
  d <- utils::read.csv(oracle(f), stringsAsFactors = FALSE)
  th <- lsog_thresholds("me_sae")
  ht <- th[th$axis == "s_ht", ]
  ours <- axis_canopy_height(d$canopy_ht_m, ht$score1_si, ht$score2_si)
  expect_equal(ours, as.integer(d$s_ht))
})

test_that("CORE4 in the fitted sample is exactly the four axes summed", {
  f <- "samp_dat_core4_DATA_2026-09-02.csv"
  skip_unless(f)
  d <- utils::read.csv(oracle(f), stringsAsFactors = FALSE)
  expect_equal(d$s_ba + d$s_mat + d$s_str + d$s_can, d$core4)
  expect_true(all(d$core4 >= 0 & d$core4 <= 7))
  # s_mat_max is the axis maximum carried as a scale constant, not a second
  # maturity score. If that ever stops being true the instrument has changed.
  if ("s_mat_max" %in% names(d)) expect_true(all(d$s_mat_max == 1))
})

test_that("the New Brunswick label card reproduces end to end from raw attributes", {
  f <- "nb_axes_v51_DATA_2026-09-02.csv"
  skip_unless(f)
  wanted <- c("ba_large", "max_dia", "sd_dia", "ba_total", "snag_ha",
              "canopy_ht_m", "s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht",
              "total_score")
  d <- utils::read.csv(oracle(f), stringsAsFactors = FALSE)[, wanted]
  # Assert no coordinate came along, before anything else happens.
  expect_false(any(grepl("lat|lon|coord|geom", names(d), ignore.case = TRUE)))

  x <- data.frame(
    ba_large_500 = d$ba_large, max_dia = d$max_dia,
    sd_dia_unweighted = d$sd_dia, ba_total = d$ba_total,
    snag_density_nofloor = d$snag_ha, canopy_ht_m = d$canopy_ht_m
  )
  ours <- score_nb_sae_card(x)
  expect_equal(ours$s_ba,  as.integer(d$s_ba))
  expect_equal(ours$s_mat, as.integer(d$s_mat))
  expect_equal(ours$s_str, as.integer(d$s_str))
  expect_equal(ours$s_can, as.integer(d$s_can))
  expect_equal(ours$s_dw,  as.integer(d$s_dw))
  expect_equal(ours$s_ht,  as.integer(d$s_ht))
  expect_equal(ours$total_score, as.integer(d$total_score))
})
