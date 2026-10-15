#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH -J rl_r10b
#SBATCH -t 02:00:00
#SBATCH --mem=32G
#SBATCH -c 16
#SBATCH -o /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/logs/r10b_%j.log
source /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/env.sh
module purge; module load gcc/12.3.0 R/4.5.2; export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript /users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/scripts/r10b_fh_fit.R $OUT; echo "rc $? END $(date)"
