#!/bin/bash
#SBATCH --job-name=lsog_phase11b
#SBATCH --time=00:30:00
#SBATCH --mem=32G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/phase11b_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/phase11b_%j.err

set -euo pipefail
module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG
Rscript --vanilla R/phase11b_finish.r
echo "PHASE11B_EXIT=$?"
