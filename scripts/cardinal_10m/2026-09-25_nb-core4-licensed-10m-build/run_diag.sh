#!/bin/bash
#SBATCH --job-name=nb_diag --account=PUOM0008 --time=00:40:00 --cpus-per-task=8 --mem=24G
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-10m_2026-09-25/logs/diag_%j.log
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
cd ~/LSOG/2026-09-25_nb-core4-licensed-10m-build
/usr/bin/python3 -u diag_block_residual_structure.py
