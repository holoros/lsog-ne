#!/bin/bash
# Download the three ORNL DAAC dataset 2498 COGs to ~/LSOG/data/rasters/ornl_2498/
# Auth via ~/.netrc with machine urs.earthdata.nasa.gov.
#
# Usage:
#   bash scripts/download_ornl2498.sh           # download all three
#   bash scripts/download_ornl2498.sh --test    # download only the small strata file
#   bash scripts/download_ornl2498.sh --resume  # skip files already present and >1MB

set -e

URL_BASE="https://data.ornldaac.earthdata.nasa.gov/protected/global_vegetation/OldGrowth_MatureForest_Maps_US/data"
DEST="$HOME/LSOG/data/rasters/ornl_2498"
LOG="$HOME/LSOG/logs/ornl2498_download.log"
mkdir -p "$DEST" "$(dirname "$LOG")"

ALL_FILES=(
  "CONUS_mature_old_growth_strata_0100m.tif"
  "CONUS_mature_old_growth_proportions_5000m.tif"
  "CONUS_mature_old_growth_probabilities_0100m.tif"
)

case "${1:-}" in
  --test)   FILES=("CONUS_mature_old_growth_strata_0100m.tif") ;;
  *)        FILES=("${ALL_FILES[@]}") ;;
esac

ts() { date "+%F %T"; }

# Reset cookies; URS will issue fresh ones via .netrc on the auth redirect.
> "$HOME/.urs_cookies"
chmod 600 "$HOME/.urs_cookies"

cd "$DEST"
for f in "${FILES[@]}"; do
  if [ -f "$f" ] && [ "$(stat -c%s "$f")" -gt 1048576 ]; then
    echo "$(ts) skip $f (already $(du -h "$f" | cut -f1))" | tee -a "$LOG"
    continue
  fi
  echo "$(ts) start $f" | tee -a "$LOG"
  rm -f "$f.part" "$f"
  if wget --load-cookies "$HOME/.urs_cookies" --save-cookies "$HOME/.urs_cookies" \
          --keep-session-cookies --auth-no-challenge=on \
          -O "$f.part" "$URL_BASE/$f"; then
    mv "$f.part" "$f"
    echo "$(ts) done $f ($(du -h "$f" | cut -f1))" | tee -a "$LOG"
  else
    echo "$(ts) FAIL $f - check ~/.netrc password and rerun scripts/refresh_earthdata_netrc.sh" | tee -a "$LOG"
    exit 1
  fi
done
echo "$(ts) ALL DONE" | tee -a "$LOG"
