#!/usr/bin/env bash
# config.sh for the New Brunswick CORE4 10 m rebuild on LICENSED MagPlot labels, 2026-09-25.
# Derived from the 16 September config; only the build tag, the training table date and the NB
# reference rate change. The NB gate reference is now the licensed design based benchmark.
export BUILD_TAG="nb-core4-licensed-10m_2026-09-25"
export SCRATCH="/fs/scratch/PUOM0008/crsfaaron"
export BUILD="${SCRATCH}/core4_10m/${BUILD_TAG}"
export TMP_TILES="${BUILD}/tile_tmp"
export FINAL="${BUILD}/final"
export OLD_BUILD="${SCRATCH}/core4_10m/menb-core4-10m_2026-09-16"
export AEF_INDEX="${SCRATCH}/v6/aef_index.csv"
export EE_SA="/users/PUOM0008/crsfaaron/.config/earthengine/service_account.json"
export NB_BOUNDARY="${SCRATCH}/canada_landcover/nb_boundary_3979.geojson"
export HANSEN_VERSION="v1.12"
export GFC_VRT="${SCRATCH}/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt"
export CLI_GRID_GDB="${OLD_BUILD}/inputs/CLI_Grid.gdb"
export ME_BOUNDARY="${OLD_BUILD}/inputs/me_boundary_3979.geojson"
export FRAME_M3="${OLD_BUILD}/inputs/frame_M3_hybrid_forest_landuse_30102x25127.tif"
export SEED=20260925
export CUT=3
export N_BOOT=20
export BOOT_NTREE=100
export FINAL_NTREE=500
export DST_CRS="EPSG:3979"
export RES=10
export TABLE_DATE="2026-09-25"
# external references, published in the manuscript, never from a build log
export REF_ME_SAMPLE_RATE="4.44,3.76,5.23"    # Maine CORE4 cut 3 sampling table rate, Methods 3.10
export REF_NB_PUBLIC_RATE="9.37,7.71,11.03"   # NOW the licensed design based benchmark, Section 4.4 (name kept so s2 runs unchanged)
export REF_ME_DB="4.56,3.83,5.30"
export REF_NB_DB="9.37,7.71,11.03"
export REF_NB_DEFF="1.855"
export REF_NB_COVERAGE="58.26"
export REF_NB_FRAME_POINTS=18334
export REF_M3_HA="ME:7410000,NB:6550000"
export EPSG3979_OVERSTATE="ME:1.033,NB:1.020"
source /etc/profile.d/lmod.sh 2>/dev/null || true
export FRAME_FOREST_VALUE=1
export WIN=2048
export PY_ACTIVATE='module load miniconda3/24.1.2-py310 && eval "$(conda shell.bash hook)" && conda activate gdalz'
# ---- Stage B additions, 2026-09-25 ----
export DATE_TAG="2026-09-25"
export TRAIN_TABLE="${BUILD}/core4_training_table_DATA_2026-09-25.csv"
export TRUE_XY="${BUILD}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"   # licensed coordinates, read in memory only
export MODEL_FINAL="${BUILD}/rf_core4_final_2026-09-25.pkl"
export BLOCK_SLOPE_REF="0.262,0.062,0.438"     # Stage A NB only OOF block slope, predicted on observed, s2_rf_summary_2026-09-25.json (diagnostic reference)
export G4B_LO=6.5                              # licensed design based interval [7.71, 11.03] widened by the Stage A calibration in the large band (OOF/observed 1.08), about 15 percent each side
export G4B_HI=12.7
