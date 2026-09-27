#!/usr/bin/env bash
H=~/LSOG/2026-09-16_menb-core4-10m-build; source $H/config.sh; module purge; module load gcc/12.3.0 gdal/3.7.3 R/4.4.0; eval "$PY_ACTIVATE"
python3 $H/prep/s4_diag2.py
