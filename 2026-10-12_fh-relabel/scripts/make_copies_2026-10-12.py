#!/usr/bin/env python3
"""make_copies_2026-10-12.py (track fh-relabel). Builds the 2026-10-12 copies of the October 5 Maine
transitioning-and-above Fay-Herriot chain from the originals, by exact string replacements that must each
match the stated number of times. Originals are read only. Only paths, date tags, the label table, the
surface and the final model change, plus a mode switch FHR_MODE (old = the October 5 inputs, used once for
the reproduction gate; new = relabelled table and rebuilt surface). Seeds, folds, learners, block
definitions and estimators are untouched."""
import os, sys
H = os.path.expanduser("~")
L = f"{H}/LSOG"; D = f"{L}/2026-10-12_fh-relabel/scripts"
def rep(s, a, b, n=1):
    c = s.count(a)
    if c != n: sys.exit(f"PATCH FAIL expected {n} got {c}: {a[:90]!r}")
    return s.replace(a, b)
def emit(name, s):
    p = f"{D}/{name}"
    if os.path.exists(p): sys.exit(f"exists {p}")
    open(p, "w").write(s); os.chmod(p, 0o600); print("wrote", p)

MODE_PY = ('MODE = os.environ.get("FHR_MODE", "new")\n'
           'if MODE not in ("old", "new"): raise SystemExit("FHR_MODE must be old or new")\n'
           'FHR = os.path.expanduser("~/LSOG/2026-10-12_fh-relabel/out")\n'
           'OUT = FHR if MODE == "new" else f"{FHR}/repro_old"\n')
NEWB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r"

# 1. prep ---------------------------------------------------------------------------------------
s = open(f"{L}/2026-09-27_sae-block-prep/sae_block_prep.py").read()
s = rep(s, '"""\nSAE block prep, 2026-09-27.',
        '"""\nsae_block_prep_2026-10-12.py: copy of ~/LSOG/2026-09-27_sae-block-prep/sae_block_prep.py (track fh-relabel).\n'
        'Changed: output folder and date tag; FHR_MODE=old reads the September table and published surface (reproduction\n'
        'gate), FHR_MODE=new reads the October 12 relabelled table (jobA v5.1, y = total_score >= 4 = trans_cut4, gated)\n'
        'and the rebuilt October 12 surface. Only ME_TRANS is run. The original docstring follows.\n'
        'SAE block prep, 2026-09-27.')
s = rep(s, 'OUT = os.path.expanduser("~/LSOG/2026-09-27_sae-block-prep/out"); os.makedirs(OUT, exist_ok=True)',
        MODE_PY + 'os.makedirs(OUT, exist_ok=True)')
s = rep(s, '    t = pd.read_csv(f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv", dtype={"plot_id": str})',
        '    TABP = {"old": f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv",\n'
        f'            "new": "{NEWB}/me_transitioning_training_table_DATA_2026-10-12.csv"}}[MODE]\n'
        '    t = pd.read_csv(TABP, dtype={"plot_id": str})')
s = rep(s, '    X = t[AE].to_numpy(float); y = (t.total_score >= 4).astype(int).to_numpy(); g = t.spatial_block.to_numpy()\n',
        '    X = t[AE].to_numpy(float); y = (t.total_score >= 4).astype(int).to_numpy(); g = t.spatial_block.to_numpy()\n'
        '    if MODE == "new" and (len(t) != 2977 or not (y == t.trans_cut4.to_numpy(int)).all()):\n'
        '        raise SystemExit("GATE FAIL relabelled table: expected 2,977 rows with total_score >= 4 equal to trans_cut4")\n')
s = rep(s, ' "ME_TRANS": dict(ras=f"{L}/products/me-transitioning-10m_2026-09-23/me-transitioning-and-above-probability_10m_ME_DATA_2026-09-23.tif",',
        ' "ME_TRANS": dict(ras={"old": f"{L}/products/me-transitioning-10m_2026-09-23/me-transitioning-and-above-probability_10m_ME_DATA_2026-09-23.tif",\n'
        f'                       "new": "{NEWB}/final/me-transitioning-and-above-probability_10m_ME_DATA_2026-10-12.tif"}}[MODE],')
