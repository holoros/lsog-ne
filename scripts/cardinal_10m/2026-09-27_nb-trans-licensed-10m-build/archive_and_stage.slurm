#!/bin/bash
#SBATCH --job-name=nbt_arch
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/archive_%j.log
set -euo pipefail
B=/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-10m_2026-09-27
H=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build
P=/users/PUOM0008/crsfaaron/LSOG/products/nb-trans-licensed-10m_2026-09-27
cp -p $B/final/* $P/
cp -p $B/trans_training_table_DATA_2026-09-27.csv $B/env_min.npy $B/env_max.npy $B/rf_trans_final_2026-09-27.pkl $B/rf_trans_boot_2026-09-27.pkl \
      $B/s1_prep_summary_2026-09-27.json $B/s2_rf_summary_2026-09-27.json $B/s2_rf_oof_DATA_2026-09-27.csv $P/stageA/
chmod 600 $P/stageA/trans_training_table_DATA_2026-09-27.csv $P/stageA/s2_rf_oof_DATA_2026-09-27.csv
cp -p $H/*.py $H/*.sh $H/*.slurm $P/code/
cp -rp $B/stress_2026-09-27 $P/diagnostics/; cp -p $B/s3_tile_list.csv $P/diagnostics/
( cd $B/final && sha256sum -c SHA256SUMS.txt ) && ( cd $P && sha256sum -c SHA256SUMS.txt )
( cd $P && find . -path ./zenodo_upload -prune -o -type f -print | sort | xargs sha256sum > MANIFEST_SHA256_20260927.txt )
echo ARCHIVE_DONE
bash $P/zenodo_upload/assemble_zenodo_pkg.sh || echo "ASSEMBLE_EXIT $?"
echo STAGE_DONE
