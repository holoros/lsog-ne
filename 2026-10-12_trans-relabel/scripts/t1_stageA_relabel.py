#!/usr/bin/env python3
"""t1_stageA_relabel.py (October 12, 2026). Stage A of the Maine transitioning-and-above 10 m surface
(record 22967250), refit on labels from the 2019 to 2023 remeasurement. A copy of
2026-09-23_me-transitioning-10m-stageA_DATA.py: same learner, seed, features, sample rule and artefacts; only the
label source changes, and the September reproduction checks on the 2004 to 2008 labels are replaced by a
predictor-identity check. The earlier docstring follows."""
#!/usr/bin/env python3
"""
2026-09-23_me-transitioning-10m-stageA_DATA.py

STAGE A of the Maine transitioning and above 10 m build: training table, fit, calibration, and the
model artefacts the September 16 tile chain consumes. No tile prediction here.

WHAT IS REUSED AND WHAT CHANGES. The September 16 bundle `2026-09-16_menb-core4-10m-build` is the
pipeline, not a starting point to rewrite: s3 predicts tiles from a pickled final model, twenty
bootstrap models and an environment envelope, and s4 mosaics and gates. This script produces those
same artefacts for a different label, so s3 and s4 need only new paths and a new G4 reference.
  label      CORE4 cut 3, pooled ME and NB   ->   v5.1 total score >= 4, MAINE ONLY
  weights    NB CLI_Grid design weights      ->   none, every Maine FIA plot carries w = 1
  G4 target  CORE4 4.56 [3.83, 5.30]         ->   adopted Maine any-LSOG 14.66 [13.40, 15.91]
Nothing in the September 16 build directory is written to. This build is a new tag.

THE FEATURE SET IS THE POINT OF THIS SCRIPT. Every diagnostic produced tonight, including the block
slope of 0.704 and its disattenuated 0.867, was computed on the 64 AlphaEarth bands alone, matching
the 17 September probe. The 10 m chain fits on 65 predictors, the 64 bands plus Hansen time since
disturbance, because s3 reads a TSD raster alongside the tiles. Quoting a 64 band diagnostic for a
65 band product would be a mismatch of exactly the kind this project keeps catching late, so both
feature sets are fitted here, side by side, on the same folds, and the shipped surface's numbers
are the ones computed on the shipped feature set.

CONTROLS, each stops the script:
  PC1 the Maine rows of the September 16 training table are a SUBSET of
      me_train_true_v51_continuous.csv with identical AlphaEarth bands to 1e-9, and the shortfall is
      the 47 plots characterised below. The first submission of this script asserted equality and
      stopped, which is how the shortfall was found.

THE 47 PLOT SHORTFALL, and why this build uses 3,062 rather than 3,015. The September 16 CORE4 10 m
surface, the one being read at a 6 percent threshold, was trained on 3,015 of the 3,062 Maine plots.
Forty seven plots in the reference table are absent from it and none go the other way. They are
spread across all ten blocks, 2 to 9 each, so it is not a spatial exclusion. They are enriched in
zero canopy height, 13 of 47 against 156 of 3,062 overall, and mildly depleted in the class, 4 of 47
transitioning and above against 13.651 percent overall, which on 47 plots is not a significant
difference. Time since disturbance is not the cause: 38 of the 47 sit in the TSD table with non
missing values. The likely cause is the September 3 pooled AlphaEarth extraction, and it is an
undocumented difference between the map's training sample and the sample every design based and
mappability number in this project uses.
REVISED after the red team pass. The first version of this script shipped all 3,062 plots on the
argument that every diagnostic tonight was computed on them. That was wrong, and the check that
overturned it is RT1 in 2026-09-23_redteam-checks_DATA.py: the 47 are not a random subset in
predictor space. Ten of the 47, 21 percent against an expected 1 percent, fall outside the 3,015
plots' range on at least one AlphaEarth band and beyond their 99th percentile Mahalanobis distance,
and their median Mahalanobis distance is 84.2 against 48.5. That pattern says the September 16
exclusion was probably deliberate quality control rather than an accident, though the reason remains
unrecorded.
The decisive consequence is downstream, not in the fit. s3 writes an extrapolation flag from
env_min and env_max, the envelope of the training predictors. Including 47 outliers widens that
envelope and makes the flag less sensitive across the whole Maine map, which is the opposite of what
the flag exists for. Whether the 47 are real forest the kept sample under represents, or extraction
artefacts, cannot be settled here.
This build therefore ships the 3,015 plots the September 16 pipeline used, with the 64 AlphaEarth
bands only, so that this surface and the CORE4 surface already in circulation rest on the same
sample and can be read together. The 3,062 fit is retained below as a reported sensitivity, and it
is also the configuration every earlier diagnostic tonight was computed on, so both sets of numbers
are printed and the shipped ones are named. What time since disturbance would have bought is
measured on the 3,015 subset and reported, rather than assumed either way. Dropping TSD also removes
a raster read from the tile step rather than adding one.
  PC2 the transitioning label is 418 positives of 3,062, 13.651 percent, matching stage 1 and the
      17 September probe.
  PC3 the AE only fit reproduces tonight's BASE exactly: AUC 0.7835, raw block slope 0.7039.
  PC4 the twenty bootstrap models and the final model all carry the shipped feature count, and the
      environment envelope has one entry per feature.

Disattenuated block slope: the slope of predicted on observed block means is divided by the
reliability of the observed means, (var between minus mean binomial noise) over var between, since
the benchmark on the x axis is a binomial proportion on a few hundred plots. Bootstrapped over
blocks. On ten blocks this interval is wide and is reported as such.

No coordinates are read. The Maine training table carries none by design.
"""
import os, sys, json, time, pickle, hashlib
import numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score, brier_score_loss

