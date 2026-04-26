# Phase 5: add GEDI canopy height as a proxy dimension

## Goal

Close the remaining gap between v4 (18% all-LSOG) and ORNL 2498's
33% mature share by adding a vertical-canopy-structure dimension to
the proxy score. The Phase 4 v3 logistic fit found that none of v4's
five FIA-only dimensions discriminate well against ORNL beyond AUC 0.56;
the missing signal is canopy height and gap pattern, which the FIA plot
variables aggregate away. GEDI-derived canopy height fills that gap.

## Two probed data sources

### ORNL DAAC ds_id 2417 (May et al. 2025)
*GEDI-FIA Fusion: Training Lidar Models to Estimate Forest Attributes.*
240 MB tarball with 967 per-tile pre-trained linear-EIV models in
.RData form, plus model code (R + Cpp). NOT a raster product; this is
the toolkit to compute predictions from raw GEDI L2A footprints, not
ready-to-extract values. Use this if we want to apply May et al.'s
modeling pipeline ourselves to GEDI L2A points; otherwise skip.

### Lang et al. 2023 ETH Global Canopy Height
*A high-resolution canopy height model of the Earth.* 10 m global
canopy height + uncertainty maps for year 2020, derived from a deep
ensemble that fuses Sentinel-2 imagery with sparse GEDI L2A supervision.
This is a ready-to-extract raster. Three access paths:

1. ETH Zurich research collection DOI 10.3929/ethz-b-000609802.
   The interactive tile browser at langnico.github.io/globalcanopyheight
   exposes per-tile download URLs that are not enumerable from a
   non-interactive shell. User manual step required.
2. Google Earth Engine asset
   `users/nlang/ETH_GlobalCanopyHeight_2020_10m_v1`. Requires GEE
   authentication and rgee or earthaccess setup.
3. ArcGIS Living Atlas tiled service. Public read access for ESRI
   accounts; can be served as WMS to GDAL.

## Recommended path forward

Use (1) — the ETH research collection — for primary production. The
user manually downloads the four 3 deg x 3 deg tiles covering Maine
and the rest of New England, lands them in
`~/LSOG/data/rasters/lang_2023/`. The download script below assumes
filenames matching `ETH_GlobalCanopyHeight_10m_2020_v1_<lat>_<lon>_Map.tif`
where <lat>/<lon> are the top-left corner of the 3 deg block.

Tiles needed for ME, NH, VT, NY (approx):

- N48W072  (northern ME, NH, VT)
- N45W072  (southern ME, NH, VT, northern NY)
- N48W075  (extreme northern NY)
- N45W075  (Adirondacks, central NY)
- N42W075  (southern NY)

Once the tiles are in place, mosaic to a single virtual raster:

```
gdalbuildvrt ~/LSOG/data/rasters/lang_2023/lang_NE.vrt \
    ~/LSOG/data/rasters/lang_2023/ETH_GlobalCanopyHeight_10m_2020_v1_*_Map.tif
```

## Proxy score addition

Add a new score dimension `score_canopy_height` based on plot-centroid
extracted RH98:

| score | rule |
|---|---|
| 2 | Lang RH98 >= 25 m   (mature canopy with super-emergent trees) |
| 1 | Lang RH98 >= 18 m   (closed mature canopy) |
| 0 | Lang RH98  < 18 m   (regenerating or young) |

This brings total score to /12 (was /10). Adjust LSOG class thresholds
proportionally:
- THRESH_OG    = 9  (was 8)
- THRESH_LS    = 7  (was 6)
- THRESH_TRANS = 5  (was 4)

Re-run the Phase 4 v3 logistic fit with the new dimension included
to confirm it lifts AUC. Expected: AUC moves from 0.56 toward 0.75+.

## Stub download script

Saved as `scripts/download_lang_2023_NE.sh`. After a manual click-through
on the tile browser, paste each tile's download URL into the script's
URL list. The script handles the wget loop and verifies file size.

## Files to add (next session)

- `scripts/download_lang_2023_NE.sh` (stubbed, user fills URLs)
- `R/phase5_lang_extract.r` (extracts RH98 at FIA plot centroids)
- `R/fia_lsog_analysis_v5.r` (v4 + Lang RH98 dimension)
- `output_v5/` (parallel to output_v4/)
- `docs/PHASE5_RESULTS.md`
