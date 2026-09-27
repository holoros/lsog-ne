#!/usr/bin/env bash
H=~/LSOG/2026-09-16_menb-core4-10m-build; source $H/config.sh; eval "$PY_ACTIVATE"
python3 $H/prep/aef_pixcheck_cardinal.py > /fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/prep/aef_pixcheck.log 2>&1
