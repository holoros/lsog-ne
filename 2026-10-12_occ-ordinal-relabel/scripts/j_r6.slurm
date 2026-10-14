#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J rl_xp
#SBATCH -t 12:00:00
#SBATCH --mem=96G
#SBATCH -c 24
#SBATCH --array=0-33%12
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r6_%A_%a.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/env.sh
/usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/r6_xp_predict.py $SLURM_ARRAY_TASK_ID
