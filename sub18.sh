#!/bin/bash
#SBATCH --job-name=p18
#SBATCH --time=00:40:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/p18_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/p18_%j.err
set -euo pipefail
module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1 R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG && Rscript --vanilla R/phase18_hex.r
