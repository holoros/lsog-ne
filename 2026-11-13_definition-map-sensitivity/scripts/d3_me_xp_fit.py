#!/usr/bin/env python3
"""d3_me_xp_fit.py (November 13, 2026). Maine, six definitions, cross-predicted forests.
PREREG 2026-11-13_menb-definition-map-sensitivity: plots, predictors (64 AlphaEarth 2024 bands), learner (random
forest, 500 trees, minimum leaf 3, sqrt features), blocks and seed are fixed; only the label changes.
Folds follow the rule of 2026-11-06_retrain/scripts/a1_xp_fit.py and a3_xp_predict.py so plots and map cells use one
rule: fold = hash of the 20 km block in EPSG:3979, K = 5; forest k is fit without fold k.
True coordinates are read only to assign folds and are never written. Outputs: a model bundle and the training
envelope in scratch, a per-plot out-of-fold table in RESTRICTED, and aggregates (>= 10 plots) in out/."""
import os, json, pickle, hashlib, numpy as np, pandas as pd
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
E = os.environ; W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = E["DS_SCR"]
PUB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
AE = [f"AE_{i:02d}" for i in range(64)]; SEED = 20260917; K, BS = 5, 20000.0; MIN_POS = 60
DEFS = ["V3", "V1", "V2", "V4", "V9_c3", "V7"]
TARGET = {"V3": 22.69, "V1": 15.92, "V2": 12.46, "V4": 9.50, "V9_c3": 5.10, "V7": 2.26}
def fold_of(x, y):
    bx = np.floor(np.asarray(x) / BS).astype(np.int64); by = np.floor(np.asarray(y) / BS).astype(np.int64)
    return ((bx * 73856093) ^ (by * 19349663)) % K, bx * 100000 + by
d = pd.read_csv(PUB, low_memory=False)[["plot_id"] + AE]
cw = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
xy = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]]
lab = pd.read_csv(f"{W}/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv", dtype={"PLT_CN": str})
n0 = len(d); d = d.merge(cw, on="plot_id", how="inner").merge(xy, on="PLT_CN", how="inner").merge(lab, on="PLT_CN", how="inner")
d = d[np.isfinite(d[AE].to_numpy(float)).all(1) & d["TRUE.LAT"].notna()].sort_values("plot_id").reset_index(drop=True)   # stable key order
assert d.plot_id.is_unique and d.PLT_CN.is_unique
px, py = Transformer.from_crs(4326, 3979, always_xy=True).transform(d["TRUE.LON"].values, d["TRUE.LAT"].values)
fk, blk = fold_of(px, py); X = d[AE].to_numpy("float32")
out = {"n_table": int(n0), "n_fit": int(len(d)), "K": K, "block_m": BS, "seed": SEED, "n_blocks": int(len(np.unique(blk))),
       "fold_sizes": [int((fk == k).sum()) for k in range(K)], "defs": {}}
def block_slope(p, y):
    u, inv = np.unique(blk, return_inverse=True); n = np.bincount(inv); o = np.bincount(inv, y) / n; q = np.bincount(inv, p) / n; m = n >= 5
    return float(np.polyfit(o[m], q[m], 1)[0]), int(m.sum())
bundle = {"K": K, "BS": BS, "features": AE, "defs": [], "models": {}}; oof = pd.DataFrame({"plot_id": d.plot_id})
for v in DEFS:
    y = d[v].to_numpy(int); npos = int(y.sum()); r = {"n_pos": npos, "sample_rate_pct": round(100 * y.mean(), 3), "design_pct": TARGET[v]}
    if npos < MIN_POS or min(int(y[fk == k].sum()) for k in range(K)) < 1:
        r["mapped"] = False; out["defs"][v] = r; print(v, "NOT MAPPED", r, flush=True); continue
    p = np.full(len(y), np.nan); ms = []
    for k in range(K):
        tr = fk != k
        m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + k).fit(X[tr], y[tr])
        p[~tr] = m.predict_proba(X[~tr])[:, 1]; ms.append(m)
    s, nb = block_slope(p, y)
    r.update(mapped=True, auc_oof=round(float(roc_auc_score(y, p)), 4), mean_oof_pct=round(100 * float(p.mean()), 3),
             block_slope_oof=round(s, 4), blocks_in_slope=nb)
    bundle["defs"].append(v); bundle["models"][v] = ms; oof[v + "_y"] = y; oof[v + "_p"] = p; out["defs"][v] = r; print(v, r, flush=True)
# order safety: refit one definition on rows in reversed order and compare the out-of-fold AUC
v = bundle["defs"][0]; idx = np.arange(len(d))[::-1]; y = d[v].to_numpy(int); p2 = np.full(len(y), np.nan)
for k in range(K):
    tr = fk[idx] != k
    m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + k).fit(X[idx][tr], y[idx][tr])
    p2[idx[~tr]] = m.predict_proba(X[idx][~tr])[:, 1]
out["row_order_check"] = {"definition": v, "auc_sorted": out["defs"][v]["auc_oof"], "auc_reversed": round(float(roc_auc_score(y, p2)), 4),
                          "corr_oof": round(float(np.corrcoef(oof[v + "_p"], p2)[0, 1]), 4)}
pickle.dump(bundle, open(f"{SCR}/me_defsens_xp_bundle.pkl", "wb")); np.save(f"{SCR}/me_env_min.npy", X.min(0)); np.save(f"{SCR}/me_env_max.npy", X.max(0))
oof.to_csv(f"{W}/RESTRICTED/me_defsens_oof_RESTRICTED.csv", index=False)
json.dump(out, open(f"{W}/out/d3_me_xp_fit_DATA.json", "w"), indent=1); print(json.dumps(out["row_order_check"]), "DONE", flush=True)
