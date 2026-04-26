# Late-Successional / Old-Growth Forest by Northeast State

FIA-based proxy classification (v5: 5 FIA dimensions + Potapov 2021 GEDI canopy height; /12 score; class thresholds 5/7/9). Acres derived from FIA EXPNS or state forest-area fallback. 95% bootstrap confidence intervals from 2,000 resamples.

## State x panel summary

| State | Panel | n | Trans LS % | Trans LS ac | LS % | LS ac | OG % | OG ac | All LSOG % | All LSOG ac |
|---|---|---:|---|---|---|---|---|---|---|---|
| ME | 2014-2018 | 3150 | 24.3% (22.7-25.7) | 3.98 M | 8.4% (7.5-9.4) | 1.40 M | 1.3% (1.0-1.7) | 226 K | 34.0% (32.3-35.6) | 5.61 M (5.33 M-5.88 M) |
| ME | 2019-2023 | 3125 | 24.9% (23.3-26.3) | 4.03 M | 9.4% (8.4-10.4) | 1.58 M | 1.2% (0.8-1.5) | 189 K | 35.4% (33.7-37.0) | 5.80 M (5.51 M-6.07 M) |
| NH | 2014-2018 | 748 | 42.2% (38.8-45.6) | 1.92 M | 20.7% (17.9-23.5) | 957 K | 1.9% (0.9-2.8) | 80 K | 64.8% (61.5-68.0) | 2.96 M (2.80 M-3.11 M) |
| NH | 2019-2023 | 757 | 39.5% (36.1-43.1) | 1.77 M | 24.3% (21.3-27.2) | 1.13 M | 2.6% (1.6-3.8) | 117 K | 66.4% (63.0-69.6) | 3.02 M (2.86 M-3.17 M) |
| NY | 2014-2018 | 2228 | 30.2% (28.3-32.1) | 5.12 M | 18.7% (17.2-20.4) | 3.36 M | 4.7% (3.9-5.6) | 860 K | 53.6% (51.5-55.7) | 9.35 M (8.97 M-9.71 M) |
| NY | 2019-2023 | 2107 | 29.6% (27.7-31.5) | 4.88 M | 20.1% (18.4-21.8) | 3.56 M | 6.1% (5.1-7.1) | 1.12 M | 55.8% (53.6-57.9) | 9.56 M (9.16 M-9.91 M) |
| VT | 2014-2018 | 660 | 38.3% (34.5-42.1) | 1.65 M | 27.4% (24.2-30.8) | 1.20 M | 3.5% (2.1-5.0) | 155 K | 69.2% (65.8-72.9) | 3.00 M (2.85 M-3.17 M) |
| VT | 2019-2023 | 657 | 38.8% (35.0-42.6) | 1.67 M | 23.6% (20.4-26.9) | 1.04 M | 5.8% (4.1-7.6) | 258 K | 68.2% (64.5-71.8) | 2.97 M (2.81 M-3.13 M) |

## Notes

- v5 score system uses six dimensions: large-tree basal area, stand maturity, TPA-weighted DBH dispersion, total basal area (canopy stocking), snag TPA, and Potapov GEDI/Landsat canopy height (RH95). Class thresholds: Transitioning LS >= 5, LS >= 7, OG >= 9 (out of 12).
- Reference points: Hagan et al. 2024 LiDAR estimate for Maine unorganized territories (9.5M ac): Trans LS 17.2%, LS+OG 4.2%, all LSOG 21.4%. Bruening et al. 2026 ORNL DAAC 2498 estimates ~33% mature-prob > 50 statewide for ME.
- Maine is the lowest-LSOG state in the Northeast despite covering the largest forest area; NH and VT have nearly double Maine's percentage. NY's Adirondack region drives its high OG share (2.5%).
- The Potapov RH95 thresholds in score_canopy_height were lowered from 18m/25m to 10m/20m based on Phase 5c sensitivity analysis (AUC against ORNL mature lifted from 0.644 to 0.682).
