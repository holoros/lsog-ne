#!/bin/bash
#SBATCH --job-name=lsog_phase15
#SBATCH --time=00:40:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/phase15_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/phase15_%j.err
set -euo pipefail
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG
Rscript --vanilla R/phase15_accuracy_auc.r
echo "PHASE15_EXIT=$?"
