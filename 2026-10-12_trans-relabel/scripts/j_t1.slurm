#!/bin/bash
#SBATCH --job-name=t1_stageA
#SBATCH --account=PUOM0008
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=96G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-12_trans-relabel/logs/t1_%j.log
set -u
module purge > /dev/null 2>&1
unset PROJ_LIB PROJ_DATA GDAL_DATA
mkdir -p /fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r
/usr/bin/python3 -c 'import sklearn; assert sklearn.__version__=="1.6.1"'
/usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_trans-relabel/scripts/t1_stageA_relabel.py
echo "exit $?  end $(date)"
