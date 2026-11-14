#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d16
#SBATCH -t 01:30:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH --array=0-1
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d16_%A_%a.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
J=(me nb)
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d16_plot_checks.py ${J[$SLURM_ARRAY_TASK_ID]}
if [ "$SLURM_ARRAY_TASK_ID" = "0" ]; then module purge; module load gcc/12.3.0 R/4.5.2; cd ~/LSOG/2026-11-13_definition-map-sensitivity; Rscript scripts/d15_me_design_agreement.R; fi
