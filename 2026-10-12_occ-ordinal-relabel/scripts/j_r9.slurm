#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J rl_r9
#SBATCH -t 08:00:00
#SBATCH --mem=128G
#SBATCH -c 16
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r9_%j.log
source /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/env.sh
module load gdal/3.7.3 2>/dev/null; unset PROJ_LIB PROJ_DATA GDAL_DATA
for s in r9_silc_compare r10_fh_crossfit; do echo "== $s $(date)"; /usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/$s.py || { echo "FAIL $s"; exit 1; }; done
echo "END $(date)"
