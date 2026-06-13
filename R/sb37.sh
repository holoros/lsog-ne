#!/bin/bash
#SBATCH --job-name=lsog_dual
#SBATCH --time=00:30:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --account=PUOM0008
#SBATCH --output=/fs/scratch/PUOM0008/crsfaaron/LCMS_TSD/sb37_%j.out
source /etc/profile.d/lmod.sh; module purge
module load gcc/12.3.0; module load gdal/3.7.3 geos/3.12.0 proj/9.2.1; module load R/4.4.0
cd ~/LSOG && Rscript --vanilla R/phase37_dualmap.R