T0 = time.time()
def log(m): print(f"[{time.time()-T0:7.1f}s] {m}", flush=True)
def die(m): log("FAIL " + m); sys.exit(2)

SEED  = 20260917
DATE  = "2026-10-12"
SRC   = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16"
MEREF = "/users/PUOM0008/crsfaaron/LSOG/output_unified/me_train_true_v51_continuous.csv"
BUILD = f"/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_{DATE}r"
KEEP  = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_trans-relabel/out"
PUB   = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
RELAB = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/out/me_training_table_relabel2023_RESTRICTED.csv"
AE    = [f"AE_{i:02d}" for i in range(64)]
FEAT_AE  = AE
FEAT_TSD = AE + ["time_since_disturbance"]
N_BOOT, BOOT_NTREE, FINAL_NTREE = 20, 100, 500
os.makedirs(BUILD, exist_ok=True)
rng = np.random.default_rng(SEED)

def md5(p):
    h = hashlib.md5()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()

# ------------------------------------------------------------------ table (relabel, October 12, 2026)
# The September 23 training table (3,062 Maine plots; AlphaEarth 2024 at the true plot position; time since
# disturbance) keeps its predictors. Labels are replaced by the v5.1 score of the same plot at its 2019 to 2023
# remeasurement (EVALID 232301 panel), from r0_relabel.py of the ordinal rebuild. Plots without a scored
# 2019 to 2023 descendant drop out (85). As in September, the shipped fit uses the plots with time since disturbance.
pub = pd.read_csv(PUB, low_memory=False)
LAB = ["s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht", "total_score", "any_lsog", "og", "lsog_class", "trans_cut4"]
rl = pd.read_csv(RELAB, low_memory=False)[["plot_id"] + LAB]
old = pub[["plot_id", "trans_cut4"]].rename(columns={"trans_cut4": "trans_old"})
d = pub.drop(columns=LAB).merge(rl, on="plot_id", how="inner").merge(old, on="plot_id")
log(f"published table {len(pub)} rows; relabelled {len(rl)}; joined {len(d)}")
if len(d) != len(rl): die("PC1 relabelled plots missing from the published table")
d["w"] = 1.0
if not np.allclose(d[AE].to_numpy(float), pub.set_index("plot_id").loc[d.plot_id, AE].to_numpy(float)): die("PC1 predictors changed")
log(f"PC1 PASS predictors identical; positives {int(d.trans_cut4.sum())} of {len(d)}, {100*d.trans_cut4.mean():.3f} percent "
    f"(earlier labels on the same plots {100*d.trans_old.mean():.3f} percent)")
