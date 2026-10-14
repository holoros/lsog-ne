#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J zen_v100r2
#SBATCH -t 16:00:00
#SBATCH --mem=8G
#SBATCH -c 2
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/zen_v100r_%j.log
# Relabel refresh of UNPUBLISHED draft 23209841 (never publishes). Runs after the tile job's checksum gate.
cd /users/PUOM0008/crsfaaron/LSOG/products/me-ordinal-lsog-v4c_2026-10-07/zenodo_upload
grep -q "CHECKSUM MATCH occ-ordinal-v5xp" /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r13_15446816.log || { echo "v5xp checksum not confirmed"; exit 3; }
ls -la check_deposit_log.txt

grep -q "ALL GATES PASS" check_deposit_log.txt || { echo GATES_FAILED; exit 2; }
/usr/bin/python3 -u /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/zen_draft_v100r_resilient.py
echo EXIT $?
