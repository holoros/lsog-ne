#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d19
#SBATCH -t 02:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d19_d20_%j.log
set -u
source /users/PUOM0008/crsfaaron/LSOG/2026-11-06_retrain/scripts/env_rt.sh
export DS_SCR=/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13
/usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d19_build_30m.py && /usr/bin/python3 -u ~/LSOG/2026-11-13_definition-map-sensitivity/scripts/d20_release30_test.py
