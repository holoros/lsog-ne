#!/usr/bin/env python3
# s5_structure_test.py  Can age and structure predictors separate old growth (Type 1) from LS (Type 2)
# where AlphaEarth 2024 alone cannot? Cardinal only: reads OCC and FIA true positions, writes aggregates only.
# Structure features per point:
#   Meta CHM v2 (1 m, chm_menb.vrt) in a 15 m radius window: mean, 95th percentile, SD, share of cells > 20 m
#   Hansen GFC v1.12 time since last loss, reference year 2024, 40 when no loss since 2001
# Tests (all grouped by OCC 2 km site or FIA spatial block):
#   A. OG vs LS among LS+OG rows, leave one group out: AE only RF, structure only logistic and RF, AE + structure RF
#   B. LS+OG vs rest on all rows, 5 grouped folds: AE only RF vs AE + structure RF
# Firewall: F1/F6 coverage of both inputs reported per source; F2 nodata stays NaN; F7 CHM range test [0, 80] m.
import os, json, numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import LeaveOneGroupOut, StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
from scipy.cluster.hierarchy import fcluster, linkage

E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"
SEED = 20261006; rng = np.random.default_rng(SEED + 5)
log = open(f"{AGG}/s5_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()
AEC = [f"AE_{k:02d}" for k in range(64)]
CHM_VRT = f"{R}/meta_chmv2/chm_menb.vrt"; GFC = f"{R}/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt"

# OCC points with coordinates (restricted), keyed by occ_id, same filter and clustering as s1
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
x3, y3 = Transformer.from_crs(4326, 3979, always_xy=True).transform(o.lon.values, o.lat.values)
o["site"] = fcluster(linkage(np.column_stack([x3, y3]), "single"), t=2000, criterion="distance")
ae = pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")[["occ_id"] + AEC]
o = o.merge(ae, on="occ_id")
o["y"] = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}); o["grp"] = "O" + o.site.astype(str); o["src"] = "OCC"
# FIA: key by PLT_CN, not row position. The row position key of tsd_extract_hansen_v112.py misassigns 809 plots
# (2026-10-05_resolution-pass_FINDINGS.md, item 4); a first run of this script used it and was discarded.
me = pd.read_csv(f"{R}/tmp_me_v51_restricted.csv", dtype={"PLT_CN": str})
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cw = j.merge(me[["PLT_CN", "TRUE.LAT", "TRUE.LON", "canopy_ht_m"]].rename(columns={"TRUE.LAT": "lat", "TRUE.LON": "lon", "canopy_ht_m": "cht_cw"}), on="PLT_CN", how="left")
f = pd.read_csv(E["TRAIN_TABLE"]); f = f[f.state == "ME"].merge(cw, on="plot_id", how="left")
L(f"FIA rows {len(f)}, with true position {int(f.lat.notna().sum())}")
ok = f.canopy_ht_m.notna() & f.cht_cw.notna()
L(f"join check: canopy_ht_m equal between training table and crosswalk at {int((np.abs(f.canopy_ht_m - f.cht_cw) < 1e-6)[ok].sum())} of {int(ok.sum())} plots")
if (np.abs(f.canopy_ht_m - f.cht_cw) < 1e-6)[ok].mean() < 0.99: L("JOIN CHECK FAIL"); raise SystemExit(2)
f["y"] = f.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3}); f["grp"] = "F" + f.spatial_block.astype(str); f["src"] = "FIA"
f = f.rename(columns={"plot_id": "occ_id"})
D = pd.concat([o[["occ_id", "src", "grp", "y", "lat", "lon"] + AEC], f[["occ_id", "src", "grp", "y", "lat", "lon"] + AEC]], ignore_index=True)
D = D[D.lat.notna() & np.isfinite(D[AEC]).all(1)].reset_index(drop=True)

# CHM window features
feat = np.full((len(D), 4), np.nan)
with rasterio.open(CHM_VRT) as ds:
    tx, ty = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(D.lon.values, D.lat.values)
    rpx = int(round(15 / abs(ds.transform.a)))
    for i, (xx, yy) in enumerate(zip(tx, ty)):
        r, c = ds.index(xx, yy)
        if r - rpx < 0 or c - rpx < 0 or r + rpx >= ds.height or c + rpx >= ds.width: continue
        a = ds.read(1, window=Window(c - rpx, r - rpx, 2 * rpx + 1, 2 * rpx + 1), masked=True).astype("float32")
        yy_, xx_ = np.ogrid[-rpx:rpx + 1, -rpx:rpx + 1]; a = np.ma.masked_where((yy_**2 + xx_**2) > rpx**2, a)
        v = a.compressed(); v = v[(v >= 0) & (v <= 80)]                      # F7 physical range
        if v.size >= 0.5 * np.pi * rpx**2:
            feat[i] = [v.mean(), np.percentile(v, 95), v.std(), (v > 20).mean()]
