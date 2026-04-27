# lsog-ne project memory

Working memory for the Northeast LSOG project. Read at the start of any
new Cowork or Claude Code session that picks up the work.

## Project at a glance

- Repo: github.com/holoros/lsog-ne
- Cardinal: crsfaaron at /users/PUOM0008/crsfaaron/LSOG/
- Branch: master
- Operational classifier: v5.1 (R/fia_lsog_analysis_v5.r)
- Latest commits: 61afd50 (Pelz 2023 review), 18ffe94 (5j refinements), 41e1f63 (memory)

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

## Reference benchmarks for v5.1

| Source | Coverage | Maine LSOG/OG estimate |
|---|---|---|
| **v5.1 (this work)** | All ME private+public | 14.1% any LSOG, 0.19% OG, 33 K ac OG |
| Hagan et al. 2024 LiDAR | Maine UT only (9.5M ac) | 21.4% LSOG, 1.0% OG (~95 K ac) |
| Bruening 2026 (ORNL 2498) | Statewide MOG-prob > 50 | ~33% mature; 0.13% OG-prob > 50 |
| **Pelz 2023 NFS Eastern R9** | NFS lands only (small in NE) | 304 K ac OG total, 3% of NFS-East |
| Thompson 2026 | Maine UT, Hagan-derived | (matches Hagan) |

The proxy v5.1 statewide ME 14% is consistent with Hagan UT-only 21.4%
after scope dilution. v5.1 OG (0.19%) is conservative vs Hagan (1.0%) and
within range of Bruening's OG-prob > 50 (0.13%).

## Don't re-iterate the threshold history

- v3 default (5/10): too conservative (ME 9% all-LSOG)
- v4 (relaxed dims): better but still under
- v5 / v5b (4/6/8 in /12 with relaxed dims + 10/20m): over-counts NH/VT/NY 65%+
- v5.1 (ORIGINAL v3 dims + 18/25m + 4/6/8 in /12): SELECTED. Calibrated.

## Module load on Cardinal (corrected from SKILL.md)

```
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

Pelz et al. 2023 (Forest Ecology and Management 549:121437) is the
official USFS old-growth methodology paper. Independent validation
pathway that does NOT need Hagan's raster.

Plan in `docs/PELZ_2023_REVIEW.md`. Steps:

1. Filter FIA plots to NFS lands (OWNCD == 11) in NE
2. Apply Pelz Eastern Region (R9) OG criteria per FIA condition:
   - Stand age 100-160 yr (varies by Tyrrell 1998 vegetation type)
   - Large tree density 5-20/ac of DBH >= 12-20 in (varies by type)
3. Compare to v5.1 OG / LS calls on the same conditions
4. Output 4x4 confusion matrix + Cohen's kappa for OG agreement
5. Compare ME/NH/VT NFS-lands OG area to Pelz's R9 estimate (123K ha = 304K ac total)

NE NFS lands include White Mountain NF (NH), Green Mountain NF (VT),
plus minimal USFS lands in ME. About 1.0M ac total.

### Phase 5+ refinement candidates (not blocked)

From Pelz 2023 review:
- **Add tree-count metric** alongside score_ba_large (Pelz uses count per acre,
  not BA, in 8 of 9 NFS regional OG definitions)
- **Forest-type-specific thresholds** for OG class (Tyrrell 1998 types vary
  in age/density requirements)
- **Condition-level scoring** (score each FIA condition separately rather
  than dominant condition per plot)

From earlier analyses:
- State-specific RH95 thresholds (Phase 5j showed each state has different optimal)
- Maine UT polygon-based filter (Maine GeoLibrary or US Census MCD shapefile)
- DUA true coordinates (public lat/lon fuzzed up to ~1 km)
- rFIA::area(customPSE) for cross-validation of design-based estimation
- GEDI L2A direct integration (vs Potapov's predicted RH95)

## Common gotchas

1. ssh heredocs need `source /etc/profile.d/lmod.sh` before `module load`
2. Cowork-to-Cardinal transfer is slow (~50 KB/s); do downloads on Cardinal
3. Cardinal GDAL lacks ZSTD codec; use gdalz conda env to read 2498 ZSTD
4. Don't re-relax v5.1 thresholds (v5.1 IS the calibrated default)
5. OG-class precision is low (kappa ~0 vs ORNL OG); Phase 7 Pelz validation
   is the next-best test before Hagan raster lands
6. Public FIA lat/lon fuzzed up to ~1 km
7. Pelz Eastern Region OG criteria use TREE COUNT per acre, not BA (different
   from v5.1's score_ba_large which uses BA)

## Key files

- R/fia_lsog_analysis_v5.r: operational classifier
- R/phase6_hagan_extract.r: scaffolded, blocked
- R/phase5g_design_based.r: FIA stratified estimation
- R/phase5h_carbon_fortyp_diag.r: carbon, forest type, OG diagnostics
- R/phase5i_final_analyses.r: refinements A-J
- R/phase5j_finals.r: UT split, diagnostics, LD 1529 policy table
- output_unified/lsog_ne_plot_table.csv: master per-plot table
- output_v5/fia_lsog_v5_all_states.csv: bootstrap CI summary
- output_design_based/design_based_area.csv: FIA-design CI summary
- output_design_based/ownership_breakdown.csv
- output_extras/carbon_by_class.csv
- output_final/A-J*.csv: refinements
- output_final2/T30,T32*.csv: UT split + LD 1529 policy table
- docs/NORTHEAST_LSOG_REPORT.md: integrated delivery doc
- docs/PELZ_2023_REVIEW.md: Pelz benchmark + Phase 7 plan
- output_figures/fig{1-16}*.png + map{1-2}*.png: 16+2 figures total

## References

- Hagan et al. 2024 (LiDAR Maine LSOG): ourclimatecommon.org/lsog-project
- Thompson et al. 2026 (Pathways for Protecting Maine's Old-Growth)
- Bruening et al. 2026 (ORNL DAAC 2498): NASA Earthdata auth required
- **Pelz et al. 2023** (FEM 549:121437): NFS Eastern Region OG criteria
- Potapov et al. 2021 (GLAD/UMD): glad.umd.edu/dataset/gedi
- Lang et al. 2023 (ETH Zurich): 10m global canopy height
- Tyrrell et al. 1998: Eastern OG vegetation types (referenced by Pelz)
- Woodall et al. 2023 (FEM 546:121361): Forest growth-stage system

## Session-start protocol

1. Read this file (CLAUDE.md)
2. Read docs/PELZ_2023_REVIEW.md if working on OG-class refinements
3. ssh-test cardinal: `ssh -F ~/.ssh/config cardinal "hostname"`
4. Check repo: `ssh cardinal 'cd ~/LSOG && git status && git log --oneline -3'`
5. Continuing analysis: `Rscript --vanilla R/<phase>.r`
6. Commit + push origin master

Update this file when Phase 6 or Phase 7 completes, baseline changes, or
repo structure changes meaningfully.
