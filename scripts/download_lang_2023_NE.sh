#!/bin/bash
# Stub: paste tile URLs from https://langnico.github.io/globalcanopyheight/assets/tile_index.html
# Click each tile covering Maine, NH, VT, NY and copy the "Map" (canopy height)
# download links into the URLS array below. URLs typically look like:
#   https://share.phys.ethz.ch/~pf/nlangdata/ETH_GlobalCanopyHeight_10m_2020_version1/
#   3deg_cogs/ETH_GlobalCanopyHeight_10m_2020_N48W072_Map.tif
# but the actual base path on the ETH research collection may differ; copy
# the live URLs from the click-map.

set -e
DEST="$HOME/LSOG/data/rasters/lang_2023"
mkdir -p "$DEST"
cd "$DEST"

URLS=(
  # "https://example.com/.../ETH_GlobalCanopyHeight_10m_2020_N48W072_Map.tif"
  # "https://example.com/.../ETH_GlobalCanopyHeight_10m_2020_N45W072_Map.tif"
  # "https://example.com/.../ETH_GlobalCanopyHeight_10m_2020_N48W075_Map.tif"
  # "https://example.com/.../ETH_GlobalCanopyHeight_10m_2020_N45W075_Map.tif"
  # "https://example.com/.../ETH_GlobalCanopyHeight_10m_2020_N42W075_Map.tif"
)

if [ ${#URLS[@]} -eq 0 ]; then
  echo "Edit this script first: paste the canopy-height tile URLs into URLS=()"
  exit 1
fi

for u in "${URLS[@]}"; do
  f=$(basename "$u")
  if [ -f "$f" ] && [ "$(stat -c%s "$f")" -gt 1000 ]; then
    echo "skip $f"
  else
    echo "fetching $f"
    wget -q -O "$f.part" "$u" && mv "$f.part" "$f"
  fi
done

echo
echo "tiles in $DEST:"
ls -lh

# Build a virtual raster mosaic for fast extraction
gdalbuildvrt lang_NE.vrt *.tif
echo "VRT: $(realpath lang_NE.vrt)"
