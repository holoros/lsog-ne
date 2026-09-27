#!/usr/bin/env python3
# s2c_learner_compare_blocked.py  (added 2026-09-16, local session)
# Puts RF and MOSVR on one footing before the learner decision. mosvr_pareto.R searches hyperparameters
# on an unweighted 4,000-row subsample with random folds and reports obs-on-pred slopes at plot level,
# which cannot be compared with the RF block-level pred-on-obs slope from s2. Here the MOSVR
# total-error-optimal and knee settings from M2_pareto.csv are refit with the SAME within-jurisdiction
# GroupKFold folds, the SAME CLI_Grid weights and the SAME block calibration and bootstrap as s2.
# SVR mirrors e1071 defaults: radial kernel, x and y standardized, epsilon in scaled-y units.
# Both slope directions are reported for both learners. Writes s2c_learner_compare_2026-09-16.json.
import os, json, time
import numpy as np, pandas as pd
from joblib import Parallel, delayed
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ; B = E["BUILD"]; SEED = int(E["SEED"])
AE = [f"AE_{i:02d}" for i in range(64)]; FEAT = AE + ["time_since_disturbance"]
d = pd.read_csv(f"{B}/core4_training_table_DATA_2026-09-16.csv")
X = d[FEAT].to_numpy(float); y = d["core4_cut3"].to_numpy(float)
w = d["w"].to_numpy(float); jur = d["jurisdiction"].to_numpy(); blk = d["blk"].to_numpy()
rf = pd.read_csv(f"{B}/s2_rf_oof_DATA_2026-09-16.csv")
assert (rf.plot_id_export.values == d.plot_id_export.values).all(), "row order differs from s2"

par = pd.read_csv(f"{B}/mosvr_output/M2_pareto.csv").sort_values("rmse").reset_index(drop=True)
allg = pd.read_csv(f"{B}/mosvr_output/M1_grid_objectives.csv")
to = allg.loc[allg.rmse.idxmin()]
rn = (par.rmse - par.rmse.min()) / (par.rmse.max() - par.rmse.min() + 1e-9)
sn = (par.sys - par.sys.min()) / (par.sys.max() - par.sys.min() + 1e-9)
knee = par.loc[np.argmin(np.sqrt(rn**2 + sn**2))]
settings = {"mosvr_total_error_optimal": to, "mosvr_knee": knee}

folds = []
for j in ["ME", "NB"]:
    ij = np.where(jur == j)[0]; io = np.where(jur != j)[0]
    for tr, te in GroupKFold(n_splits=5).split(ij, groups=blk[ij]):
        folds.append((np.concatenate([ij[tr], io]), ij[te]))

def fit_fold(tri, tei, c, g, e):
    sx = StandardScaler().fit(X[tri]); my, sy = y[tri].mean(), y[tri].std()
    m = SVR(kernel="rbf", C=c, gamma=g, epsilon=e, cache_size=4000)
    m.fit(sx.transform(X[tri]), (y[tri] - my) / sy, sample_weight=w[tri])
    return tei, m.predict(sx.transform(X[tei])) * sy + my

rng = np.random.default_rng(SEED)
ub = np.unique(blk); bidx = {b: np.where(blk == b)[0] for b in ub}
def metrics(p, name):
    ok = np.isfinite(p)
    rmse = float(np.sqrt(np.average((y[ok] - p[ok])**2, weights=w[ok])))
    auc = float(roc_auc_score(y[ok], p[ok], sample_weight=w[ok]))
    bt = pd.DataFrame({"blk": blk, "y": y * w, "p": p * w, "w": w}).groupby("blk").sum()
    cnt = pd.Series(blk).value_counts(); bt = bt[cnt.reindex(bt.index) >= 20]
    o = (bt.y / bt.w).to_numpy(); q = (bt.p / bt.w).to_numpy()
    r = np.random.default_rng(SEED)
    res = {}
    for lab, (a, b) in {"pred_on_obs": (o, q), "obs_on_pred": (q, o)}.items():
        s = float(np.polyfit(a, b, 1)[0])
        bs = [float(np.polyfit(a[i], b[i], 1)[0]) for i in (r.integers(0, len(a), len(a)) for _ in range(2000))]
        res[lab] = {"slope": s, "ci": [float(np.percentile(bs, 2.5)), float(np.percentile(bs, 97.5))]}
    top = o >= np.quantile(o, 0.9)
    res["pred_on_obs_top_decile"] = float(np.polyfit(o[top], q[top], 1)[0])
    out = {"rmse_w": rmse, "auc_w": auc, "n_blocks": int(len(o)), **res,
           "mean_pred_pct": {j: float(100 * np.average(p[jur == j], weights=w[jur == j])) for j in ["ME", "NB"]}}
    log(f"{name}: {json.dumps(out)}")
    return out

summary = {"rf": metrics(rf.oof_prob.to_numpy(), "rf")}
for name, s in settings.items():
    c, g, e = float(s.cost), float(s.gamma), float(s.eps)
    log(f"fitting {name} cost={c} gamma={g} eps={e} on {len(folds)} blocked folds")
    p = np.full(len(d), np.nan)
    for tei, pr in Parallel(n_jobs=len(folds))(delayed(fit_fold)(tr, te, c, g, e) for tr, te in folds):
        p[tei] = pr
    summary[name] = {"cost": c, "gamma": g, "eps": e, "pareto_search": s.to_dict(), **metrics(p, name)}
    pd.DataFrame({"plot_id_export": d.plot_id_export, name: p}).to_csv(f"{B}/s2c_{name}_oof_DATA_2026-09-16.csv", index=False)
for k in summary:
    summary[k]["abs_1_minus_pred_on_obs"] = abs(1 - summary[k]["pred_on_obs"]["slope"])
json.dump(summary, open(f"{B}/s2c_learner_compare_2026-09-16.json", "w"), indent=2, default=float)
log("S2C_DONE")
