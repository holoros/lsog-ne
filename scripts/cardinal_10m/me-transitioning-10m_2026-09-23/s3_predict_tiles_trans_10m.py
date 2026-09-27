#!/usr/bin/env python3
# s3_predict_tiles_trans_10m.py  START END
# Stage 2B. Native 10 m prediction of the Maine transitioning-and-above probability over the
# Maine AlphaEarth 2024 tiles, windowed so no tile is ever held whole in memory. Only cells inside
# the M3 hybrid forest frame are predicted.
#
# Differences from s3_predict_tiles_10m.py (2026-09-16), and only these:
#   1. model pickles point at the Stage A rf_trans_* artefacts
#   2. feature set is the 64 AlphaEarth bands; the time_since_disturbance band assembly and its
#      Hansen raster read are removed. Stage A measured TSD at 0.00022 of Brier, so nothing is lost
#      and one input dependency goes away.
#   3. tile selection is Maine only
# The nodata initialisation, the AlphaEarth -128 sentinel test and the [-1, 1] range test are
# carried over untouched: they are the F2 and F7 controls and they are correct.
#
# Per tile writes three rasters in the tile's own CRS and grid:
#   prob_<tag>.tif  uint16, probability x 10000, nodata 65535
#   sd_<tag>.tif    uint16, block-bootstrap SD x 10000 (B = N_BOOT), nodata 65535
#   env_<tag>.tif   uint8, 1 if any feature is outside the training envelope, nodata 255
# Plus samp_<tag>.npz, a seeded Bernoulli sample of predicted forest cells for s5. These are
# raster cell positions, not plot coordinates.
import os, sys, gc, json, pickle, time
import numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from rasterio.warp import reproject
from rasterio.windows import Window, transform as wtransform
from rasterio.transform import xy as cell_xy

T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ
sa = E["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR", VSI_CACHE="TRUE", GDAL_CACHEMAX="4096")
B = E["BUILD"]; TMP = E["TMP_TILES"]; os.makedirs(TMP, exist_ok=True); os.makedirs(f"{B}/logs", exist_ok=True)
WIN = int(E["WIN"]); FV = int(E["FRAME_FOREST_VALUE"])
SAMPLE_RATE = float(E.get("SAMPLE_RATE", "0.0025")); SEED = int(E["SEED"])
U16, U8 = 65535, 255

final = pickle.load(open(E["MODEL_FINAL"], "rb"))
boots = pickle.load(open(E["MODEL_BOOT"], "rb"))
emin = np.load(f"{B}/env_min.npy"); emax = np.load(f"{B}/env_max.npy")
assert emin.shape == (64,) and emax.shape == (64,), f"envelope is not 64 band: {emin.shape}"

REG = {"ME": (-71.10, 43.00, -66.90, 47.50)}          # Maine only, Stage 2B
idx = pd.read_csv(E["AEF_INDEX"])
sel = []
for r, (W, S, Ee, N) in REG.items():
    s = idx[(idx.year == 2024) & (idx.wgs84_east >= W) & (idx.wgs84_west <= Ee) &
            (idx.wgs84_north >= S) & (idx.wgs84_south <= N)].copy()
    s["region"] = r; sel.append(s)
sel = pd.concat(sel).drop_duplicates(subset=["path"]).reset_index(drop=True)
if not os.path.exists(f"{B}/s3_tile_list.csv"):  # array tasks race here, so write atomically
    tmp = f"{B}/s3_tile_list.{os.getpid()}.csv"; sel.to_csv(tmp, index=False); os.replace(tmp, f"{B}/s3_tile_list.csv")

def dequant(v):
    v = v.astype("float32")
    v = np.where(v == -128, np.nan, v)                 # F7: AlphaEarth sentinel
    x = (np.abs(v) / 127.5) ** 2 * np.sign(v)
    return np.where(np.abs(x) <= 1.0, x, np.nan)       # F7: dequantised range

frame = rasterio.open(E["FRAME_M3"])
def warp_to(src, tr, crs, h, w, fill):
    out = np.full((h, w), fill, "float32")
    reproject(rasterio.band(src, 1), out, dst_transform=tr, dst_crs=crs,
              dst_nodata=fill, resampling=Resampling.nearest)
    return out

