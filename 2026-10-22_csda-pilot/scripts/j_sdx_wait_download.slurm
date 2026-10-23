#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --job-name=sdx_wait_dl
#SBATCH --time=23:00:00
#SBATCH --ntasks=1
#SBATCH --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/LSOG/2026-10-22_csda-pilot/logs/sdx_wait_dl_%j.log
# Waits for Aaron to place ~/.sdx_token, then checks it and runs the clipped download.
cd ~/LSOG/2026-10-22_csda-pilot
for i in $(seq 1 240); do
  if [ -s ~/.sdx_token ]; then
    echo "token found $(date)"; python3 scripts/s5_sdx_download.py --check && python3 scripts/s5_sdx_download.py; exit $?
  fi
  sleep 300
done
echo "no token after 20 h"; exit 2
