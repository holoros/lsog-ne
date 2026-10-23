#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=t1_full
#SBATCH --time=00:40:00
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/t1_full_%j.log
cd /users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot && python3 scripts/t1_synthetic_test.py && CSDA_DIR=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/TEST python3 scripts/s9_chm_metrics.py && module purge && module load gcc/12.3.0 R/4.5.2 && CSDA_DIR=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/TEST Rscript scripts/s10_h2_score.R
