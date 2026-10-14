#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s17a_me_table.py  Cross-jurisdiction comparison, step 1 (October 7, 2026). Same Maine data assembly as s16a/s9 (V2 OCC points);
# writes the Maine feature table (no coordinates) with distance to the NB border, restricted, Cardinal only.
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
log = open(f"{AGG}/s17a_log.txt", "w")
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
# ---- distance to the shared Maine and New Brunswick border (xj_border.py), restricted table only
import sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from xj_border import border_km
D["border_km"] = border_km(D.lon.values, D.lat.values); D["HN"] = HN
# s16a fold of each row (20 km blocks in EPSG:3979), so s17e can use block held-out predictions on the Maine side
_bx, _by = Transformer.from_crs(4326, 3979, always_xy=True).transform(D.lon.values, D.lat.values)
D["fold_xp"] = ((np.floor(np.asarray(_bx) / 20000.0).astype(np.int64) * 73856093) ^ (np.floor(np.asarray(_by) / 20000.0).astype(np.int64) * 19349663)) % 5
D.drop(columns=["lat", "lon"]).to_csv(f"{OUT}/xj_me_table_RESTRICTED.csv", index=False)
L(f"S17A DONE rows {len(D)}; FIA {int(isF.sum())}; OCC {int(O.sum())}; within 25 km of border {int((D.border_km <= 25).sum())}")
