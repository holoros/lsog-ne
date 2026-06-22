#!/bin/bash
# Warp annual LCMS Change tiles for NH, VT, NY to per-state Maine-style AOI tiles.
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 gdal/3.7.3 >/dev/null 2>&1
WD=/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD; cd "$WD"
BASE="/vsizip/vsicurl/https://data.fs.usda.gov/geodata/LCMS"
# state : west south east north (EPSG:4326)
declare -A BBOX
BBOX[NH]="-72.65 42.60 -70.55 45.35"
BBOX[VT]="-73.50 42.70 -71.45 45.05"
BBOX[NY]="-79.85 40.45 -71.80 45.05"
for ST in NH VT NY; do
  read W S E N <<< "${BBOX[$ST]}"
  mkdir -p "aoi_${ST}"
  echo "=== $ST bbox $W $S $E $N ==="
  for YR in $(seq 1985 2023); do
    OUT="aoi_${ST}/lcms_${YR}.tif"
    gdalinfo "$OUT" >/dev/null 2>&1 && continue
    INNER="${BASE}/LCMS_CONUS_v2024-10_Change_Annual_${YR}.zip/LCMS_CONUS_v2024-10_Change_${YR}.tif"
    gdalwarp -q -overwrite -te $W $S $E $N -te_srs EPSG:4326 -t_srs EPSG:5070 \
      -tr 100 100 -r near -co COMPRESS=DEFLATE "$INNER" "$OUT" 2>/dev/null
    gdalinfo "$OUT" >/dev/null 2>&1 || { rm -f "$OUT"; echo "BAD $ST $YR"; }
  done
  echo "$ST tiles: $(ls aoi_${ST}/lcms_*.tif 2>/dev/null | wc -l)"
done
echo ALLDONE
