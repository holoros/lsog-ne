#!/usr/bin/env python3
# s2d_mosvr_retune_blocked.py  (added 2026-09-16 at Aaron's request, after s2c)
# The mosvr_pareto.R grid starts at gamma 0.25, which on 65 standardized features is about 16 times
# 1/p and flattens the RBF fit. This reruns the MoSVR Pareto search with gamma scaled to p = 65,
# on the full weighted table and the SAME within-jurisdiction GroupKFold folds as s2 and s2c.
# Objectives: total error = weighted OOF RMSE; systematic error under the house adoption rule
# sys_po = |1 - block-level predicted-on-observed slope| (s2 convention), with the skill's plot-level
# sys_op = |1 - slope of observed on predicted| reported alongside and its own knee identified.
# Writes s2d_grid_DATA_2026-09-16.csv, s2d_pareto_DATA_2026-09-16.csv, s2d_mosvr_retune_2026-09-16.json.
import os, json, time, itertools
import numpy as np, pandas as pd
from joblib import Parallel, delayed
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ; B = E["BUILD"]; SEED = int(E["SEED"])
FEAT = [f"AE_{i:02d}" for i in range(64)] + ["time_since_disturbance"]
d = pd.read_csv(f"{B}/core4_training_table_DATA_2026-09-16.csv")
X = d[FEAT].to_numpy(float); y = d["core4_cut3"].to_numpy(float)
w = d["w"].to_numpy(float); jur = d["jurisdiction"].to_numpy(); blk = d["blk"].to_numpy()
folds = []
for j in ["ME", "NB"]:
    ij = np.where(jur == j)[0]; io = np.where(jur != j)[0]
    for tr, te in GroupKFold(n_splits=5).split(ij, groups=blk[ij]):
        folds.append((np.concatenate([ij[tr], io]), ij[te]))
cnt = pd.Series(blk).value_counts()

def block_xy(p):
    bt = pd.DataFrame({"blk": blk, "y": y * w, "p": p * w, "w": w}).groupby("blk").sum()
    bt = bt[cnt.reindex(bt.index) >= 20]
    return (bt.y / bt.w).to_numpy(), (bt.p / bt.w).to_numpy()

def fit_fold(k, c, g, e):
    tri, tei = folds[k]
    sx = StandardScaler().fit(X[tri]); my, sy = y[tri].mean(), y[tri].std()
    m = SVR(kernel="rbf", C=c, gamma=g, epsilon=e, cache_size=2000)
    m.fit(sx.transform(X[tri]), (y[tri] - my) / sy, sample_weight=w[tri])
    return m.predict(sx.transform(X[tei])) * sy + my

P = len(FEAT)
grid = list(itertools.product([0.25, 1, 4, 16], [0.25 / P, 0.5 / P, 1 / P, 2 / P, 4 / P], [0.1, 0.5, 1.0]))
log(f"{len(grid)} settings x {len(folds)} folds, gamma values {sorted(set(g for _, g, _ in grid))}")
jobs = [(i, k) for i in range(len(grid)) for k in range(len(folds))]
out = Parallel(n_jobs=int(E.get("SLURM_CPUS_PER_TASK", "8")), verbose=0)(
    delayed(fit_fold)(k, *grid[i]) for i, k in jobs)
preds = {i: np.full(len(d), np.nan) for i in range(len(grid))}
for (i, k), pr in zip(jobs, out):
    preds[i][folds[k][1]] = pr
log("fits done")
rows = []
for i, (c, g, e) in enumerate(grid):
    p = preds[i]
    o, q = block_xy(p)
    s_po = float(np.polyfit(o, q, 1)[0])
    s_op = float(np.polyfit(p, y, 1, w=np.sqrt(w))[0])
    rows.append(dict(i=i, cost=c, gamma=g, eps=e,
                     rmse=float(np.sqrt(np.average((y - p) ** 2, weights=w))),
                     auc=float(roc_auc_score(y, p, sample_weight=w)),
                     slope_po_block=s_po, sys_po=abs(1 - s_po),
                     slope_op_plot=s_op, sys_op=abs(1 - s_op)))
G = pd.DataFrame(rows); G.to_csv(f"{B}/s2d_grid_DATA_2026-09-16.csv", index=False)

def front(G, sys):
    keep = []
    for a in G.itertuples():
        dom = ((G.rmse <= a.rmse) & (G[sys] <= getattr(a, sys)) &
               ((G.rmse < a.rmse) | (G[sys] < getattr(a, sys)))).any()
        if not dom: keep.append(a.Index)
    F = G.loc[keep].sort_values("rmse")
    rn = (F.rmse - F.rmse.min()) / (F.rmse.max() - F.rmse.min() + 1e-9)
    sn = (F[sys] - F[sys].min()) / (F[sys].max() - F[sys].min() + 1e-9)
    return F, F.index[np.argmin(np.sqrt(rn**2 + sn**2))]
F, knee = front(G, "sys_po"); F.to_csv(f"{B}/s2d_pareto_DATA_2026-09-16.csv", index=False)
_, knee_op = front(G, "sys_op")
te = G.rmse.idxmin()

def boot_slope(p, R=2000):
    o, q = block_xy(p); r = np.random.default_rng(SEED)
    bs = [np.polyfit(o[s], q[s], 1)[0] for s in (r.integers(0, len(o), len(o)) for _ in range(R))]
    return [float(np.percentile(bs, 2.5)), float(np.percentile(bs, 97.5))]
res = {"n_grid": len(grid), "n_pareto_sys_po": int(len(F))}
for name, idx in [("total_error_optimal", te), ("knee_house_po", knee), ("knee_skill_op", knee_op)]:
    r = G.loc[idx].to_dict(); r["slope_po_block_ci"] = boot_slope(preds[idx])
    r["mean_pred_pct"] = {j: float(100 * np.average(preds[idx][jur == j], weights=w[jur == j])) for j in ["ME", "NB"]}
    res[name] = r; log(f"{name}: {json.dumps(r)}")
    pd.DataFrame({"plot_id_export": d.plot_id_export, "oof": preds[idx]}).to_csv(
        f"{B}/s2d_{name}_oof_DATA_2026-09-16.csv", index=False)
json.dump(res, open(f"{B}/s2d_mosvr_retune_2026-09-16.json", "w"), indent=2, default=float)
log("S2D_DONE")
