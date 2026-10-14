#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s16a_xp_fit.py  Cross-predicted rebuild, October 7, 2026 (red team item: training-point signal). Same data assembly and
# model form as s9_fit_v4.py (v3 selected there), with the V2 OCC points (OCC_334 corrected). Every training point is
# assigned to one of five folds by its 20 km block in EPSG:3979; model k is fit without fold k, and s16b predicts each
# 10 m cell with the model of the fold that holds the cell, so no cell is predicted by a forest that saw a point in its block.
# Original s9 header follows.
# s9_fit_v4.py header:
# Aaron, 6 October 2026: rebuild Hagan's map (aspen and hybrid larch read as LSOG), run at 10 m then aggregate,
# and add a species composition layer because hardwood, softwood and mixedwood stands likely carry different
# LSOG signatures.
# Features at each point (all at the 10 m cell, so the map step sees the same definition):
#   AE_00..AE_63 (AlphaEarth 2024), chm_mean, chm_max, chm_sd (Meta CHM v2 at 10 m), chm_mean3, chm_max3
#   (3 x 3 cell means, 30 m context), tsd (Hansen v1.12, 2024 - year of last loss, 40 when none)
# Composition: softwood share of live basal area (trees >= 5 in DBH) at FIA plots, from ME_TREE by PLT_CN.
#   Classes: hardwood < 0.35, mixedwood 0.35 to 0.65, softwood > 0.65 [ASSUMPTION: conventional thresholds].
# Hard negatives (from s6): FIA plots in aspen or balsam poplar (FORTYPCD 901, 904), introduced larch (385) or
#   of planted origin (STDORGCD 1) are Not LSOG with weight 3.
# Candidates, all on the same rows and grouped folds:
#   v3 AE + structure; v4 v3 + predicted softwood share; v5 separate models per predicted composition class.
# Selection rule, fixed before fitting: highest OCC out of fold Type 2 AUC; a candidate must beat the simpler
#   one by at least 0.01 to be chosen (v3 < v4 < v5 in complexity).
# Cardinal only; aggregates leave. FIA plots keyed by PLT_CN, never by row position.
import os, json, pickle, numpy as np, pandas as pd, rasterio
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score, r2_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"
S10 = f"{OUT}/structure10"; S30 = f"{OUT}/structure"
SEED = 20261006; rng = np.random.default_rng(SEED + 9); NT, LEAF, HN_W = 500, 3, 3.0
AEC = [f"AE_{k:02d}" for k in range(64)]; STR = ["chm_mean", "chm_max", "chm_sd", "chm_mean3", "chm_max3", "tsd"]
log = open(f"{AGG}/s16a_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

# ---- points (restricted positions, never written)
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
o = o.merge(pd.read_csv(f"{OUT}/occ_points_ae_maps_occv2_RESTRICTED.csv")[["occ_id", "site"] + AEC], on="occ_id")
o["y"] = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}); o["grp"] = "O" + o.site.astype(str)
o["src"] = "OCC"; o["ftg"] = "OCC"; o["PLT_CN"] = np.nan
me = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]].rename(columns={"TRUE.LAT": "lat", "TRUE.LON": "lon"})
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

# ---- composition model (FIA only), out of fold, then a final fit used for OCC rows and the map
hasC = isF & D.sw_frac.notna().values
swo = np.full(len(D), np.nan)
reg = lambda s: RandomForestRegressor(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=s)
for k, (tr_, te_) in enumerate(folds):
    trc = tr_[hasC[tr_]]; m = reg(SEED + k).fit(XS[trc], D.sw_frac.values[trc]); swo[te_] = m.predict(XS[te_])
