# Phase 1 baseline notes (April 25, 2026)

## What's in this commit
- R/fia_lsog_analysis_v3.r: working v3 classifier
- R/fia_lsog_analysis.R: previous pre-v3 script (kept for reference)
- output_v3/: v3 results from the March 19, 2026 local run (partial PNG set;
  the v3 script can regenerate any missing figures locally on Cardinal)
- output_legacy/: skipped this commit due to bandwidth constraints during
  setup; will be added in a follow-up commit

## Outstanding items for Phase 2
1. Add 2020-2024 evaluation panel to eval_breaks tribble
2. Refresh FOREST_ACRES from EVALIDator
3. Add subset_unorg flag to process_state(); requires Maine unorganized-territory
   boundary shapefile (try MaineGEO or Maine GeoLibrary)
4. STDAGE imputation: per-species DIA-to-age regression to fill NAs

## Phase 3 dependencies (blocked)
- Hagan LSOG raster: not yet on Cardinal. The Thompson PDF supplements do not
  contain the raster file itself. Will need to request the GeoTIFF from
  John Hagan / Our Climate Common, or via the LD 1529 / Maine DACF working
  group channel.

## Phase 4 dependencies (downloadable)
- ORNL DAAC 2498: 1-ha probability raster, downloadable from
  https://daac.ornl.gov/cgi-bin/dsviewer.pl?ds_id=2498
  Will need an Earthdata login. Best fetched via wget on a Cardinal compute
  node since the file set is multi-GB.

