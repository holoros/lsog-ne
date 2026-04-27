# lsog-ne project memory

Working memory for the Northeast LSOG project. Read at the start of any
new Cowork or Claude Code session that picks up the work.

## Project at a glance

- Repo: github.com/holoros/lsog-ne
- Cardinal: crsfaaron at /users/PUOM0008/crsfaaron/LSOG/
- Branch: master (28 commits)
- Operational classifier: v5.1 (R/fia_lsog_analysis_v5.r)
- Latest commit: 11bb757 (Phase 8 NE-extension scaffold + debug)

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

## Headline regional results (FIA panel 2019-2023, plot-based v5.1)

| State | n | All LSOG % (95% CI) | LS+OG % | OG % | Acres LSOG |
|---|---:|---:|---:|---:|---:|
| ME | 3,125 | 14.1 (12.9-15.3) | 2.06 | 0.19 | 2.36 M |
| NH | 757   | 31.2 (28.0-34.3) | 5.28 | 0.26 | 1.44 M |
| NY | 2,107 | 27.2 (25.2-29.0) | 7.40 | 1.28 | 4.81 M |
| VT | 657   | 28.8 (25.4-32.3) | 6.70 | 0.15 | 1.26 M |

NE total: ~9.87 M ac all-LSOG; ~2.19 M LS+OG; ~286 K OG.

## Reference benchmarks

| Source | Coverage | ME LSOG/OG estimate |
|---|---|---|
| **v5.1 plot-based** | All ME private+public, FIA panel | 14.1% any LSOG, 0.19% OG, 33 K ac OG |
| **Phase 8 TreeMap** | Wall-to-wall ME 2020/2022 | ~11% any-LSOG (excl Unknown 50%) |
| Hagan et al. 2024 LiDAR | Maine UT only (9.5 M ac) | 21.4% LSOG, 1.0% OG |
| Bruening 2026 (ORNL 2498) | Statewide MOG-prob > 50 | ~33% mature; 0.13% OG-prob > 50 |
| Pelz 2023 (FEM 549:121437) | NFS lands only | 304 K ac OG total NFS-East |

## Don't re-iterate the threshold history

- v3 default (5/10): too conservative (ME 9% all-LSOG)
- v4 (relaxed dims): better but still under
- v5 / v5b (4/6/8 in /12 with relaxed dims + 10/20m): over-counts NH/VT/NY 65%+
- v5.1 (ORIGINAL v3 dims + 18/25m + 4/6/8 in /12): SELECTED. Calibrated.

## Module load on Cardinal (corrected from SKILL.md)

```bash
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0    # MUST come first
module load gdal/3.7.3    # geos/proj bundled
module load R/4.4.0
```

For ZSTD rasters use conda gdalz env at ~/.conda/envs/gdalz.

## Outstanding work paths

### Phase 6 BLOCKED: Hagan validation
Drop GeoTIFF at data/rasters/hagan_lsog/hagan_lsog_100m.tif then:
```
bash scripts/stage_hagan_raster.sh
Rscript --vanilla R/phase6_hagan_extract.r
```
Acquire from John Hagan (info@ourclimatecommon.org), LD 1529 / Maine DACF
working group, or Harvard Forest Thompson team.

### Phase 7 NOT BLOCKED: Pelz 2023 cross-validation
Independent validation pathway. Plan in `docs/PELZ_2023_REVIEW.md`.
Filter NE plots to USFS NFS lands (OWNCD == 11), apply Pelz Eastern
Region (R9) OG criteria (stand age 100-160 yr, density 5-20/ac of
DBH >= 12-20 in by Tyrrell veg type), compare to v5.1 OG/LS calls.
NE NFS = WMNF (NH) + GMNF (VT) + small ME fragments ~1.0M ac.

### Phase 8 IN PROGRESS: TreeMap wall-to-wall
**Done**:
- v1: ME 2020 + 2022 with 50% Unknown coverage gap
- v2: ME 2020 + 2022 wall-to-wall, Unknown gap closed to 0.33% via
  all-panels v4 lookup. ME any-LSOG = 8.04-8.15 percent (vs v5.1
  plot-based 14.1 percent; difference is the missing Potapov dim).
- NE-wide scaffold (R/phase8_v2_NE_wall_to_wall.r) committed.

**Pending - resolves next session**: NE extension to NH/VT/NY hit a
TM_ID-encoding mismatch when cropping CONUS raster at runtime. The
pre-cropped ME_TM_20.tif worked; runtime-cropped CONUS subset returns
all NA on TM_ID merge. Two paths forward documented in
docs/PHASE8_TREEMAP_NOTES.md:
  1. Inspect terra::cats() of CONUS raster for value->TM_ID mapping
  2. Pre-crop CONUS to NH/VT/NY bounding boxes via gdal_translate

**v2 plan in docs/PHASE8_TREEMAP_NOTES.md**:
- Close Unknown gap (50% of ME pixels imputed from older FIA panels +
  some non-NE state plots)
- Two options: extend unified to 1999-2013 panels (hybrid v5.1/v4
  fallback for older plots), OR full-CONUS scoring via ENTIRE FIA files
- Then extend to NH/VT/NY and TreeMap 2016
- TreeMap data at /users/PUOM0008/crsfaaron/TREEMAP/{TM2016,TM2020,TM2022}
  + ME-clipped rasters ME_TM_20.tif, ME_TM_22.tif

### Phase 5+ refinement candidates (not blocked, not yet done)