comp_final = reg(SEED).fit(XS[hasC], D.sw_frac.values[hasC])
swo[O] = comp_final.predict(XS[O])                       # OCC has no tree data; never in composition training
cls = lambda v: np.where(v < 0.35, 0, np.where(v > 0.65, 2, 1))
obs_c = cls(D.sw_frac.values[hasC]); pred_c = cls(swo[hasC])
L(f"composition OOF at FIA plots: R2 {r2_score(D.sw_frac.values[hasC], swo[hasC]):.3f}; class accuracy {np.mean(obs_c == pred_c):.3f}")
L("composition confusion (rows observed HW/MX/SW, cols predicted):\n" + pd.crosstab(obs_c, pred_c).to_string())
D["sw_pred"] = swo; D["comp"] = cls(swo)
L("LSOG class by predicted composition (0 HW, 1 MX, 2 SW):\n" + pd.crosstab([D.src, D.comp], D.y).to_string())
L("median structure by composition and LSOG class (signatures):\n" + D.groupby(["comp", "y"])[["chm_mean", "chm_max", "chm_sd", "chm_mean3"]].median().round(2).to_string())

def fit_cum(X, y, w, seed):
    out = []
    for k in (1, 2, 3):
        yk = (y >= k).astype(int)
        if yk.sum() == 0 or yk.sum() == len(yk): out.append(float(yk.mean())); continue
        m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt", n_jobs=-1, random_state=seed + k)
        m.fit(X, yk, sample_weight=w); out.append(m)
    return out
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] if hasattr(m, "predict_proba") else np.full(len(X), m) for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
# ---- cross-prediction: folds from 20 km blocks in EPSG:3979 (the same rule s16b applies to every map cell)
K, BS = 5, 20000.0
def fold_of(x, y):
    bx = np.floor(np.asarray(x) / BS).astype(np.int64); by = np.floor(np.asarray(y) / BS).astype(np.int64)
    return ((bx * 73856093) ^ (by * 19349663)) % K
px, py = Transformer.from_crs(4326, 3979, always_xy=True).transform(D.lon.values, D.lat.values); fk = fold_of(px, py)
L(f"cross-prediction folds (points): {np.bincount(fk, minlength=K).tolist()}")
L("positives by fold (>= trans, >= LS, OG): " + str([[int((y2[fk == k] >= c).sum()) for c in (1, 2, 3)] for k in range(K)]))
models, comps = [], []; Pxp = np.full((len(D), 3), np.nan)
for k in range(K):
    tr = fk != k; trc = tr & hasC
    models.append(fit_cum(XS[tr], y2[tr], w2[tr], SEED + 100 * k)); comps.append(reg(SEED + 100 * k).fit(XS[trc], D.sw_frac.values[trc]))
    Pxp[fk == k] = pred_cum(models[k], XS[fk == k]); L(f"fold {k} fitted on {int(tr.sum())} points")
# aggregate check: the value the cross-predicted map gives at each training point (block held out)
from sklearn.metrics import roc_auc_score
rows = []
for nm, base in (("OCC field points", O), ("FIA plots outside hard negatives", isF & ~HN)):
    for cn, fy, jj, sub in (("Trans+ vs Not", lambda v: v >= 1, 0, None), ("Type 2 pool vs rest", lambda v: v >= 2, 1, None),
                            ("OG vs rest", lambda v: v == 3, 2, None), ("OG vs LS", lambda v: v == 3, 2, lambda v: v >= 2)):
        m = base if sub is None else (base & sub(y1)); yy = fy(y1[m]).astype(int)
        rows.append(dict(scored=nm, contrast=cn, n=int(m.sum()), auc=round(roc_auc_score(yy, Pxp[m, jj]), 3) if 0 < yy.sum() < len(yy) else np.nan))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/xp_block_heldout_auc_DATA.csv", index=False); L(A.to_string(index=False))
pickle.dump({"choice": "v3", "K": K, "BS": BS, "lsog": models, "comp": comps, "features": AEC + STR}, open(f"{OUT}/rf_xp_bundle.pkl", "wb"))
np.save(f"{OUT}/env_min_xp.npy", XS.min(0)); np.save(f"{OUT}/env_max_xp.npy", XS.max(0))
json.dump({"choice": "v3", "n": int(len(D)), "pos": [int((y2 >= c).sum()) for c in (1, 2, 3)], "n_hard_neg": int(HN.sum()),
           "fold_sizes": np.bincount(fk, minlength=K).tolist()}, open(f"{OUT}/xp_meta.json", "w"))
L("S16A DONE")
