#!/usr/bin/env python3
# s11a_fh_crossfit_v4.py  Block covariates from the rebuilt FIA + OCC (Hagan) 10 m map for the Maine
# transitioning and above Fay-Herriot model (the 2026-09-27 prep and 2026-10-05 cross fit, H3 resolution 4).
# Two covariates, written as block sums in the fhx convention (n, npos, sw, swy, swo_k, swo2_k, swyo_k):
#   v4map   block mean of the gated, recalibrated v4 P(>= transitioning), from the 100 m aggregate of the 10 m map
#           (each 100 m cell assigned to the H3 block of its centre; area mean)
#   v4lobo  plot level cross fit: for every H3 block, the v4 learner (composition model, then the P(>= transitioning)
#           classifier, same features, hard negatives, seed) is refit without that block's FIA plots and OCC points,
#           predicted at the block's FIA plots, and recalibrated with the same prior shift as the map
# The direct estimate stays y = total_score >= 4 from the prep (unchanged). If s9 selected v5 (per composition class),
# the cross fit uses the v4 form (pooled with predicted softwood share) and says so in the summary.
# Cardinal only; block aggregates only. Plots keyed by PLT_CN.
import os, sys, json, numpy as np, pandas as pd, rasterio, h3
from pyproj import Transformer
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; R = "/fs/scratch/PUOM0008/crsfaaron"; L_ = os.path.expanduser("~/LSOG")
SEED = 20261006; HN_W = 3.0
AEC = [f"AE_{k:02d}" for k in range(64)]; STR = ["chm_mean", "chm_max", "chm_sd", "chm_mean3", "chm_max3", "tsd"]
def cell(lat, lng): return h3.latlng_to_cell(lat, lng, 4) if hasattr(h3, "latlng_to_cell") else h3.geo_to_h3(lat, lng, 4)
def log(m): print(m, flush=True)
def die(m): log("GATE FAIL " + m); sys.exit(2)
meta = json.load(open(f"{OUT}/v4_meta.json")); pi_s = meta["pos"][0] / meta["n"]
lor1 = np.log(0.1466 / (1 - 0.1466)) - np.log(pi_s / (1 - pi_s))
def shift(p): p = np.clip(p, 1e-6, 1 - 1e-6); return 1 / (1 + np.exp(-(np.log(p / (1 - p)) + lor1)))

# ---- rows exactly as s9 builds them
o = pd.read_csv(E["OCC_CSV"]); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
o = o.merge(pd.read_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv")[["occ_id", "site"] + AEC], on="occ_id")
o["y"] = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}); o["src"] = "OCC"; o["ftg"] = "OCC"; o["tot4"] = np.nan
me = pd.read_csv(f"{R}/tmp_me_v51_restricted.csv", dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]].rename(columns={"TRUE.LAT": "lat", "TRUE.LON": "lon"})
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cond = pd.read_csv(f"{R}/FIA/ME_COND.csv", usecols=["PLT_CN", "COND_STATUS_CD", "FORTYPCD", "STDORGCD", "CONDPROP_UNADJ"], dtype={"PLT_CN": str})
cond = cond[cond.COND_STATUS_CD == 1].sort_values("CONDPROP_UNADJ", ascending=False).drop_duplicates("PLT_CN")
f = pd.read_csv(E["TRAIN_TABLE"]); f = f[f.state == "ME"].merge(j, on="plot_id", how="left").merge(me, on="PLT_CN", how="left").merge(cond, on="PLT_CN", how="left")
f["y"] = f.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3}); f["src"] = "FIA"; f["tot4"] = (f.total_score >= 4).astype(float)
f["ftg"] = np.where(f.FORTYPCD.isin([901, 904]) | (f.FORTYPCD == 385) | (f.STDORGCD == 1), "HN", "other")
tr = pd.read_csv(f"{R}/FIA/ME_TREE.csv", usecols=["PLT_CN", "STATUSCD", "SPCD", "DIA", "TPA_UNADJ"], dtype={"PLT_CN": str})
tr = tr[(tr.STATUSCD == 1) & (tr.DIA >= 5) & tr.TPA_UNADJ.notna() & tr.PLT_CN.isin(f.PLT_CN.dropna())]
tr["ba"] = 0.005454 * tr.DIA ** 2 * tr.TPA_UNADJ; tr["swba"] = np.where(tr.SPCD < 300, tr.ba, 0.0)
s = tr.groupby("PLT_CN")[["ba", "swba"]].sum(); s["sw_frac"] = s.swba / s.ba.replace(0, np.nan)
f = f.merge(s[["sw_frac"]].reset_index(), on="PLT_CN", how="left")
cols = ["occ_id", "src", "y", "ftg", "lat", "lon", "tot4"] + AEC
D = pd.concat([o.rename(columns={"occ_id": "occ_id"})[cols].assign(sw_frac=np.nan), f.rename(columns={"plot_id": "occ_id"})[cols + ["sw_frac"]]], ignore_index=True)
D = D[D.lat.notna() & np.isfinite(D[AEC]).all(1)].reset_index(drop=True)
def samp(path, win):
    with rasterio.open(path) as ds:
        x, y = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(D.lon.values, D.lat.values)
        out = np.full((len(D), (2 * win + 1) ** 2), np.nan)
        for i, (xx, yy) in enumerate(zip(x, y)):
            r, c = ds.index(xx, yy)
            if r - win < 0 or c - win < 0 or r + win >= ds.height or c + win >= ds.width: continue
            out[i] = ds.read(1, window=rasterio.windows.Window(c - win, r - win, 2 * win + 1, 2 * win + 1)).astype(float).ravel()
        return out
