#!/usr/bin/env python3
# s9b_grouping_sensitivity.py  Red team, 7 October 2026. The field point AUCs in s9 group OCC points into 2 km single
# linkage sites, so neighbouring sites in one reserve can fall in different folds. This refits the selected form (v3)
# with the same rows, features, hard negatives and seeds under three OCC groupings: 2 km sites (reproduces s9),
# 10 km single linkage clusters, and project. It also gives an honest screening cut: for each fold the Youden cut is
# chosen on the other folds' out of fold OCC scores and applied to the held out fold. FIA grouping is unchanged.
# Rows and features are built by the same code as s9 (lines copied verbatim); only aggregates are written.
import os, json, pickle, numpy as np, pandas as pd, rasterio
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score, r2_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"
S10 = f"{OUT}/structure10"; S30 = f"{OUT}/structure"
SEED = 20261006; rng = np.random.default_rng(SEED + 9); NT, LEAF, HN_W = 500, 3, 3.0
AEC = [f"AE_{k:02d}" for k in range(64)]; STR = ["chm_mean", "chm_max", "chm_sd", "chm_mean3", "chm_max3", "tsd"]
def L(m): print(m, flush=True)
# ---- points (restricted positions, never written)
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
o = o.merge(pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")[["occ_id", "site"] + AEC], on="occ_id")
o["y"] = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}); o["grp"] = "O" + o.site.astype(str)
o["src"] = "OCC"; o["ftg"] = "OCC"; o["PLT_CN"] = np.nan
me = pd.read_csv(f"{R}/tmp_me_v51_restricted.csv", dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]].rename(columns={"TRUE.LAT": "lat", "TRUE.LON": "lon"})
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cond = pd.read_csv(f"{R}/FIA/ME_COND.csv", usecols=["PLT_CN", "COND_STATUS_CD", "FORTYPCD", "STDORGCD", "CONDPROP_UNADJ"], dtype={"PLT_CN": str})
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
# softwood share of live basal area
tr = pd.read_csv(f"{R}/FIA/ME_TREE.csv", usecols=["PLT_CN", "STATUSCD", "SPCD", "DIA", "TPA_UNADJ"], dtype={"PLT_CN": str})
tr = tr[(tr.STATUSCD == 1) & (tr.DIA >= 5) & tr.TPA_UNADJ.notna() & tr.PLT_CN.isin(f.PLT_CN.dropna())]
tr["ba"] = 0.005454 * tr.DIA ** 2 * tr.TPA_UNADJ; tr["sw"] = tr.SPCD < 300
sw = tr.groupby("PLT_CN").apply(lambda d: d.ba[d.sw].sum() / d.ba.sum() if d.ba.sum() > 0 else np.nan).rename("sw_frac").reset_index()
f = f.merge(sw, on="PLT_CN", how="left")
L(f"FIA rows {len(f)}; position {int(f.lat.notna().sum())}; softwood share {int(f.sw_frac.notna().sum())}")
cols = ["occ_id", "src", "grp", "y", "ftg", "lat", "lon"] + AEC
D = pd.concat([o[cols].assign(sw_frac=np.nan), f[cols + ["sw_frac"]]], ignore_index=True)
D = D[D.lat.notna() & np.isfinite(D[AEC]).all(1)].reset_index(drop=True)

# ---- structure at the 10 m cell plus 3 x 3 context
def samp(path, win=0):
    with rasterio.open(path) as ds:
        x, y = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(D.lon.values, D.lat.values)
        out = np.full((len(D), (2 * win + 1) ** 2), np.nan)
        for i, (xx, yy) in enumerate(zip(x, y)):
            r, c = ds.index(xx, yy)
            if r - win < 0 or c - win < 0 or r + win >= ds.height or c + win >= ds.width: continue
            a = ds.read(1, window=rasterio.windows.Window(c - win, r - win, 2 * win + 1, 2 * win + 1)).astype(float).ravel()
            out[i] = a
        return out
mean9 = samp(f"{S10}/chm_mean10.vrt", 1); max9 = samp(f"{S10}/chm_max10.vrt", 1); rms1 = samp(f"{S10}/chm_rms10.vrt", 0)[:, 0]
bad9 = (mean9 < 0) | (max9 == 255)      # F2/F7: declared nodata only; 0 m is a real height (harvested stands). A first fit that
#   also dropped 0/0 cells lost 133 FIA plots and was discarded.
mean9[bad9] = np.nan; max9[bad9] = np.nan
D["chm_mean"] = mean9[:, 4]; D["chm_max"] = max9[:, 4]
D["chm_sd"] = np.sqrt(np.clip(rms1 ** 2 - D.chm_mean.values ** 2, 0, None)); D.loc[D.chm_mean.isna(), "chm_sd"] = np.nan
D["chm_mean3"] = np.nanmean(mean9, 1); D["chm_max3"] = np.nanmean(max9, 1)
ly = samp(f"{S30}/lossyear30.tif", 0)[:, 0]; D["tsd"] = np.where(ly > 0, 24 - ly, 40.0)
assert np.nanmax(D.chm_max) <= 80 and np.nanmin(D.chm_mean) >= 0, "F7 CHM range"
for s in ("OCC", "FIA"):
    m = D.src == s; L(f"{s}: 10 m structure present at {int(D.loc[m, 'chm_mean'].notna().sum())} of {int(m.sum())}")
