#!/bin/bash
#SBATCH --job-name=nbt_s4
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=25
#SBATCH --mem=120G
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-10m_2026-09-27/logs/s4_%j.out
bash /users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/run_step_nb.sh s4
