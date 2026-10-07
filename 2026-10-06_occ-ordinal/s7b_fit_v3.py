#!/usr/bin/env python3
# s7b_fit_v3.py  Rebuild of the FIA + OCC ordinal model, v3: AlphaEarth 2024 plus structure (Meta CHM v2 at 30 m:
# mean, max, SD; Hansen v1.12 time since loss) plus the aspen, poplar, introduced larch and planted hard negatives
# of s6. v1 (AE, labels as given), v2 (AE, hard negatives) and v3 are refit here on the same rows and folds so the
# comparison is paired. Structure is read from the s7a 30 m layers exactly as the map step reads it, so training
# and prediction see the same feature definition. Cardinal only; aggregates leave.
import os, pickle, json, numpy as np, pandas as pd, rasterio
from pyproj import Transformer
from scipy.cluster.hierarchy import fcluster, linkage
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"; SD_ = f"{OUT}/structure"
SEED = 20261006; rng = np.random.default_rng(SEED + 7); NT, LEAF, HN_W = 500, 3, 3.0
AEC = [f"AE_{k:02d}" for k in range(64)]; STR = ["chm_mean", "chm_max", "chm_sd", "tsd"]
log = open(f"{AGG}/s7b_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

# points with positions (restricted, never written)
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
ao = pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")[["occ_id", "site"] + AEC]
o = o.merge(ao, on="occ_id"); o["y"] = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3})
o["grp"] = "O" + o.site.astype(str); o["src"] = "OCC"; o["ftg"] = "OCC"
me = pd.read_csv(f"{R}/tmp_me_v51_restricted.csv", dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]].rename(columns={"TRUE.LAT": "lat", "TRUE.LON": "lon"})
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cond = pd.read_csv(f"{R}/FIA/ME_COND.csv", usecols=["PLT_CN", "COND_STATUS_CD", "FORTYPCD", "STDAGE", "STDORGCD", "CONDPROP_UNADJ"], dtype={"PLT_CN": str})
cond = cond[cond.COND_STATUS_CD == 1].sort_values("CONDPROP_UNADJ", ascending=False).drop_duplicates("PLT_CN")
f = pd.read_csv(E["TRAIN_TABLE"]); f = f[f.state == "ME"].merge(j, on="plot_id", how="left").merge(me, on="PLT_CN", how="left").merge(cond, on="PLT_CN", how="left")
f["y"] = f.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3}); f["grp"] = "F" + f.spatial_block.astype(str); f["src"] = "FIA"
def ftg(r):
    if r.FORTYPCD in (901, 904): return "aspen or balsam poplar"
    if r.FORTYPCD == 385: return "introduced larch"
    if r.STDORGCD == 1: return "planted, other types"
    if r.FORTYPCD == 902: return "paper birch"
    if r.FORTYPCD == 126: return "tamarack"
    return "other"
f["ftg"] = f.apply(ftg, axis=1); f = f.rename(columns={"plot_id": "occ_id"})
D = pd.concat([o[["occ_id", "src", "grp", "y", "ftg", "lat", "lon"] + AEC], f[["occ_id", "src", "grp", "y", "ftg", "lat", "lon"] + AEC]], ignore_index=True)
D = D[D.lat.notna() & np.isfinite(D[AEC]).all(1)].reset_index(drop=True)

# structure at points from the 30 m layers
def samp(name):
    with rasterio.open(f"{SD_}/{name}.tif") as ds:
        x, y = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(D.lon.values, D.lat.values)
        return np.array([v[0] for v in ds.sample(list(zip(x, y)))], dtype=float)
mean, mx, rms, ly = samp("chm_mean30"), samp("chm_max30"), samp("chm_rms30"), samp("lossyear30")
miss = (mean < 0) | (mx == 255) | ((mean <= 0) & (mx <= 0))   # F2/F7: nodata (-1, 255) or absent tile (0), treat as missing
D["chm_mean"] = np.where(miss, np.nan, mean); D["chm_max"] = np.where(miss, np.nan, mx)
D["chm_sd"] = np.where(miss, np.nan, np.sqrt(np.clip(rms**2 - mean**2, 0, None)))
D["tsd"] = np.where(ly > 0, 24 - ly, 40.0)
assert np.nanmax(D.chm_max) <= 80 and np.nanmin(D.chm_mean) >= 0, "F7 CHM out of physical range"
for s in ("OCC", "FIA"):
    m = D.src == s; L(f"{s}: structure present at {int(D.loc[m, 'chm_mean'].notna().sum())} of {int(m.sum())}")
D = D[D[STR].notna().all(1)].reset_index(drop=True)
L("median structure by source and class:\n" + D.groupby(["src", "y"])[STR].median().round(2).to_string())
L("median structure by FIA forest type group:\n" + D[D.src == "FIA"].groupby("ftg")[STR].median().round(2).to_string())

