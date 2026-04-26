# Phase 4 v2: panel-aligned + multi-bin + threshold grid search

Run date: 2026-04-25
Inputs: ME FIA panels 2019-2023 (n=3,125) and 2020-2024 (n=3,117)
ORNL raster: Bruening et al. 2026 (ds_id 2498), c.2022

## Panel-aligned headline (2019-2023)

| Metric | v3 default (4/6/8) | ORNL 2498 |
|---|---:|---:|
| any-LSOG / MOG > 50    | 10.05 |  33.54 |
| LS + OG / OG > 50      |  1.15 |   0.13 |
| OG / OG > 50           |  0.06 |   0.13 |

The 2020-2024 panel is essentially identical (10.5%, 1.2%, 0.10%). So the
8.25% number from v1 (all-panels, 19,149 plots) is being pulled down by
older panels containing more young stands; the recent panel is closer to
~10%.

## What the multi-bin confusion shows (2019-2023, n=3,125)

ORNL OG class corroboration:
- v3 OG: 2 plots; ORNL OG-prob is <=5% on both
- v3 LS: 34 plots; ORNL OG-prob ~26-50% on 1, the rest <25%
- v3 TLS: 278 plots; ORNL OG-prob >25% on 10
- v3 Not LSOG: 2,811 plots; ORNL OG-prob >50% on 3

The OG-specific channel is essentially noise at panel scale: too few plots
on either side, and the pixels are not lining up.

ORNL mature class — the real signal:
- v3 LS: 34 plots; ORNL mature-prob >50% on 19 (56%), >75% on 6
- v3 TLS: 278 plots; ORNL mature-prob >50% on 122 (44%)
- v3 Not LSOG: 2,811 plots; ORNL mature-prob >50% on 886 (32%)
- v3 Not LSOG: 2,811 plots; ORNL mature-prob 26-50% on 1,267 (45%)

77% of v3 Not-LSOG plots have ORNL mature-prob >25%. The proxy is
pinning the maturity dimension floor much higher than ORNL's QDA.

## Threshold grid search (2019-2023)

ORNL targets: any-MOG = 33.54%, OG = 0.13%

Tried THRESH_TRANS in {3,4,5}, THRESH_LS in {5,6,7}, THRESH_OG in {7,8,9}
with the trans <= ls <= og constraint.

Best fit (smallest absolute calibration loss):

| t_trans | t_ls | t_og | pct any-LSOG | pct OG | abs loss |
|---:|---:|---:|---:|---:|---:|
| **3** | 5 | 8 | 21.18 | 0.064 | 12.4 |
| 3 | 6 | 8 | 21.18 | 0.064 | 12.4 |
| 3 | 7 | 8 | 21.18 | 0.064 | 12.4 |
| 4 | 5 | 8 | 10.05 | 0.064 | 23.6 |
| **default 4/6/8** | 6 | 8 | 10.05 | 0.064 | 23.6 |

The lowered THRESH_TRANS from 4 to 3 lifts any-LSOG share from 10% to 21%,
but is still ~12 percentage points below ORNL. The score-threshold knob
alone is not enough.

## Diagnosis

The dimensional thresholds inside the score, not the score thresholds
themselves, are the actual lever. Specifically:

- score_canopy fires at BA >=100 ft^2/ac for 1 point, 150 for 2. ORNL's
  mature class includes plots with BA in the 80-120 range. Lowering
  score_canopy bins to >=80 ft^2/ac for 1 point would shift many more
  plots into TLS.
- score_structure fires at sd_dia >=5 in for 1 point. Many regenerating
  hardwood stands have sd_dia in the 3-5 range. Lowering to >=3 for 1
  point would also shift a chunk.
- score_maturity uses STDAGE >=80 for 1 point or max_dia >=24 in for 1
  point as a fallback. STDAGE is NA on a large fraction of FIA plots in
  Maine (50%+); the max_dia >=24 fallback is strict for a hardwood-spruce
  matrix where mature stands often peak around 18-22 in DBH.

## Recommended Phase 4 v3 changes

1. Lower the dimensional thresholds for the maturity, canopy, and
   structure dimensions by one notch each, keeping the score thresholds
   at 4/6/8.
2. Re-fit the score thresholds against ORNL OG-prob > 50 as a binary
   target using logistic regression on the 5 dimension scores. This
   gives a recalibrated proxy that can be reported alongside the v3
   defaults.
3. Repeat for NH, NY, VT once those FIA tables are in place to test
   whether the recalibration generalizes across the Northeast.

## Files

In `output_phase4/v2/`:

- `phase4_v2_state_compare.csv` per-state per-panel summary
- `phase4_v2_confusion.csv` confusion table for all 3 ORNL bins
- `phase4_v2_threshold_grid.csv` 27-row grid search
- `phase4_v2_confusion_facet.png` heatmap, log10 color, three facets
- `phase4_v2_plot_classified_*.csv` per-plot detail (gitignored)
