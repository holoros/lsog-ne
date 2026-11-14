#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=defsens_me_gate
#SBATCH --time=00:30:00
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d2_%j.log
cd ~/LSOG/2026-11-13_definition-map-sensitivity
module purge; module load gcc/12.3.0 R/4.5.2
Rscript scripts/d2_me_gate.R
