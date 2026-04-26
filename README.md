# lsog-ne

FIA-based late-successional / old-growth (LSOG) classification for the U.S.
Northeast. Started in Maine; designed to extend to New Hampshire, Vermont, and
New York as data become available.

Built on the proxy scoring framework in `R/fia_lsog_analysis_v3.r`. The v3
script already supports a multi-state `STATE_CODES` vector and produces
regional comparison figures when more than one state is processed.

## Project arc

- Phase 1 (done): Cardinal project layout, v3 baseline import, GitHub remote.
- Phase 2: 2020-2024 evaluation panel + unorganized-territory subset; STDAGE
  imputation; multi-state run for ME, NH, VT, NY.
- Phase 3 (blocked on raster availability): plot-level recalibration against
  Hagan et al. (2024) LiDAR LSOG classes for the Maine unorganized townships.
- Phase 4 (in progress this session): cross-validate the v3 proxy against
  the ORNL DAAC dataset 2498 ("Mature and Old-growth Forest Probability Maps
  for the Conterminous US") at the FIA plot level, statewide for each state
  in `STATE_CODES`.

## Layout

- `R/`            Analysis scripts.
  - `fia_lsog_analysis_v3.r`     v3 baseline classifier (multi-state aware)
  - `fia_lsog_analysis.R`        v1 reference
  - `phase4_helpers.r`           shared scoring + raster utilities
  - `phase4_ornl2498_extract.r`  Phase 4 pipeline
- `scripts/`      Shell helpers.
  - `download_ornl2498.sh`       wget + .netrc downloader for the 3 COGs
  - `refresh_earthdata_netrc.sh` interactive password updater
  - `submit_phase4.sh`           sbatch template (uses default account)
- `data/fia/`     FIA tables (gitignored). Cardinal already has `~/fia_data/`
                  with ME tables; symlinked here.
- `data/rasters/` Hagan and ORNL rasters (gitignored).
- `output_v3/`    Phase 1 baseline figures and CSVs.
- `output_legacy/` Earlier outputs (will populate in a follow-up commit).
- `output_phase4/` Phase 4 results (created by phase4 scripts).
- `docs/`         Methodology notes, comparison tables, source PDFs.
- `logs/`         SLURM logs (gitignored).

## v3 baseline result (Maine, 2014-2018)

Statewide:

- Transitioning LS:    ~1,328,000 ac (7.9 percent)
- Late-Successional:    ~171,000 ac (1.0 percent)
- Old-Growth:            ~22,000 ac (0.13 percent)
- All LSOG:           ~1,521,000 ac (9.0 percent)

Compare with Hagan/Thompson (Maine unorganized territories only, 9.5M ac):

- Transitioning LS:  17.2 percent
- LS + OG:            4.2 percent
- All LSOG:          21.4 percent

## References

- Bruening, J.M. et al. 2026. Mature and Old-growth Forest Probability Maps
  for the Conterminous United States. ORNL DAAC.
  https://doi.org/10.3334/ORNLDAAC/2498
- Hagan, J. et al. 2024. Using LiDAR to Map, Quantify, and Conserve LSOG in
  Maine. Our Climate Common. https://ourclimatecommon.org/lsog-project/
- Thompson, J. et al. 2026. Pathways for Protecting Maine's Remaining
  Old-Growth Forests. Harvard Forest / University of Maine.

## Running on Cardinal

```bash
source /etc/profile.d/lmod.sh && module purge && module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
cd ~/LSOG
ln -sf ~/fia_data data/fia    # use the already-staged FIA tables
Rscript R/fia_lsog_analysis_v3.r
```

For the Phase 4 ORNL comparison see `docs/PHASE4_PLAN.md`.
