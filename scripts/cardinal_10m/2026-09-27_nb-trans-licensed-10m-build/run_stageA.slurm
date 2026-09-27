#!/bin/bash
#SBATCH --job-name=nbtrans_A
#SBATCH --account=PUOM0008
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build/stageA_%j.log
set -euo pipefail
HERE=/users/PUOM0008/crsfaaron/LSOG/2026-09-27_nb-trans-licensed-10m-build
source $HERE/config.sh
module purge; module load gcc/12.3.0 gdal/3.7.3; unset PROJ_LIB PROJ_DATA GDAL_DATA
/usr/bin/python3 -c "import sklearn; print('sklearn', sklearn.__version__)"
/usr/bin/python3 $HERE/s1_prep_trans_licensed.py
/usr/bin/python3 $HERE/s2_fit_rf_trans_licensed_nbonly.py
