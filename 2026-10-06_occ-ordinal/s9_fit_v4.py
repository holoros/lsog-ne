#!/usr/bin/env python3
# s9_fit_v4.py  Rebuild of the FIA + OCC (Hagan) LSOG map at 10 m with structure and species composition.
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
log = open(f"{AGG}/s9_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

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
X4 = np.column_stack([XS, swo]).astype("float32")
P = {k: np.full((len(D), 3), np.nan) for k in ("v3", "v4", "v5")}
for k_, (tr_, te_) in enumerate(folds):
    s = SEED + 10 * k_
    P["v3"][te_] = pred_cum(fit_cum(XS[tr_], y2[tr_], w2[tr_], s), XS[te_])
    P["v4"][te_] = pred_cum(fit_cum(X4[tr_], y2[tr_], w2[tr_], s), X4[te_])
    for c in (0, 1, 2):
        trc = tr_[D.comp.values[tr_] == c]; tec = te_[D.comp.values[te_] == c]
        if len(tec): P["v5"][tec] = pred_cum(fit_cum(XS[trc], y2[trc], w2[trc], s + c), XS[tec])
def auc_ci(yb, sc, gg, B=1000):
    if yb.sum() < 3 or yb.sum() == len(yb): return (np.nan,) * 3
    a = roc_auc_score(yb, sc); ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], sc[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
rows = []; keepF = isF & ~HN
for cn, fy, fs, jj in (("Trans+ vs Not", lambda v: v >= 1, None, 0), ("Type 2 pool vs rest", lambda v: v >= 2, None, 1),
                       ("OG vs rest", lambda v: v == 3, None, 2), ("OG vs LS", lambda v: v == 3, lambda v: v >= 2, 2)):
    for k in P:
        for scored, base in (("OCC field points", O), ("FIA plots outside hard negatives", keepF)):
            keep = base.copy() if fs is None else (base & fs(y1))
            rows.append(dict(scored=scored, contrast=cn, model=k, **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keep]).astype(int), P[k][keep, jj], g[keep])))))
    for c, cn_ in ((0, "hardwood"), (1, "mixedwood"), (2, "softwood")):       # within composition class, v4
        keep = (D.comp.values == c) if fs is None else ((D.comp.values == c) & fs(y1))
        rows.append(dict(scored=f"all points, predicted {cn_}", contrast=cn, model="v4", n=int(keep.sum()),
                         **dict(zip(["auc", "lo", "hi"], auc_ci(fy(y1[keep]).astype(int), P["v4"][keep, jj], g[keep], B=500)))))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/v345_auc_DATA.csv", index=False); L(A.to_string(index=False))
fr = []
for gname in ["aspen or balsam poplar", "introduced larch", "planted, other types", "paper birch", "tamarack", "other"]:
    m = (isF & (D.ftg.values == gname) & (y1 == 0)) if gname == "other" else (isF & (D.ftg.values == gname))
    for k in P:
        fr.append(dict(group=gname, model=k, n=int(m.sum()), mean_P_type2=round(P[k][m, 1].mean(), 4),
                       share_type2_ge_0p0706=round((P[k][m, 1] >= 0.0706).mean(), 4)))
for k in P:
    m = O & (y1 == 0); fr.append(dict(group="OCC Not LS (field)", model=k, n=int(m.sum()), mean_P_type2=round(P[k][m, 1].mean(), 4),
                                      share_type2_ge_0p0706=round((P[k][m, 1] >= 0.0706).mean(), 4)))
F = pd.DataFrame(fr); F.to_csv(f"{AGG}/v345_falsepos_by_group_DATA.csv", index=False); L(F.to_string(index=False))
# selection
t2 = {k: A[(A.scored == "OCC field points") & (A.contrast == "Type 2 pool vs rest") & (A.model == k)].auc.iloc[0] for k in P}
choice = "v3"
if t2["v4"] >= t2[choice] + 0.01: choice = "v4"
if t2["v5"] >= t2[choice] + 0.01: choice = "v5"
L(f"OCC Type 2 OOF AUC: {t2}; selected {choice}")
# screening cut for the selected model, from OCC out of fold scores (Youden), for display only
from sklearn.metrics import roc_curve
fp_, tp_, th_ = roc_curve((y1[O] >= 2).astype(int), P[choice][O, 1]); kk = int(np.argmax(tp_ - fp_))
cut = float(th_[kk]); L(f"Type 2 screen cut {cut:.4f} (sensitivity {tp_[kk]:.3f}, specificity {1 - fp_[kk]:.3f})")
# final fits
if choice == "v5":
    final = {c: fit_cum(XS[D.comp.values == c], y2[D.comp.values == c], w2[D.comp.values == c], SEED + c) for c in (0, 1, 2)}
elif choice == "v4":
    swf = swo.copy(); final = fit_cum(X4, y2, w2, SEED)
else:
    final = fit_cum(XS, y2, w2, SEED)
pickle.dump({"choice": choice, "lsog": final, "comp": comp_final, "features": AEC + STR, "comp_cuts": [0.35, 0.65], "type2_cut": cut},
            open(f"{OUT}/rf_v4_bundle.pkl", "wb"))
Xe = X4 if choice == "v4" else XS
np.save(f"{OUT}/env_min_v4.npy", Xe.min(0)); np.save(f"{OUT}/env_max_v4.npy", Xe.max(0))
json.dump({"choice": choice, "n": int(len(D)), "pos": [int((y2 >= k).sum()) for k in (1, 2, 3)], "type2_cut": cut},
          open(f"{OUT}/v4_meta.json", "w"))
pd.DataFrame({"occ_id": D.occ_id[O], "y": y1[O], "grp": g[O], **{f"{k}_{c}": P[k][O, i] for k in P for i, c in enumerate(["ge1", "ge2", "og"])}}).to_csv(f"{OUT}/v345_occ_oof_RESTRICTED.csv", index=False)
L("S9 DONE")
