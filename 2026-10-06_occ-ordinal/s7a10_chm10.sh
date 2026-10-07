#!/bin/bash
# s7a10_chm10.sh LAYER STRIP  Meta CHM v2 (1.19 m, EPSG:3857) summarized to a 10 m EPSG:3979 grid, from full
# resolution (-ovr NONE). Aaron, 6 October 2026: run everything at the finer resolution, then aggregate.
#   LAYER 0 mean, 1 max, 2 rms (SD is formed downstream as sqrt(rms^2 - mean^2))
#   STRIP 0..3: four north-south strips of the Maine extent, run in parallel and joined by a VRT
# F7: Meta CHM v2 codes no data as 255; it is declared as source nodata so it never enters a summary.
# F2: absent tiles read as 0 m; downstream treats mean 0 and max 0 as missing. Output nodata is -1 (Float32) or 255 (Byte).
# Grid: -tap at 10 m is aligned with the 30 m M3 frame (origin 1739670, 558510 is a multiple of 30 m).
set -eu
L=$1; S=$2
R=/fs/scratch/PUOM0008/crsfaaron; OUTD=$OUT/structure10; mkdir -p $OUTD
X0=1860720; Y0=-291180; X1=2187210; Y1=238830          # same Maine extent as the 30 m build (s7a log)
H=$(( (Y1 - Y0) / 4 )); H=$(( H / 30 * 30 ))
YA=$(( Y0 + S * H )); YB=$(( S == 3 ? Y1 : Y0 + (S + 1) * H ))
NAME=$(case $L in 0) echo mean;; 1) echo max;; 2) echo rms;; esac)
RS=$(case $L in 0) echo average;; 1) echo max;; 2) echo rms;; esac)
OT=$(case $L in 1) echo "Byte -dstnodata 255";; *) echo "Float32 -dstnodata -1";; esac)
OUTF=$OUTD/chm_${NAME}10_s${S}.tif
gdalwarp -overwrite -of GTiff -ovr NONE -t_srs EPSG:3979 -te $X0 $YA $X1 $YB -tr 10 10 -r $RS -srcnodata 255 -ot $OT \
  -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS -multi -wm 4096 \
  $R/meta_chmv2/chm_menb.vrt $OUTF.part
mv $OUTF.part $OUTF
test -s $OUTF || { echo "S7A10 FAIL $L $S"; exit 3; }
gdalinfo -stats $OUTF | grep -E "STATISTICS_(MIN|MAX|MEAN)"
echo S7A10_DONE $NAME $S
