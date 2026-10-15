#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J rl_fit
#SBATCH -t 06:00:00
#SBATCH --mem=96G
#SBATCH -c 32
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r1_%j.log
source /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/env.sh
md5sum $TRAIN_TABLE $OCC_CSV /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/r1_fit_v5.py /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/r5_xp_fit.py
for s in r1_fit_v5 r5_xp_fit; do echo "== $s $(date)"; /usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/$s.py || { echo "FAIL $s"; exit 1; }; done
for s in r8a_fit_compare r8b_fia_only r8c_grouping r11a_me_table r11b_xj_oof; do echo "== $s $(date)"; /usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/$s.py || echo "FAIL $s"; done
echo "R1 END $(date)"
