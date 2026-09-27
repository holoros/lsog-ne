#!/usr/bin/env bash
# run_s2c.sh  Wrapper for the added blocked learner comparison (kept separate from run_step.sh,
# which was in use by running jobs when s2c was added on 2026-09-16).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config.sh"
module purge; module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
eval "$PY_ACTIVATE"
python3 "$HERE/s2c_learner_compare_blocked.py"
