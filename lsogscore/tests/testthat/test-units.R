test_that("conversions round trip", {
  expect_equal(m2ha_to_ft2ac(ft2ac_to_m2ha(40)), 40)
  expect_equal(cm_to_in(in_to_cm(20)), 20)
  expect_equal(stems_ha_to_tpa(tpa_to_stems_ha(18)), 18)
})

test_that("the conversions reproduce the constants the source code asserts", {
  # cardinal_nb_magplot.py lines 36 and 37 assert this exact mapping.
  expect_equal(round(ft2ac_to_m2ha(40), 2), 9.18)
  expect_equal(round(ft2ac_to_m2ha(80), 2), 18.37)
  expect_equal(round(ft2ac_to_m2ha(100), 2), 22.96)
  expect_equal(round(ft2ac_to_m2ha(150), 2), 34.44)
  expect_equal(round(in_to_cm(8), 1), 20.3)
  expect_equal(round(in_to_cm(12), 1), 30.5)
  expect_equal(round(in_to_cm(5), 1), 12.7)
  expect_equal(round(in_to_cm(24), 2), 60.96)
  expect_equal(round(in_to_cm(20), 1), 50.8)
  expect_equal(round(in_to_cm(16), 2), 40.64)
  expect_equal(round(tpa_to_stems_ha(18), 1), 44.5)
  expect_equal(round(tpa_to_stems_ha(36), 1), 89.0)
})

test_that("the New Brunswick literal constants are NOT exact conversions of Maine's", {
  # This is the point of storing thresholds in their native units. New Brunswick
  # rounded 80 ft2 ac-1 to 18.4 where the exact conversion is 18.36544, so the
  # two published cards differ by 0.035 m2 ha-1 on the large-tree score 2. Below
  # the printed resolution, and real.
  expect_false(isTRUE(all.equal(ft2ac_to_m2ha(80), 18.4)))
  expect_equal(round(18.4 - ft2ac_to_m2ha(80), 3), 0.035)
})

test_that("basal area expansion matches both conventions on the same tree", {
  # A 20 in tree is 50.8 cm. One tree per acre is 2.4710538 stems per hectare.
  # They agree to about 28 ppm and not better, because the FIA 0.005454 constant
  # is a rounded pi / (4 * 144). See test-axes-and-instruments.R for the full
  # statement of that limit.
  fia <- ft2ac_to_m2ha(ba_fia(20, 1))
  cli <- ba_metric(50.8, tpa_to_stems_ha(1))
  expect_equal(fia, cli, tolerance = 1e-4)
})
