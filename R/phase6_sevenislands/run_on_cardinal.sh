#!/bin/bash
# =============================================================================
# Cardinal-side runner for Phase 6 Seven Islands wall-to-wall prediction.
# Source the lmod profile, load gcc -> gdal -> R in that order, run the script.
#
# Usage (from local machine):
#   ssh -F ~/.ssh/config cardinal "bash -s" < run_on_cardinal.sh
# Or copy to Cardinal and run interactively.
# =============================================================================
set -euo pipefail

source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0
module load gdal/3.7.3
module load R/4.4.0

cd /users/PUOM0008/crsfaaron/LSOG

# Make sure phase 6 output dir exists and the script is on Cardinal.
mkdir -p output_phase6

# Pull latest from origin if newer (assumes scripts/02_cardinal_wall_to_wall.R is committed).
git pull --rebase origin master || true

Rscript --vanilla R/phase6_sevenislands/02_cardinal_wall_to_wall.R 2>&1 \
  | tee output_phase6/run_$(date +%Y%m%d_%H%M%S).log

# Pull outputs back to Cowork-mountable location (or use rsync to Aaron's laptop).
ls -lh output_phase6/

echo "Phase 6 wall-to-wall done. Transfer the GeoTIFFs back to local with:"
echo "  rsync -av cardinal:/users/PUOM0008/crsfaaron/LSOG/output_phase6/ ~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/phase6_sevenislands/outputs/"
