#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=defsens_me_labels
#SBATCH --time=01:00:00
#SBATCH --ntasks=1
#SBATCH --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-11-13_definition-map-sensitivity/logs/d1_d2_%j.log
cd ~/LSOG/2026-11-13_definition-map-sensitivity
python3 scripts/d1_me_labels.py || exit 2
module purge; module load gcc/12.3.0 R/4.5.2
Rscript scripts/d2_me_gate.R
