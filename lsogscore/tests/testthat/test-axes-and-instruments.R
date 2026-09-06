test_that("score_step is a two-step function and NA fails rather than propagates", {
  expect_equal(score_step(c(0, 40, 80, 120), 40, 80), c(0L, 1L, 2L, 2L))
  expect_equal(score_step(c(NA, 40), 40, 80), c(0L, 1L))
  # A missing t2 makes the axis 0/1, which is the maturity axis on both label
  # cards and in CORE4.
  expect_equal(score_step(c(10, 30), 24, NA), c(0L, 1L))
})

test_that("every threshold row converts to SI without error and carries provenance", {
  th <- lsog_thresholds()
  expect_true(all(nzchar(th$source_file)))
  expect_true(all(nzchar(th$source_line)))
  # Exactly one row may carry a missing score1, the Maine published card's
  # deadwood axis, because it is the only quantile-set threshold in any
  # instrument and has no literal value to store. If a second one ever appears,
  # a threshold has gone missing rather than being deliberately absent.
  missing1 <- th[is.na(th$score1_si), , drop = FALSE]
  expect_equal(nrow(missing1), 1L)
  expect_equal(missing1$instrument, "me_v51")
  expect_equal(missing1$axis, "s_dw")
  expect_match(missing1$note, "quantile")
})

test_that("the instrument table states the maxima the source code states", {
  s <- instrument_summary()
  get <- function(i, f) s[[f]][s$instrument == i]
  expect_equal(get("me_v51", "max_score"), 12L)
  expect_equal(get("nb_v51", "max_score"), 10L)
  expect_equal(get("me_sae", "max_score"), 11L)
  expect_equal(get("nb_sae", "max_score"), 11L)
  expect_equal(get("core4", "max_score"), 7L)
  expect_equal(get("core4", "cut_any_lsog"), 3L)
  expect_equal(get("me_v51", "cut_any_lsog"), 4L)
})

test_that("only one instrument scores canopy height, and the strict rule never touches it", {
  s <- instrument_summary()
  expect_false(s$height_in_score[s$instrument == "nb_v51"])
  expect_false(s$height_in_score[s$instrument == "core4"])
  expect_false(s$height_in_score[s$instrument == "strict4"])
  expect_true(s$height_as_gate[s$instrument == "core5_continuous"])
  expect_false(s$height_in_score[s$instrument == "core5_continuous"])
})

test_that("the axis maxima in the registry sum to the instrument maximum", {
  for (i in c("me_v51", "nb_v51", "me_sae", "nb_sae")) {
    th <- lsog_thresholds(i)
    # The Maine published card's fallback shares the maturity axis rather than
    # adding one, so it is excluded from the sum.
    th <- th[th$axis != "s_mat_fallback", , drop = FALSE]
    expect_equal(sum(th$max_score),
                 instrument_summary()$max_score[instrument_summary()$instrument == i],
                 info = i)
  }
})

test_that("a hand-computed FIA plot gives the attributes we can check by hand", {
  # Three live trees and one snag, one tree per acre each.
  a <- plot_attributes_fia(
    dia_in   = c(22, 18, 6, 8),
    tpa      = c(1, 1, 1, 1),
    statuscd = c(1, 1, 1, 2)
  )
  expect_equal(a$n_live, 3); expect_equal(a$n_snag, 1)
  expect_equal(a$max_dia, in_to_cm(22))
  # Only the 22 in tree clears the 20 in floor.
  expect_equal(a$ba_large_508, ft2ac_to_m2ha(ba_fia(22, 1)))
  # Both the 22 and the 18 clear the 16 in A1 floor.
  expect_equal(a$ba_large_406, ft2ac_to_m2ha(ba_fia(22, 1) + ba_fia(18, 1)))
  # The 8 in snag clears the 5 in floor, so both snag columns agree here.
  expect_equal(a$snag_density_127, tpa_to_stems_ha(1))
  expect_equal(a$snag_density_nofloor, tpa_to_stems_ha(1))
})

test_that("the snag floor is where Maine and New Brunswick genuinely diverge", {
  # A stand of small snags counts fully in New Brunswick and not at all in Maine.
  a <- plot_attributes_fia(
    dia_in   = c(20, 3, 3, 3),
    tpa      = c(1, 10, 10, 10),
    statuscd = c(1, 2, 2, 2)
  )
  expect_equal(a$snag_density_127, 0)
  expect_gt(a$snag_density_nofloor, 70)
})

test_that("the two attribute builders agree on the same stand expressed both ways", {
  fia <- plot_attributes_fia(
    dia_in   = c(24, 20, 12),
    tpa      = c(2, 3, 5),
    statuscd = c(1, 1, 1)
  )
  cli <- plot_attributes_cli(
    dbh_cm   = in_to_cm(c(24, 20, 12)),
    stems_ha = tpa_to_stems_ha(c(2, 3, 5)),
    status   = c("L", "L", "L")
  )
  # Tolerance is 1e-4 and not tighter, for a reason worth knowing. See the test
  # below: the FIA basal-area constant is itself rounded, so the two conventions
  # cannot agree to machine precision on the same stand.
  expect_equal(fia$ba_total, cli$ba_total, tolerance = 1e-4)
  expect_equal(fia$max_dia, cli$max_dia, tolerance = 1e-9)
  expect_equal(fia$qmd, cli$qmd, tolerance = 1e-9)
  expect_equal(fia$sd_dia_unweighted, cli$sd_dia_unweighted, tolerance = 1e-9)
  expect_equal(fia$ba_large_500, cli$ba_large_500, tolerance = 1e-4)
})