D = D[D[STR].notna().all(1)].reset_index(drop=True)
isF = (D.src == "FIA").values; O = ~isF; g = D.grp.values; y1 = D.y.values.astype(int)
HN = isF & D.ftg.isin(["aspen or balsam poplar", "introduced larch", "planted, other types"]).values
y2 = y1.copy(); y2[HN] = 0; w2 = np.where(HN, HN_W, 1.0)
XS = D[AEC + STR].values.astype("float32")
folds = list(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(XS, y1, g))
from scipy.cluster.hierarchy import linkage, fcluster
from sklearn.metrics import roc_curve
xo, yo = Transformer.from_crs(4326, 26919, always_xy=True).transform(D.lon.values[O], D.lat.values[O])
cl10 = fcluster(linkage(np.column_stack([xo, yo]), "single"), 10000, "distance")
occ_meta = pd.read_csv(E["OCC_CSV"])[["occ_id", "project"]]
proj = D[["occ_id"]].merge(occ_meta, on="occ_id", how="left").project.astype(str).values
G = {"2 km sites": g, "10 km clusters": g.copy(), "project": g.copy()}
G["10 km clusters"][O] = np.array([f"C{c}" for c in cl10]); G["project"][O] = np.array([f"P{p}" for p in proj[O]])
L(f"OCC groups: 2 km {len(set(g[O]))}, 10 km {len(set(G['10 km clusters'][O]))}, project {len(set(G['project'][O]))}; OG groups at 10 km {len(set(G['10 km clusters'][O & (y1 == 3)]))}")
def fit_cum(X, y, w, seed):
    out = []
    for k in (1, 2, 3):
        yk = (y >= k).astype(int); m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt", n_jobs=-1, random_state=seed + k)
        m.fit(X, yk, sample_weight=w); out.append(m)
    return out
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] for m in ms]); p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
def auc_ci(yb, sc, gg, B=1000):
    if yb.sum() < 3 or yb.sum() == len(yb): return (np.nan,) * 3
    a = roc_auc_score(yb, sc); ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], sc[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
rows = []; scr = []
keepF = isF & ~HN
for gname, gg in G.items():
    fo = list(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(XS, y1, gg))
    P = np.full((len(D), 3), np.nan); fid = np.full(len(D), -1)
    for k_, (tr_, te_) in enumerate(fo):
        P[te_] = pred_cum(fit_cum(XS[tr_], y2[tr_], w2[tr_], SEED + 10 * k_), XS[te_]); fid[te_] = k_
    for cn, fy, fs, jj in (("Trans+ vs Not", lambda v: v >= 1, None, 0), ("Type 2 pool vs rest", lambda v: v >= 2, None, 1),
                           ("OG vs rest", lambda v: v == 3, None, 2), ("OG vs LS", lambda v: v == 3, lambda v: v >= 2, 2)):
        for scored, base in (("OCC field points", O), ("FIA plots outside hard negatives", keepF)):
            keep = base.copy() if fs is None else (base & fs(y1))
            rows.append(dict(grouping=gname, scored=scored, contrast=cn, **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keep]).astype(int), P[keep, jj], gg[keep])))))
    # honest screen: cut chosen on the other folds' OOF OCC scores
    yt = (y1 >= 2).astype(int); tp = fn = tn = fp = 0; cuts = []
    for k_ in range(5):
        oth = O & (fid != k_); hold = O & (fid == k_)
        f_, t_, th = roc_curve(yt[oth], P[oth, 1]); c = float(th[int(np.argmax(t_ - f_))]); cuts.append(c)
        pr = P[hold, 1] >= c; tp += int((pr & (yt[hold] == 1)).sum()); fn += int((~pr & (yt[hold] == 1)).sum())
        tn += int((~pr & (yt[hold] == 0)).sum()); fp += int((pr & (yt[hold] == 0)).sum())
    scr.append(dict(grouping=gname, cut_median=float(np.median(cuts)), cut_min=min(cuts), cut_max=max(cuts),
                    sensitivity=tp / (tp + fn), specificity=tn / (tn + fp)))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/v3_grouping_sensitivity_auc_DATA.csv", index=False); L(A.to_string(index=False))
Sx = pd.DataFrame(scr); Sx.to_csv(f"{AGG}/v3_screen_crossvalidated_DATA.csv", index=False); L(Sx.to_string(index=False))
L("S9B DONE")
