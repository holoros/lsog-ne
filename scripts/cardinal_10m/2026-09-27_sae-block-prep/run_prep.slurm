#!/bin/bash
#SBATCH --job-name=sae_prep
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_sae-block-prep/prep_%j.log
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
/usr/bin/python3 /users/PUOM0008/crsfaaron/LSOG/2026-09-27_sae-block-prep/sae_block_prep.py ${SURFS}
