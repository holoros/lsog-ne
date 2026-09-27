#!/usr/bin/env bash
# submit_chain.sh  Two-stage SLURM chain on Cardinal.
#   stage A: bash submit_chain.sh A   -> s1 labels/weights, s2 RF fit, s2b MOSVR compare (stops for the learner decision)
#   stage B: bash submit_chain.sh B   -> s3a frame check, s3 tile array, s4 mosaic/mask/gates
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config.sh"
bash "$HERE/s0_preflight.sh"
LOGS="${BUILD}/logs"; mkdir -p "$LOGS"
common=(--account=PUOM0008 --mail-type=END,FAIL --mail-user=aaron.weiskittel@maine.edu --export=ALL)
R="bash $HERE/run_step.sh"

if [ "${1:-}" = "A" ]; then
  j1=$(sbatch --parsable "${common[@]}" -J c4_s1 -t 01:00:00 --mem=32G -c 4 -o "$LOGS/s1_%j.out" \
       --wrap "$R s1")
  j2=$(sbatch --parsable "${common[@]}" -J c4_s2 -t 06:00:00 --mem=64G -c 48 -o "$LOGS/s2_%j.out" \
       --dependency=afterok:$j1 --wrap "$R s2")
  j3=$(sbatch --parsable "${common[@]}" -J c4_s2b -t 08:00:00 --mem=32G -c 8 -o "$LOGS/s2b_%j.out" \
       --dependency=afterok:$j2 --wrap "$R s2b")
  j3c=$(sbatch --parsable "${common[@]}" -J c4_s2c -t 04:00:00 --mem=64G -c 12 -o "$LOGS/s2c_%j.out" \
       --dependency=afterany:$j3 --wrap "$R s2c")
  j3d=$(sbatch --parsable "${common[@]}" -J c4_s2d -t 04:00:00 --mem=96G -c 48 -o "$LOGS/s2d_%j.out" \
       --dependency=afterany:$j3 --wrap "$R s2d")
  echo "stage A submitted: $j1 -> $j2 -> $j3 -> ($j3c s2c, $j3d s2d, same blocked folds)"
  echo "When s2b stops, write ${LOGS}/s2b_learner_decision.txt (starting RF or MOSVR), then run stage B."
elif [ "${1:-}" = "B" ]; then
  grep -q "^RF" "$LOGS/s2b_learner_decision.txt" || { echo "stage B needs an RF decision in s2b_learner_decision.txt"; exit 4; }
  j4=$(sbatch --parsable "${common[@]}" -J c4_s3a -t 00:30:00 --mem=16G -c 2 -o "$LOGS/s3a_%j.out" \
       --wrap "$R s3a")
  # tile list is written on the first s3 call, so size the array from the index with the same filter
  eval "$PY_ACTIVATE"
  NT=$(python3 - << 'PY'
import os, pandas as pd
idx = pd.read_csv(os.environ["AEF_INDEX"]); REG = {"ME": (-71.10, 43.00, -66.90, 47.50), "NB": (-69.10, 44.50, -63.70, 48.10)}
s = pd.concat([idx[(idx.year == 2024) & (idx.wgs84_east >= W) & (idx.wgs84_west <= E) & (idx.wgs84_north >= S) & (idx.wgs84_south <= N)]
               for W, S, E, N in REG.values()]).drop_duplicates(subset=["path"])
print(len(s))
PY
)
  echo "tiles: $NT"
  j5=$(sbatch --parsable "${common[@]}" -J c4_s3 -t 12:00:00 --mem=120G -c 48 --array=0-$((NT-1))%12 \
       -o "$LOGS/s3_%A_%a.out" --dependency=afterok:$j4 \
       --wrap "$R s3 \$SLURM_ARRAY_TASK_ID")
  j6=$(sbatch --parsable "${common[@]}" -J c4_s4 -t 24:00:00 --mem=180G -c 48 -o "$LOGS/s4_%j.out" \
       --dependency=afterok:$j5 --wrap "$R s4")
  j7=$(sbatch --parsable "${common[@]}" -J c4_s5 -t 04:00:00 --mem=64G -c 4 -o "$LOGS/s5_%j.out" \
       --dependency=afterany:$j6 --wrap "$R s5")
  echo "stage B submitted: $j4 -> array $j5 ($NT tiles) -> $j6 -> $j7 (s5 share interval)"
else
  echo "usage: bash submit_chain.sh A|B"; exit 1
fi
