#!/usr/bin/env bash
# run_step.sh STEP [args]  Loads modules and the Python env, then runs one step. Used by submit_chain.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config.sh"
module purge; module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
eval "$PY_ACTIVATE"
step="$1"; shift
case "$step" in
  s1)  Rscript "$HERE/s1_labels_weights_core4.R" ;;
  s2)  python3 "$HERE/s2_fit_rf_core4.py" ;;
  s2b) bash "$HERE/s2b_mosvr_compare.sh" ;;
  s2c) python3 "$HERE/s2c_learner_compare_blocked.py" ;;
  s2d) python3 "$HERE/s2d_mosvr_retune_blocked.py" ;;
  s3a) python3 "$HERE/s3a_frame_check.py" ;;
  s3)  python3 "$HERE/s3_predict_tiles_10m.py" "$1" "$(( $1 + 1 ))" ;;
  s4)  python3 "$HERE/s4_mosaic_mask_gate.py" ;;
  s5)  python3 "$HERE/s5_share_bootstrap_interval.py" ;;
  *)   echo "unknown step $step"; exit 1 ;;
esac
