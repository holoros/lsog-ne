#!/usr/bin/env bash
# config_trans.sh  Relabel refit of the Maine transitioning-and-above 10 m surface (October 12, 2026).
# Sources the September 23 Stage 2B config (config_trans_0923.sh, unedited copy) and overrides only the build
# location, date tag, Stage A artefacts of t1_stageA_relabel.py (SLURM 15460827), the relabelled sample rate and
# the Stage A out-of-fold block slope that G7b checks against. Every gate and every other setting is unchanged.
set -a
HERE_R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${HERE_R}/config_trans_0923.sh"
export BUILD_TAG="me-transitioning-10m_2026-10-12r"
export BUILD="${SCRATCH}/trans_10m/${BUILD_TAG}"
export TMP_TILES="${BUILD}/tile_tmp"
export FINAL="${BUILD}/final"
export DATE_TAG="2026-10-12"
export MODEL_FINAL="${BUILD}/rf_trans_final_2026-10-12.pkl"
export MODEL_BOOT="${BUILD}/rf_trans_boot_2026-10-12.pkl"
export TRAIN_TABLE="${BUILD}/me_transitioning_training_table_DATA_2026-10-12.csv"
export REF_ME_SAMPLE_RATE="14.146,13.40,15.91"   # relabelled shipped sample rate (2,969 plots); interval is the design-based one, as in September
export BLOCK_SLOPE_REF="0.6607,-0.1532,1.2522"   # t2_slope_ref.py: Stage A OOF block slope in the s4 direction (observed on mapped), 2,000 block bootstrap; the first value, from slopes(), regressed the other way
set +a
