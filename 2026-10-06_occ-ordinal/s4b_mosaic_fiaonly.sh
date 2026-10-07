#!/bin/bash
# s4b_mosaic_fiaonly.sh  mosaic the FIA only statewide 30 m tiles exactly as s4a does for the pooled model.
set -eu
CUT=/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson
ls $OUT/tiles_state30_fiaonly/ord_state30_*.tif > $OUT/_state30_fiaonly_list.txt
wc -l < $OUT/_state30_fiaonly_list.txt
python3 -c "import pandas as pd,glob;c=pd.concat([pd.read_csv(f) for f in glob.glob('$OUT/tiles_state30_fiaonly/cov_*.csv')]);c.to_csv('$OUT/agg/coverage_state30_fiaonly_DATA.csv',index=False);print(c.predicted.sum()/c.forest_cells.sum())"
gdalwarp -overwrite -t_srs EPSG:3979 -tr 30 30 -tap -r near -srcnodata 65535 -dstnodata 65535 -cutline $CUT -crop_to_cutline \
  -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS --optfile $OUT/_state30_fiaonly_list.txt \
  $OUT/final/occ-ordinal-lsog_30m_state30-fiaonly_ME_DATA_2026-10-06_PROVISIONAL.tif
echo S4B DONE
