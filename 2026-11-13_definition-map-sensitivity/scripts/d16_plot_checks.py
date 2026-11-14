#!/usr/bin/env python3
"""d16_plot_checks.py (November 14, 2026; arg me or nb). Plot-level checks asked for by the blind referee read of patch42.
(1) Label containment: of the plots positive under the stricter of two definitions, the share also positive under the
looser one, from the labels alone (no map). (2) New Brunswick only: design-weighted share of plots positive under at
least one, at least three and all six definitions, with a 20 km block bootstrap (weights w of the training table; not
ecoregion post-stratified, so it is a plot mean and not the estimator of Table S3). (3) Null fit: labels permuted, same
folds, features and learner; the slope of mean out-of-fold probability on the label rate shows what extent tracking
looks like with no skill. (4) 40 km blocks: the block bootstrap of d5/d9 rerun on 20 km blocks grouped two by two.
Aggregates only; cells under 10 plots are suppressed."""
import os, sys, json, numpy as np, pandas as pd
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score
J = sys.argv[1]; E = os.environ; W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = E["DS_SCR"]; K, BS = 5, 20000.0
if J == "me":
    PUB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
    FEAT = [f"AE_{i:02d}" for i in range(64)]; SEED = 20260917; DEFS = ["V3", "V1", "V2", "V4", "V9_c3", "V7"]; DES = [22.69, 15.92, 12.46, 9.50, 5.10, 2.26]
    d = pd.read_csv(PUB, low_memory=False)[["plot_id"] + FEAT]
    cw = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]; xy = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]]
    lab = pd.read_csv(f"{W}/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv", dtype={"PLT_CN": str})
    d = d.merge(cw, on="plot_id", how="inner").merge(xy, on="PLT_CN", how="inner").merge(lab, on="PLT_CN", how="inner")
    d = d[np.isfinite(d[FEAT].to_numpy(float)).all(1) & d["TRUE.LAT"].notna()].sort_values("plot_id").reset_index(drop=True); lon, lat = d["TRUE.LON"].values, d["TRUE.LAT"].values; w = np.ones(len(d))
else:
    NBB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-tsd2024-10m_2026-10-05"
    FEAT = [f"AE_{i:02d}" for i in range(64)] + ["time_since_disturbance"]; SEED = 20260927; DEFS = ["W2", "W1", "W4", "X9_c3", "X9", "W6"]; DES = [39.39, 31.47, 9.75, 9.37, 6.12, 4.49]
    t = pd.read_csv(f"{NBB}/trans_training_table_DATA_2026-09-27.csv"); c = pd.read_csv(f"{NBB}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv")
    d = pd.concat([c[["magp_site_id", "latitude", "longitude"]], t[FEAT + ["w"]]], axis=1).merge(pd.read_csv(f"{W}/RESTRICTED/nb_def_labels_RESTRICTED.csv"), on="magp_site_id", how="inner")
    d = d[np.isfinite(d[FEAT].to_numpy(float)).all(1)].sort_values("magp_site_id").reset_index(drop=True); lon, lat = d.longitude.values, d.latitude.values; w = d.w.to_numpy(float)
px, py = Transformer.from_crs(4326, 3979, always_xy=True).transform(lon, lat); bx = np.floor(np.asarray(px) / BS).astype(np.int64); by = np.floor(np.asarray(py) / BS).astype(np.int64)
fk = ((bx * 73856093) ^ (by * 19349663)) % K; blk = bx * 100000 + by; Y = d[DEFS].to_numpy(int); n = len(d); out = {"jurisdiction": J, "n_plots": int(n), "defs": DEFS}
# (1) label containment
cont = {}
for i in range(6):
    for j in range(i + 1, 6):
        a, b = Y[:, i], Y[:, j]; small, big = (b, a) if b.sum() <= a.sum() else (a, b); ns = int(small.sum())
        cont[f"{DEFS[i]}|{DEFS[j]}"] = None if ns < 10 else round(float((small & big).sum() / ns), 4)