X_ae = D[AEC].values.astype("float32"); X_st = D[AEC + STR].values.astype("float32")
y1 = D.y.values.astype(int); g = D.grp.values; isF = (D.src == "FIA").values
HN = isF & D.ftg.isin(["aspen or balsam poplar", "introduced larch", "planted, other types"]).values
y2 = y1.copy(); y2[HN] = 0; w2 = np.where(HN, HN_W, 1.0)
def fit_cum(X, y, w, seed):
    out = []
    for k in (1, 2, 3):
        m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt", n_jobs=-1, random_state=seed + k)
        m.fit(X, (y >= k).astype(int), sample_weight=w); out.append(m)
    return out
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] for m in ms]); p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
def auc_ci(yb, s, gg, B=1000):
    a = roc_auc_score(yb, s); ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
VER = {"v1 AE, labels as given": (X_ae, y1, None), "v2 AE, hard negatives": (X_ae, y2, w2), "v3 AE + structure, hard negatives": (X_st, y2, w2)}
P = {k: np.full((len(D), 3), np.nan) for k in VER}
for fo, (tr, te) in enumerate(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(X_ae, y1, g)):
    for k, (X, yy, ww) in VER.items():
        P[k][te] = pred_cum(fit_cum(X[tr], yy[tr], None if ww is None else ww[tr], SEED + 10 * fo), X[te])
rows = []; O = ~isF; keepF = isF & ~HN
for cn, fy, fs, j_ in (("Trans+ vs Not", lambda v: v >= 1, None, 0), ("Type 2 pool vs rest", lambda v: v >= 2, None, 1),
                       ("OG vs rest", lambda v: v == 3, None, 2), ("OG vs LS", lambda v: v == 3, lambda v: v >= 2, 2)):
    for k in VER:
        keep = O.copy() if fs is None else (O & fs(y1))
        rows.append(dict(scored="OCC field points", contrast=cn, model=k, **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keep]).astype(int), P[k][keep, j_], g[keep])))))
        if cn in ("Trans+ vs Not", "Type 2 pool vs rest"):
            rows.append(dict(scored="FIA plots outside hard negative groups", contrast=cn, model=k,
                             **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keepF]).astype(int), P[k][keepF, j_], g[keepF], B=500)))))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/v123_auc_DATA.csv", index=False); L(A.to_string(index=False))
# false positive behaviour: groups that should not read as LSOG, scored on Type 2 at the s4a OCC screen cut and on P(>= trans)
fr = []
for gname in ["aspen or balsam poplar", "introduced larch", "planted, other types", "paper birch", "tamarack", "other"]:
    m = isF & (D.ftg.values == gname) & (y1 == 0) if gname == "other" else isF & (D.ftg.values == gname)
    for k in VER:
        fr.append(dict(group=gname + (" (Not LSOG only)" if gname == "other" else ""), model=k, n=int(m.sum()),
                       mean_P_type2=round(P[k][m, 1].mean(), 4), share_type2_ge_0p0706=round((P[k][m, 1] >= 0.0706).mean(), 4),
                       mean_P_ge_trans=round(P[k][m, 0].mean(), 4)))
F = pd.DataFrame(fr); F.to_csv(f"{AGG}/v123_falsepos_by_group_DATA.csv", index=False); L(F.to_string(index=False))
# OCC Not LS points as a second false positive check (field verified negatives)
for k in VER:
    m = O & (y1 == 0); L(f"{k}: OCC Not LS points, mean P(type2) {P[k][m, 1].mean():.4f}, share >= 0.0706 {(P[k][m, 1] >= 0.0706).mean():.3f}")
pd.DataFrame({"occ_id": D.occ_id[O], "occ_class": D.y[O], "grp": D.grp[O], **{f"{k}_{c}": P[k][O, i] for k in VER for i, c in enumerate(["ge1", "ge2", "og"])}}).to_csv(f"{OUT}/v123_occ_oof_RESTRICTED.csv", index=False)
ms = fit_cum(X_st, y2, w2, SEED)
pickle.dump(ms, open(f"{OUT}/rf_ordinal_final_v3.pkl", "wb"))
np.save(f"{OUT}/env_min_v3.npy", X_st.min(0)); np.save(f"{OUT}/env_max_v3.npy", X_st.max(0))
json.dump({"features": AEC + STR, "n": int(len(D)), "pos": [int((y2 >= k).sum()) for k in (1, 2, 3)]}, open(f"{OUT}/v3_meta.json", "w"))
L(f"v3 training prevalence: {[int((y2 >= k).sum()) for k in (1, 2, 3)]} of {len(D)}")
L("S7B DONE")