mean9 = samp(f"{OUT}/structure10/chm_mean10.vrt", 1); max9 = samp(f"{OUT}/structure10/chm_max10.vrt", 1); rms1 = samp(f"{OUT}/structure10/chm_rms10.vrt", 0)[:, 0]
bad9 = (mean9 < 0) | (max9 == 255); mean9[bad9] = np.nan; max9[bad9] = np.nan   # 0 m is a real height
D["chm_mean"] = mean9[:, 4]; D["chm_max"] = max9[:, 4]
D["chm_sd"] = np.where(D.chm_mean.isna(), np.nan, np.sqrt(np.clip(rms1 ** 2 - np.nan_to_num(D.chm_mean.values) ** 2, 0, None)))
D["chm_mean3"] = np.nanmean(mean9, 1); D["chm_max3"] = np.nanmean(max9, 1)
ly = samp(f"{OUT}/structure/lossyear30.tif", 0)[:, 0]; D["tsd"] = np.where(ly > 0, 24 - ly, 40.0)
D = D[D[STR].notna().all(1)].reset_index(drop=True)
D["h3"] = [cell(a, b) for a, b in zip(D.lat.values, D.lon.values)]
isF = (D.src == "FIA").values; HN = isF & (D.ftg.values == "HN")
y2 = D.y.values.astype(int).copy(); y2[HN] = 0; w2 = np.where(HN, HN_W, 1.0)
XS = D[AEC + STR].values.astype("float32"); hasC = isF & D.sw_frac.notna().values
log(f"rows {len(D)} (FIA {int(isF.sum())}); choice in s9: {meta['choice']}")

# ---- cross fit, leave one H3 block out
oof = np.full(len(D), np.nan); blocks = sorted(set(D.h3[isF]))
for i, b in enumerate(blocks):
    te = (D.h3.values == b); trn = ~te
    cm = RandomForestRegressor(n_estimators=300, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED).fit(XS[trn & hasC], D.sw_frac.values[trn & hasC])
    swp = cm.predict(XS)
    X4 = np.column_stack([XS, swp]).astype("float32")
    m = RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=SEED + 1)
    m.fit(X4[trn], (y2[trn] >= 1).astype(int), sample_weight=w2[trn])
    te_f = te & isF; oof[te_f] = shift(m.predict_proba(X4[te_f])[:, 1])
    if (i + 1) % 10 == 0: log(f"  lobo {i + 1} of {len(blocks)}")
F = D[isF].assign(o=oof[isF])
if F.o.isna().any(): die("plots left unpredicted")
F["y"] = F.tot4; F["o2"] = F.o ** 2; F["yo"] = F.y * F.o
G = F.groupby("h3").agg(n=("y", "size"), npos=("y", "sum"), swo_v4lobo=("o", "sum"), swo2_v4lobo=("o2", "sum"), swyo_v4lobo=("yo", "sum")).reset_index()
G["sw"] = G.n.astype(float); G["swy"] = G.npos.astype(float)
from sklearn.metrics import roc_auc_score
log(f"v4 lobo AUC for total_score >= 4 at FIA plots: {roc_auc_score(F.y, F.o):.4f}; mean {100 * F.o.mean():.2f}% vs observed {100 * F.y.mean():.2f}%")

# ---- map block means from the gated 100 m aggregate
with rasterio.open(f"{OUT}/final/occ-ordinal-v4-lsog-recalibrated_100m-from10m_ME_DATA_2026-10-06.tif") as ds:
    a = ds.read(1).astype(float); a[a == 65535] = np.nan; a /= 1e4
    rr, cc = np.nonzero(np.isfinite(a)); xs, ys = rasterio.transform.xy(ds.transform, rr, cc)
    lon, lat = Transformer.from_crs(ds.crs, 4326, always_xy=True).transform(np.array(xs), np.array(ys))
    M = pd.DataFrame({"h3": [cell(la, lo) for la, lo in zip(lat, lon)], "p": a[rr, cc]})
MB = M.groupby("h3").agg(map_mean_v4=("p", "mean"), n_cells_v4=("p", "size")).reset_index()
pr = pd.read_csv(f"{L_}/2026-09-27_sae-block-prep/out/sae_blocks_ME_TRANS_DATA_2026-09-27.csv", dtype={"h3": str})
C = pr[["h3", "n", "swy"]].merge(G[["h3", "n", "swy"]], on="h3", how="left", suffixes=("_prep", ""))
dn = float(np.nanmax(np.abs(C.n.fillna(0) - C.n_prep.fillna(0))))
log(f"block plot counts vs prep: max |dn| {dn} (differences arise only where structure is missing at a plot)")
out = pr[["h3"]].merge(G, on="h3", how="left").merge(MB, on="h3", how="left")
out.to_csv(f"{AGG}/fh_blocks_v4_DATA.csv", index=False)
log(f"blocks {len(out)}, with map mean {int(out.map_mean_v4.notna().sum())}")
log("S11A DONE")
