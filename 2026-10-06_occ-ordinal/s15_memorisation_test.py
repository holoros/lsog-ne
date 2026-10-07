#!/usr/bin/env python3
# s15_memorisation_test.py  Red team, 7 October 2026. The 10 m map is predicted with the final forests fit on all
# training points, so the cell at each training point may carry a memorised spike that could reveal FIA true plot
# positions or OCC stand positions near their public or fuzzed locations. Test, aggregates only:
#   for every training point (FIA true position, OCC point), read the raw 10 m layers at the point cell and at 8 cells
#   on a 40 m ring; spike = centre minus ring mean. Control: the same for a point 1 km away in a random direction.
#   Leak AUC: discrimination of the training label (>= LS for band 2, >= transitioning for band 1) by the centre value
#   against by the ring mean; a centre AUC well above the ring AUC means the surface encodes the label at the point.
#   The same test on the 30 m product (ring at 90 m) and the 100 m product (ring at 300 m).
import os, json, pickle, numpy as np, pandas as pd, rasterio
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score, r2_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"
S10 = f"{OUT}/structure10"; S30 = f"{OUT}/structure"
SEED = 20261006; rng = np.random.default_rng(SEED + 9); NT, LEAF, HN_W = 500, 3, 3.0
AEC = [f"AE_{k:02d}" for k in range(64)]; STR = ["chm_mean", "chm_max", "chm_sd", "chm_mean3", "chm_max3", "tsd"]
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
FIN = f"{OUT}/final"; U = 65535
PRODS = {"10 m raw": (f"{FIN}/occ-ordinal-v4-lsog_10m_ME_DATA_2026-10-06.tif", 40),
         "30 m": (f"{FIN}/occ-ordinal-v4-lsog-recalibrated_30m-from10m_ME_DATA_2026-10-06.tif", 90),
         "100 m": (f"{FIN}/occ-ordinal-v4-lsog-recalibrated_100m-from10m_ME_DATA_2026-10-06.tif", 300)}
ang = np.deg2rad(np.arange(0, 360, 45)); ctrl_ang = rng.uniform(0, 2 * np.pi, len(D))
y = D.y.values.astype(int); src = D.src.values
res = []
for name, (path, rad) in PRODS.items():
    with rasterio.open(path) as ds:
        x0, y0 = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(D.lon.values, D.lat.values)
        def val(xx, yy, b):
            v = np.array([z[0] for z in ds.sample(zip(xx, yy), indexes=b)], dtype="float64")
            return np.where(v == U, np.nan, v / 1e4)
        for lab, cx, cy in (("training point", x0, y0), ("control 1 km", x0 + 1000 * np.cos(ctrl_ang), y0 + 1000 * np.sin(ctrl_ang))):
            for b, bn, ythr in ((1, "P(>= transitioning)", 1), (2, "P(LS or OG)", 2)):
                cen = val(cx, cy, b); ring = np.nanmean(np.column_stack([val(cx + rad * np.cos(t), cy + rad * np.sin(t), b) for t in ang]), 1)
                for s in ("FIA", "OCC"):
                    m = (src == s) & np.isfinite(cen) & np.isfinite(ring); spike = cen[m] - ring[m]; yy = (y[m] >= ythr).astype(int)
                    rr = dict(product=name, location=lab, band=bn, source=s, n=int(m.sum()), mean_spike=float(np.mean(spike)),
                              sd_spike=float(np.std(spike)), p95_abs_spike=float(np.percentile(np.abs(spike), 95)),
                              mean_spike_positives=float(np.mean(spike[yy == 1])) if yy.sum() else np.nan)
                    if lab == "training point" and 0 < yy.sum() < len(yy):
                        rr.update(auc_centre=float(roc_auc_score(yy, cen[m])), auc_ring=float(roc_auc_score(yy, ring[m])))
                    res.append(rr)
    print(name, "done", flush=True)
R_ = pd.DataFrame(res); R_.to_csv(f"{AGG}/memorisation_test_DATA.csv", index=False); print(R_.to_string(index=False))
print("S15 DONE")
