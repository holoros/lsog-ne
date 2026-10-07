#!/bin/bash
# s7a_structure_layers.sh TASK  Statewide Maine structure covariates on the EPSG:3979 30 m grid of the M3 frame
# (grid aligned with -tap; frame origin 1739670, 558510 is a multiple of 30 m).
#   0 chm_mean30: Meta CHM v2 (1.19 m, EPSG:3857) averaged to 30 m
#   1 chm_max30 : maximum (proxy for the upper canopy)
#   2 chm_rms30 : root mean square, so chm_sd30 = sqrt(rms^2 - mean^2) is formed downstream
#   3 tsd30     : Hansen GFC v1.12 lossyear, nearest, recoded downstream as 2024 - (2000 + ly), 40 for no loss
# F7: Meta CHM v2 codes no data as 255; a first run without that nodata put 255 m into the 30 m layers and was discarded.
# F2: the CHM VRT declares no nodata, so absent tiles read as 0 m. Downstream steps treat a 30 m cell with mean
# 0 and max 0 inside the forest frame as missing, never as a real zero height.
set -eu
R=/fs/scratch/PUOM0008/crsfaaron; OUTD=$OUT/structure; mkdir -p $OUTD
CUT=$R/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson
TE=$(python3 -c "
import json,math
g=json.load(open('$CUT'));xs=[];ys=[]
def walk(c):
    if isinstance(c[0],(int,float)): xs.append(c[0]); ys.append(c[1])
    else: [walk(k) for k in c]
for f in g['features']: walk(f['geometry']['coordinates'])
print(math.floor(min(xs)/30)*30-300, math.floor(min(ys)/30)*30-300, math.ceil(max(xs)/30)*30+300, math.ceil(max(ys)/30)*30+300)")
echo "extent $TE"
CO="-of GTiff -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS -multi -wm 4096"
case $1 in
  0) gdalwarp -overwrite -t_srs EPSG:3979 -te $TE -tr 30 30 -r average -ot Float32 -srcnodata 255 -dstnodata -1 $CO $R/meta_chmv2/chm_menb.vrt $OUTD/chm_mean30.tif.part && mv $OUTD/chm_mean30.tif.part $OUTD/chm_mean30.tif ;;
  1) gdalwarp -overwrite -t_srs EPSG:3979 -te $TE -tr 30 30 -r max -ot Byte -srcnodata 255 -dstnodata 255 $CO $R/meta_chmv2/chm_menb.vrt $OUTD/chm_max30.tif.part && mv $OUTD/chm_max30.tif.part $OUTD/chm_max30.tif ;;
  2) gdalwarp -overwrite -t_srs EPSG:3979 -te $TE -tr 30 30 -r rms -ot Float32 -srcnodata 255 -dstnodata -1 $CO $R/meta_chmv2/chm_menb.vrt $OUTD/chm_rms30.tif.part && mv $OUTD/chm_rms30.tif.part $OUTD/chm_rms30.tif ;;
  3) gdalwarp -overwrite -t_srs EPSG:3979 -te $TE -tr 30 30 -r near -ot Byte $CO $R/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt $OUTD/lossyear30.tif.part && mv $OUTD/lossyear30.tif.part $OUTD/lossyear30.tif ;;
esac
F=$(case $1 in 0) echo chm_mean30;; 1) echo chm_max30;; 2) echo chm_rms30;; 3) echo lossyear30;; esac); test -s $OUTD/$F.tif || { echo "S7A FAIL $1"; exit 3; }
gdalinfo -stats $OUTD/$F.tif | grep -E "STATISTICS_(MIN|MAX|MEAN)"
echo S7A_DONE $1
