#!/usr/bin/env bash
# submit_chain_trans.sh  Stage 2B on Cardinal, Maine transitioning and above, 10 m.
#   bash submit_chain_trans.sh smoke   -> one tile, gating. Nothing else runs until it passes.
#   bash submit_chain_trans.sh B       -> tile array at 12 concurrent, then s4 mosaic and gates
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config_trans.sh"
LOGS="${BUILD}/logs"; mkdir -p "$LOGS" "$TMP_TILES" "$FINAL"
common=(--account=PUOM0008 --mail-type=END,FAIL --mail-user=aaron.weiskittel@maine.edu --export=ALL)
R="bash $HERE/run_step_trans.sh"

if [ "${1:-}" = "smoke" ]; then
  j=$(sbatch --parsable "${common[@]}" -J tr_smoke -t 02:00:00 --mem=64G -c 16 \
      -o "$LOGS/smoke_%j.out" --wrap "$R smoke")
  echo "smoke test submitted: $j"
  echo "It must print SMOKE PASS before stage B is launched."
elif [ "${1:-}" = "B" ]; then
  test -f "$LOGS/smoke_check_${DATE_TAG}.json" || { echo "stage B needs a passing smoke test first"; exit 4; }
  # tile count is computed with the same interpreter the steps use
  PYC=/usr/bin/python3
  NT=$($PYC - << 'PY'
import os, pandas as pd
idx = pd.read_csv(os.environ["AEF_INDEX"]); W, S, E, N = -71.10, 43.00, -66.90, 47.50
s = idx[(idx.year == 2024) & (idx.wgs84_east >= W) & (idx.wgs84_west <= E) &
        (idx.wgs84_north >= S) & (idx.wgs84_south <= N)].drop_duplicates(subset=["path"])
print(len(s))
PY
)
  echo "Maine tiles: $NT"
  j5=$(sbatch --parsable "${common[@]}" -J tr_s3 -t 12:00:00 --mem=120G -c 48 --array=0-$((NT-1))%12 \
       -o "$LOGS/s3_%A_%a.out" --wrap "$R s3 \$SLURM_ARRAY_TASK_ID")
  j6=$(sbatch --parsable "${common[@]}" -J tr_s4 -t 24:00:00 --mem=180G -c 48 -o "$LOGS/s4_%j.out" \
       --dependency=afterok:$j5 --wrap "$R s4")
  echo "stage B submitted: array $j5 ($NT tiles, 12 concurrent) -> $j6 (s4 mosaic and gates)"
else
  echo "usage: bash submit_chain_trans.sh smoke|B"; exit 1
fi