s = rep(s, 'B.to_csv(f"{OUT}/sae_blocks_{sname}_DATA_2026-09-27.csv", index=False)',
        'B.to_csv(f"{OUT}/sae_blocks_{sname}_DATA_2026-10-12.csv", index=False)')
s = rep(s, "_{'_'.join(sys.argv[1:])}_2026-09-27.json", "_{'_'.join(sys.argv[1:])}_2026-10-12.json")
s = rep(s, 'for sname in sys.argv[1:]:\n', 'if sys.argv[1:] != ["ME_TRANS"]: raise SystemExit("this copy runs ME_TRANS only")\nfor sname in sys.argv[1:]:\n')
emit("sae_block_prep_2026-10-12.py", s)

# 2. FH producer of 2026-09-27 ------------------------------------------------------------------
s = open(f"{H}/zenodo_staging/menb-lsog-manuscript/v160_work_20261001/sae_src/2026-09-27_lsog-sae-fh_DATA.R").read()
s = rep(s, "# 2026-09-27_lsog-sae-fh_DATA.R\n",
        "# sae_fh_2026-10-12.R: copy of 2026-09-27_lsog-sae-fh_DATA.R (track fh-relabel). Changed: date tags of the input\n"
        "# and output files (2026-09-27 -> 2026-10-12) and an optional second argument for the output folder. Run for\n"
        "# ME_TRANS only (the other inputs are absent and skipped by the original rule). Original header follows.\n"
        "# 2026-09-27_lsog-sae-fh_DATA.R\n")
s = rep(s, 'OUT <- "output"', 'OUT <- if (length(args) > 1) args[2] else "output"')
s = rep(s, 'sae_blocks_%s_DATA_2026-09-27.csv', 'sae_blocks_%s_DATA_2026-10-12.csv', 3)
s = rep(s, 'sae-blocks_%s_DATA_2026-09-27.csv', 'sae-blocks_%s_DATA_2026-10-12.csv')
s = rep(s, 'fig_sae_%s_2026-09-27.png', 'fig_sae_%s_2026-10-12.png')
s = rep(s, 'fig_sae_%s_2026-09-27.pdf', 'fig_sae_%s_2026-10-12.pdf')
s = rep(s, 'sae_summary_2026-09-27.json', 'sae_summary_2026-10-12.json')
s = rep(s, 'sae_summary_2026-09-27.rds', 'sae_summary_2026-10-12.rds')
emit("sae_fh_2026-10-12.R", s)

# 3. cross-fitted OOF ---------------------------------------------------------------------------
s = open(f"{L}/2026-10-05_fh-crossfit/fhx_oof_2026-10-05.py").read()
s = rep(s, '"""\nfhx_oof_2026-10-05.py  (track fh-crossfit).',
        '"""\nfhx_oof_2026-10-12.py: copy of fhx_oof_2026-10-05.py (track fh-relabel). Changed: paths and date tags; FHR_MODE\n'
        'old reads the October 5 inputs (reproduction gate), new reads the October 12 relabelled table and\n'
        'rf_trans_final_2026-10-12.pkl. The fixed row and positive counts of the old inputs are kept for old and replaced\n'
        'for new by the relabelled counts (2,977 rows, 422 positives, 2,969 with time since disturbance) and by the\n'
        'plot count the copied prep recorded. The sb gate now checks the copied prep of the same mode.\n'
        'Original docstring follows.\nfhx_oof_2026-10-05.py  (track fh-crossfit).')
s = rep(s, 'OUT = f"{L}/2026-10-05_fh-crossfit/out"; os.makedirs(OUT, exist_ok=True)\n'
           'TAB = f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv"\n',
        MODE_PY + 'os.makedirs(OUT, exist_ok=True)\n'
        'TAB = {"old": f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv",\n'
        f'       "new": "{NEWB}/me_transitioning_training_table_DATA_2026-10-12.csv"}}[MODE]\n')
