# Phase 13-14: A third method (TreeMap), and an independent test of "rapid loss"

**Date:** June 9, 2026. Jobs 11409983 (Phase 13), 11410040 (Phase 14).
Scripts `R/phase13_treemap_consensus.r`, `R/phase14_treemap_timeseries.r`.
Outputs `output_phase13/`, `output_phase14/`.

## TreeMap as a third, independent estimate of amount

TreeMap imputes a real FIA plot, with its full six-dimension v5.1 structural class, to
every 30 m forested pixel. Unlike the canopy-LiDAR (Hagan) and canopy-height (GEDI) methods,
it carries field structure directly. Over the unorganized townships (native 30 m, 2022):

| Method | any-LSOG % of AOI |
|---|---:|
| Hagan (airborne-LiDAR canopy) | 21.9 |
| v5.1-GEDI / Potapov (canopy height) | 14.0 |
| TreeMap (FIA structure, imputed) | 7.8 |

A third credible method widens the spread to roughly **2.8x** (7.8% to 21.9%). Note a
technical point that is itself instructive: TreeMap imputation smooths rare classes, so its
LSOG *locations* correlate weakly with the other methods (kappa near 0) and a 100 m mode
aggregation deflates its area further (to 2.9%). TreeMap is therefore best read as an estimate
of **amount and trend**, not pixel location.

## Is LSOG "rapidly disappearing"? Two independent lines say no

Hagan's framing is rapid loss: 1.37%/yr across the study area, 2.19%/yr on commercial
timberland. We tested that with two independent measurements of the LSOG **stock** over the
same unorganized townships.

| Line | 2016 | 2020 | 2022 | implied annual change |
|---|---:|---:|---:|---:|
| TreeMap any-LSOG (UT) | 6.45% | 7.90% | 7.81% | **+3.2%/yr** |
| TreeMap LS+OG (UT) | 0.22% | 0.61% | 0.59% | rising (small base) |

| FIADB v5.1 (ME plots) | 2014-2018 | 2019-2023 | implied annual change |
|---|---:|---:|---:|
| any-LSOG | 12.16% | 13.70% | **+2.4%/yr** |

Both independent lines show LSOG **stable to increasing** over 2016-2023, the opposite sign
to Hagan's premise. (The longer FIA v3 panel series tells the same story: ME any-LSOG rose
from about 7% in 2001 to about 10-14% by 2021.)

## How can both be true? Gross harvest flux vs net stock

Hagan's "loss" is not a remeasured stock. It is the count of mapped LSOG hectares that
experienced more than 30% canopy removal in the Global Forest Watch record since the LiDAR
flight, that is, a **gross harvest flux**. It does not net out ingrowth, the younger stands
that mature into LSOG condition each year. FIA and TreeMap measure the **net stock**, which can
rise even while some stands are harvested, because aging and ingrowth more than replace the
hectares cut. Both can be correct at once:

- Hagan correctly measures that LSOG stands are being **harvested** at roughly 2%/yr.
- FIA and TreeMap correctly measure that the total LSOG **stock** is stable to increasing,
  because more forest is aging into LSOG than is being removed.

This is consistent with Birdsey et al. (2025), who find northeastern old-growth gains from
aging nearly offset (here, more than offset) by losses in harvested areas. The rhetorical
"rapidly disappearing" conflates a gross flux with the net trend; the conservation-relevant
quantity, how much LSOG exists and whether the total is growing or shrinking, is not declining.

## Caveats (so we are careful too)

- TreeMap year-to-year differences blend real forest change with FIA-panel vintage and
  imputation-model updates; the 2016 to 2020 jump partly reflects the panel and model change,
  and 2020 to 2022 is essentially flat. The robust signal is **direction (not declining)**,
  shared with the design-based FIA plots, not the precise rate.
- FIADB plot panels are the most defensible line: directly remeasured plots, design-based.
- The contrast with Hagan is about **what is measured** (flux vs stock), not about whether his
  harvest detection is wrong. Both pieces matter for policy, but they answer different questions.

## Ownership

Across all owner classes in the AOI, 99 to 100% of the LSOG flagged by any method is
"contested" (flagged by one or two methods, not all), so the mapping uncertainty is **pervasive
across ownership**, not concentrated in one owner type. (Owner-class labels in the source
raster are coded, not named, so we report the pattern, not per-owner totals.)

## Bottom line

Adding a third method widens the amount disagreement to about 2.8x, and an independent
temporal test contradicts the "rapidly disappearing" premise: the LSOG stock in Maine's
unorganized townships is stable to increasing on both TreeMap and FIA. Hagan's harvest-flux
result and the stock trend are both real and not in conflict once the distinction is made. For
LD 1529, this argues for framing LSOG conservation around protecting a stock that is not in
free-fall, with explicit uncertainty, rather than around an urgency narrative that a single
flux statistic implies.

## Files

output_phase13/: T1_area_4method, T2_pairwise_kappa_4method, T3_consensus_levels,
T4_ownership_consensus, M4_treemap_class_100m.tif, CONSENSUS_nmethods_100m.tif.
output_phase14/: T1_treemap_lsog_timeseries, T2_fiadb_v51_trend_ME, T3_change_synthesis,
fig/trend.png.
