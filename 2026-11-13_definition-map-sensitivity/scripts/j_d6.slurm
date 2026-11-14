#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d6
#SBATCH -t 06:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d6_%j.log
set -u
module purge > /dev/null 2>&1; unset PROJ_LIB PROJ_DATA GDAL_DATA
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d6_nb_labels.py
