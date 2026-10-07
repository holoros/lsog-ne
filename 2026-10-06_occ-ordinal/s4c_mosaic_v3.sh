#!/bin/bash
# s4c_mosaic_v3.sh MODE RES  Mosaic the v3 ordinal tiles to EPSG:3979, clipped to Maine, as _PROVISIONAL.
# Coverage of the M3 forest frame is summed from the tile logs; gates and recalibration run downstream.
set -eu
MODE=$1; RES=$2
CUT=/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson
ls $OUT/tiles_${MODE}_v3/ord_${MODE}_*.tif > $OUT/_${MODE}_v3_list.txt
echo "tiles: $(wc -l < $OUT/_${MODE}_v3_list.txt)"
python3 -c "import pandas as pd,glob;c=pd.concat([pd.read_csv(f) for f in glob.glob('$OUT/tiles_${MODE}_v3/cov_*.csv')]);c.to_csv('$OUT/agg/coverage_${MODE}_v3_DATA.csv',index=False);print('predicted share of frame forest',c.predicted.sum()/c.forest_cells.sum())"
gdalwarp -overwrite -t_srs EPSG:3979 -tr $RES $RES -tap -r near -srcnodata 65535 -dstnodata 65535 -cutline $CUT -crop_to_cutline \
  -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS -multi --optfile $OUT/_${MODE}_v3_list.txt \
  $OUT/final/occ-ordinal-v3-lsog_${RES}m_${MODE}_ME_DATA_2026-10-06_PROVISIONAL.tif
echo S4C DONE $MODE
