#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d10
#SBATCH -t 03:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=160G
#SBATCH --array=0-1
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d10_%A_%a.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
J=(me nb)
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d10_stress.py ${J[$SLURM_ARRAY_TASK_ID]}
