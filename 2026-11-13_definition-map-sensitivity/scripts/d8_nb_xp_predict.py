#!/usr/bin/env python3
"""d8_nb_xp_predict.py TASK (November 13, 2026). Cross-predicted 10 m probability for every mapped New Brunswick
definition, one AlphaEarth 2024 tile per task. Tile list, forest frame, dequantisation and the time since
disturbance rule (2024 minus Hansen loss year, 40 for no loss, hard failure outside [0, 23] or 40) are those of
2026-10-05_nb-trans-licensed-tsd2024-10m-build/s3_predict_tiles_nb_trans_10m.py. Each cell is predicted by the
forest fit without the fold of its 20 km block (EPSG:3979). Output per tile, uint16, nodata 65535: one band per
definition (probability x 1e4, bundle order) and a last band with the extrapolation flag."""
import os, sys, gc, json, pickle, numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from rasterio.warp import reproject
from rasterio.windows import Window, transform as wtransform
from pyproj import Transformer
E = os.environ; sa = E["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", VSI_CACHE="TRUE", GDAL_CACHEMAX="4096")
TASK = int(sys.argv[1]); SCR = E["DS_SCR"]; TT = f"{SCR}/nb_tiles"; FV = int(E["FRAME_FOREST_VALUE"]); U = 65535; WIN = 2048
B = pickle.load(open(f"{SCR}/nb_defsens_xp_bundle.pkl", "rb")); DEFS = B["defs"]; M = B["models"]; K, BS = B["K"], B["BS"]; ND = len(DEFS)
def fold_of(x, y):
    bx = np.floor(np.asarray(x) / BS).astype(np.int64); by = np.floor(np.asarray(y) / BS).astype(np.int64)
    return ((bx * 73856093) ^ (by * 19349663)) % K
emin, emax = np.load(f"{SCR}/nb_env_min.npy"), np.load(f"{SCR}/nb_env_max.npy")
row = pd.read_csv(E["NB_TILE_LIST"]).iloc[TASK]; tag = f"{TASK:04d}"; dst = f"{TT}/defsens_xp_{tag}.tif"
if os.path.exists(dst): print("exists", dst); sys.exit(0)
def dequant(v):
    v = v.astype("float32"); v = np.where(v == -128, np.nan, v); x = (np.abs(v) / 127.5) ** 2 * np.sign(v)
    return np.where(np.abs(x) <= 1.0, x, np.nan)
gfc = rasterio.open(E["GFC_VRT"]); frame = rasterio.open(E["FRAME_M3"])
def warp(s, tr, crs, h, w, fill):
    a = np.full((h, w), fill, "float32")
    reproject(rasterio.band(s, 1), a, dst_transform=tr, dst_crs=crs, dst_nodata=fill, resampling=Resampling.nearest); return a
nf = npred = 0; psum = np.zeros(ND)
with rasterio.open("/vsigs/" + row.path[5:]) as ds:
    TRX = Transformer.from_crs(ds.crs, 3979, always_xy=True)
    prof = dict(driver="GTiff", height=ds.height, width=ds.width, count=ND + 1, dtype="uint16", nodata=U, crs=ds.crs,
                transform=ds.transform, compress="deflate", tiled=True, blockxsize=512, blockysize=512)
    out = rasterio.open(dst + ".part", "w", **prof)
    for r0 in range(0, ds.height, WIN):
        for c0 in range(0, ds.width, WIN):
            win = Window(c0, r0, min(WIN, ds.width - c0), min(WIN, ds.height - r0)); h, w = int(win.height), int(win.width)
            wt = wtransform(win, ds.transform); res = np.full((ND + 1, h * w), U, "uint16")
            fm = warp(frame, wt, ds.crs, h, w, -1).reshape(-1) == FV; nf += int(fm.sum())
            if fm.any():
                Xa = dequant(ds.read(window=win)).reshape(64, -1).T
                ly = warp(gfc, wt, ds.crs, h, w, 0).reshape(-1); tsd = np.where((ly > 0) & (ly <= 24), 2024 - (2000.0 + ly), 40.0)
                ok = fm & np.isfinite(Xa).all(1); t_ = tsd[ok]
                if not ((((t_ >= 0) & (t_ <= 23)) & (t_ == np.round(t_))) | (t_ == 40)).all(): print(tag, "FAIL tsd range", flush=True); sys.exit(5)
                if ok.any():
                    Xf = np.hstack([Xa[ok], tsd[ok, None]]).astype("float32"); idx = np.nonzero(ok)[0]; rr, cc = idx // w, idx % w
                    xs = wt.c + (cc + 0.5) * wt.a + (rr + 0.5) * wt.b; ys = wt.f + (cc + 0.5) * wt.d + (rr + 0.5) * wt.e
                    fx, fy = TRX.transform(xs, ys); fk = fold_of(fx, fy); p = np.zeros((len(Xf), ND), "float32")
                    for k in range(K):
                        mk = fk == k
                        if mk.any():
                            for j, v in enumerate(DEFS): p[mk, j] = M[v][k].predict_proba(Xf[mk])[:, 1]
                    for j in range(ND): res[j, ok] = np.rint(np.clip(p[:, j], 0, 1) * 10000).astype("uint16")
                    res[ND, ok] = ((Xf < emin) | (Xf > emax)).any(1).astype("uint16"); npred += int(ok.sum()); psum += p.sum(0)
            out.write(res.reshape(ND + 1, h, w), window=win); gc.collect()
    out.close(); os.replace(dst + ".part", dst)
pd.DataFrame([{"tile": tag, "forest_cells": nf, "predicted": npred, **{f"psum_{v}": float(psum[j]) for j, v in enumerate(DEFS)}}]).to_csv(f"{TT}/cov_{tag}.csv", index=False)
print("DONE", tag, nf, npred, flush=True)
