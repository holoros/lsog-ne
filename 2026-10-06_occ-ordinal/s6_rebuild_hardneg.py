#!/usr/bin/env python3
# s6_rebuild_hardneg.py  Rebuild of the FIA + OCC ordinal model so that aspen and poplar stands and introduced
# (hybrid) larch and other planted stands stop reading as LSOG. Aaron, 6 October 2026: "our 10 m still identifies
# populus and hybrid larch stands as LSOG".
# v1 = the 6 October pooled model (labels as given). v2 = the same learner, seed and folds, with FIA plots whose
# dominant forested condition is aspen or balsam poplar (FORTYPCD 901, 904), introduced larch (385), or of planted
# origin (STDORGCD 1) set to Not LSOG and given weight HN_W. [ASSUMPTION: these stands are early successional or
# planted and cannot be late successional or old growth under the FSC Type 1 and Type 2 definitions.]
# FIA plots are keyed by PLT_CN (never by row position). Aggregates only leave Cardinal.
import os, pickle, numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"
SEED = 20261006; rng = np.random.default_rng(SEED + 6); NT, LEAF = 500, 3; HN_W = float(E.get("HN_W", "3"))
AEC = [f"AE_{k:02d}" for k in range(64)]
log = open(f"{AGG}/s6_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

occ = pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")
occ["y"] = occ.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}); occ["grp"] = "O" + occ.site.astype(str)
fia = pd.read_csv(E["TRAIN_TABLE"]); fia = fia[fia.state == "ME"].copy()
fia["y"] = fia.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3}); fia["grp"] = "F" + fia.spatial_block.astype(str)
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cond = pd.read_csv(f"{R}/FIA/ME_COND.csv", usecols=["PLT_CN", "CONDID", "COND_STATUS_CD", "FORTYPCD", "STDAGE", "STDORGCD", "CONDPROP_UNADJ"], dtype={"PLT_CN": str})
cond = cond[cond.COND_STATUS_CD == 1].sort_values("CONDPROP_UNADJ", ascending=False).drop_duplicates("PLT_CN")
fia = fia.merge(j, on="plot_id", how="left").merge(cond[["PLT_CN", "FORTYPCD", "STDAGE", "STDORGCD"]], on="PLT_CN", how="left")
L(f"FIA rows {len(fia)}; PLT_CN found {int(fia.PLT_CN.notna().sum())}; forested condition found {int(fia.FORTYPCD.notna().sum())}")
def grp_of(r):
    if r.FORTYPCD in (901, 904): return "aspen or balsam poplar"
    if r.FORTYPCD == 385: return "introduced larch"
    if r.STDORGCD == 1: return "planted, other types"
    if r.FORTYPCD == 902: return "paper birch (not relabeled)"
    if r.FORTYPCD == 126: return "tamarack (not relabeled)"
    return "other"
fia["ftg"] = fia.apply(grp_of, axis=1)
L("FIA label by forest type group (columns 0 Not, 1 Trans, 2 LS, 3 OG):\n" + pd.crosstab(fia.ftg, fia.y, margins=True).to_string())
L("median stand age by group: " + str(fia.groupby("ftg").STDAGE.median().round(0).to_dict()))
hn = fia.ftg.isin(["aspen or balsam poplar", "introduced larch", "planted, other types"]).values
L(f"hard negatives: {int(hn.sum())} FIA plots, of which {int((fia.y.values[hn] > 0).sum())} carried an LSOG class >= transitioning and are relabeled")
fia = fia[np.isfinite(fia[AEC]).all(1)].reset_index(drop=True); hn = fia.ftg.isin(["aspen or balsam poplar", "introduced larch", "planted, other types"]).values
occ = occ[np.isfinite(occ[AEC]).all(1)].reset_index(drop=True)

