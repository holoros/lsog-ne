#!/usr/bin/env python3
"""d10_stress.py (November 13, 2026). PREREG stress alternatives that are cheap on existing outputs.
Part A (arg: me or nb): a fixed 0.5 probability threshold in place of the rank rule, on the cross-predicted tiles
of d4 and d8 with the same cutline, frame and zone rule as d5 and d9 (their load() is imported unchanged).
Part B: five seeds for the base card of each jurisdiction (V1, W1), refit at plot level with the folds, features and
learner of d3 and d7. Seed 0 is the seed of the mapped layer. The surfaces are not remapped for seeds 1 to 4, so
Part B measures seed noise in out-of-fold plot predictions, not in mapped cells. Aggregates only."""
import os, sys, json, importlib.util, numpy as np, pandas as pd
from multiprocessing import Pool
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); J = sys.argv[1]; assert J in ("me", "nb")
spec = importlib.util.spec_from_file_location("agg", f"{W}/scripts/" + ("d5_me_aggregate.py" if J == "me" else "d9_nb_aggregate.py"))
A = importlib.util.module_from_spec(spec); spec.loader.exec_module(A); ND = A.ND; DEFS = A.DEFS
def part_a(path):
    a, ok, *_ = A.load(path); n = int(ok.sum())
    if n == 0: return np.zeros(ND, np.int64), np.zeros(ND + 1, np.int64), 0
    F = a[:ND][:, ok] >= 5000; return F.sum(1).astype(np.int64), np.bincount(F.sum(0), minlength=ND + 1).astype(np.int64), n
def five_seeds():
    from pyproj import Transformer
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import roc_auc_score
    E = os.environ; K, BS = 5, 20000.0
    if J == "me":
        PUB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
        FEAT = [f"AE_{i:02d}" for i in range(64)]; SEED = 20260917; v = "V1"; rate = 15.92
        d = pd.read_csv(PUB, low_memory=False)[["plot_id"] + FEAT]
        cw = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
        xy = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]]
        lab = pd.read_csv(f"{W}/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv", dtype={"PLT_CN": str})
        d = d.merge(cw, on="plot_id", how="inner").merge(xy, on="PLT_CN", how="inner").merge(lab, on="PLT_CN", how="inner")
        d = d[np.isfinite(d[FEAT].to_numpy(float)).all(1) & d["TRUE.LAT"].notna()].sort_values("plot_id").reset_index(drop=True)
        lon, lat = d["TRUE.LON"].values, d["TRUE.LAT"].values; w = np.ones(len(d))
    else:
        NBB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/nb-trans-licensed-tsd2024-10m_2026-10-05"
        FEAT = [f"AE_{i:02d}" for i in range(64)] + ["time_since_disturbance"]; SEED = 20260927; v = "W1"; rate = 31.47
        t = pd.read_csv(f"{NBB}/trans_training_table_DATA_2026-09-27.csv"); c = pd.read_csv(f"{NBB}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv")
        d = pd.concat([c[["magp_site_id", "latitude", "longitude"]], t[FEAT + ["w"]]], axis=1)
        d = d.merge(pd.read_csv(f"{W}/RESTRICTED/nb_def_labels_RESTRICTED.csv"), on="magp_site_id", how="inner")
        d = d[np.isfinite(d[FEAT].to_numpy(float)).all(1)].sort_values("magp_site_id").reset_index(drop=True)
        lon, lat = d.longitude.values, d.latitude.values; w = d.w.to_numpy(float)
    px, py = Transformer.from_crs(4326, 3979, always_xy=True).transform(lon, lat)
    bx = np.floor(np.asarray(px) / BS).astype(np.int64); by = np.floor(np.asarray(py) / BS).astype(np.int64); fk = ((bx * 73856093) ^ (by * 19349663)) % K
    X = d[FEAT].to_numpy("float32"); y = d[v].to_numpy(int); P = []
    for s in range(5):
        p = np.full(len(y), np.nan)
        for k in range(K):
            tr = fk != k
            m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + 1000 * s + k)
            m.fit(X[tr], y[tr], sample_weight=(w[tr] if J == "nb" else None)); p[~tr] = m.predict_proba(X[~tr])[:, 1]
        P.append(p); print("seed", s, flush=True)
    P = np.array(P); nf = int(round(len(y) * rate / 100.0)); order = np.argsort(d.iloc[:, 0].astype(str).values, kind="stable")   # stable key for ties
    flag = []
    for p in P:
        o = np.lexsort((order, -p)); f = np.zeros(len(y), bool); f[o[:nf]] = True; flag.append(f)
    auc = [float(roc_auc_score(y, p, sample_weight=(w if J == "nb" else None))) for p in P]; mean = [100 * float(np.average(p, weights=w)) for p in P]
    jac = [float((flag[i] & flag[j]).sum() / (flag[i] | flag[j]).sum()) for i in range(5) for j in range(i + 1, 5)]
    cor = [float(np.corrcoef(P[i], P[j])[0, 1]) for i in range(5) for j in range(i + 1, 5)]
    r4 = lambda x: [round(float(min(x)), 4), round(float(max(x)), 4)]
    return {"definition": v, "n_plots": int(len(y)), "seeds": 5, "level": "plot, out of fold; surfaces not remapped", "auc_oof_range": r4(auc), "auc_oof_seed0": round(auc[0], 4),
            "mean_oof_pct_range": r4(mean), "top_share_flag_pct": rate, "n_flagged": nf, "pairwise_jaccard_flagged_plots_range": r4(jac), "pairwise_corr_oof_range": r4(cor)}
if __name__ == "__main__":
    with Pool(12) as p: R = p.map(part_a, A.tiles)
    N = sum(r[2] for r in R); f = sum(r[0] for r in R); c = sum(r[1] for r in R)
    rank = json.load(open(f"{W}/out/" + ("d5_me_aggregate_DATA.json" if J == "me" else "d9_nb_aggregate_DATA.json")))
    assert N == rank["cells_in_maine_forest_frame"] if J == "me" else True
    out = {"jurisdiction": J, "cells": int(N), "fixed_threshold": 0.5,
           "flagged_share_pct_at_0.5": {v: round(100 * float(f[j]) / N, 4) for j, v in enumerate(DEFS)}, "design_pct": A.DESIGN,
           "ratio_flagged_at_0.5_to_design": {v: round(100 * float(f[j]) / N / A.DESIGN[v], 4) for j, v in enumerate(DEFS)},
           "agreement_share_pct_at_0.5": {"any": round(100 * float(1 - c[0] / N), 4), "half": round(100 * float(c[3:].sum() / N), 4), "all": round(100 * float(c[ND] / N), 4)},
           "agreement_share_pct_rank_rule": {k: rank["agreement_share_pct"][k]["est"] for k in ("any", "half", "all")}}
    json.dump(out, open(f"{W}/out/d10_{J}_stress_DATA.json", "w"), indent=1); print(json.dumps(out), flush=True)
    out["five_seeds"] = five_seeds()
    json.dump(out, open(f"{W}/out/d10_{J}_stress_DATA.json", "w"), indent=1); print(json.dumps(out["five_seeds"]), "DONE", flush=True)
