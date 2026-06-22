#!/bin/bash
#SBATCH --job-name=lsog_phase12
#SBATCH --time=02:00:00
#SBATCH --mem=110G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/phase12_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/phase12_%j.err
set -euo pipefail
module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG
Rscript --vanilla R/phase12_uncertainty_3method.r
echo "PHASE12_EXIT=$?"
