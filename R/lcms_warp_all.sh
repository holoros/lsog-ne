#!/bin/bash
# Warp every annual LCMS v2024-10 Change (cause-of-change) raster to a Maine AOI
# tile at 100 m (EPSG:5070), cropping server-side from the remote COG via vsicurl.
# Run on a Cardinal LOGIN node (needs outbound network). ~3-5 min total.
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 gdal/3.7.3 >/dev/null 2>&1
WD=/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD; mkdir -p "$WD/aoi"; cd "$WD"
BASE="/vsizip/vsicurl/https://data.fs.usda.gov/geodata/LCMS"
ok=0; miss=""
for YR in $(seq 1985 2023); do
  OUT="aoi/lcms_${YR}.tif"
  [ -s "$OUT" ] && { ok=$((ok+1)); continue; }
  INNER="${BASE}/LCMS_CONUS_v2024-10_Change_Annual_${YR}.zip/LCMS_CONUS_v2024-10_Change_${YR}.tif"
  if gdalwarp -q -overwrite -te -71.2 42.9 -66.8 47.6 -te_srs EPSG:4326 \
       -t_srs EPSG:5070 -tr 100 100 -r near -co COMPRESS=DEFLATE \
       "$INNER" "$OUT" 2>/dev/null && [ -s "$OUT" ]; then
    ok=$((ok+1)); echo "OK $YR"
  else
    miss="$miss $YR"; rm -f "$OUT"; echo "MISS $YR"
  fi
done
echo "DONE years_ok=$ok missing=[$miss]"
ls aoi/lcms_*.tif | wc -l
