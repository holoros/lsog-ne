#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d8
#SBATCH -t 24:00:00
#SBATCH --mem=96G
#SBATCH -c 24
#SBATCH --array=0-40%12
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d8_%A_%a.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
export GFC_VRT=/fs/scratch/PUOM0008/crsfaaron/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt
export NB_TILE_LIST=/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-tsd2024-10m_2026-10-05/s3_tile_list.csv
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d8_nb_xp_predict.py $SLURM_ARRAY_TASK_ID
