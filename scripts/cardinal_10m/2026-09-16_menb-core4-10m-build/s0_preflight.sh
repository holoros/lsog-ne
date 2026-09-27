#!/usr/bin/env bash
# s0_preflight.sh  Checks every input before any compute is spent. Exits nonzero on the first failure.
set -uo pipefail
source "$(dirname "$0")/config.sh"
mkdir -p "${BUILD}/inputs" "${TMP_TILES}" "${FINAL}" "${BUILD}/logs"
fail=0
need() { if [ ! -e "$1" ]; then echo "FAIL missing: $1  ($2)"; fail=1; else echo "ok   $1"; fi; }

need "$POOLED_TABLE" "Sep 4 pooled training table"
need "$TSD_TABLE"    "Sep 3 disturbance covariates"
need "$AEF_INDEX"    "AlphaEarth tile index"
need "$EE_SA"        "Earth Engine service account for /vsigs/"
need "$GFC_VRT"      "Hansen ${HANSEN_VERSION} lossyear VRT"
need "$NB_BOUNDARY"  "NB boundary, EPSG:3979"
need "$CORE4_SAMPLE" "copy build/saeczi_v1/samp_dat_core4_DATA_2026-09-02.csv here"
need "$CLI_GRID_GDB" "unzip the re-sent CLI_Grid.gdb.zip here"
need "$NB_PUBLIC_XY" "public NB plot coordinates keyed by plot_id_export"
need "$ME_BOUNDARY"  "Maine polygon in EPSG:3979"
need "$FRAME_M3"     "M3 hybrid forest frame from Zenodo v1.3.0"
need "$MOSVR_SCRIPT" "mosvr_pareto.R from the mosvr skill"

# F10 size screens on staged inputs
if [ -e "$FRAME_M3" ]; then
  sz=$(stat -c %s "$FRAME_M3"); [ "$sz" -gt 15000000 ] || { echo "FAIL M3 frame is $sz bytes, expected about 17.6 MB"; fail=1; }
fi
if [ -e "$CORE4_SAMPLE" ]; then
  n=$(($(wc -l < "$CORE4_SAMPLE") - 1)); [ "$n" -eq 13708 ] || { echo "FAIL CORE4 sample has $n rows, expected 13,708"; fail=1; }
  head -1 "$CORE4_SAMPLE" | grep -q "s_mat_max" || { echo "FAIL CORE4 sample lacks s_mat_max"; fail=1; }
fi

# Guard against the FIA coordinate rule: nothing Maine may carry coordinates in this build
if [ -e "$NB_PUBLIC_XY" ]; then
  if grep -q "^ME_" "$NB_PUBLIC_XY"; then echo "FAIL nb_public_plot_xy.csv contains Maine rows; remove them"; fail=1; fi
fi

# Python and R stacks
module purge >/dev/null 2>&1; module load gcc/12.3.0 gdal/3.7.3 R/4.4.0 >/dev/null 2>&1 || { echo "FAIL module load"; fail=1; }
eval "$PY_ACTIVATE" || { echo "FAIL python env activation: $PY_ACTIVATE"; fail=1; }
python3 -c "import geopandas" || { echo "FAIL geopandas missing in python env"; fail=1; }
python3 -c "import rasterio, sklearn, shapely, scipy, pandas; print('ok   python stack', rasterio.__version__, sklearn.__version__)" || fail=1
Rscript -e 'for (p in c("data.table","sf")) if (!requireNamespace(p, quietly=TRUE)) stop("missing R package ", p); cat("ok   R stack\n")' || fail=1
command -v gdalwarp >/dev/null && command -v gdalbuildvrt >/dev/null || { echo "FAIL GDAL tools not on PATH"; fail=1; }

# AlphaEarth read probe (one tile header, no pixels)
python3 - << 'PY' || fail=1
import os, json, pandas as pd, rasterio
sa = os.environ["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR")
idx = pd.read_csv(os.environ["AEF_INDEX"]); row = idx[idx.year == 2024].iloc[0]
with rasterio.open("/vsigs/" + row["path"].replace("gs://", "")) as ds:
    assert ds.count == 64, f"expected 64 bands, got {ds.count}"
    print("ok   AlphaEarth probe", ds.width, "x", ds.height, ds.res, ds.crs)
PY

[ $fail -eq 0 ] && echo "PREFLIGHT PASS" || { echo "PREFLIGHT FAIL"; exit 1; }
