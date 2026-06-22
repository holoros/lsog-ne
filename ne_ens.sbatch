#!/bin/bash
#SBATCH -J ne_ens
#SBATCH -A PUOM0008
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 8
#SBATCH -t 1:30:00
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/ne_ens_%j.out
module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1 R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG
Rscript R/phase24_ne_ensemble.R
