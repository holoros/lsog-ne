#!/usr/bin/env bash
# config.sh for the New Brunswick TRANSITIONING AND ABOVE 10 m build on LICENSED MagPlot labels, 2026-09-27.
# Derived from the 25 September NB CORE4 licensed config. Label: five axis total_score >= 4 (Configuration D any-LSOG).
# Derived from the 16 September config; only the build tag, the training table date and the NB
# reference rate change. The NB gate reference is now the licensed design based benchmark.
export BUILD_TAG="nb-trans-licensed-10m_2026-09-27"
export SCRATCH="/fs/scratch/PUOM0008/crsfaaron"
export BUILD="${SCRATCH}/trans_10m/${BUILD_TAG}"
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
export SEED=20260927
export CUT=3
export N_BOOT=20
export BOOT_NTREE=100
export FINAL_NTREE=500
export DST_CRS="EPSG:3979"
export RES=10
export TABLE_DATE="2026-09-27"
# external references, published in the manuscript, never from a build log
export REF_ME_SAMPLE_RATE="4.44,3.76,5.23"    # Maine CORE4 cut 3 sampling table rate, Methods 3.10
export REF_NB_PUBLIC_RATE="31.47,29.17,33.31"   # licensed Configuration D any-LSOG (five axis total_score >= 4), results_nb_cli_fullscope_Dbasis_20260906d/nb_designbased_estimate_fullCLI.csv HEADLINE (name kept so s2 runs unchanged)
export REF_ME_DB="4.56,3.83,5.30"
export REF_NB_DB="31.47,29.17,33.31"
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
export DATE_TAG="2026-09-27"
export TRAIN_TABLE="${BUILD}/trans_training_table_DATA_2026-09-27.csv"
export TRUE_XY="${BUILD}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"   # licensed coordinates, read in memory only
export MODEL_FINAL="${BUILD}/rf_trans_final_2026-09-27.pkl"
export BLOCK_SLOPE_REF="0.278,0.160,0.417"     # Stage A NB only OOF block slope, predicted on observed, s2_rf_summary_2026-09-27.json (diagnostic reference)
export G4B_LO=24.8                              # licensed Configuration D interval [29.17, 33.31] widened 15 percent each side, the NB CORE4 rule, fixed 2026-09-27 before any fit
export G4B_HI=38.3

export CORE4_CACHE="/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-10m_2026-09-25/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"
export CORE4_TABLE="/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-10m_2026-09-25/core4_training_table_DATA_2026-09-25.csv"
