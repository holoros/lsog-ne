#!/bin/bash
#SBATCH --job-name=nbt_s5
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-10m_2026-09-27/logs/s5stress_%j.out
set -euo pipefail
bash /users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/run_step_nb.sh s5
source /users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/config.sh; module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
/usr/bin/python3 /users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/stress_test_nb_trans.py
