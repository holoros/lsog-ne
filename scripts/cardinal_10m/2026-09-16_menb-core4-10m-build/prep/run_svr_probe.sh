#!/usr/bin/env bash
set -euo pipefail
H=~/LSOG/2026-09-16_menb-core4-10m-build; source $H/config.sh
module purge; module load gcc/12.3.0 gdal/3.7.3
eval "$PY_ACTIVATE"
python3 $H/prep/svr_cost_probe.py
