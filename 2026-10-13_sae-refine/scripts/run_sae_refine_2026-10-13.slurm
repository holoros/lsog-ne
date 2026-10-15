#!/bin/bash
#SBATCH --job-name=sae_refine
#SBATCH --account=PUOM0008
#SBATCH --time=03:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-13_sae-refine/logs/refine_%j.log
# Submit with --export=ALL,SAE_NBOOT=20 for a smoke test, default 500 for the run.
set -euo pipefail
umask 077
T=/users/PUOM0008/crsfaaron/LSOG/2026-10-13_sae-refine
echo "host $(hostname) $(date) NBOOT ${SAE_NBOOT:-500}"
cd $T/scripts && md5sum *.py *.R
module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=1
cd $T/out && Rscript --vanilla -e 'Sys.setenv(R_LIBS_USER="/users/PUOM0008/crsfaaron/R/rhel9/4.5.2"); .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths())); source("../scripts/sae_refine_2026-10-13.R")'
echo JOB_DONE
