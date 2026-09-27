#!/usr/bin/env bash
# s2b_mosvr_compare.sh  Runs the MOSVR Pareto fit on the same table and applies the house selection rule:
# adopt the learner whose predicted-on-observed slope is closer to 1, and state the RMSE cost.
# The 10 m prediction step (s3) is written for the random forest. If MOSVR wins, the chain stops here,
# since predicting an SVR over roughly 1.4 billion forest cells is a separate compute decision.
set -euo pipefail
source "$(dirname "$0")/config.sh"
FEATS=$(python3 -c "print(','.join([f'AE_{i:02d}' for i in range(64)] + ['time_since_disturbance']))")
Rscript "$MOSVR_SCRIPT" "${BUILD}/s2_mosvr_input_DATA_2026-09-16.csv" core4_cut3 "$FEATS" "${BUILD}/mosvr_output" 4000
python3 - << 'PY'
import json, os, glob, sys
B = os.environ["BUILD"]
rf = json.load(open(f"{B}/s2_rf_summary_2026-09-16.json"))
cands = glob.glob(f"{B}/mosvr_output/*.json") + glob.glob(f"{B}/mosvr_output/*summary*.csv")
print("MOSVR outputs:", cands)
print(f"RF block calibration slope (pred on obs) {rf['block_calibration_slope_pred_on_obs']:.3f} {rf['slope_ci']}")
print("Read the MOSVR knee and total-error slopes from the files above and record the decision in")
print(f"{B}/logs/s2b_learner_decision.txt as one line: RF or MOSVR, with both slopes and the RMSE cost.")
PY
test -s "${BUILD}/logs/s2b_learner_decision.txt" || { echo "STOP: learner decision not recorded yet"; exit 3; }
grep -q "^RF" "${BUILD}/logs/s2b_learner_decision.txt" || { echo "STOP: MOSVR adopted, s3 is RF only"; exit 4; }
echo "S2B_DONE (RF adopted)"
