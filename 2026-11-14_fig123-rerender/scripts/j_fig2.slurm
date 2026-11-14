#!/bin/bash
#SBATCH --job-name=fig123
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-11-14_fig123-rerender/logs/fig123_%j.log
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1 R/4.4.0
cd ~/LSOG/2026-11-14_fig123-rerender
Rscript scripts/fig2_rebuild_v3.R
