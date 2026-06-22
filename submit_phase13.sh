#!/bin/bash
#SBATCH --job-name=lsog_phase13
#SBATCH --time=02:30:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/phase13_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/phase13_%j.err
set -euo pipefail
module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG
Rscript --vanilla R/phase13_treemap_consensus.r
echo "PHASE13_EXIT=$?"
