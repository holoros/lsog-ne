#!/bin/bash
#SBATCH --job-name=lsog_phase4
#SBATCH --time=02:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/phase4_%j.out
#SBATCH --error=logs/phase4_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# Default OSC allocation (no --account flag).

set -e
cd ~/LSOG
mkdir -p logs

# Cardinal module setup: gcc must precede gdal; geos/proj are bundled in gdal
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0
module load gdal/3.7.3
module load R/4.4.0
module list

# FIA tables symlink
if [ ! -e data/fia ] && [ -d ~/fia_data ]; then
  ln -sfn ~/fia_data data/fia
fi

# Confirm ORNL raster present
RASTER=~/LSOG/data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m.tif
if [ ! -f "$RASTER" ]; then
  echo "ORNL raster missing; running download script..."
  bash scripts/download_ornl2498.sh
fi

Rscript --vanilla R/phase4_ornl2498_extract.r
