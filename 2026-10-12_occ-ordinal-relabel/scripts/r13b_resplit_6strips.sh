#!/usr/bin/env bash
# r13b_resplit_6strips.sh  Fallback for Zenodo 502s on >1 GB PUTs (October 12, 2026). Splits strips 2 and 3 of each Maine
# 10 m layer into row halves, giving six strips per layer (largest about 0.87 GB). Lossless; the new VRT's band checksums
# must equal the source GeoTIFF's. Writes to zenodo_tiles6/ and leaves the four-strip set untouched.
set -euo pipefail
T4=/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/zenodo_tiles; T=/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/zenodo_tiles6
mkdir -p $T; cd $T
CO="-co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 -co TILED=YES -co BIGTIFF=YES"
for pair in "final:occ-ordinal-v5-lsog-areacal_10m_ME_DATA_2026-10-12" "finalxp:occ-ordinal-v5xp-lsog-areacal_10m_ME_DATA_2026-10-12"; do
  d=${pair%%:*}; B=${pair##*:}; SRC=/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/$d/$B.tif
  read X Y < <(gdalinfo $SRC | awk '/Size is/{gsub(",","");print $3, $4}'); H=$(( (Y + 3) / 4 ))
  n=0; list=""
  for i in 1 2 3 4; do off=$(( (i - 1) * H )); h=$(( off + H > Y ? Y - off : H ))
    if [ $i -eq 2 ] || [ $i -eq 3 ]; then h1=$(( h / 2 )); h2=$(( h - h1 ))
      n=$((n+1)); gdal_translate -q -srcwin 0 $off $X $h1 $CO $SRC ${B}_part$n.tif; list="$list ${B}_part$n.tif"
      n=$((n+1)); gdal_translate -q -srcwin 0 $((off + h1)) $X $h2 $CO $SRC ${B}_part$n.tif; list="$list ${B}_part$n.tif"
    else n=$((n+1)); cp $T4/${B}_part$i.tif ${B}_part$n.tif; list="$list ${B}_part$n.tif"; fi
  done
  gdalbuildvrt -q $B.vrt $list; sed -i 's#relativeToVRT="0"#relativeToVRT="1"#g' $B.vrt
  a=$(gdalinfo -checksum $SRC | grep Checksum | tr '\n' ' '); b=$(gdalinfo -checksum $B.vrt | grep Checksum | tr '\n' ' ')
  echo "$B src: $a"; echo "$B vrt: $b"; [ "$a" == "$b" ] && echo "CHECKSUM MATCH $B" || { echo "CHECKSUM MISMATCH $B"; exit 3; }
done; ls -la $T
