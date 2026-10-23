#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=acq_conf
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --mem=4G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/acq_%j.log
module purge; module load gcc/12.3.0 R/4.5.2
cd ~/LSOG/2026-10-22_csda-pilot && Rscript scripts/s7_lidar_acq_confound.R