s = rep(s, 'FINAL = f"{S}/trans_10m/me-transitioning-10m_2026-09-23/rf_trans_final_2026-09-23.pkl"\n'
           'PREP = f"{L}/2026-09-27_sae-block-prep/out/sae_blocks_ME_TRANS_DATA_2026-09-27.csv"\n',
        'FINAL = {"old": f"{S}/trans_10m/me-transitioning-10m_2026-09-23/rf_trans_final_2026-09-23.pkl",\n'
        f'         "new": "{NEWB}/rf_trans_final_2026-10-12.pkl"}}[MODE]\n'
        'PREP = f"{OUT}/sae_blocks_ME_TRANS_DATA_2026-10-12.csv"\n'
        'EXP = {"old": (3062, 418, 3015, 3023),\n'
        '       "new": (2977, 422, 2969, json.load(open(f"{OUT}/sae_block_prep_summary_ME_TRANS_2026-10-12.json"))["ME_TRANS"]["plots_used"])}[MODE]\n')
s = rep(s, 'if len(t) != 3062 or int(y.sum()) != 418 or int(ship.sum()) != 3015:\n'
           '    die(f"rows {len(t)} positives {int(y.sum())} shipped {int(ship.sum())}, expected 3062 / 418 / 3015")\n'
           'log("GATE PASS 3,062 rows, 418 positives, 3,015 shipped sample")\n',
        'if len(t) != EXP[0] or int(y.sum()) != EXP[1] or int(ship.sum()) != EXP[2]:\n'
        '    die(f"rows {len(t)} positives {int(y.sum())} shipped {int(ship.sum())}, expected {EXP[:3]}")\n'
        'if MODE == "new" and not (y == t.trans_cut4.to_numpy(int)).all(): die("y is not the jobA trans_cut4")\n'
        'log(f"GATE PASS {EXP[0]} rows, {EXP[1]} positives, {EXP[2]} shipped sample")\n')
s = rep(s, 'if int(has.sum()) != 3023: die(f"expected 3,023 plots with coordinates as in the prep, got {int(has.sum())}")',
        'if int(has.sum()) != EXP[3]: die(f"expected {EXP[3]} plots with coordinates as in the prep, got {int(has.sum())}")')
s = rep(s, 'fhx_blocks_ME_TRANS_DATA_2026-10-05.csv', 'fhx_blocks_ME_TRANS_DATA_2026-10-12.csv')
s = rep(s, 'fhx_oof_summary_2026-10-05.json', 'fhx_oof_summary_2026-10-12.json')
emit("fhx_oof_2026-10-12.py", s)

# 4. FH fit with cross-fitted covariate -----------------------------------------------------------
s = open(f"{L}/2026-10-05_fh-crossfit/fhx_fit_2026-10-05.R").read()
s = rep(s, "# fhx_fit_2026-10-05.R  (track fh-crossfit).",
        "# fhx_fit_2026-10-12.R: copy of fhx_fit_2026-10-05.R (track fh-relabel). Changed: paths and date tags only. The\n"
        "# prep blocks and the FH table it gates M0 against are the copies of the same mode (sae_block_prep_2026-10-12.py,\n"
        "# sae_fh_2026-10-12.R) in the output folder given as the second argument. Original header follows.\n"
        "# fhx_fit_2026-10-05.R  (track fh-crossfit).")
s = rep(s, 'OUT <- file.path(BASE, "out")', 'OUT <- if (length(args) > 1) args[2] else file.path(BASE, "out")')
s = rep(s, 'B0 <- fread(file.path(path.expand("~/LSOG/2026-09-27_sae-block-prep/out"), "sae_blocks_ME_TRANS_DATA_2026-09-27.csv"))\n'
           'PUB <- fread(path.expand("~/LSOG/2026-10-01_surface-maps/sae-blocks_ME_TRANS_DATA_2026-09-27.csv"))\n'
           'NEW <- fread(file.path(OUT, "fhx_blocks_ME_TRANS_DATA_2026-10-05.csv"))\n',
        'B0 <- fread(file.path(OUT, "sae_blocks_ME_TRANS_DATA_2026-10-12.csv"))\n'
        'PUB <- fread(file.path(OUT, "sae-blocks_ME_TRANS_DATA_2026-10-12.csv"))\n'
        'NEW <- fread(file.path(OUT, "fhx_blocks_ME_TRANS_DATA_2026-10-12.csv"))\n')
s = rep(s, 'fhx_method_summary_2026-10-05.csv', 'fhx_method_summary_2026-10-12.csv')
s = rep(s, 'sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05_PROVISIONAL.csv', 'sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12_PROVISIONAL.csv')
emit("fhx_fit_2026-10-12.R", s)