From Pelz 2023 review (`docs/PELZ_2023_REVIEW.md`):
- Add `score_large_tree_count` (count per acre, not BA)
- Forest-type-specific thresholds (Tyrrell 1998 by FORTYPCD)
- Condition-level scoring (vs current dominant-condition-per-plot)

From earlier analyses:
- State-specific RH95 thresholds (Phase 5j: each state has different optimal)
- Maine UT polygon-based filter (vs the current county/UNITCD proxy)
- DUA true coordinates (public lat/lon fuzzed up to ~1 km)
- rFIA::area(customPSE) for cross-validation
- GEDI L2A direct integration (vs Potapov's predicted RH95)

## Common gotchas

1. ssh heredocs need `source /etc/profile.d/lmod.sh` before `module load`
2. Cowork-to-Cardinal transfer is slow (~50 KB/s); do downloads on Cardinal
3. Cardinal GDAL lacks ZSTD codec; use gdalz conda env to read ORNL 2498
4. Don't re-relax v5.1 thresholds (v5.1 IS the calibrated default)
5. OG-class precision is low (kappa ~0 vs ORNL OG); Phase 7 Pelz is next
   non-blocked validation; Phase 6 Hagan is blocked on raster
6. Public FIA lat/lon fuzzed up to ~1 km
7. Pelz Eastern Region OG criteria use TREE COUNT per acre, not BA
8. TreeMap's vat.dbf has BALIVE/TPA_DEAD/QMD but NO STDAGE / max_dia /
   sd_dia / large-tree-count - to score v5.1 from TreeMap, must join
   PLT_CN to FIA tables
9. ME_TM_20.tif and ME_TM_22.tif are pre-cropped; for other states or
   2016, need to crop CONUS or use the full raster

## Key files

### R scripts
- R/fia_lsog_analysis_v5.r: operational classifier
- R/phase6_hagan_extract.r: scaffolded, blocked
- R/phase5g_design_based.r: FIA stratified estimation
- R/phase5h_carbon_fortyp_diag.r: carbon, forest type, OG diagnostics
- R/phase5i_final_analyses.r: refinements A-J
- R/phase5j_finals.r: UT split, diagnostics, LD 1529 policy table
- R/phase8_treemap_lsog.r: TreeMap wall-to-wall (initial)

### Outputs
- output_unified/lsog_ne_plot_table.csv: master per-plot table (13,432 rows)
- output_v5/fia_lsog_v5_all_states.csv: bootstrap CI summary
- output_design_based/design_based_area.csv: FIA-design CI summary
- output_design_based/ownership_breakdown.csv
- output_extras/carbon_by_class.csv
- output_final/A-J*.csv: refinements
- output_final2/T30,T32*.csv: UT split + LD 1529 policy table
- output_treemap/treemap_me_lsog.csv: TreeMap ME 2020+2022 shares
- output_figures/fig{1-16}*.png + map{1-2}*.png

### Documentation
- docs/NORTHEAST_LSOG_REPORT.md: integrated delivery doc
- docs/PELZ_2023_REVIEW.md: Pelz benchmark + Phase 7 plan
- docs/PHASE8_TREEMAP_NOTES.md: TreeMap method + Unknown gap plan
- docs/PHASE{1,4,5}*: methodology + results docs

## References

- Hagan et al. 2024 (LiDAR Maine LSOG): ourclimatecommon.org/lsog-project
- Thompson et al. 2026 (Pathways for Protecting Maine's Old-Growth)
- Bruening et al. 2026 (ORNL DAAC 2498): NASA Earthdata auth required
- Pelz et al. 2023 (FEM 549:121437): NFS Eastern Region OG criteria
- Potapov et al. 2021 (GLAD/UMD): glad.umd.edu/dataset/gedi
- Lang et al. 2023 (ETH Zurich): 10m global canopy height
- Tyrrell et al. 1998: Eastern OG vegetation types
- Woodall et al. 2023 (FEM 546:121361): Forest growth-stage system
- USFS TreeMap (Riley et al.): 30m imputed FIA pixels for CONUS

## Session-start protocol

1. Read CLAUDE.md (this file)
2. If working on OG-class refinements: read docs/PELZ_2023_REVIEW.md
3. If working on wall-to-wall maps: read docs/PHASE8_TREEMAP_NOTES.md
4. ssh-test cardinal: `ssh -F ~/.ssh/config cardinal "hostname"`
5. Check repo: `ssh cardinal 'cd ~/LSOG && git status && git log --oneline -3'`
6. Continuing analysis: `Rscript --vanilla R/<phase>.r`
7. Commit + push origin master

Update this file when Phase 6, 7, or 8-v2 completes, baseline changes,
or repo structure changes meaningfully.

## Quick state snapshot (April 26, 2026)

24 commits on master. Repo contains:
- Operational classifier v5.1 across ME/NH/VT/NY
- 16 figures + 2 maps + 40+ data tables
- Bootstrap and FIA design-based CIs
- Ownership x carbon breakdown for LD 1529
- Pelz 2023 benchmark and Phase 7 plan
- Phase 8 TreeMap initial (ME 2020/2022, 50% Unknown coverage gap)
- Integrated NE LSOG delivery report
- This memory file (CLAUDE.md), updated periodically

Two genuine open questions remain:
1. Is v5.1 systematically under-counting LSOG in unorganized Maine vs
   Hagan? (12% vs 21% gap - resolved when Hagan raster lands - Phase 6)
2. Are v5.1's OG plots actually old-growth or false positives? (kappa
   ~0 vs ORNL; Phase 7 Pelz cross-check is the next non-blocked test)

Phase 8 v2 (close TreeMap Unknown gap) is the next concrete coding task.
