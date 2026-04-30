# lsog-ne project memory

Working memory for the Northeast LSOG project. Read this at the start of any
new Cowork session that picks up the work.

## Project at a glance

- **Repo**: `github.com/holoros/lsog-ne`
- **Cardinal user**: `crsfaaron` at `/users/PUOM0008/crsfaaron/LSOG/`
- **Branch**: `master` (default; remote tracking already set up)
- **Latest commit as of memory write**: `e54aa19` — Manuscript V1 sections 2-5 drafted (April 30, 2026)
- **Total commits**: 36+ (April 30, 2026 session: Phase 8 v3, Phase 8 v3-Potapov, deck polish, manuscript V1 body, Phase 7 Pelz)

## Operational classifier: v5.1

Six-dimension proxy at `R/fia_lsog_analysis_v5.r`. Each dim 0/1/2; total /12.

| # | Dimension | 1pt | 2pt | Notes |
|---|---|---|---|---|
| 1 | score_ba_large | BA(DBH≥20") ≥ 40 ft²/ac | ≥ 80 | unchanged from v3 |
| 2 | score_maturity | STDAGE ≥ 80 yr | ≥ 120 | max_dia ≥ 24 in fallback if STDAGE NA |
| 3 | score_structure | sd_dia ≥ 5 in | ≥ 8 | TPA-weighted SD of DBH |
| 4 | score_canopy | BA total ≥ 100 ft²/ac | ≥ 150 | total stocking |
| 5 | score_deadwood | snag_tpa ≥ 75th pct | ≥ 90th | data-driven percentiles |
| 6 | score_canopy_height | Potapov RH95 ≥ 18 m | ≥ 25 m | from ORNL DAAC 2417 (Lang 2023 alt) |

Class thresholds: TLS ≥ 4, LS ≥ 6, OG ≥ 8.

## Key threshold history (don't repeat the iteration)

- **v3 default** (5/10 score): too conservative for ORNL/Hagan. ME 9% all-LSOG.
- **v4 (relaxed dims)**: BA 100/150 → 80/120; sd_dia 5/8 → 3/6; max_dia 24 → 20.
  Better but still under target. Operationalized Mar 2026.
- **v5 = v4 + Potapov height** (5/7/9 in /12): under-counted at high end.
- **v5b = v4 + Potapov + 4/6/8 in /12**: GOOD on ME but over-counted NH/VT/NY.
- **10/20m RH95 + relaxed dims**: ME 35% (matches ORNL 33% mature) but NH 66%, VT 68% — implausible.
- **v5.1 = v3-original dims + 18/25m + 4/6/8 in /12**: SELECTED. ME 14%, NH 31%, NY 27%, VT 29%. Defensible across all four states.

The temptation to re-relax thresholds for higher LSOG share is wrong — v5.1 is calibrated.

## Headline regional results (v5.1, FIA panel 2019-2023)

| State | n | All LSOG % (95% CI) | LS+OG % | OG % | Acres LSOG |
|---|---:|---:|---:|---:|---:|
| ME | 3,125 | 14.1 (12.9-15.3) | 2.06 | 0.19 | 2.36 M |
| NH | 757 | 31.2 (28.0-34.3) | 5.28 | 0.26 | 1.44 M |
| NY | 2,107 | 27.2 (25.2-29.0) | 7.40 | 1.28 | 4.81 M |
| VT | 657 | 28.8 (25.4-32.3) | 6.70 | 0.15 | 1.26 M |

NE total all-LSOG ≈ 9.87 M acres; LS+OG ≈ 2.19 M; OG ≈ 286 K.

## Cardinal layout

```
~/LSOG/
  R/
    fia_lsog_analysis_v3.r       v3 reference
    fia_lsog_analysis_v4.r       v4 reference
    fia_lsog_analysis_v5.r       v5.1 OPERATIONAL
    phase4_helpers.r             scoring + raster utilities
    phase4_ornl2498_extract.r    Phase 4 v1
    phase4_v2.r, phase4_v3.r     Phase 4 iterations
    phase5_potapov_extract.r     Phase 5 (Potapov integration)
    phase5b_variants.r           classifier variant comparison
    phase5c_potapov_sensitivity.r RH95 grid search
    phase5d_threshold_compare.r  18/25 vs 14/22 vs 10/20
    phase5e_refinement.r         6-variant calibration sweep
    phase5g_design_based.r       FIA design-based estimation
    phase5h_carbon_fortyp_diag.r carbon, fortyp, OG diagnostics
    phase5i_final_analyses.r     A-J refinements
    phase6_hagan_extract.r       SCAFFOLDED, blocked on raster
    build_unified_plot_table.r   master per-plot table producer
    build_reporting_table.r      DACF-style reporting table
    build_figures_maps.r         basic figure set
    build_design_based_figures.r design-based + ownership figures
  scripts/
    download_ornl2498.sh         Bruening 2026 raster download
    download_lang_2023_NE.sh     Lang 2023 stub (manual URLs needed)
    refresh_earthdata_netrc.sh   URS password updater
    stage_hagan_raster.sh        Phase 6 staging check
    submit_phase4.sh             SBATCH template
  data/
    fia/                         symlink to ~/fia_data/
    rasters/
      ornl_2498/                 1.5 GB ZSTD + 1.7 GB LZW (Bruening)
      ornl_2417/                 240 MB tarball (May 2025 model code)
      potapov_2019/              5.4 GB NAM mosaic (Potapov 2021)
      hagan_lsog/                EMPTY — drop GeoTIFF here for Phase 6
  output_v3/, output_v4/, output_v5/        per-version baseline outputs
  output_phase4/, output_phase5/             Phase 4/5 results
  output_design_based/                       Phase 5g outputs
  output_extras/                             Phase 5h carbon/fortyp/diag
  output_final/                              Phase 5i refinements (A-J)
  output_unified/lsog_ne_plot_table.csv      master per-plot table
  output_figures/                            12 figures + 2 maps
  docs/                                      methodology + results docs
  logs/                                      SLURM and Rscript logs
```

FIA inputs at `~/fia_data/`: `{ME,NH,VT,NY}_{PLOT,COND,TREE,POP_*}.csv`.
Auxiliary rasters in `~/LSOG/data/rasters/`.

## SSH and module setup

Every Cowork session needs to install Cardinal SSH key (in skill at
`hpc-cardinal/.ssh-keys/id_ed25519_cardinal`) into `~/.ssh/`:

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp $SKILL_DIR/.ssh-keys/id_ed25519_cardinal ~/.ssh/id_ed25519_cardinal
chmod 600 ~/.ssh/id_ed25519_cardinal
cat > ~/.ssh/config << 'EOC'
Host cardinal
    HostName cardinal.osc.edu
    User crsfaaron
    IdentityFile ~/.ssh/id_ed25519_cardinal
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOC
chmod 600 ~/.ssh/config
```

GitHub auth: `~/.ssh/id_ed25519_github` exists on Cardinal (already set up).
The `id_ed25519_cardinal` key is in the upload at `id_ed25519_cardinal` in the
attached file list.

Cardinal module load (NOT what skill says — corrected):
```bash
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0    # MUST come first
module load gdal/3.7.3    # geos/proj come bundled
module load R/4.4.0       # 4.5.2 also available
```

For ZSTD-compressed rasters (ORNL DAAC), Cardinal's bundled GDAL lacks
ZSTD codec. Use the conda env at `~/.conda/envs/gdalz/`:
```bash
module load miniconda3/24.1.2-py310
eval "$(conda shell.bash hook)"
conda activate gdalz
```

## Outstanding / blocked work

### Phase 6: Hagan validation (BLOCKED)

Drop GeoTIFF at `~/LSOG/data/rasters/hagan_lsog/hagan_lsog_100m.tif` then:
```bash
bash scripts/stage_hagan_raster.sh
Rscript --vanilla R/phase6_hagan_extract.r
```

Pipeline is fully scaffolded. Outputs: 4×4 confusion matrix, binary kappa
(any-LSOG), weighted ordinal kappa, OG-only kappa.

Acquisition: email John Hagan / Our Climate Common (info@ourclimatecommon.org)
or via LD 1529 / Maine DACF working group, or Harvard Forest Thompson team.

### Future refinement candidates (not blocked, not yet done)

- **State-specific RH95 thresholds**: Phase 5j showed each state has different
  optimal threshold. Could implement per-state calibration if comparable
  reporting across states becomes secondary to local accuracy.
- **Maine UT polygon-based filter**: county proxy in Phase 5i was crude.
  Maine GeoLibrary or MaineGEO probably has UT/MCD shapefile.
- **Plot-level true coordinates**: public FIA lat/lon is fuzzed up to ~1 km,
  causes ~30 pixel uncertainty on Potapov RH95 extraction. DUA coordinates
  would tighten this.
- **rFIA::area(customPSE)**: instead of manual stratified estimation in
  phase5g, could use rFIA's design-based functions for cross-validation.
- **Public-private LSOG carbon stock breakdown**: Phase 5i has carbon × ownership
  table; could surface as policy-ready summary numbers.
- **GEDI L2A direct integration**: use raw GEDI L2A footprints near plots
  rather than Potapov's predicted RH95 raster. More work.

## Common gotchas to avoid

1. **The default `module load gdal/3.7.3` will fail** in non-interactive ssh
   sessions because the module init isn't sourced. Always run
   `source /etc/profile.d/lmod.sh` first, then `module purge`, then load
   `gcc → gdal → R` in that order.

2. **`bash` heredocs inside `ssh -F config cardinal 'bash -s' << 'REMOTE'`
   won't have `module` available** unless you `source /etc/profile.d/lmod.sh`
   inside the heredoc.

3. **Large file transfers from Cowork to Cardinal are slow** (~50 KB/s).
   Use Cardinal-side downloads (wget) for anything > a few MB.

4. **Cardinal's GDAL doesn't support ZSTD**. Re-encode ORNL 2498 to LZW
   one-time using the gdalz conda env (already done; LZW file lives
   at `data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m_lzw.tif`).

5. **Don't re-relax v5.1 thresholds**. The 10/20m RH95 / relaxed dims
   combination over-counts in NH/VT/NY. v5.1's original v3 dims + 18/25m +
   4/6/8 in /12 is the calibrated default.

6. **OG-class precision is low**. v5.1 OG has bootstrap kappa ~0 vs ORNL OG.
   Don't over-interpret state-level OG percentages without Hagan validation.

## Key references

- **Hagan et al. 2024**: Maine LiDAR LSOG. https://ourclimatecommon.org/lsog-project/
- **Thompson et al. 2026**: Pathways for Protecting Maine's Old-Growth.
- **Bruening et al. 2026** (ORNL DAAC 2498): ZSTD COG at
  https://data.ornldaac.earthdata.nasa.gov/protected/global_vegetation/OldGrowth_MatureForest_Maps_US/data/
- **Potapov et al. 2021** (GLAD/UMD): https://glad.umd.edu/dataset/gedi/
- **May et al. 2025** (ORNL DAAC 2417): GEDI-FIA model code, NOT a raster.
- **Lang et al. 2023** (ETH Zurich): 10m global canopy height.
  Manual click-map at langnico.github.io/globalcanopyheight.

## Session-start protocol

Future Cowork sessions on this project should:

1. Read this memory file
2. SSH-test to Cardinal: `ssh -F ~/.ssh/config cardinal "hostname"`
3. Check repo state: `ssh cardinal 'cd ~/LSOG && git status && git log --oneline -3'`
4. If new work: branch off master with descriptive name
5. If continuing analysis: `Rscript --vanilla R/<phase script>.r`
6. Commit with descriptive message; push to origin master

## Reference benchmarks (added April 2026)

| Source | Coverage | ME LSOG/OG estimate |
|---|---|---|
| **v5.1** | All ME private+public | 14.1% any LSOG, 0.19% OG, 33 K ac OG |
| Hagan et al. 2024 LiDAR | Maine UT only (9.5M ac) | 21.4% LSOG, 1.0% OG (~95 K ac) |
| Bruening 2026 (ORNL 2498) | Statewide MOG-prob > 50 | ~33% mature, 0.13% OG-prob > 50 |
| **Pelz 2023 (FEM 549:121437)** | NFS lands only | 304 K ac OG total NFS-East |
| Thompson 2026 | Maine UT, Hagan-derived | (matches Hagan) |

## Pelz 2023 derived refinements (Phase 7+ planned)

Pelz et al. 2023 is the official USFS old-growth methodology paper. Key
takeaways for v5.1 (full review at `docs/PELZ_2023_REVIEW.md` on Cardinal):

1. **Eastern Region (R9) OG criteria** (vegetation-type-specific):
   - Stand age 100-160 yr (varies by Tyrrell 1998 type)
   - Density 5-20 trees/ac of DBH >= 12-20 in (varies)

2. **Phase 7 plan** — independent validation NOT requiring Hagan:
   - Filter NE FIA plots to NFS lands (OWNCD == 11)
   - Apply Pelz Eastern criteria per condition
   - Compare to v5.1 OG/LS calls
   - 4×4 confusion + Cohen's kappa
   - NE NFS lands: White Mountain NF (NH), Green Mountain NF (VT), ~1.0M ac

3. **Three v5.1 refinements informed by Pelz**:
   - Add `score_large_tree_count` (count per acre, not BA)
   - Forest-type-specific thresholds (spruce-fir vs hardwood)
   - Condition-level scoring (vs current dominant-condition-per-plot)

## Phase 8 TreeMap wall-to-wall (IN PROGRESS)

USFS TreeMap (Riley et al.) at `/users/PUOM0008/crsfaaron/TREEMAP/`. Each
30m pixel is assigned an imputed FIA plot ID (TM_ID -> PLT_CN via vat.dbf).

### Done (commit `e9b3a3c`):
- Maine 2020 and 2022, full state
- 191 M NE-source pixels (42.4 M ac across 4,657 NE PLT_CNs)
- ME 2020 results (out of 75M total ME pixels):
  - Unknown: 50.2% (PLT_CNs from older FIA panels not in unified table)
  - Transitioning LS: 5.2% (3.94M pixels = 0.88M ac)
  - LS: 0.33%
  - OG: 0.04% (3 unique TM_IDs only)
  - Not LSOG: 44.2%
- Excluding Unknown: ~11% any-LSOG (vs 14.1% v5.1 plot-based)

### Phase 8 v2 plan
The 50% Unknown gap = Maine FIA plots from 2009-2013 panel + earlier,
plus some non-NE state plots imputed to ME pixels. To close:

1. **Option A**: Extend unified table to 1999-2013 panels using v4
   (no Potapov, comparable across panels). Hybrid v5.1/v4 fallback.
2. **Option B**: Full-CONUS v5.1 scoring via ENTIRE FIA tables
   (~/FIA/ENTIRE_*.csv, 600+ MB each).

Then extend to NH/VT/NY (need to crop CONUS rasters or use full extent)
and TreeMap 2016 (need to crop CONUS to state bbox).

### TreeMap data structure
- `/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif` (4.84 GB)
- `/users/PUOM0008/crsfaaron/TREEMAP/TM2020/TreeMap2020_CONUS.tif.vat.dbf`
  (34 MB, 64,743 plots with TM_ID, PLT_CN, FORTYPCD, BALIVE, TPA_DEAD,
  STANDHT, QMD, DRYBIO_L, CARBON_L, etc.)
- `ME_TM_20.tif` and `ME_TM_22.tif` are ME-clipped (745 MB each)
- TreeMap.R is Aaron's existing workflow script

### TreeMap-only classification limits
The vat.dbf has BALIVE, TPA_DEAD, QMD, STANDHT but NO STDAGE, no max_dia,
no sd_dia, no large-tree count. To compute v5.1 from TreeMap alone,
must join PLT_CN to FIA tables for the missing variables. This is what
Phase 8 does (joining via PLT_CN -> v5.1 class lookup in unified table).

### Phase 8 v2 results (commit 494a632)

ME wall-to-wall coverage closed via all-panels v4 lookup:

| Year | Class | Acres | % of pixels |
|---|---|---:|---:|
| 2020 | Transitioning LS | 1.25 M | 7.45 |
| 2020 | LS | 118 K | 0.70 |
| 2020 | Unknown | 56 K | 0.33 |
| 2020 | Not LSOG | 15.30 M | 91.51 |
| 2022 | Transitioning LS | 1.23 M | 7.36 |
| 2022 | LS | 113 K | 0.68 |

ME wall-to-wall any-LSOG: 8.04-8.15% (~1.35 M acres). Lower than
v5.1 plot-based 14.1% because Phase 8 v2 uses v4-style scoring (no
Potapov canopy height — Potapov is 2019-only and not applicable to
older panels). Adding Potapov dim would lift share by ~6 percentage
points to match v5.1.

### Phase 8 NE extension RESOLVED (commit 9d0468b, April 30, 2026)

`R/phase8_NE_wall_to_wall_v3.r` is the operational NE-wide pipeline.
Root cause of the all-Unknown bug: `terra::cats(r)` on the CONUS raster
returns activeCat = 4 (ForTypName), so `terra::freq()` returned forest
type strings instead of integer Value codes. Fix: `levels(rc) <- NULL`
after crop/mask, before freq. Phase 8 v3 NE summary:

| State | Year | any-LSOG % | Acres |
|---|---:|---:|---:|
| ME | 2020 | 8.09 | 1,333,955 |
| ME | 2022 | 7.99 | 1,313,970 |
| NH | 2020 | 15.75 | 735,489 |
| NH | 2022 | 15.65 | 730,610 |
| NY | 2020 | 13.62 | 2,562,932 |
| NY | 2022 | 13.55 | 2,552,411 |
| VT | 2020 | 16.15 | 728,756 |
| VT | 2022 | 16.03 | 724,263 |

### Phase 8 v3-Potapov COMPLETE (commit 03bd809, April 30, 2026)

`R/phase8_v3_potapov_wall_to_wall.r` adds canopy-height dimension to
wall-to-wall via hybrid lookup (v5.1 for 2019-2023 panel plots, v4 for
older). Lifts any-LSOG by 1 to 3 percentage points across the region:
ME 8.09 → 9.17, NH 15.75 → 17.49, NY 13.62 → 15.07, VT 16.15 → 18.87.

VT shows the largest lift (taller mid-elevation forests); ME the
smallest (heavy-harvest history). Same regional ranking as plot-based
v5.1 in both wall-to-wall variants.

### Manuscript V1 (commit e54aa19, April 30, 2026)

`manuscript/MANUSCRIPT_DRAFT_V1_BODY.md` covers Sections 2-5 (Methods,
Results, Discussion, Conclusion) using the calibrated v5.1 numbers.
Combined with the V1 Introduction (April 27), the full manuscript is
at first-complete-draft stage at ~9,000 words. Reconciliation note in
the Body documents the shift from earlier v5 baseline numbers.

### Slide deck polished (commit b5b0557, April 30, 2026)

16-slide pptx at `deck/Northeast_LSOG_Project.pptx`:
title, TL;DR, methods divider, why-it-matters, v5.1 classifier,
results divider, headline shares, time series, ownership, carbon,
validation divider, benchmarks, wall-to-wall, Pelz validation,
limitations, project status. Speaker notes on every slide.

## Memory-file maintenance

Update this file when:
- Phase 6 (Hagan) completes
- Phase 7 (Pelz) completes
- TreeMap analysis completes
- New collaborator gets access
- Major refinement / recalibration changes the v5.1 baseline
- Repo structure changes significantly

Run `consolidate-memory` skill periodically to merge / prune as work evolves.