d.to_csv(f"{BUILD}/me_transitioning_training_table_DATA_{DATE}.csv", index=False)
# ------------------------------------------------------------------ diagnostics
def blockframe(p, yy, b, minn=5):
    g = pd.DataFrame({"y": yy, "p": p, "b": b}).groupby("b").agg(
        obs=("y", "mean"), pred=("p", "mean"), n=("y", "size"))
    return g[g.n >= minn]

def slopes(p, yy, b):
    g = blockframe(p, yy, b)
    raw = float(np.polyfit(g.obs, g.pred, 1)[0])
    v_tot = float(np.var(g.obs, ddof=1)); v_err = float(np.mean(g.obs * (1 - g.obs) / g.n))
    rel = (v_tot - v_err) / v_tot if v_tot > 0 else np.nan
    return raw, rel, (raw / rel if rel and rel > 0 else np.nan)

def boot_slopes(p, yy, b, nrep=2000):
    ub = np.unique(b); R, C = [], []
    r2 = np.random.default_rng(SEED)
    for _ in range(nrep):
        pick = r2.choice(ub, len(ub), replace=True)
        idx = np.concatenate([np.where(b == q)[0] for q in pick])
        bb = np.concatenate([np.full((b == q).sum(), i) for i, q in enumerate(pick)])
        try:
            r, rel, c = slopes(p[idx], yy[idx], bb)
            if np.isfinite(r): R.append(r)
            if np.isfinite(c): C.append(c)
        except Exception:
            continue
    q = lambda a: [round(float(np.percentile(a, 2.5)), 4), round(float(np.percentile(a, 97.5)), 4)] if a else None
    return q(R), q(C)

def evaluate(feats, tag, d, blk, y, folds):
    X = d[feats].to_numpy(float)
    oof = np.full(len(d), np.nan)
    for tr, te in folds:
        m = RandomForestClassifier(n_estimators=300, min_samples_leaf=3, max_features="sqrt",
                                   n_jobs=-1, random_state=SEED).fit(X[tr], y[tr])
        oof[te] = m.predict_proba(X[te])[:, 1]
    r, rel, c = slopes(oof, y, blk)
    ci_r, ci_c = boot_slopes(oof, y, blk)
    e = dict(surface=tag, n_features=len(feats), n_rows=int(len(d)),
             auc=round(float(roc_auc_score(y, oof)), 4),
             brier=round(float(brier_score_loss(y, oof)), 5),
             mean_oof_pct=round(100 * float(oof.mean()), 3),
             obs_pct=round(100 * float(y.mean()), 3),
             cal_in_large=round(float(y.mean() / oof.mean()), 4),
             block_slope_raw=round(r, 4), block_slope_raw_ci=ci_r,
             reliability=round(float(rel), 4),
             block_slope_disattenuated=round(float(c), 4), slope_dis_ci=ci_c)
    log(f"  {tag}: {json.dumps(e)}")
    return e, oof


ds = d[d.time_since_disturbance.notna()].reset_index(drop=True)
bs = ds.spatial_block.to_numpy(); ys = ds.trans_cut4.to_numpy(int)
fs = list(GroupKFold(n_splits=5).split(ds[AE].to_numpy(), groups=bs))
log(f"\n=== shipped form on the relabelled sample: {len(ds)} plots with time since disturbance ===")
e_new, oof_new = evaluate(FEAT_AE, f"AE64_n{len(ds)}_relabel2023", ds, bs, ys, fs)
yo = ds.trans_old.to_numpy(int)
e_old, oof_old = evaluate(FEAT_AE, f"AE64_n{len(ds)}_labels0408_sameplots", ds, bs, yo, fs)
cross = dict(auc_oldfit_on_newlabels=round(float(roc_auc_score(ys, oof_old)), 4),
             auc_newfit_on_oldlabels=round(float(roc_auc_score(yo, oof_new)), 4),
             spearman_oof=round(float(pd.Series(oof_new).corr(pd.Series(oof_old), method="spearman")), 4),
             n_label_change=int((ys != yo).sum()), n_gain=int(((ys == 1) & (yo == 0)).sum()), n_loss=int(((ys == 0) & (yo == 1)).sum()))
