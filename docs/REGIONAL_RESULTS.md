# Regional results: Northeast US LSOG share by state and panel

Dates: 2026-04-26
v4 (no GEDI dim, /10 score, 4/6/8 thresholds): 5 panels 1999-2023
v5 (with Potapov RH95, /12 score, 5/7/9 thresholds): 2 panels 2014-2018, 2019-2023

## v5 multi-state share table (with Potapov canopy height)

| State | Panel | n | Trans LS | LS | OG | All LSOG |
|---|---|---:|---:|---:|---:|---:|
| ME | 2014-2018 | 3,150 | 18.4 | 5.1 | 0.41 | 23.9 |
| ME | 2019-2023 | 3,125 | 19.9 | 5.5 | 0.38 | 25.8 |
| **NH** | 2014-2018 | 748 | **42.8** | **8.7** | 0.40 | **51.9** |
| **NH** | 2019-2023 | 757 | **42.5** | **12.0** | 1.06 | **55.6** |
| NY | 2014-2018 | 2,228 | 29.1 | 12.5 | 1.71 | 43.3 |
| NY | 2019-2023 | 2,107 | 31.1 | 12.9 | 2.52 | 46.5 |
| **VT** | 2014-2018 | 660 | **40.2** | **15.2** | 0.91 | **56.2** |
| **VT** | 2019-2023 | 657 | **42.9** | 13.9 | 1.07 | **57.8** |

**Striking regional pattern**: ME has the lowest LSOG share in the
Northeast (~26 percent), VT and NH are the highest (56-58 percent), NY
sits in between (~46 percent). This is consistent with Maine's heavy
commercial-timber harvest history relative to NH/VT/NY where forests
have aged longer with less intensive cutting.

## v4 long time series (1999-2023, no GEDI dim)

| State | All LSOG percent (1999-2003) | (2019-2023) | Net change |
|---|---:|---:|---:|
| ME | 16.8 | 20.4 | +3.6 |
| **NH** | 22.9 | **44.3** | **+21.4** |
| **NY** | 16.5 | 33.2 | **+16.7** |
| **VT** | 25.4 | 39.9 | **+14.5** |

NH essentially doubled its LSOG share over 20 years; NY also doubled.
VT and ME show smaller (but consistent) increases. The all-state pattern
is "forests aging" — consistent with the Birdsey et al. 2025 finding
that Northeast LSOG gains are partially offset by losses in active
harvest areas.

## Potapov RH95 threshold sensitivity (Phase 5c)

| Configuration | AUC vs ORNL mature > 50 |
|---|---:|
| Default v5 (18m / 25m breakpoints) | 0.644 |
| Optimal grid search (10m / 20m) | 0.682 |
| Continuous RH95 in logit | **0.689** |

The default 18/25m breakpoints in score_canopy_height are conservative.
A 10/20m breakpoint set produces 4 percentage points more AUC against
ORNL mature; using continuous RH95 directly in a logistic regression
gives another 0.7 percentage points. The continuous-RH95 fit is now
the highest-AUC variant we have tested.

Recommended next move: drop the v5 score_canopy_height thresholds from
18/25m to 10/20m. This will lift any-LSOG share toward ORNL's 33 percent
and improve plot-level kappa.

## Unified plot-level analytical table

`output_unified/lsog_ne_plot_table.csv`:
- 13,432 rows = 4 states x 2 panels x plots
- 32 columns: state, eval_period, CN, INVYR, LAT/LON, STDAGE, all 6 v5
  dimension scores, v4_total, v5_total, v4_class, v5_class, v5b_class,
  all 5 ORNL probability bands, Potapov RH95.
- Suitable as the master analytical artifact for downstream users
  (Thompson team, DACF, MFS).

