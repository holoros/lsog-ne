#!/usr/bin/env bash
# config.sh  ME/NB pooled CORE4 10 m build, shared settings. Source this from every step.
# Every path marked CONFIRM was not verifiable from the Cowork session (no Cardinal access on
# September 16, 2026). s0_preflight.sh fails loudly if any of them is wrong.

export BUILD_TAG="menb-core4-10m_2026-09-16"
export SCRATCH="/fs/scratch/PUOM0008/crsfaaron"
export BUILD="${SCRATCH}/core4_10m/${BUILD_TAG}"          # all outputs land here
export TMP_TILES="${BUILD}/tile_tmp"
export FINAL="${BUILD}/final"

# ---- inputs carried from the September 4 pooled tolerance surface (known paths) ----
export TOL_WORK="${SCRATCH}/tolscore_surface/pooled_nojurisd_disturb_2026-09-04"
export POOLED_TABLE="${TOL_WORK}/pooled-training-table_DATA_2026-09-03.csv"   # AE_00..AE_63, blk, plot_id_export, jurisdiction
export TSD_TABLE="${BUILD}/inputs/tsd_hansen_v112_DATA_2026-09-16.csv"    # plot_id, time_since_disturbance (Hansen v1.12, prep/tsd_extract_hansen_v112.py)
export AEF_INDEX="${SCRATCH}/v6/aef_index.csv"
export EE_SA="/users/PUOM0008/crsfaaron/.config/earthengine/service_account.json"
export NB_BOUNDARY="${SCRATCH}/canada_landcover/nb_boundary_3979.geojson"

# ---- Hansen decision, revised September 16, 2026 at Aaron's request: GFC-2024-v1.12 lossyear ----
# (tiles 50N_070W and 50N_080W fetched to Cardinal; the v1.11 VRT used by the September 4 surface is
#  /users/PUOM0008/crsfaaron/Disturbance/validation_data/GFC/gfc_lossyear_conus.vrt)
export HANSEN_VERSION="v1.12"
export GFC_VRT="/fs/scratch/PUOM0008/crsfaaron/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt"

# ---- inputs to stage or confirm (CONFIRM) ----
export CORE4_SAMPLE="${BUILD}/inputs/samp_dat_core4_DATA_2026-09-02.csv"      # copy up from build/saeczi_v1/
export CLI_GRID_GDB="${BUILD}/inputs/CLI_Grid.gdb"                           # unzip of the re-sent CLI_Grid.gdb.zip
export NB_PUBLIC_XY="${BUILD}/inputs/nb_public_plot_xy.csv"                   # plot_id_export, lon, lat (public CLI coordinates, NB only)
export ME_BOUNDARY="${BUILD}/inputs/me_boundary_3979.geojson"                 # Maine state polygon, EPSG:3979
export FRAME_M3="${BUILD}/inputs/frame_M3_hybrid_forest_landuse_30102x25127.tif"  # Zenodo v1.3.0 file, EPSG:3979, 30 m
export MOSVR_SCRIPT="/fs/scratch/PUOM0008/crsfaaron/mtt_sae/mosvr_pareto.R"   # confirmed on Cardinal 2026-09-16, 4292 bytes

# ---- fixed analysis settings ----
export SEED=20260916
export CUT=3                       # CORE4 any-LSOG at three axes fired out of four
export N_BOOT=20                   # spatial block bootstrap models for the SD layer
export BOOT_NTREE=100
export FINAL_NTREE=500
export DST_CRS="EPSG:3979"
export RES=10

# ---- external references for the gates (all published in the manuscript, never from a build log) ----
export REF_ME_SAMPLE_RATE="4.44,3.76,5.23"   # Maine CORE4 cut 3 sampling-table rate, Methods 3.10
export REF_NB_PUBLIC_RATE="4.61,3.86,5.37"   # NB CORE4 cut 3 on 10,681 public plots, Methods 3.10
export REF_ME_DB="4.56,3.83,5.30"            # Maine CORE4 cut 3 design-based benchmark, Section 4.4
export REF_NB_DB="9.37,7.71,11.03"           # NB CORE4 cut 3 licensed benchmark, Section 4.4
export REF_NB_DEFF="1.855"                   # CLI_Grid design effect, Section 4.4
export REF_NB_COVERAGE="58.26"               # CLI_Grid panel coverage (%), Section 4.4
export REF_NB_FRAME_POINTS=18334
export REF_M3_HA="ME:7410000,NB:6550000"     # hybrid frame, geodesic, Methods 3.12
export EPSG3979_OVERSTATE="ME:1.033,NB:1.020" # raw EPSG:3979 cell area overstatement, Methods 3.12

source /etc/profile.d/lmod.sh 2>/dev/null || true

# ---- frame coding (CONFIRM with s3a_frame_check.py output) ----
export FRAME_FOREST_VALUE=1
export WIN=2048                     # prediction window, pixels

# ---- Python environment used by the September 4 pooled jobs (CONFIRM; preflight tests it) ----
export PY_ACTIVATE='module load miniconda3/24.1.2-py310 && eval "$(conda shell.bash hook)" && conda activate gdalz'
