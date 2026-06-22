#!/bin/bash
#SBATCH --job-name=lsog_phase10
#SBATCH --time=02:30:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/phase10_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/phase10_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

set -euo pipefail
module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0

cd /users/PUOM0008/crsfaaron/LSOG
Rscript --vanilla R/phase10_hagan_reproduction.r
echo "PHASE10_EXIT=$?"