D[["chm_mean", "chm_p95", "chm_sd", "chm_gt20"]] = feat
with rasterio.open(GFC) as g:
    ly = np.array([s[0] for s in g.sample(list(zip(D.lon.values, D.lat.values)))]).astype(float)
D["tsd"] = np.where(ly > 0, 2024 - (2000 + ly), 40.0)
for s in ("OCC", "FIA"):
    m = D.src == s; L(f"coverage {s}: CHM {int(D.loc[m, 'chm_mean'].notna().sum())} of {int(m.sum())}; Hansen {int(np.isfinite(D.loc[m, 'tsd']).sum())}")
L("median structure by source and class:\n" + D.groupby(["src", "y"])[["chm_mean", "chm_p95", "chm_sd", "chm_gt20", "tsd"]].median().round(2).to_string())
STR = ["chm_mean", "chm_p95", "chm_sd", "chm_gt20", "tsd"]
D = D[D[STR].notna().all(1)].reset_index(drop=True)

def auc_ci(yb, s, g, B=1000):
    a = roc_auc_score(yb, s); ug = np.unique(g); idx = {u: np.where(g == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
rf = lambda: RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED)
lr = lambda: make_pipeline(StandardScaler(), LogisticRegression(C=1.0, max_iter=2000))
rows = []

# A. OG vs LS
A = D[D.y >= 2].reset_index(drop=True); yA = (A.y == 3).astype(int).values; gA = A.grp.values
L(f"A: LS+OG rows {len(A)} (OG {yA.sum()}; OG groups {A[A.y == 3].grp.nunique()})")
for u in STR:
    rows.append(dict(test="A OG vs LS", model=f"univariate {u}", n=len(A), pos=int(yA.sum()), **dict(zip(["auc", "lo", "hi"], auc_ci(yA, A[u].values, gA)))))
for name, cols, mk in (("AE only RF", AEC, rf), ("structure only logistic", STR, lr), ("structure only RF", STR, rf), ("AE + structure RF", AEC + STR, rf)):
    p = np.full(len(A), np.nan)
    for tr, te in LeaveOneGroupOut().split(A, yA, gA):
        if yA[tr].sum() == 0: continue
        m = mk().fit(A.loc[tr, cols].values, yA[tr]); p[te] = m.predict_proba(A.loc[te, cols].values)[:, 1]
    rows.append(dict(test="A OG vs LS", model=name, n=len(A), pos=int(yA.sum()), **dict(zip(["auc", "lo", "hi"], auc_ci(yA, p, gA)))))
    for s in ("OCC", "FIA"):
        mm = (A.src == s).values
        if 0 < yA[mm].sum() < mm.sum():
            rows.append(dict(test=f"A OG vs LS, scored {s}", model=name, n=int(mm.sum()), pos=int(yA[mm].sum()), **dict(zip(["auc", "lo", "hi"], auc_ci(yA[mm], p[mm], gA[mm])))))
# B. Type 2 pool vs rest
yB = (D.y >= 2).astype(int).values; gB = D.grp.values
for name, cols in (("AE only RF", AEC), ("AE + structure RF", AEC + STR), ("structure only RF", STR)):
    p = np.full(len(D), np.nan)
    for tr, te in StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(D, yB, gB):
        p[te] = rf().fit(D.loc[tr, cols].values, yB[tr]).predict_proba(D.loc[te, cols].values)[:, 1]
    for s in ("OCC", "FIA"):
        mm = (D.src == s).values
        rows.append(dict(test=f"B Type 2 vs rest, scored {s}", model=name, n=int(mm.sum()), pos=int(yB[mm].sum()), **dict(zip(["auc", "lo", "hi"], auc_ci(yB[mm], p[mm], gB[mm])))))
T = pd.DataFrame(rows); T.to_csv(f"{AGG}/structure_test_auc_DATA.csv", index=False); L(T.to_string(index=False))
L("S5 DONE")
