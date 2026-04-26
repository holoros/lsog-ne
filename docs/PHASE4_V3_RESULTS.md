# Phase 4 v3: relaxed dimensional thresholds + logistic recalibration

Run date: 2026-04-25
Inputs: ME FIA panel 2019-2023, n=3,125 plots
ORNL raster: Bruening et al. 2026 (ds_id 2498), c.2022

## Three-way comparison (any-LSOG / mature share)

| Variant | any-LSOG percent | OG percent |
|---|---:|---:|
| v3 default (4/6/8, default dim thresholds) | 10.0 | 0.06 |
| **v3R relaxed dims** (4/6/8, BA/sd/max relaxed by one notch) | **20.4** | **0.22** |
| v3 logit (P_mature>50 \| 5 dim scores) at 0.5 | 4.5 | n/a |
| ORNL mature-prob > 50 (target) | 33.4 | n/a |
| ORNL MOG-prob > 50 (target) | 33.5 | n/a |
| ORNL OG-prob > 50 (target) | n/a | 0.13 |

**v3R doubles any-LSOG** to 20.4% by relaxing three dimensional thresholds:

- score_canopy: BA >=100 -> >=80 for 1pt;  >=150 -> >=120 for 2pt
- score_structure: sd_dia >=5 -> >=3 for 1pt;  >=8 -> >=6 for 2pt
- score_maturity: max_dia fallback 24 -> 20 for 1pt

That gets us halfway to the ORNL mature target. v3R also tilts OG slightly
above ORNL (0.22 vs 0.13) — an interesting reversal of the v3 default
under-call.

## The killer finding from the logistic fit

Predict ORNL mature_prob > 50 (binary) from the 5 default-threshold
dimension scores. Fit on 80% (n=2,459), test on 20% (n=615):

| Dimension | Coef | Odds ratio | p-value |
|---|---:|---:|---:|
| (intercept) | -0.81 | 0.45 | <0.001 |
| score_ba_large | 0.035 | 1.04 | 0.88 |
| score_maturity | 0.15 | 1.16 | 0.076 |
| **score_structure** | **1.07** | **2.93** | **<1e-6** |
| score_canopy | -0.057 | 0.95 | 0.33 |
| score_deadwood | 0.23 | 1.26 | 0.001 |

AUC test = 0.56. Balanced accuracy at 0.5 = 0.52.

**Only the structure (TPA-weighted DBH dispersion) and deadwood (snag TPA)
dimensions carry real signal for matching ORNL "mature".** The other three
dimensions (large-tree BA, maturity, canopy) are essentially noise.

The model barely beats chance (AUC 0.56). That tells us the v3 dimension
set, even with their default thresholds, does not encode what ORNL's
QDA is keying on. ORNL is reading LiDAR-detected canopy structure —
vertical heterogeneity (loosely captured by sd_dia, well predicted) and
gap pattern (loosely captured by snag_tpa, also predicted). FIA-plot
aggregates of large-tree BA, total BA, and stand age lose the within-
stand variation that ORNL is using.

## Implications

1. Lowering dimensional thresholds (the v3R approach) is a workable
   compromise. It doubles LSOG share to 20% with one principled change.
2. The proxy needs new dimensions to close the remaining gap to 33%.
   Candidates: GEDI RH98 percentile and the GEDI VDR ratio at the plot
   centroid (the same predictors ORNL uses); within-subplot DBH coefficient
   of variation (a finer-grained structural complexity signal).
3. Three of the five existing dimensions (BA-large, canopy total BA,
   stand age) are not contributing to ORNL agreement. They may still be
   contributing to Hagan et al.'s LiDAR LSOG agreement; that test waits
   on getting the Hagan raster.

## Files

In `output_phase4/v3/`:

- `phase4_v3_three_way_compare.csv`   side-by-side share table
- `phase4_v3_three_way_bar.png`       bar chart of the three-way comparison
- `phase4_v3_logit_coefficients.csv`  logistic regression fit
- `phase4_v3_logit_metrics.csv`       AUC + balanced accuracy
- `phase4_v3_score_shift.csv`         d_total -> r_total cell counts
- `phase4_v3_plot_classified_*.csv`   per-plot detail (gitignored)
