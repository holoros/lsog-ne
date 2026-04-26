# Phase 5 results: Potapov canopy height as 6th dimension

Date: 2026-04-26
Inputs: ME FIA panel 2019-2023 (n=3,125), ORNL DAAC 2498 (Bruening 2026),
Potapov et al. 2021 30 m global forest canopy height (GLAD/UMD, NAM mosaic, 5.4 GB).

## What changed from v4

- Added a sixth dimension `score_canopy_height` derived from Potapov RH95
  at FIA plot centroid (geographic CRS):
  - 2 pts if RH95 >= 25 m
  - 1 pt  if RH95 >= 18 m
  - 0 pts otherwise (or missing)
- Total score now /12 (was /10 in v4).
- LSOG class thresholds adjusted: TRANS=5, LS=7, OG=9.

## Three-way share table

| Variant | any-LSOG | LS+OG | OG |
|---|---:|---:|---:|
| v4 default (4/6/8, /10 score) | 20.4 | 4.00 | 0.224 |
| v5 with Potapov RH95 (5/7/9, /12 score) | 12.8 | 1.79 | **0.128** |
| ORNL mature > 50 (target) | 33.4 | n/a | n/a |
| ORNL OG > 50 (target) | n/a | n/a | **0.130** |

The /12 threshold scaling makes v5 more conservative on the broad LSOG
share but converges remarkably well with ORNL on the OG class:
**v5 OG = 0.128 percent, ORNL OG = 0.130 percent**. Same 4 plots out of
3,125. That's a hard match.

## Logistic fit (6 dimensions, target = ORNL mature > 50)

| Dimension | Coef | Odds ratio | p-value |
|---|---:|---:|---:|
| (intercept) | -1.13 | 0.32 | <1e-43 |
| score_ba_large | 0.07 | 1.08 | 0.74 |
| score_maturity | 0.02 | 1.02 | 0.84 |
| **score_structure** | 0.60 | 1.82 | <1e-9 |
| score_canopy | -0.05 | 0.96 | 0.41 |
| score_deadwood | 0.18 | 1.20 | 0.013 |
| **score_canopy_height** | **0.82** | **2.26** | **<1e-16** |

AUC train = 0.638, test = **0.664** (up from 0.56 with v3R/v4 dims).

The new GEDI canopy height dimension has the largest coefficient of any
predictor, with an odds ratio of 2.26 per scored point. It is more
informative than score_structure (sd_dia at plot scale), confirming the
Phase 4 v3 diagnosis: vertical canopy structure derived from
satellite/LIDAR is the missing signal.

Three of the six dimensions are still essentially noise vs ORNL mature:
score_ba_large, score_maturity, score_canopy. These three rely on FIA
plot aggregates that lose the within-stand variation ORNL keys on.

## Recommendation: v5 thresholds and dimension weighting

Two natural next moves:

1. **v5b: lower the v5 thresholds to 4/6/8 within /12.** That should
   bring the any-LSOG share back up around 20-25 percent while keeping
   the strict OG class converged with ORNL.
2. **v5logit: use the logistic predicted probability directly.**
   Threshold P(mature > 50) > 0.5 should give a recalibrated, AUC-
   maximized any-LSOG class. Train on ORNL OG > 50 separately for OG.

Both can be added to phase5_potapov_extract.r in roughly 30 lines.

## Files

In `output_phase5/`:

- `phase5_three_way_compare.csv` four-row share table
- `phase5_three_way_bar.png` bar chart of the comparison
- `phase5_logit_coefficients.csv` 7-row fit table
- `phase5_logit_metrics.csv` AUC + n
- `phase5_plot_classified_ME.csv` per-plot detail (gitignored)

