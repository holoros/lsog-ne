#!/usr/bin/env bash
# run_step_nb.sh STEP [args]  System python3 (scikit-learn 1.6.1), the interpreter Stage A fitted under.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config.sh"
module purge; module load gcc/12.3.0 gdal/3.7.3
unset PROJ_LIB PROJ_DATA GDAL_DATA
PY=/usr/bin/python3
step="$1"; shift
case "$step" in
  s3)  $PY "$HERE/s3_predict_tiles_nb_trans_10m.py" "$1" "$(( $1 + 1 ))" ;;
  s4)  $PY "$HERE/s4_mosaic_mask_gate_nb_trans.py" ;;
  s5)  $PY "$HERE/s5_share_bootstrap_interval_nb_trans.py" ;;
  *)   echo "unknown step $step"; exit 1 ;;
esac
