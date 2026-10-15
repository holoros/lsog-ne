#!/usr/bin/env bash
# config_trans.sh  Maine transitioning-and-above 10 m build, Stage 2B.
# Sources the September 16 config unedited, then overrides only what
# 2026-09-24_stage2b-launch-spec_PLAN.md names. The September 16 chain is left untouched
# so it stays reproducible; every Stage 2B step has its own _trans file.
set -a
HERE_C="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${HERE_C}/config.sh"

export BUILD_TAG="me-transitioning-10m_2026-09-23"
export BUILD="${SCRATCH}/trans_10m/${BUILD_TAG}"
export TMP_TILES="${BUILD}/tile_tmp"
export FINAL="${BUILD}/final"
export DATE_TAG="2026-09-23"

export CUT=4
export REF_ME_SAMPLE_RATE="13.651,13.40,15.91"
export REF_ME_DB="14.66,13.40,15.91"
export REGIONS="ME"

# Stage A artefacts, SLURM 14865484, verified present on scratch 2026-09-24
export MODEL_FINAL="${BUILD}/rf_trans_final_2026-09-23.pkl"
export MODEL_BOOT="${BUILD}/rf_trans_boot_2026-09-23.pkl"
export TRAIN_TABLE="${BUILD}/me_transitioning_training_table_DATA_2026-09-23.csv"

# G4b, the tight magnitude gate. Provenance is the adopted design based any-LSOG of
# 14.66 [13.40, 15.91], widened for the map's own block attenuation of about 0.72.
# External to the artifact being gated, which G4's sampling table anchor is not.
export G4B_LO=11.5
export G4B_HI=18.5

# G7, plot level spatial check. Coordinates are FIA true coordinates and STAY ON CARDINAL:
# s4 reads them, writes only block level aggregates, and never emits a coordinate.
export TRUE_XY="/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted/lsog_train_true.csv"
export PLOTID_PLTCN="/fs/scratch/PUOM0008/crsfaaron/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
export BLOCK_SLOPE_REF="0.7233,0.2174,1.1109"   # Stage A out of fold block slope and its CI
export G7A_MIN_R=0.95
export G7A_MAX_MAD=0.02
set +a
