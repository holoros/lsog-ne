#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d4
#SBATCH -t 24:00:00
#SBATCH --mem=96G
#SBATCH -c 24
#SBATCH --array=0-33%12
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d4_%A_%a.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d4_me_xp_predict.py $SLURM_ARRAY_TASK_ID
