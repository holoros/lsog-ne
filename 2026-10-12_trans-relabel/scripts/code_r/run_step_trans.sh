#!/usr/bin/env bash
# run_step_trans.sh STEP [args]  Stage 2B step runner.
#
# INTERPRETER, and why it is not the conda env the September 16 chain used.
# Stage A fitted rf_trans_final and rf_trans_boot under Cardinal's system python3 (3.9.21) with
# scikit-learn 1.6.1, because its SLURM script ran `module purge` and then a bare `python3`. The
# gdalz conda env carries scikit-learn 1.9.0, and unpickling a 1.6.1 forest there raises
# InconsistentVersionWarning and gives no guarantee the predictions are the ones Stage A measured.
# A two day array is the wrong place to inherit that. So every Stage 2B step runs on the same
# interpreter Stage A used. The gdal module is still loaded, for the gdalwarp and ogr2ogr binaries
# only, with the PROJ and GDAL data variables unset so they do not fight rasterio's bundled GDAL.
# s4 was rewritten to use ogr2ogr instead of geopandas for exactly this reason.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/config_trans.sh"
module purge
module load gcc/12.3.0 gdal/3.7.3
unset PROJ_LIB PROJ_DATA GDAL_DATA
PY=/usr/bin/python3
$PY -c 'import sklearn,sys; assert sklearn.__version__=="1.6.1", "scikit-learn is "+sklearn.__version__+", Stage A fitted under 1.6.1"; print("interpreter", sys.version.split()[0], "scikit-learn", sklearn.__version__)'
step="$1"; shift
case "$step" in
  smoke) $PY "$HERE/s3_predict_tiles_trans_10m.py" 0 1 && $PY "$HERE/s_smoke_check_trans.py" ;;
  s3)    $PY "$HERE/s3_predict_tiles_trans_10m.py" "$1" "$(( $1 + 1 ))" ;;
  s4)    $PY "$HERE/s4_mosaic_mask_gate_trans.py" ;;
  *)     echo "unknown step $step"; exit 1 ;;
esac