D = pd.concat([occ.assign(src="OCC", ftg="OCC"), fia.assign(src="FIA")], ignore_index=True)
X = D[AEC].values.astype("float32"); y1 = D.y.values.astype(int); g = D.grp.values
isF = (D.src == "FIA").values; HN = np.zeros(len(D), bool); HN[isF] = hn
y2 = y1.copy(); y2[HN] = 0; w2 = np.where(HN, HN_W, 1.0)

def fit_cum(Xt, yt, wt, seed):
    ms = []
    for k in (1, 2, 3):
        m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt", n_jobs=-1, random_state=seed + k)
        m.fit(Xt, (yt >= k).astype(int), sample_weight=wt); ms.append(m)
    return ms
def pred_cum(ms, Xn):
    p = np.column_stack([m.predict_proba(Xn)[:, 1] for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
def auc_ci(yb, s, gg, B=1000):
    a = roc_auc_score(yb, s); ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)

P1 = np.full((len(D), 3), np.nan); P2 = np.full((len(D), 3), np.nan)
for f_, (tr, te) in enumerate(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(X, y1, g)):
    P1[te] = pred_cum(fit_cum(X[tr], y1[tr], None, SEED + 10 * f_), X[te])
    P2[te] = pred_cum(fit_cum(X[tr], y2[tr], w2[tr], SEED + 10 * f_), X[te])

rows = []
O = ~isF
for cn, fy, fs, j_ in (("Trans+ vs Not", lambda v: v >= 1, None, 0), ("Type 2 pool vs rest", lambda v: v >= 2, None, 1),
                       ("OG vs rest", lambda v: v == 3, None, 2), ("OG vs LS", lambda v: v == 3, lambda v: v >= 2, 2)):
    keep = O.copy() if fs is None else (O & fs(y1))
    for mn, P in (("v1 pooled", P1), ("v2 hard negatives", P2)):
        rows.append(dict(scored="OCC field points", contrast=cn, model=mn, **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keep]).astype(int), P[keep, j_], g[keep])))))
# FIA, original labels, excluding the hard negative groups so v2 gets no circular credit
keepF = isF & ~HN
for cn, k in (("Trans+ vs Not", 1), ("Type 2 pool vs rest", 2)):
    for mn, P in (("v1 pooled", P1), ("v2 hard negatives", P2)):
        rows.append(dict(scored="FIA plots outside the hard negative groups", contrast=cn, model=mn,
                         **dict(zip(["auc", "lo", "hi"], auc_ci((y1[keepF] >= k).astype(int), P[keepF, k - 1], g[keepF], B=500)))))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/hardneg_auc_DATA.csv", index=False); L(A.to_string(index=False))

# false positive behaviour by forest type group, out of fold
fr = []
for gname in sorted(D.loc[isF, "ftg"].unique()):
    m = isF & (D.ftg.values == gname)
    for mn, P in (("v1 pooled", P1), ("v2 hard negatives", P2)):
        fr.append(dict(group=gname, model=mn, n=int(m.sum()), mean_P_ge_trans=round(P[m, 0].mean(), 4), mean_P_type2=round(P[m, 1].mean(), 4),
                       share_type2_screen=round((P[m, 1] >= 0.0706).mean(), 4), share_trans_ge_0p297=round((P[m, 0] >= 0.297).mean(), 4)))
F = pd.DataFrame(fr); F.to_csv(f"{AGG}/hardneg_falsepos_by_group_DATA.csv", index=False); L(F.to_string(index=False))

ms = fit_cum(X, y2, w2, SEED)
pickle.dump(ms, open(f"{OUT}/rf_ordinal_final_hardneg.pkl", "wb"))
np.save(f"{OUT}/env_min_hardneg.npy", X.min(0)); np.save(f"{OUT}/env_max_hardneg.npy", X.max(0))
L(f"v2 training prevalence: y>=1 {int((y2 >= 1).sum())}, y>=2 {int((y2 >= 2).sum())}, y>=3 {int((y2 >= 3).sum())} of {len(y2)}")
L("S6 DONE")
