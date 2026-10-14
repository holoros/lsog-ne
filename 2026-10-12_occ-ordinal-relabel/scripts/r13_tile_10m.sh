#!/usr/bin/env bash
# r13_tile_10m.sh  Split the area calibrated 10 m Maine v5 and v5xp layers (relabel, October 12, 2026) into four row strips
# plus a VRT for upload, as tile_10m_v4c.sh and tile_10m_v4xp.sh did; lossless; band checksums of VRT and source compared.
set -euo pipefail
T=/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/zenodo_tiles; cd $T
for pair in "final:occ-ordinal-v5-lsog-areacal_10m_ME_DATA_2026-10-12" "finalxp:occ-ordinal-v5xp-lsog-areacal_10m_ME_DATA_2026-10-12"; do
  d=${pair%%:*}; B=${pair##*:}; SRC=/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/$d/$B.tif
  read X Y < <(gdalinfo $SRC | awk '/Size is/{gsub(",","");print $3, $4}'); H=$(( (Y + 3) / 4 ))
  for i in 1 2 3 4; do off=$(( (i - 1) * H )); h=$(( off + H > Y ? Y - off : H ))
    gdal_translate -q -srcwin 0 $off $X $h -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9 -co TILED=YES -co BIGTIFF=YES $SRC ${B}_part$i.tif; done
  gdalbuildvrt -q $B.vrt ${B}_part1.tif ${B}_part2.tif ${B}_part3.tif ${B}_part4.tif; sed -i 's#relativeToVRT="0"#relativeToVRT="1"#g' $B.vrt
  a=$(gdalinfo -checksum $SRC | grep Checksum | tr '\n' ' '); b=$(gdalinfo -checksum $B.vrt | grep Checksum | tr '\n' ' ')
  echo "$B src: $a"; echo "$B vrt: $b"; [ "$a" == "$b" ] && echo "CHECKSUM MATCH $B" || { echo "CHECKSUM MISMATCH $B"; exit 3; }
done; ls -la $T