START = int(sys.argv[1]); END = min(int(sys.argv[2]), len(sel))
cov_rows = []
for ti in range(START, END):
    row = sel.iloc[ti]; tag = f"{row.region}_{ti:04d}"
    paths = {k: f"{TMP}/{k}_{tag}.tif" for k in ("prob", "sd", "env")}
    spath = f"{TMP}/samp_{tag}.npz"
    if all(os.path.exists(p) for p in paths.values()) and os.path.exists(spath):
        continue
    rng = np.random.default_rng(SEED + ti); samp = []
    try:
        src_path = "/vsigs/" + row.path[5:] if row.path.startswith("gs://") else row.path
        with rasterio.open(src_path) as ds:
            base = dict(driver="GTiff", height=ds.height, width=ds.width, count=1, crs=ds.crs,
                        transform=ds.transform, compress="deflate", tiled=True, blockxsize=512, blockysize=512)
            part = {k: p + ".part" for k, p in paths.items()}
            dst = {"prob": rasterio.open(part["prob"], "w", dtype="uint16", nodata=U16, **base),
                   "sd": rasterio.open(part["sd"], "w", dtype="uint16", nodata=U16, **base),
                   "env": rasterio.open(part["env"], "w", dtype="uint8", nodata=U8, **base)}
            n_forest = n_pred = 0
            for r0 in range(0, ds.height, WIN):
                for c0 in range(0, ds.width, WIN):
                    win = Window(c0, r0, min(WIN, ds.width - c0), min(WIN, ds.height - r0))
                    h, w = int(win.height), int(win.width); wt = wtransform(win, ds.transform)
                    # F2: destinations start at nodata
                    pr = np.full(h * w, U16, "uint16"); sd = np.full(h * w, U16, "uint16"); ev = np.full(h * w, U8, "uint8")
                    fm = warp_to(frame, wt, ds.crs, h, w, -1).reshape(-1) == FV
                    n_forest += int(fm.sum())
                    if fm.any():
                        Xa = dequant(ds.read(window=win)).reshape(64, -1).T
                        ok = fm & np.isfinite(Xa).all(1)
                        if ok.any():
                            Xf = Xa[ok]                       # 64 AlphaEarth bands, no TSD
                            p = final.predict_proba(Xf)[:, 1]
                            bp = np.stack([m.predict_proba(Xf)[:, 1] for m in boots])
                            pr[ok] = np.rint(np.clip(p, 0, 1) * 10000).astype("uint16")
                            sd[ok] = np.rint(np.clip(bp.std(0), 0, 1) * 10000).astype("uint16")
                            ev[ok] = ((Xf < emin) | (Xf > emax)).any(1).astype("uint8")
                            n_pred += int(ok.sum())
                            pick = rng.random(int(ok.sum())) < SAMPLE_RATE
                            if pick.any():
                                flat = np.flatnonzero(ok)[pick]
                                xs, ys = cell_xy(wt, flat // w, flat % w)
                                samp.append(np.column_stack([xs, ys, p[pick], bp[:, pick].T]).astype("float64"))
                    dst["prob"].write(pr.reshape(h, w), 1, window=win)
                    dst["sd"].write(sd.reshape(h, w), 1, window=win)
                    dst["env"].write(ev.reshape(h, w), 1, window=win)
                    gc.collect()
            for k, f in dst.items():
                f.close(); os.replace(part[k], paths[k])
            S = np.vstack(samp) if samp else np.zeros((0, 3 + len(boots)))
            np.savez(spath + ".part.npz", s=S, crs=str(ds.crs), region=row.region, rate=SAMPLE_RATE)
            os.replace(spath + ".part.npz", spath)
        cov_rows.append({"tag": tag, "region": row.region, "forest_cells": n_forest, "predicted_cells": n_pred,
                         "predicted_share": n_pred / n_forest if n_forest else np.nan})
        log(f"{tag} forest {n_forest:,} predicted {n_pred:,}")
    except Exception as ex:
        log(f"{tag} ERROR {ex!r}"[:400])
        with open(f"{B}/logs/s3_errors.txt", "a") as f: f.write(f"{tag}\t{ex!r}\n")
if cov_rows:
    pd.DataFrame(cov_rows).to_csv(f"{B}/logs/s3_coverage_{START:04d}_{END:04d}.csv", index=False)
print("S3_RANGE_DONE", START, END, flush=True)
