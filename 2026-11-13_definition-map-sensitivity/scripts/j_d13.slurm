#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J defsens_d13
#SBATCH -t 00:20:00
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d13_%j.log
cd ~/LSOG/2026-11-13_definition-map-sensitivity
module purge; module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1 R/4.4.0
module list 2>&1 | tail -3
Rscript scripts/d13_figure.R