# 5. promotion to the 66 block record ---------------------------------------------------------------
s = open(f"{L}/2026-10-05_hexmap-crossfit/fhx_promote_2026-10-05.R").read()
s = rep(s, "# fhx_promote_2026-10-05.R  (track hexmap-crossfit).",
        "# fhx_promote_2026-10-12.R: copy of fhx_promote_2026-10-05.R (track fh-relabel). Changed: paths, date tags, and\n"
        "# the two gates that checked the 2026-09-27/10-05 numbers themselves (statewide rounds to 14.00; exactly 5\n"
        "# synthetic blocks), which apply only with FHR_MODE=old; with FHR_MODE=new the synthetic count is gated against\n"
        "# the copied fit's method summary, and the 13.40 to 15.91 interval gate is kept. greg, greg_se and sel_fixed\n"
        "# come from, and are gated against, the copied 2026-09-27 FH producer of the same mode. Column names are kept\n"
        "# (fh_insample_2026_09_27 holds the in-sample map covariate fit of the mode's surface). Original header follows.\n"
        "# fhx_promote_2026-10-05.R  (track hexmap-crossfit).")
s = rep(s, 'FX <- path.expand("~/LSOG/2026-10-05_fh-crossfit"); OUT <- file.path(FX, "out")\n'
           'REC <- file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05.csv")\n',
        'MODE <- Sys.getenv("FHR_MODE", "new"); if (!MODE %in% c("old", "new")) stop("FHR_MODE must be old or new")\n'
        'FX <- path.expand("~/LSOG/2026-10-12_fh-relabel"); OUT <- if (MODE == "new") file.path(FX, "out") else file.path(FX, "out", "repro_old")\n'
        'REC <- file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv")\n')
s = rep(s, 'B0 <- fread(path.expand("~/LSOG/2026-09-27_sae-block-prep/out/sae_blocks_ME_TRANS_DATA_2026-09-27.csv"))\n'
           'PUB <- fread(path.expand("~/LSOG/2026-10-01_surface-maps/sae-blocks_ME_TRANS_DATA_2026-09-27.csv"))\n'
           'NEW <- fread(file.path(OUT, "fhx_blocks_ME_TRANS_DATA_2026-10-05.csv"))\n'
           'PROV <- fread(file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05_PROVISIONAL.csv"))\n'
           'MS <- fread(file.path(OUT, "fhx_method_summary_2026-10-05.csv"))\n',
        'B0 <- fread(file.path(OUT, "sae_blocks_ME_TRANS_DATA_2026-10-12.csv"))\n'
        'PUB <- fread(file.path(OUT, "sae-blocks_ME_TRANS_DATA_2026-10-12.csv"))\n'
        'NEW <- fread(file.path(OUT, "fhx_blocks_ME_TRANS_DATA_2026-10-12.csv"))\n'
        'PROV <- fread(file.path(OUT, "sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12_PROVISIONAL.csv"))\n'
        'MS <- fread(file.path(OUT, "fhx_method_summary_2026-10-12.csv"))\n')
s = rep(s, 'if (sprintf("%.2f", st) != "14.00" || st < 13.40 || st > 15.91) die("statewide %.4f not 14.00 inside 13.40 to 15.91", st)',
        'if ((MODE == "old" && sprintf("%.2f", st) != "14.00") || st < 13.40 || st > 15.91) die("statewide %.4f not 14.00 (old) or not inside 13.40 to 15.91", st)')
s = rep(s, 'if (M2[, sum(synthetic)] != 5) die("expected 5 synthetic blocks, got %d", M2[, sum(synthetic)])',
        'nsyn <- if (MODE == "old") 5L else as.integer(MS[method == "M2_oof_h3_lobo", blocks_synthetic])\n'
        'if (M2[, sum(synthetic)] != nsyn) die("expected %d synthetic blocks, got %d", nsyn, M2[, sum(synthetic)])')
s = rep(s, 'say("sel_fixed vs 2026-09-27: max abs diff %.3e", dsel)', 'say("sel_fixed vs copied FH producer (%s): max abs diff %.3e", MODE, dsel)')
emit("fhx_promote_2026-10-12.R", s)
print("COPIES_DONE")
