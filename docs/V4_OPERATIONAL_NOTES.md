# v4 operational classifier (relaxed dimensional thresholds)

Date: 2026-04-25
Replaces: fia_lsog_analysis_v3.r as the working baseline.

## What changed from v3

Three dimensional thresholds inside the score were relaxed by one notch
based on the Phase 4 v3 ORNL recalibration analysis:

| Dimension | v3 default | v4 |
|---|---|---|
| score_canopy 1pt   | ba_total >= 100 | ba_total >= **80**  |
| score_canopy 2pt   | ba_total >= 150 | ba_total >= **120** |
| score_structure 1pt | sd_dia  >= 5    | sd_dia  >= **3**    |
| score_structure 2pt | sd_dia  >= 8    | sd_dia  >= **6**    |
| score_maturity fallback | max_dia >= 24 | max_dia >= **20**   |

The score thresholds (THRESH_TRANS=4, THRESH_LS=6, THRESH_OG=8) and the
data-driven snag thresholds are unchanged.

## v4 vs v3 vs Hagan (Maine, 2014-2018 panel)

| Metric | v3 default | v4 | Hagan/Thompson (UT only) |
|---|---:|---:|---:|
| Transitioning LS percent | 7.9 | 14.2 | 17.2 |
| LS percent | 1.0 | 3.5 | n/a |
| OG percent | 0.13 | 0.22 | 1.0 |
| LS + OG percent | 1.14 | 3.75 | 4.2 |
| All LSOG percent | 9.0 | 18.0 | 21.4 |

v4 is in striking distance of the Hagan/Thompson LiDAR estimates from
the unorganized territories. v4 statewide All-LSOG (18.0%) lands within
3.4 points of Hagan's UT-only estimate (21.4%) — an enormous
improvement from v3's 9.0%. LS+OG also closes from 1.14% (v3) to
3.75% (v4), within 0.5 points of Hagan's 4.2%.

The OG-specific class still trails Hagan (0.22 vs 1.0). Two reasons:
the LiDAR detects vertical canopy structure that FIA-plot variables
cannot capture, and Hagan's OG class is concentrated in the unorganized
territories where the highest-quality stands sit.

## Files

`R/fia_lsog_analysis_v4.r` is the operational successor to v3. It
otherwise inherits the v3 structure (multi-state STATE_CODES, bootstrap
CIs, regional comparison figures, Hagan/Thompson comparison block).
The v3 script remains in the repo for reference and reproducibility of
older results.

`output_v4/`:
- fia_lsog_all_states_v4.csv: 5 panels x state with bootstrap CIs
- lsog_acres_facet_ME_v4.png
- lsog_pct_combined_ME_v4.png