out["label_containment_smaller_in_larger"] = cont; v = [x for x in cont.values() if x is not None]; out["label_containment_median"] = round(float(np.median(v)), 4); out["label_containment_min"] = round(float(min(v)), 4)
cnt = Y.sum(1); out["plots_by_count_unweighted"] = {str(k): int((cnt == k).sum()) for k in range(7) if (cnt == k).sum() >= 10}
# (2) weighted plot shares with a block bootstrap
u, inv = np.unique(blk, return_inverse=True); rng = np.random.default_rng(SEED)
def shares(ww):
    return [100 * float(np.sum(ww * (cnt >= k)) / np.sum(ww)) for k in (1, 3, 6)]
S0 = shares(w); B = []
for _ in range(2000):
    m = np.bincount(rng.integers(0, len(u), len(u)), minlength=len(u))[inv]; B.append(shares(w * m))
B = np.array(B); out["weighted_plot_share_pct"] = {k: {"est": round(S0[i], 3), "ci": [round(float(x), 3) for x in np.percentile(B[:, i], [2.5, 97.5])]} for i, k in enumerate(("any", "half", "all"))}
out["weighted_plot_share_note"] = "plot mean with design weights (Maine: unweighted fitted plots; see d15 for the design-based estimate); 20 km block bootstrap, 2,000 replicates"
# (3) null fit with permuted labels
X = d[FEAT].to_numpy("float32"); pr = np.random.default_rng(SEED + 7); rate, mean_null, auc_null = [], [], []
for j, vdef in enumerate(DEFS):
    y = pr.permutation(Y[:, j]); p = np.full(n, np.nan)
    for k in range(K):
        tr = fk != k
        m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + k).fit(X[tr], y[tr], sample_weight=(w[tr] if J == "nb" else None)); p[~tr] = m.predict_proba(X[~tr])[:, 1]
    rate.append(100 * float(np.average(y, weights=w))); mean_null.append(100 * float(np.average(p, weights=w))); auc_null.append(float(roc_auc_score(y, p, sample_weight=(w if J == "nb" else None)))); print("null", vdef, flush=True)
sl, ic = np.polyfit(rate, mean_null, 1)
out["null_permuted_labels"] = {"label_rate_pct": [round(x, 3) for x in rate], "mean_oof_prob_pct": [round(x, 3) for x in mean_null], "auc_oof": [round(x, 4) for x in auc_null],
                               "slope_mean_prob_on_rate": round(float(sl), 4), "intercept": round(float(ic), 4), "slope_on_design_pct": round(float(np.polyfit(DES, mean_null, 1)[0]), 4)}
# (4) 40 km blocks on the d5/d9 block table
Bk = pd.read_pickle(f"{SCR}/{J}_block_table.pkl"); gb = (np.round(Bk.block / 100000).astype(int) // 2) * 100000 + ((Bk.block - np.round(Bk.block / 100000).astype(int) * 100000).astype(int) // 2)
G = Bk.drop(columns=["block"]).groupby(gb.values).sum().reset_index(drop=True); nn = G.n.to_numpy(float); rng = np.random.default_rng(SEED + 40); bs = []
def st(ww):
    dd = (nn * ww).sum(); m = np.array([(G[f"p_{v}"] * ww).sum() / dd / 100.0 for v in DEFS])
    return [1 - (G.c0 * ww).sum() / dd, sum((G[f"c{k}"] * ww).sum() for k in range(3, 7)) / dd, (G.c6 * ww).sum() / dd, float(np.polyfit(DES, m, 1)[0])]
for _ in range(2000): bs.append(st(np.bincount(rng.integers(0, len(G), len(G)), minlength=len(G)).astype(float)))
bs = np.array(bs); s0 = st(np.ones(len(G)))
out["blocks_40km"] = {"n_blocks": int(len(G)), **{k: {"est": round((100 if i < 3 else 1) * s0[i], 3), "ci": [round((100 if i < 3 else 1) * float(x), 3) for x in np.percentile(bs[:, i], [2.5, 97.5])]} for i, k in enumerate(("any", "half", "all", "slope"))}}
json.dump(out, open(f"{W}/out/d16_{J}_plot_checks_DATA.json", "w"), indent=1); print(json.dumps(out), "DONE", flush=True)
