#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d7
#SBATCH -t 03:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=96G
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d7_%j.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
module purge > /dev/null 2>&1; unset PROJ_LIB PROJ_DATA GDAL_DATA
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d7_nb_xp_fit.py
