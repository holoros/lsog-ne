#!/usr/bin/env python3
# s2b_fia_only.py  FIA only counterpart of the pooled ordinal model, to isolate the influence of the OCC data.
# Same learner, settings, seed, classes and grouped folds as s2_fit_compare.py; only the training rows differ.
# Evaluated (1) at all OCC points, which this model never sees, and (2) out of fold on FIA plots.
# The pooled model's FIA OOF predictions are recomputed here on the same folds so the FIA comparison is paired.
import os, pickle, numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"
SEED = 20261006; rng = np.random.default_rng(SEED + 1); NT, LEAF = 500, 3
AEC = [f"AE_{k:02d}" for k in range(64)]
log = open(f"{AGG}/s2b_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

occ = pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")
fia = pd.read_csv(E["TRAIN_TABLE"]); fia = fia[fia.state == "ME"].copy()
occ["y"] = occ.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3})
fia["y"] = fia.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3})
occ = occ[np.isfinite(occ[AEC]).all(1)].copy(); fia = fia[np.isfinite(fia[AEC]).all(1)].copy()
occ["grp"] = "O" + occ.site.astype(str); fia["grp"] = "F" + fia.spatial_block.astype(str)

def fit_cum(X, y, seed):
    ms = []
    for k in (1, 2, 3):
        m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt", n_jobs=-1, random_state=seed + k)
        m.fit(X, (y >= k).astype(int)); ms.append(m)
    return ms
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
def auc_ci(yb, s, g, B=2000):
    a = roc_auc_score(yb, s); ug = np.unique(g); idx = {u: np.where(g == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return a, np.percentile(bs, 2.5), np.percentile(bs, 97.5)

XF, yF = fia[AEC].values.astype("float32"), fia.y.values.astype(int)
XO, yO = occ[AEC].values.astype("float32"), occ.y.values.astype(int)
msF = fit_cum(XF, yF, SEED)
pickle.dump(msF, open(f"{OUT}/rf_ordinal_final_fiaonly.pkl", "wb"))
np.save(f"{OUT}/env_min_fiaonly.npy", XF.min(0)); np.save(f"{OUT}/env_max_fiaonly.npy", XF.max(0))
pO_F = pred_cum(msF, XO)                                          # FIA only at OCC points: fully independent
oof = pd.read_csv(f"{OUT}/occ_oof_scores_RESTRICTED.csv").set_index("occ_id").loc[occ.occ_id]
pO_P = oof[["new_ge1", "new_ge2", "new_og"]].values               # pooled, OCC sites held out by fold

# paired FIA out of fold: same grouped folds for both models; pooled folds also carry OCC rows in training
D = pd.concat([occ.assign(src="OCC"), fia.assign(src="FIA")], ignore_index=True)
X, y, g = D[AEC].values.astype("float32"), D.y.values.astype(int), D.grp.values
isF = (D.src == "FIA").values
oofP = np.full((len(D), 3), np.nan); oofF = np.full((len(D), 3), np.nan)
for f, (tr, te) in enumerate(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(X, y, g)):
    oofP[te] = pred_cum(fit_cum(X[tr], y[tr], SEED + 10 * f), X[te])
    trF = tr[isF[tr]]; oofF[te] = pred_cum(fit_cum(X[trF], y[trF], SEED + 10 * f), X[te])

C = {"Trans+ vs Not": (lambda v: v >= 1, None, 0), "Type 2 pool (LS+OG) vs rest": (lambda v: v >= 2, None, 1),
     "Type 1 (OG) vs rest": (lambda v: v == 3, None, 2), "Type 1 (OG) vs LS": (lambda v: v == 3, lambda v: v >= 2, 2)}
rows = []
for cn, (fy, fs, j) in C.items():
    for ev, yy, gg, sets in (("OCC field points", yO, occ.grp.values, {"FIA only": pO_F, "FIA + OCC": pO_P}),
                             ("FIA plots, out of fold", y[isF], g[isF], {"FIA only": oofF[isF], "FIA + OCC": oofP[isF]})):
        keep = np.ones(len(yy), bool) if fs is None else fs(yy)
        yb = fy(yy[keep]).astype(int)
        if yb.sum() < 3: continue
        for mn, P in sets.items():
            a, lo, hi = auc_ci(yb, P[keep, j], gg[keep], B=1000)
            rows.append(dict(evaluation=ev, contrast=cn, model=mn, auc=a, lo=lo, hi=hi, n=int(keep.sum()), n_pos=int(yb.sum())))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/fia_vs_pooled_auc_DATA.csv", index=False)
L(A.round(3).to_string(index=False))
# class medians at OCC points under each model (aggregate)
M = pd.DataFrame({"occ_class": occ.occ_class.values, "fia_ge2": pO_F[:, 1], "pool_ge2": pO_P[:, 1], "fia_og": pO_F[:, 2], "pool_og": pO_P[:, 2]})
M.groupby("occ_class").median().to_csv(f"{AGG}/fia_vs_pooled_class_medians_DATA.csv"); L(M.groupby("occ_class").median().round(3).to_string())
L("S2B DONE")
