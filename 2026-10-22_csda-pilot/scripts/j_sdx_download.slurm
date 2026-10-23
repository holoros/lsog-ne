#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=sdx_dl
#SBATCH --time=08:00:00
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/sdx_dl_%j.log
cd ~/LSOG/2026-10-22_csda-pilot && python3 scripts/s5_sdx_download.py
