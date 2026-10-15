#!/bin/bash
#SBATCH --job-name=fh_relabel
#SBATCH --account=PUOM0008
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-12_fh-relabel/logs/fhr_%x_%j.log
# run_fhrelabel_2026-10-12.slurm (track fh-relabel). Copies of the October 5 chain:
#   sae_block_prep_2026-10-12.py -> sae_fh_2026-10-12.R -> fhx_oof_2026-10-12.py -> fhx_fit_2026-10-12.R -> fhx_promote_2026-10-12.R
# Submit with --export=ALL,FHR_MODE=old first (reproduction gate against the October 5 outputs), then FHR_MODE=new.
# Resources are the prep job's (run_prep.slurm); module and R settings are those of fhx_run_2026-10-05.slurm.
set -euo pipefail
umask 077
T=/users/PUOM0008/crsfaaron/LSOG/2026-10-12_fh-relabel
SC=$T/scripts
MODE=${FHR_MODE:?set FHR_MODE to old or new}
if [ "$MODE" = old ]; then OUTD=$T/out/repro_old; else OUTD=$T/out; fi
mkdir -p $OUTD
echo "MODE $MODE  OUT $OUTD  host $(hostname)  $(date)"
cd $SC && md5sum *.py *.R *.slurm
if [ "$MODE" = new ]; then
  [ -f $T/out/REPRO_GATE_PASS_2026-10-12.txt ] || { echo "GATE FAIL reproduction gate has not passed"; exit 2; }
  F=/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r/final
  [ -f $F/me-transitioning-and-above-probability_10m_ME_DATA_2026-10-12.tif ] || { echo "GATE FAIL rebuilt surface missing"; exit 2; }
  /usr/bin/python3 -c "import json,sys; g=json.load(open('$F/me-transitioning-10m-build-summary_DATA_2026-10-12.json'))['gates']; print(g); sys.exit(0 if g and all(g.values()) else 2)" || { echo "GATE FAIL surface build gates"; exit 2; }
  md5sum $F/me-transitioning-and-above-probability_10m_ME_DATA_2026-10-12.tif
fi
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
export FHR_MODE=$MODE
/usr/bin/python3 $SC/sae_block_prep_2026-10-12.py ME_TRANS
module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
(cd $OUTD && Rscript --vanilla $SC/sae_fh_2026-10-12.R $OUTD $OUTD)
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
/usr/bin/python3 $SC/fhx_oof_2026-10-12.py
module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript $SC/fhx_fit_2026-10-12.R $T $OUTD
Rscript $SC/fhx_promote_2026-10-12.R
if [ "$MODE" = old ]; then
  Rscript $SC/repro_gate_2026-10-12.R
else
  Rscript $SC/fh_relabel_compare_2026-10-12.R
  module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
  /usr/bin/python3 $SC/check_record_2026-10-12.py
fi
echo JOB_DONE
