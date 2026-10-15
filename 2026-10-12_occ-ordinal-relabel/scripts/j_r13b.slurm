#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J r13b
#SBATCH -t 04:00:00
#SBATCH --mem=32G
#SBATCH -c 8
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r13b_%j.log
source /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/env.sh
bash /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/r13b_resplit_6strips.sh; echo "rc $? END $(date)"
