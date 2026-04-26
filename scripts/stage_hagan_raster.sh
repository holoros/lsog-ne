#!/bin/bash
# Stub: place the Hagan et al. 2024 LSOG 100m raster at:
#   ~/LSOG/data/rasters/hagan_lsog/hagan_lsog_100m.tif
#
# Acquisition path (since the raster is not in a public archive):
# 1. Email John Hagan / Our Climate Common at info@ourclimatecommon.org
#    referencing Hagan et al. 2024 (Maine LSOG report).
# 2. Or via the LD 1529 / Maine DACF stakeholder working group.
# 3. The Thompson team (Harvard Forest) holds a copy too; they were the
#    primary downstream user in Thompson et al. 2026.
#
# Once the file is in hand, transfer to Cardinal:
#   scp hagan_lsog_100m.tif crsfaaron@cardinal.osc.edu:~/LSOG/data/rasters/hagan_lsog/
#
# Then run:
#   bash scripts/stage_hagan_raster.sh   (verifies presence)
#   Rscript --vanilla R/phase6_hagan_extract.r

set -e
DEST="$HOME/LSOG/data/rasters/hagan_lsog"
mkdir -p "$DEST"

if [ ! -f "$DEST/hagan_lsog_100m.tif" ]; then
  echo "Hagan raster missing at $DEST/hagan_lsog_100m.tif"
  echo "Place the GeoTIFF there, then re-run."
  exit 1
fi

echo "Hagan raster found:"
ls -lh "$DEST/hagan_lsog_100m.tif"
source /etc/profile.d/lmod.sh
module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
gdalinfo "$DEST/hagan_lsog_100m.tif" | head -15
echo
echo "Class value histogram (run R/phase6_hagan_extract.r to do plot-level extraction):"
gdalinfo -stats "$DEST/hagan_lsog_100m.tif" 2>&1 | grep -E "Min|Max|STATISTICS_" | head
