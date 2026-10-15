#!/bin/bash
#SBATCH --job-name=saeref_rebuild
#SBATCH --account=PUOM0008
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=24
#SBATCH --mem=60G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-13_sae-refine/logs/rebuild_%j.log
set -euo pipefail
umask 077
T=/users/PUOM0008/crsfaaron/LSOG/2026-10-13_sae-refine
module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript $T/scripts/pkgcheck.R
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
/usr/bin/python3 -c "import h3, sklearn; print('h3', h3.__version__, 'sklearn', sklearn.__version__)"
/usr/bin/python3 $T/scripts/plot_rebuild_2026-10-13.py
echo JOB_DONE

