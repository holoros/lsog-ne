#!/bin/bash
#SBATCH --job-name=p19
#SBATCH --time=01:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/logs/p19_%j.out
#SBATCH --error=/users/PUOM0008/crsfaaron/LSOG/logs/p19_%j.err
set -euo pipefail
module load gcc/12.3.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1 R/4.4.0
cd /users/PUOM0008/crsfaaron/LSOG && Rscript --vanilla R/phase19_ownership_stress.r
