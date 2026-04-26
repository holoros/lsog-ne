# v5 operational classifier (with Potapov canopy height)

Date: 2026-04-26
Successor to: v4 (which remains valid for historical time-series analysis
back to 1999, since Potapov is a single-year 2019 product).

## Score system (/12)

1. **score_ba_large**: 0/1/2 (BA in trees DBH >= 20 in: 0 / >=40 / >=80)
2. **score_maturity**: 0/1/2 (STDAGE 80/120 or max_dia >=20 fallback)
3. **score_structure**: 0/1/2 (sd_dia >=3 / >=6)
4. **score_canopy**: 0/1/2 (BA total >=80 / >=120)
5. **score_deadwood**: 0/1/2 (data-driven snag TPA percentiles)
6. **score_canopy_height**: 0/1/2 (Potapov RH95 >=18 / >=25 m)

Class thresholds: TLS >=4, LS >=6, OG >=8.

## Maine 2014-2018 results vs Hagan/Thompson (UT only)

| Metric | **v5 statewide** | Hagan UT only |
|---|---:|---:|
| Transitioning LS | 18.4% | 17.2% |
| LS | 5.08% | n/a |
| OG | 0.41% | 1.0% |
| LS + OG | 5.49% | 4.2% |
| All LSOG | 23.9% | 21.4% |

v5 statewide TLS share (18.4) lands within 1.2 points of Hagan's UT-only
LiDAR estimate (17.2). v5 LS+OG (5.49) overshoots Hagan UT (4.2) by 1.3
points. The OG-specific gap (0.41 vs 1.0) is narrower than v4 (0.22 vs
1.0) but still present; resolving it likely waits on the Hagan raster.

## v5 vs v4 trajectory

| | v3 default | v4 | v5 |
|---|---:|---:|---:|
| Trans LS percent | 7.9 | 14.2 | 18.4 |
| LS percent | 1.0 | 3.5 | 5.08 |
| OG percent | 0.13 | 0.22 | 0.41 |
| All LSOG percent | 9.0 | 18.0 | 23.9 |

v5 closes most of the remaining gap to Hagan's UT estimates by adding the
Potapov canopy height dimension. The v3 -> v4 -> v5 trajectory is a
recalibration of the FIA proxy against multiple independent reference
datasets (ORNL DAAC 2498 Bayesian QDA, Potapov 2021 GEDI fusion).

## Scope

v5 runs the recent FIA panels overlapping Potapov's 2019 reference year:
- 2014-2018
- 2019-2023

For longer time series (1999-2023) the v4 5-dim system is the right tool;
v5 is the right tool for current-state assessment and for cross-validation
against the LiDAR and satellite-derived MOG products.

## Files

- `R/fia_lsog_analysis_v5.r`: production classifier
- `output_v5/fia_lsog_v5_all_states.csv`: bootstrap CIs for all panels
- `output_v5/lsog_pct_combined_ME_v5.png`: percent time-series figure
- `R/phase6_hagan_extract.r`: scaffolded for when the Hagan raster lands
- `scripts/stage_hagan_raster.sh`: helper to verify staging

## Phase 6: queued, unblocked once the Hagan raster lands

`R/phase6_hagan_extract.r` is a complete drop-in pipeline:
1. Source v5 to score plots
2. Extract Hagan class at FIA plot centroids
3. Build 4x4 confusion table
4. Compute binary kappa (any-LSOG), weighted kappa (ordinal 4-class),
   and OG-only kappa
5. Save heatmap PNG and per-plot CSV

Once you have the GeoTIFF, scp it to
`~/LSOG/data/rasters/hagan_lsog/hagan_lsog_100m.tif` on Cardinal and run:
```
bash scripts/stage_hagan_raster.sh
Rscript --vanilla R/phase6_hagan_extract.r
```
