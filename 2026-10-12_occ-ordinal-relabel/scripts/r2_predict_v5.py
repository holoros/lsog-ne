#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s3_predict_v4.py TASK  Statewide native 10 m prediction for the rebuilt FIA + OCC (Hagan) LSOG model (s9 bundle).
# One AlphaEarth 2024 tile per task. Per window: AE (64 bands), Meta CHM v2 10 m mean, max and SD at the cell,
# 3 x 3 means of CHM mean and max, Hansen time since loss, then the composition model (softwood share) and the
# selected LSOG model (v3, v4 with the predicted softwood share, or v5 routed by predicted composition class).
# Writes ord_v4_<tag>.tif in the tile's own grid, uint16, nodata 65535:
#   b1 P(>= transitioning) x1e4, b2 P(LS or OG) x1e4, b3 P(OG) x1e4, b4 softwood share x1e4, b5 extrapolation flag
# Controls carried from earlier builds: nodata initialisation (F2), AE sentinel and range (F7), M3 forest frame only;
# CHM no data (255, -1) is missing; 0 m is a real height (harvested or regenerating stands).
import os, sys, gc, json, pickle, numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from rasterio.warp import reproject
from rasterio.windows import Window, transform as wtransform
from scipy.ndimage import uniform_filter
E = os.environ; sa = E["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", VSI_CACHE="TRUE", GDAL_CACHEMAX="4096")
TASK = int(sys.argv[1]); W = E["W"]; OUT = f"{W}/out"; TT = f"{OUT}/tiles_v4"; os.makedirs(TT, exist_ok=True)
B = pickle.load(open(f"{OUT}/rf_v4_bundle.pkl", "rb")); choice = B["choice"]; LM = B["lsog"]; CM = B["comp"]
emin, emax = np.load(f"{OUT}/env_min_v4.npy"), np.load(f"{OUT}/env_max_v4.npy")
tiles = pd.read_csv(E["TILE_LIST"]); row = tiles.iloc[TASK]; tag = f"{TASK:04d}"; dst = f"{TT}/ord_v4_{tag}.tif"
if os.path.exists(dst): print("exists", dst); sys.exit(0)
def dequant(v):
    v = v.astype("float32"); v = np.where(v == -128, np.nan, v); x = (np.abs(v) / 127.5) ** 2 * np.sign(v)
    return np.where(np.abs(x) <= 1.0, x, np.nan)
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] if hasattr(m, "predict_proba") else np.full(len(X), m) for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
frame = rasterio.open(E["FRAME_M3"]); FV = int(E["FRAME_FOREST_VALUE"]); U = 65535; PAD = 1
src = {k: rasterio.open(p) for k, p in {"mean": f"{OUT}/structure10/chm_mean10.vrt", "max": f"{OUT}/structure10/chm_max10.vrt",
                                       "rms": f"{OUT}/structure10/chm_rms10.vrt", "ly": f"{OUT}/structure/lossyear30.tif"}.items()}
def warp(s, tr, crs, h, w):
    a = np.full((h, w), -9, "float32")
    reproject(rasterio.band(s, 1), a, dst_transform=tr, dst_crs=crs, dst_nodata=-9, resampling=Resampling.nearest); return a
WIN = 2048; nf = npred = 0
with rasterio.open("/vsigs/" + row.path[5:]) as ds:
    prof = dict(driver="GTiff", height=ds.height, width=ds.width, count=5, dtype="uint16", nodata=U, crs=ds.crs,
                transform=ds.transform, compress="deflate", tiled=True, blockxsize=512, blockysize=512)
    out = rasterio.open(dst + ".part", "w", **prof)
    for r0 in range(0, ds.height, WIN):
        for c0 in range(0, ds.width, WIN):
            win = Window(c0, r0, min(WIN, ds.width - c0), min(WIN, ds.height - r0)); h, w = int(win.height), int(win.width)
            wt = wtransform(win, ds.transform); res = np.full((5, h * w), U, "uint16")
            fm = warp(frame, wt, ds.crs, h, w).reshape(-1) == FV; nf += int(fm.sum())
            if fm.any():
                # structure on a padded window so the 3 x 3 context is exact at window edges
                pw = Window(c0 - PAD, r0 - PAD, w + 2 * PAD, h + 2 * PAD); pt = wtransform(pw, ds.transform)
                mn = warp(src["mean"], pt, ds.crs, h + 2, w + 2); mx = warp(src["max"], pt, ds.crs, h + 2, w + 2)
                bad = (mn < 0) | (mx == 255) | (mx < 0)   # declared nodata only; 0 m is a real height
                mnn = np.where(bad, np.nan, mn); mxn = np.where(bad, np.nan, mx)
                def ctx(a):
                    v = np.where(np.isnan(a), 0, a); n = uniform_filter((~np.isnan(a)).astype("float32"), 3, mode="constant")
                    s = uniform_filter(v, 3, mode="constant"); return np.where(n > 0, s / np.maximum(n, 1e-9), np.nan)
                m3 = ctx(mnn)[1:-1, 1:-1].reshape(-1); x3 = ctx(mxn)[1:-1, 1:-1].reshape(-1)
                mnc = mnn[1:-1, 1:-1].reshape(-1); mxc = mxn[1:-1, 1:-1].reshape(-1)
                rms = warp(src["rms"], wt, ds.crs, h, w).reshape(-1)
                sd = np.where(np.isnan(mnc), np.nan, np.sqrt(np.clip(rms ** 2 - np.nan_to_num(mnc) ** 2, 0, None)))
                ly = warp(src["ly"], wt, ds.crs, h, w).reshape(-1); tsd = np.where(ly < 0, np.nan, np.where(ly > 0, 24 - ly, 40.0))
                Xa = dequant(ds.read(window=win)).reshape(64, -1).T
                X = np.column_stack([Xa, mnc, mxc, sd, m3, x3, tsd]).astype("float32")
                ok = fm & np.isfinite(X).all(1)
                if ok.any():
                    Xf = X[ok]; swp = np.clip(CM.predict(Xf), 0, 1)
                    if choice == "v4":
                        Xm = np.column_stack([Xf, swp]).astype("float32"); p = pred_cum(LM, Xm)
                    elif choice == "v5":
                        Xm = Xf; cl = np.where(swp < 0.35, 0, np.where(swp > 0.65, 2, 1)); p = np.zeros((len(Xf), 3))
                        for c in (0, 1, 2):
                            mm = cl == c
                            if mm.any(): p[mm] = pred_cum(LM[c], Xf[mm])
                    else:
                        Xm = Xf; p = pred_cum(LM, Xf)
                    for b in range(3): res[b, ok] = np.rint(np.clip(p[:, b], 0, 1) * 10000).astype("uint16")
                    res[3, ok] = np.rint(swp * 10000).astype("uint16")
                    res[4, ok] = ((Xm < emin) | (Xm > emax)).any(1).astype("uint16"); npred += int(ok.sum())
            out.write(res.reshape(5, h, w), window=win); gc.collect()
    out.close(); os.replace(dst + ".part", dst)
pd.DataFrame([{"tile": tag, "forest_cells": nf, "predicted": npred}]).to_csv(f"{TT}/cov_{tag}.csv", index=False)
print("DONE", tag, nf, npred, flush=True)
