#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=t1_s10
#SBATCH --time=00:30:00
#SBATCH --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/t1_s10_%j.log
module purge; module load gcc/12.3.0 R/4.5.2
cd /users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot && CSDA_DIR=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/TEST Rscript scripts/s10_h2_score.R
