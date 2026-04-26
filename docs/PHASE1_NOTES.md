# Phase 1 baseline notes

## What is in this commit

- R/fia_lsog_analysis_v3.r: v3 classifier (multi-state via STATE_CODES vector)
- R/fia_lsog_analysis.R: pre-v3 reference
- output_v3/: v3 result CSV and four figures from March 19, 2026 local run
- README.md, docs/PHASE1_NOTES.md, .gitignore, logs/.gitkeep

## Outstanding items from Phase 1

- Two v3 PNGs and the legacy March 3 output set did not transfer in the
  initial setup session. They will land in a follow-up commit.

## Cardinal-side data already in place

The user already has on Cardinal at ~/fia_data/:
- ME_PLOT.csv, ME_COND.csv, ME_TREE.csv (April 17, 2026 vintage)
- ME_POP_*.csv tables for proper EXPNS and population estimation
- fia_db_ME.rds (precomputed Maine FIA database, 727 MB)

States not yet present on Cardinal (downloadable from FIA DataMart):
- NH, VT, NY (and re-pulls of MA, CT for consistency)

## Repo scope

Originally scoped to Maine (lsog-maine). Renamed to lsog-ne (Northeast)
since the v3 classifier already supports multi-state runs and the user
plans to extend to NH, VT, and NY.

## Phase 4 prep added in this session

- R/phase4_helpers.r: shared scoring + raster utilities
- R/phase4_ornl2498_extract.r: full extraction and confusion-matrix pipeline
- scripts/download_ornl2498.sh: wget-based downloader using ~/.netrc
- scripts/refresh_earthdata_netrc.sh: helper to fix the URS 401 (stale password)
- scripts/submit_phase4.sh: SBATCH template, no --account flag
- docs/PHASE4_PLAN.md: methodology, run instructions, caveats

Currently blocked on Earthdata password refresh: existing ~/.netrc returns 401
from URS. The refresh script fixes that, then download_ornl2498.sh pulls all
three COGs and submit_phase4.sh runs the comparison.
