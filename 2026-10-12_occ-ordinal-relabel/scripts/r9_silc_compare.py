#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s10b_silc_compare.py  Red team revision of s10 (7 October 2026). Changes: (1) the area calibrated rebuild (s4e) replaces
# the s4d layers (AUC is unchanged by a monotone shift; shares change); (2) the shipped 10 m CORE4 surface joins the
# shipped transitioning surface, so the LS or OG contrast has a reference built for that class; (3) block bootstrap at
# 10 km (100 x 100 m cells) as well as 2 km, since one ownership is spatially clustered; (4) every contrast is repeated
# after dropping cells within 5 km of any OCC field point, because the Seven Islands classification and the rebuild may
# share OCC stands as training labels; (5) class codes 1 to 4 read as Not LS, Trans LS, LS, OG-like, as recorded in
# CLAUDE.md Phase 9. Aggregates only; the Seven Islands raster and the OCC positions stay on Cardinal.
import os, json, numpy as np, pandas as pd, rasterio
from rasterio.warp import reproject
from rasterio.enums import Resampling
from pyproj import Transformer
from scipy.spatial import cKDTree
from scipy.stats import spearmanr
from sklearn.metrics import roc_auc_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; rng = np.random.default_rng(20261007)
SILC = "/users/PUOM0008/crsfaaron/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif"
V4 = f"{OUT}/final/occ-ordinal-v5-lsog-areacal_10m_ME_DATA_2026-10-12.tif"
TR = "/users/PUOM0008/crsfaaron/LSOG/products/me-transitioning-10m_2026-09-23/me-transitioning-and-above-probability_10m_ME_DATA_2026-09-23.tif"
C4 = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/final/core4-structural-core-probability_10m_ME_DATA_2026-09-16.tif"
with rasterio.open(SILC) as s:
    sc = s.read(1).astype(int); tr_, crs, H, W = s.transform, s.crs, s.height, s.width
valid = np.isin(sc, [1, 2, 3, 4])
def onto(path, bands, scale):
    out = []
    with rasterio.open(path) as src:
        nod = src.nodata if src.nodata is not None else 65535
        for b in bands:
            a = np.full((H, W), np.nan, "float32")
            reproject(rasterio.band(src, b), a, dst_transform=tr_, dst_crs=crs, src_nodata=nod, dst_nodata=np.nan, resampling=Resampling.average)
            out.append(a / scale)
    return out
ge1, ge2, og, sw = onto(V4, [1, 2, 3, 4], 1e4); trs, = onto(TR, [1], 1e4); c4, = onto(C4, [1], 1e4)
ok = valid & np.isfinite(ge1) & np.isfinite(trs) & np.isfinite(c4)
rr, cc = np.nonzero(ok); xs, ys = rasterio.transform.xy(tr_, rr, cc)
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.1, -66.9) & o.lat.between(43, 47.5)]
ox, oy = Transformer.from_crs(4326, crs, always_xy=True).transform(o.lon.values, o.lat.values)
dist, _ = cKDTree(np.column_stack([ox, oy])).query(np.column_stack([xs, ys]))
far = dist >= 5000
print("comparable cells", int(ok.sum()), "cells >= 5 km from any OCC point", int(far.sum()), flush=True)
c = sc[ok]; b2 = ((rr // 20) * 10000 + cc // 20); b10 = ((rr // 100) * 10000 + cc // 100)
L = {"rebuild P(>=trans)": ge1[ok], "rebuild P(LS or OG)": ge2[ok], "rebuild P(OG)": og[ok], "shipped transitioning": trs[ok], "shipped CORE4": c4[ok]}
def auc_ci(yb, s, g, B=400):
    a = roc_auc_score(yb, s); ug = np.unique(g); idx = {u: np.where(g == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
rows = []
CON = (("Trans+ vs Not", c >= 2, None, ["rebuild P(>=trans)", "shipped transitioning", "shipped CORE4"]),
       ("LS or OG vs rest", c >= 3, None, ["rebuild P(LS or OG)", "shipped CORE4", "shipped transitioning"]),
       ("OG vs rest", c == 4, None, ["rebuild P(OG)", "shipped CORE4", "shipped transitioning"]),
       ("OG vs LS", c == 4, c >= 3, ["rebuild P(OG)", "shipped CORE4", "shipped transitioning"]))
for subset, msk in (("all cells", np.ones(len(c), bool)), ("cells >= 5 km from OCC points", far)):
    for cn, yb, keep, layers in CON:
        k = msk if keep is None else (msk & keep)
        for nm in layers:
            a2 = auc_ci(yb[k].astype(int), L[nm][k], b2[k]); a10 = auc_ci(yb[k].astype(int), L[nm][k], b10[k])
            rows.append(dict(subset=subset, contrast=cn, layer=nm, n_cells=int(k.sum()), n_pos=int(yb[k].sum()), auc=a2[0],
                             lo_2km=a2[1], hi_2km=a2[2], lo_10km=a10[1], hi_10km=a10[2]))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/silc_compare_v2_auc_DATA.csv", index=False); print(A.to_string(index=False))
sh = {"n_cells": int(ok.sum()), "n_far": int(far.sum()),
      "silc_share_pct": {"Trans+": 100 * float((c >= 2).mean()), "LS+OG": 100 * float((c >= 3).mean()), "OG": 100 * float((c == 4).mean())},
      "rebuild_areacal_expected_pct": {"Trans+": 100 * float(ge1[ok].mean()), "LS+OG": 100 * float(ge2[ok].mean()), "OG": 100 * float(og[ok].mean())},
      "spearman_with_silc_class": {nm: float(spearmanr(v, c).correlation) for nm, v in L.items()},
      "rebuild_mean_P_LSOG_by_silc_class": {int(k): float(ge2[ok][c == k].mean()) for k in (1, 2, 3, 4)},
      "rebuild_mean_softwood_by_silc_class": {int(k): float(sw[ok][c == k].mean()) for k in (1, 2, 3, 4)}}
json.dump(sh, open(f"{AGG}/silc_compare_v2_shares_DATA.json", "w"), indent=1); print(json.dumps(sh, indent=1))
print("S10B DONE")
