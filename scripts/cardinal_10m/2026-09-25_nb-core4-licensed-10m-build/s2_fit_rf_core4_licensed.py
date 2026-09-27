#!/usr/bin/env python3
# s2_fit_rf_core4.py
# Pooled ME+NB random forest for CORE4 cut-3 any-LSOG, no jurisdiction term, 64 AlphaEarth bands plus
# Hansen time since disturbance, NB rows carrying CLI_Grid design weights. Mirrors the evaluation set of
# pooled_train_nojurisd_disturb_2026-09-04.py and adds what a rare binary class needs:
#   within-jurisdiction spatially blocked CV (GroupKFold on blk), leave-one-jurisdiction-out,
#   block-level calibration slope (predicted on observed, house convention) with a block bootstrap
#   interval, AUC with a block bootstrap interval, a label-permutation null floor, and the F5 check that
#   the weighted mean OOF probability sits near each jurisdiction's published sample rate.
# Writes the final model, 20 spatial-block bootstrap models for the SD layer, the MOSVR input table,
# and a JSON summary. No coordinates are read.
import os, sys, json, pickle, time
import numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score

T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ
BUILD = E["BUILD"]; SEED = int(E["SEED"]); rng = np.random.default_rng(SEED)
AE = [f"AE_{i:02d}" for i in range(64)]
FEAT = AE + ["time_since_disturbance"]

d = pd.read_csv(f"{BUILD}/core4_training_table_DATA_2026-09-25.csv")
X = d[FEAT].to_numpy(float); y = d["core4_cut3"].to_numpy(int)
w = d["w"].to_numpy(float); jur = d["jurisdiction"].to_numpy(); blk = d["blk"].to_numpy()
log(f"rows {len(d)}  ME {np.sum(jur=='ME')}  NB {np.sum(jur=='NB')}  positives {y.sum()}")

def rf(n=300, seed=SEED):
    return RandomForestClassifier(n_estimators=n, min_samples_leaf=3, max_features="sqrt",
                                  n_jobs=-1, random_state=seed)

# (a) within-jurisdiction spatially blocked CV, other jurisdiction always in training
oof = np.full(len(d), np.nan)
cv = {}
for j in ["ME", "NB"]:
    ij = np.where(jur == j)[0]; io = np.where(jur != j)[0]
    for tr, te in GroupKFold(n_splits=5).split(ij, groups=blk[ij]):
        tri = np.concatenate([ij[tr], io]); tei = ij[te]
        m = rf(); m.fit(X[tri], y[tri], sample_weight=w[tri])
        oof[tei] = m.predict_proba(X[tei])[:, 1]
    cv[j] = {"auc": float(roc_auc_score(y[ij], oof[ij], sample_weight=w[ij])), "n": int(len(ij)),
             "n_blocks": int(len(set(blk[ij]))),
             "obs_rate_pct": float(100 * np.average(y[ij], weights=w[ij])),
             "mean_oof_prob_pct": float(100 * np.average(oof[ij], weights=w[ij]))}
    log(f"(a) {j}: {cv[j]}")

# block bootstrap helper, resampling whole blocks
ub = np.unique(blk)
bidx = {b: np.where(blk == b)[0] for b in ub}
def boot(stat, B=2000):
    out = []
    for _ in range(B):
        take = np.concatenate([bidx[b] for b in rng.choice(ub, size=len(ub), replace=True)])
        try: out.append(stat(take))
        except ValueError: pass
    return [float(np.percentile(out, 2.5)), float(np.percentile(out, 97.5))]

auc_all = float(roc_auc_score(y, oof, sample_weight=w))
auc_ci = boot(lambda t: roc_auc_score(y[t], oof[t], sample_weight=w[t]))
log(f"pooled OOF AUC {auc_all:.4f} {auc_ci}")

# block-level calibration: predicted rate regressed on observed rate across blocks with >= 20 plots
bt = pd.DataFrame({"blk": blk, "y": y * w, "p": oof * w, "w": w}).groupby("blk").sum()
cnt = pd.Series(blk).value_counts()
bt = bt[cnt.reindex(bt.index) >= 20]
obs_b = (bt.y / bt.w).to_numpy(); pred_b = (bt.p / bt.w).to_numpy()
slope = float(np.polyfit(obs_b, pred_b, 1)[0])
sl = [float(np.polyfit(obs_b[i], pred_b[i], 1)[0])
      for i in (rng.integers(0, len(obs_b), len(obs_b)) for _ in range(2000))]
