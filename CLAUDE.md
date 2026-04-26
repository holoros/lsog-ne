# lsog-ne project memory

Working memory for the Northeast LSOG project. Read at the start of any
new Cowork or Claude Code session that picks up the work.

## Project at a glance

- Repo: github.com/holoros/lsog-ne
- Cardinal: crsfaaron at /users/PUOM0008/crsfaaron/LSOG/
- Branch: master
- Operational classifier: v5.1 (R/fia_lsog_analysis_v5.r)

## v5.1 classifier (six dimensions, /12 score, 4/6/8 class thresholds)

| # | Dimension | 1pt | 2pt |
|---|---|---|---|
| 1 | score_ba_large | BA(DBH>=20") >= 40 | >= 80 ft^2/ac |
| 2 | score_maturity | STDAGE >= 80 yr | >= 120 (max_dia>=24in fallback) |
| 3 | score_structure | sd_dia >= 5 in | >= 8 |
| 4 | score_canopy | BA total >= 100 | >= 150 ft^2/ac |
| 5 | score_deadwood | snag TPA >= 75th pct | >= 90th |
| 6 | score_canopy_height | Potapov RH95 >= 18 m | >= 25 m |

Class thresholds: TLS >= 4, LS >= 6, OG >= 8 (out of 12).

## Headline regional results (FIA panel 2019-2023)

| State | n | All LSOG % (95% CI) | LS+OG % | OG % | Acres LSOG |
|---|---:|---:|---:|---:|---:|
| ME | 3,125 | 14.1 (12.9-15.3) | 2.06 | 0.19 | 2.36 M |
| NH | 757   | 31.2 (28.0-34.3) | 5.28 | 0.26 | 1.44 M |
| NY | 2,107 | 27.2 (25.2-29.0) | 7.40 | 1.28 | 4.81 M |
| VT | 657   | 28.8 (25.4-32.3) | 6.70 | 0.15 | 1.26 M |

NE total: ~9.87 M ac all-LSOG; ~2.19 M LS+OG; ~286 K OG.

## Don't re-iterate the threshold history

- v3 default 5/10: too low (ME 9% all-LSOG)
- v4 relaxed dims: better but still under
- v5/v5b 4/6/8 in /12 with relaxed dims: over-counts NH/VT (66%+)
- 10/20m RH95: ME calibrates to ORNL but NH/VT implausible
- v5.1 (ORIGINAL v3 dims + 18/25m + 4/6/8 in /12): SELECTED

## Module load on Cardinal (corrected from SKILL.md)

```
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0    # MUST come first
module load gdal/3.7.3    # geos/proj bundled
module load R/4.4.0
```

For ZSTD rasters use conda gdalz env at ~/.conda/envs/gdalz.

## Phase 6 (BLOCKED on raster)

Drop GeoTIFF at data/rasters/hagan_lsog/hagan_lsog_100m.tif then:
```
bash scripts/stage_hagan_raster.sh
Rscript --vanilla R/phase6_hagan_extract.r
```

Acquire from John Hagan (info@ourclimatecommon.org), LD 1529 / Maine DACF
working group, or Harvard Forest Thompson team.

## Common gotchas

1. ssh heredocs need `source /etc/profile.d/lmod.sh` before `module load`
2. Cowork-to-Cardinal transfer is slow (~50 KB/s); do downloads on Cardinal
3. Cardinal GDAL lacks ZSTD codec; use gdalz conda env to read 2498 ZSTD
4. Don't re-relax v5.1 thresholds (v5.1 IS the calibrated default)
5. OG-class precision is low; need Hagan to validate the 14 OG plots
6. Public FIA lat/lon fuzzed up to ~1 km

## Key files

- R/fia_lsog_analysis_v5.r: operational classifier
- R/phase6_hagan_extract.r: scaffolded, blocked
- R/phase5g_design_based.r: FIA stratified estimation
- R/phase5h_carbon_fortyp_diag.r: carbon, forest type, OG diagnostics
- R/phase5i_final_analyses.r: refinements A-J
- output_unified/lsog_ne_plot_table.csv: master per-plot table
- output_v5/fia_lsog_v5_all_states.csv: bootstrap CI summary
- output_design_based/design_based_area.csv: FIA-design CI summary
- output_design_based/ownership_breakdown.csv
- output_extras/carbon_by_class.csv
- output_final/A-J*.csv: refinements
- docs/NORTHEAST_LSOG_REPORT.md: integrated delivery doc
- output_figures/fig{1-12}*.png + map{1-2}*.png

## References

- Hagan et al. 2024 (LiDAR Maine LSOG): ourclimatecommon.org/lsog-project
- Thompson et al. 2026 (Pathways for Protecting Maine's Old-Growth)
- Bruening et al. 2026 (ORNL DAAC 2498): NASA Earthdata auth required
- Potapov et al. 2021 (GLAD/UMD): glad.umd.edu/dataset/gedi
- Lang et al. 2023 (ETH Zurich): 10m global canopy height

## Session-start protocol

1. Read this file
2. ssh-test cardinal: `ssh -F ~/.ssh/config cardinal "hostname"`
3. Check repo: `ssh cardinal 'cd ~/LSOG && git status && git log --oneline -3'`
4. Continuing analysis: `Rscript --vanilla R/<phase>.r`
5. Commit + push origin master

Update this file when Phase 6 completes, baseline changes, or repo
structure changes meaningfully.
