#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=h2_post
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/h2_post_%j.log
# Runs after the SDX download job: EarthDEM canopy metrics (Python array step), then H2 scoring in R.
cd ~/LSOG/2026-10-22_csda-pilot && python3 scripts/s9_chm_metrics.py && module purge && module load gcc/12.3.0 R/4.5.2 && Rscript scripts/s10_h2_score.R
