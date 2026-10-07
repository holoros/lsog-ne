#!/usr/bin/env python3
# s3_predict_ordinal_v3.py MODE TASK  (v3: 64 AE bands + 4 structure features from the s7a 30 m layers)
#   MODE study  : native 10 m over the AlphaEarth 2024 tiles that hold OCC points (task = position in study list)
#   MODE state30: every Maine tile, read at 30 m (decimation 3, nearest), task = tile index
# Writes per tile, in the tile's own CRS: ord_<mode>_<tag>.tif, 4 bands uint16 (x10000, nodata 65535):
#   b1 P(>= transitioning), b2 P(>= LS) = Type 2 pool, b3 P(OG) = Type 1, b4 extrapolation flag (0/1)
# Carried controls from s3_predict_tiles_trans_10m.py: nodata initialisation (F2), AE sentinel and range (F7),
# prediction only inside the M3 hybrid forest frame. Coordinates of OCC points are used only to choose tiles.
import os, sys, gc, json, pickle, numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from rasterio.warp import reproject
from rasterio.windows import Window, transform as wtransform
from affine import Affine

E = os.environ; sa = E["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", VSI_CACHE="TRUE", GDAL_CACHEMAX="4096")
MODE, TASK = sys.argv[1], int(sys.argv[2])
W = E["W"]; OUT = f"{W}/out"; SFX = "_v3"
TT = f"{OUT}/tiles_{MODE}{SFX}"; os.makedirs(TT, exist_ok=True)
ms = pickle.load(open(f"{OUT}/rf_ordinal_final{SFX}.pkl", "rb"))
emin, emax = np.load(f"{OUT}/env_min{SFX}.npy"), np.load(f"{OUT}/env_max{SFX}.npy")
tiles = pd.read_csv(E["TILE_LIST"])
if MODE == "study":
    st = pd.read_csv(f"{OUT}/study_tiles.csv"); ti = int(st.tile_index.iloc[TASK]); DEC = 1
elif MODE == "state10":
    ti = TASK; DEC = 1                                  # full statewide native 10 m
else:
    ti = TASK; DEC = 3
row = tiles.iloc[ti]; tag = f"{ti:04d}"; dst_path = f"{TT}/ord_{MODE}_{tag}.tif"
if os.path.exists(dst_path): print("exists", dst_path); sys.exit(0)


def dequant(v):
    v = v.astype("float32"); v = np.where(v == -128, np.nan, v)
    x = (np.abs(v) / 127.5) ** 2 * np.sign(v)
    return np.where(np.abs(x) <= 1.0, x, np.nan)
def pred(Xf):
    p = np.column_stack([m.predict_proba(Xf)[:, 1] for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p

frame = rasterio.open(E["FRAME_M3"]); FV = int(E["FRAME_FOREST_VALUE"]); U16 = 65535
SD_ = f"{OUT}/structure"
ST = {k: rasterio.open(f"{SD_}/{k}.tif") for k in ("chm_mean30", "chm_max30", "chm_rms30", "lossyear30")}
assert emin.shape == (68,), emin.shape
WIN = 2048 * DEC
with rasterio.open("/vsigs/" + row.path[5:]) as ds:
    H, Wd = ds.height // DEC, ds.width // DEC
    tr = ds.transform * Affine.scale(DEC)
    prof = dict(driver="GTiff", height=H, width=Wd, count=4, dtype="uint16", nodata=U16, crs=ds.crs,
                transform=tr, compress="deflate", tiled=True, blockxsize=512, blockysize=512)
    out = rasterio.open(dst_path + ".part", "w", **prof)
    n_for = n_pred = 0
    for r0 in range(0, ds.height, WIN):
        for c0 in range(0, ds.width, WIN):
            win = Window(c0, r0, min(WIN, ds.width - c0), min(WIN, ds.height - r0))
            h, w = int(win.height) // DEC, int(win.width) // DEC
            if h == 0 or w == 0: continue
            wt = wtransform(win, ds.transform) * Affine.scale(DEC)
            fm = np.full((h, w), -1, "float32")
            reproject(rasterio.band(frame, 1), fm, dst_transform=wt, dst_crs=ds.crs, dst_nodata=-1, resampling=Resampling.nearest)
            fm = fm.reshape(-1) == FV
            res = np.full((4, h * w), U16, "uint16")       # F2: nodata start
            n_for += int(fm.sum())
            if fm.any():
                Xa = dequant(ds.read(window=win, out_shape=(64, h, w), resampling=Resampling.nearest)).reshape(64, -1).T
                sv = {}
                for k, src in ST.items():
                    a = np.full((h, w), -1, "float32")
                    reproject(rasterio.band(src, 1), a, dst_transform=wt, dst_crs=ds.crs, dst_nodata=-1, resampling=Resampling.nearest)
                    sv[k] = a.reshape(-1)
                miss = (sv["chm_mean30"] < 0) | (sv["chm_max30"] == 255) | ((sv["chm_mean30"] <= 0) & (sv["chm_max30"] <= 0))   # F2/F7: nodata, outside layer, or absent tile
                cm = np.where(miss, np.nan, sv["chm_mean30"]); cx = np.where(miss, np.nan, sv["chm_max30"])
                csd = np.where(miss, np.nan, np.sqrt(np.clip(sv["chm_rms30"] ** 2 - sv["chm_mean30"] ** 2, 0, None)))
                ly = sv["lossyear30"]; tsd = np.where(ly < 0, np.nan, np.where(ly > 0, 24 - ly, 40.0))
                Xa = np.column_stack([Xa, cm, cx, csd, tsd]).astype("float32")
                ok = fm & np.isfinite(Xa).all(1)
                if ok.any():
                    Xf = Xa[ok]; p = pred(Xf)
                    for b in range(3): res[b, ok] = np.rint(np.clip(p[:, b], 0, 1) * 10000).astype("uint16")
                    res[3, ok] = ((Xf < emin) | (Xf > emax)).any(1).astype("uint16")
                    n_pred += int(ok.sum())
            out.write(res.reshape(4, h, w), window=Window(c0 // DEC, r0 // DEC, w, h))
            gc.collect()
    out.close(); os.replace(dst_path + ".part", dst_path)
pd.DataFrame([{"mode": MODE, "tile": tag, "forest_cells": n_for, "predicted": n_pred}]).to_csv(f"{TT}/cov_{tag}.csv", index=False)
print("DONE", MODE, tag, n_for, n_pred, flush=True)