test_that("the FIA basal-area constant is rounded, which caps cross-convention agreement", {
  # 0.005454 is a rounded pi / (4 * 144) = 0.005454153...  The two conventions
  # therefore differ by about 28 parts per million on any stand, always in the
  # same direction, with FIA reading low. Far below any threshold spacing here,
  # so it changes no score, and worth knowing before anyone chases a mismatch in
  # the fifth decimal place of a reconciliation.
  exact <- pi / (4 * 144)
  expect_equal(round(exact, 9), 0.005454154)
  rel <- (exact - 0.005454) / exact
  expect_lt(rel, 3e-5)
  expect_gt(rel, 2e-5)
  # The gap is one-directional, so it cannot cancel across a large sample.
  expect_lt(ft2ac_to_m2ha(ba_fia(20, 1)), ba_metric(50.8, tpa_to_stems_ha(1)))
})

test_that("CORE5 subtracts only on the interaction and never raises a score", {
  core4 <- c(4L, 4L, 4L, 4L)
  ht    <- c(20, 20, 10, 10)
  tol   <- c(2.0, 4.0, 2.0, 4.0)   # continuous index, penalty at or below 2.75
  r <- score_core5(core4, ht, tol, form = "continuous")
  expect_equal(r$penalty, c(1L, 0L, 0L, 0L))
  expect_equal(r$core5, c(3L, 4L, 4L, 4L))
  expect_true(all(r$core5 <= core4))
})

test_that("a plot with no tolerance value is never penalized", {
  r <- score_core5(4L, 25, NA_real_, form = "continuous")
  expect_equal(r$penalty, 0L)
  expect_equal(r$core5, 4L)
})

test_that("the categorical CORE5 form gates in the opposite direction", {
  # pct_ba_intolerant fires at or ABOVE 50, tol_score_ba fires at or BELOW 2.75.
  expect_equal(score_core5(4L, 20, 60, form = "categorical")$penalty, 1L)
  expect_equal(score_core5(4L, 20, 40, form = "categorical")$penalty, 0L)
})

test_that("the strict rule is conjunctive, so any one failing axis fails the plot", {
  x <- data.frame(
    ba_large_406 = c(10, 10, 10, 10, 1),
    ba_snag_127  = c(2, 2, 2, 0.1, 2),
    ba_late_prop = c(0.8, 0.8, 0.2, 0.8, 0.8)
  )
  yodh <- c(0, 2001, 0, 0, 0)
  r <- score_strict_four_axis(x, yodh)
  expect_equal(r$true_lsog, c(1L, 0L, 0L, 0L, 0L))
})

test_that("the A3 species set is the ten codes the executed rule used", {
  sp <- late_species()
  expect_equal(nrow(sp), 10L)
  expect_equal(sp$spcd, c(261L, 97L, 95L, 94L, 241L, 318L, 531L, 371L, 129L, 833L))
  # Balsam fir is not in the set. This is the specification question on record,
  # and the test exists so that a silent change to the vector fails loudly.
  expect_false(12L %in% sp$spcd)
  expect_equal(sp$species[sp$spcd == 94L], "glauca")
  expect_equal(sp$species[sp$spcd == 95L], "mariana")
})

test_that("the Maine snag quantiles recompute from data and fall back when sparse", {
  q <- me_v51_snag_quantiles(c(rep(0, 50), 1:40))
  expect_equal(unname(q[["score1"]]), round(unname(stats::quantile(1:40, 0.75))))
  f <- me_v51_snag_quantiles(c(1, 2, 3))
  expect_equal(unname(f[["score1"]]), 10)
  expect_match(attr(f, "source"), "fallback")
})

test_that("running every instrument over one table returns comparable flags", {
  x <- data.frame(
    ba_large_508 = c(20, 5), ba_large_500 = c(20, 5), ba_large_406 = c(25, 6),
    ba_total = c(40, 15), ba_snag_127 = c(2, 0.1),
    sd_dia_weighted = c(22, 8), sd_dia_unweighted = c(22, 8),
    max_dia = c(70, 30), qmd = c(35, 18),
    snag_density_127 = c(150, 5), snag_density_nofloor = c(150, 5),
    ba_late_prop = c(0.9, 0.1), canopy_ht_m = c(24, 12)
  )
  s <- score_all_instruments(x, jurisdiction = c("ME", "NB"),
                             yodh = c(0, 0), tolerance = c(4.5, 2.0))
  expect_true(all(c("core4", "core5", "published_total") %in% names(s)))
  expect_equal(s$core4_any, c(1L, 0L))
  d <- instrument_deltas(s)
  expect_true("core4" %in% d$instrument)
  expect_true(all(d$rate_pct >= 0 & d$rate_pct <= 100))
})
