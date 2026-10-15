#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J zen_v100r
#SBATCH -t 08:00:00
#SBATCH --mem=8G
#SBATCH -c 2
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/zen_v100r_%j.log
# Relabel refresh of UNPUBLISHED draft 23209841 (never publishes). Runs after the tile job's checksum gate.
cd /users/PUOM0008/crsfaaron/LSOG/products/me-ordinal-lsog-v4c_2026-10-07/zenodo_upload
grep -q "CHECKSUM MATCH occ-ordinal-v5xp" /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r13_15446816.log || { echo "v5xp checksum not confirmed"; exit 3; }
touch README.md
/usr/bin/python3 check_deposit.py > /dev/null 2>&1; grep -E "FAIL|RESULT|pass G" check_deposit_log.txt
grep -q "ALL GATES PASS" check_deposit_log.txt || { echo GATES_FAILED; exit 2; }
for i in 1 2; do /usr/bin/python3 -u zenodo_draft_v100.py && break; echo "retry pass $i"; sleep 300; done
echo EXIT $?