log(f"  cross: {json.dumps(cross)}")
pd.DataFrame({"plot_id": ds.plot_id, "oof_new": oof_new, "oof_old": oof_old, "y_new": ys, "y_old": yo}).to_csv(
    f"{KEEP}/t1_oof_RESTRICTED.csv", index=False)
SHIP, ship_tag, e_ship = FEAT_AE, e_new["surface"], e_new
dship = ds

# ------------------------------------------------------------------ artefacts for s3
log("\n=== final and bootstrap models for the tile step ===")
Xs = dship[SHIP].to_numpy(float)
ys = dship.trans_cut4.to_numpy(int); bshp = dship.spatial_block.to_numpy()
final = RandomForestClassifier(n_estimators=FINAL_NTREE, min_samples_leaf=3, max_features="sqrt",
                               n_jobs=-1, random_state=SEED).fit(Xs, ys)
pickle.dump(final, open(f"{BUILD}/rf_trans_final_{DATE}.pkl", "wb"))
ub = np.unique(bshp)
boots = []
for i in range(N_BOOT):
    pick = rng.choice(ub, len(ub), replace=True)
    idx = np.concatenate([np.where(bshp == b)[0] for b in pick])
    boots.append(RandomForestClassifier(n_estimators=BOOT_NTREE, min_samples_leaf=3,
                                        max_features="sqrt", n_jobs=-1,
                                        random_state=SEED + i).fit(Xs[idx], ys[idx]))
    log(f"  bootstrap model {i+1} of {N_BOOT}")
pickle.dump(boots, open(f"{BUILD}/rf_trans_boot_{DATE}.pkl", "wb"))
np.save(f"{BUILD}/env_min.npy", Xs.min(0)); np.save(f"{BUILD}/env_max.npy", Xs.max(0))

if final.n_features_in_ != len(SHIP) or any(b.n_features_in_ != len(SHIP) for b in boots) \
   or np.load(f"{BUILD}/env_min.npy").shape[0] != len(SHIP):
    die("PC4 a model or the environment envelope does not carry the shipped feature count")
log("PC4 PASS")

summary = dict(date=DATE, build=BUILD, seed=SEED, label="v5.1 total_score >= 4 at the 2019 to 2023 remeasurement (EVALID 232301 panel), transitioning and above",
               jurisdiction="ME", n=int(len(dship)), positives=int(ys.sum()),
               n_relabelled=int(len(d)), n_no_2023_score=int(len(pub) - len(d)), cross_label=cross,
               shipped_feature_set=ship_tag, shipped_features=SHIP,
               candidates=[e_new, e_old], shipped=e_ship,
               g4_reference_pct=[14.66, 13.40, 15.91],
               g4_reference_note=("adopted Maine design based any-LSOG, jobA v5.1, EVALID 232301. "
                                  "The relabelled sample rate is shipped.obs_pct."),
               artefacts=dict(final=f"rf_trans_final_{DATE}.pkl", boot=f"rf_trans_boot_{DATE}.pkl",
                              env=["env_min.npy", "env_max.npy"],
                              table=f"me_transitioning_training_table_DATA_{DATE}.csv"),
               scratch_warning="this build lives on purge eligible scratch")
json.dump(summary, open(f"{BUILD}/stageA_summary_{DATE}.json", "w"), indent=1, default=str)
json.dump(summary, open(f"{KEEP}/me_transitioning_stageA_summary_{DATE}.json", "w"), indent=1, default=str)
pd.DataFrame([e_new, e_old]).to_csv(f"{KEEP}/me_transitioning_stageA_candidates_DATA_{DATE}.csv", index=False)
log("\nSTAGE_A_DONE")