slope_ci = [float(np.percentile(sl, 2.5)), float(np.percentile(sl, 97.5))]
top = obs_b >= np.quantile(obs_b, 0.9)
slope_top = float(np.polyfit(obs_b[top], pred_b[top], 1)[0]) if top.sum() > 4 else float("nan")
log(f"block calibration (pred on obs): slope {slope:.3f} {slope_ci}, top decile {slope_top:.3f}, blocks {len(obs_b)}")

# (b) leave one jurisdiction out
lojo = {}
for a, b in [("ME", "NB"), ("NB", "ME")]:
    ia, ib = jur == a, jur == b
    m = rf(); m.fit(X[ia], y[ia], sample_weight=w[ia])
    lojo[f"train_{a}_predict_{b}"] = float(roc_auc_score(y[ib], m.predict_proba(X[ib])[:, 1], sample_weight=w[ib]))
log(f"(b) LOJO AUC {lojo}")

# null floor, labels permuted within jurisdiction, same blocked CV (3 permutations)
null = []
for k in range(3):
    yp = y.copy()
    for j in ["ME", "NB"]:
        ij = np.where(jur == j)[0]; yp[ij] = rng.permutation(yp[ij])
    op = np.full(len(d), np.nan)
    for tr, te in GroupKFold(n_splits=5).split(X, groups=blk):
        m = rf(n=150, seed=SEED + k); m.fit(X[tr], yp[tr], sample_weight=w[tr])
        op[te] = m.predict_proba(X[te])[:, 1]
    null.append(float(roc_auc_score(yp, op, sample_weight=w)))
log(f"null AUC floor {null}")

# ---- gates (F5 and model sanity), references from config, never from this run ----
def ref(k): return [float(v) for v in E[k].split(",")]
fails = []
if auc_ci[0] <= max(null) + 0.02: fails.append(f"AUC lower bound {auc_ci[0]:.3f} not above null {max(null):.3f}")
for j, k in [("ME", "REF_ME_SAMPLE_RATE"), ("NB", "REF_NB_PUBLIC_RATE")]:
    r = ref(k); mp = cv[j]["mean_oof_prob_pct"]
    if not (0.5 * r[1] <= mp <= 2.0 * r[2]):
        fails.append(f"{j} mean OOF probability {mp:.2f}% outside absurdity bounds of {r}")
json.dump({"feature_set": FEAT, "n": int(len(d)), "positives": int(y.sum()),
           "within_jur_cv": cv, "pooled_auc": auc_all, "pooled_auc_ci": auc_ci,
           "block_calibration_slope_pred_on_obs": slope, "slope_ci": slope_ci,
           "slope_top_decile": slope_top, "n_blocks_calib": int(len(obs_b)),
           "lojo_auc": lojo, "null_auc": null, "gate_failures": fails},
          open(f"{BUILD}/s2_rf_summary_2026-09-25.json", "w"), indent=2)
pd.DataFrame({"plot_id_export": d.plot_id_export, "jurisdiction": jur, "blk": blk,
              "observed": y, "w": w, "oof_prob": oof}).to_csv(f"{BUILD}/s2_rf_oof_DATA_2026-09-25.csv", index=False)
if fails:
    for f in fails: log("FAIL " + f)
    sys.exit(2)

# MOSVR input, same rows and features, no ids beyond the export id
d[["plot_id_export"] + FEAT + ["core4_cut3"]].to_csv(f"{BUILD}/s2_mosvr_input_DATA_2026-09-25.csv", index=False)

final = rf(n=int(E["FINAL_NTREE"])); final.fit(X, y, sample_weight=w)
pickle.dump(final, open(f"{BUILD}/rf_core4_final_2026-09-25.pkl", "wb"))
boots = []
for b in range(int(E["N_BOOT"])):
    take = np.concatenate([bidx[k] for k in rng.choice(ub, size=len(ub), replace=True)])
    m = rf(n=int(E["BOOT_NTREE"]), seed=SEED + 100 + b); m.fit(X[take], y[take], sample_weight=w[take])
    boots.append(m)
pickle.dump(boots, open(f"{BUILD}/rf_core4_boot_2026-09-25.pkl", "wb"))
np.save(f"{BUILD}/env_min.npy", X.min(0)); np.save(f"{BUILD}/env_max.npy", X.max(0))
log("S2_DONE")
