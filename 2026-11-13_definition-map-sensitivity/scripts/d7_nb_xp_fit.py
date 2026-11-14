#!/usr/bin/env python3
"""d7_nb_xp_fit.py (November 13, 2026). New Brunswick, six definitions, cross-predicted forests.
Held fixed as in the licensed 10 m builds of October 5: the 9,042 licensed plots, the 64 AlphaEarth 2024 bands plus
time since disturbance, the CLI_Grid design weights as sample weights, random forest (500 trees, minimum leaf 3,
sqrt features). Only the label changes. Folds use the rule of the Maine fits: 20 km block in EPSG:3979, K = 5.
Licensed coordinates are read in memory only to assign folds. Aggregates only leave RESTRICTED."""
import os, json, pickle, numpy as np, pandas as pd
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = os.environ["DS_SCR"]
NBB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-tsd2024-10m_2026-10-05"
AE = [f"AE_{i:02d}" for i in range(64)]; FEAT = AE + ["time_since_disturbance"]; SEED = 20260927; K, BS = 5, 20000.0; MIN_POS = 60
DEFS = ["W2", "W1", "W4", "X9_c3", "X9", "W6"]; TARGET = {"W2": 39.39, "W1": 31.47, "W4": 9.75, "X9_c3": 9.37, "X9": 6.12, "W6": 4.49}
def fold_of(x, y):
    bx = np.floor(np.asarray(x) / BS).astype(np.int64); by = np.floor(np.asarray(y) / BS).astype(np.int64)
    return ((bx * 73856093) ^ (by * 19349663)) % K, bx * 100000 + by
t = pd.read_csv(f"{NBB}/trans_training_table_DATA_2026-09-27.csv"); c = pd.read_csv(f"{NBB}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv")
assert len(t) == len(c) == 9042 and (t.jurisdiction == "NB").all()
assert np.array_equal(t.time_since_disturbance.to_numpy(float), c.time_since_disturbance.to_numpy(float)) and np.array_equal(t.trans_ge4.to_numpy(int), c.trans_ge4.to_numpy(int)), "cache and table rows differ"
d = pd.concat([c[["magp_site_id", "latitude", "longitude"]], t[FEAT + ["w"]]], axis=1)
lab = pd.read_csv(f"{W}/RESTRICTED/nb_def_labels_RESTRICTED.csv"); n0 = len(d); d = d.merge(lab, on="magp_site_id", how="inner")
w1_match = float((d.W1.to_numpy(int) == c.set_index("magp_site_id").loc[d.magp_site_id, "trans_ge4"].to_numpy(int)).mean())
d = d[np.isfinite(d[FEAT].to_numpy(float)).all(1)].sort_values("magp_site_id").reset_index(drop=True); assert d.magp_site_id.is_unique
px, py = Transformer.from_crs(4326, 3979, always_xy=True).transform(d.longitude.values, d.latitude.values); fk, blk = fold_of(px, py)
X = d[FEAT].to_numpy("float32"); w = d.w.to_numpy(float)
out = {"n_table": int(n0), "n_fit": int(len(d)), "W1_equals_archived_trans_label_share": round(w1_match, 5), "K": K, "block_m": BS, "seed": SEED,
       "n_blocks": int(len(np.unique(blk))), "fold_sizes": [int((fk == k).sum()) for k in range(K)], "defs": {}}
def block_slope(p, y):
    u, inv = np.unique(blk, return_inverse=True); n = np.bincount(inv, w); o = np.bincount(inv, w * y) / n; q = np.bincount(inv, w * p) / n; m = np.bincount(inv) >= 5
    return float(np.polyfit(o[m], q[m], 1)[0]), int(m.sum())
bundle = {"K": K, "BS": BS, "features": FEAT, "defs": [], "models": {}}; oof = pd.DataFrame({"magp_site_id": d.magp_site_id})
for v in DEFS:
    y = d[v].to_numpy(int); npos = int(y.sum()); r = {"n_pos": npos, "sample_rate_weighted_pct": round(100 * float(np.average(y, weights=w)), 3), "design_pct": TARGET[v]}
    if npos < MIN_POS: r["mapped"] = False; out["defs"][v] = r; print(v, "NOT MAPPED", flush=True); continue
    p = np.full(len(y), np.nan); ms = []
    for k in range(K):
        tr = fk != k
        m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + k).fit(X[tr], y[tr], sample_weight=w[tr])
        p[~tr] = m.predict_proba(X[~tr])[:, 1]; ms.append(m)
    s, nb = block_slope(p, y)
    r.update(mapped=True, auc_oof=round(float(roc_auc_score(y, p, sample_weight=w)), 4), mean_oof_weighted_pct=round(100 * float(np.average(p, weights=w)), 3), block_slope_oof=round(s, 4), blocks_in_slope=nb)
    bundle["defs"].append(v); bundle["models"][v] = ms; oof[v + "_y"] = y; oof[v + "_p"] = p; out["defs"][v] = r; print(v, r, flush=True)
pickle.dump(bundle, open(f"{SCR}/nb_defsens_xp_bundle.pkl", "wb")); np.save(f"{SCR}/nb_env_min.npy", X.min(0)); np.save(f"{SCR}/nb_env_max.npy", X.max(0))
oof.to_csv(f"{W}/RESTRICTED/nb_defsens_oof_RESTRICTED.csv", index=False)
json.dump(out, open(f"{W}/out/d7_nb_xp_fit_DATA.json", "w"), indent=1); print("DONE", flush=True)
