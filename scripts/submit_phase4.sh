#!/bin/bash
#SBATCH --job-name=lsog_phase4
#SBATCH --time=02:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/phase4_%j.out
#SBATCH --error=logs/phase4_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

# Defaults: no --account flag (uses user's default OSC allocation).

set -e
cd ~/LSOG
mkdir -p logs

module load gdal/3.7.3 gcc/12.3.0 geos/3.12.0 proj/9.2.1 R/4.4.0

# Make sure FIA tables are reachable as data/fia/<ST>_*.csv
if [ ! -e data/fia ] && [ -d ~/fia_data ]; then
  ln -sf ~/fia_data data/fia
fi

# Make sure the ORNL raster is present (otherwise R script will stop early)
RASTER=~/LSOG/data/rasters/ornl_2498/CONUS_mature_old_growth_probabilities_0100m.tif
if [ ! -f "$RASTER" ]; then
  echo "ORNL raster missing; running download script..."
  bash scripts/download_ornl2498.sh
fi

Rscript --vanilla R/phase4_ornl2498_extract.r
