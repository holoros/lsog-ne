#!/usr/bin/env python3
"""d19_build_30m.py (November 14, 2026). Release build (Aaron, November 14: release the six Maine definition layers at
30 m, the grain at which d18 found peak recovery at chance for every definition). Block means of the 10 m
cross-predicted layers of d4 on the 30 m grid of d18 (cells aligned to multiples of 30 m from the tile-0 origin).
Only forest-frame cells inside the Maine cutline enter (the cells of the d5 agreement rasters); a 30 m cell is kept
when at least 5 of its 9 cells are such cells. Output: one north-up GeoTIFF, EPSG:32619,
uint16, nodata 65535; bands 1 to 6 = mean probability x 1e3 for V3, V1, V2, V4, V9_c3, V7; band 7 = share of the
cell's 10 m cells outside the training range of at least one predictor, x 1e4. No plot data is read."""
import os, glob, json, hashlib, numpy as np, rasterio
from rasterio.transform import Affine
from rasterio.enums import Resampling
SCR = os.environ["DS_SCR"]; W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); U = 65535; G = 3
DEFS = ["V3", "V1", "V2", "V4", "V9_c3", "V7"]
NAMES = ["Fixed deadwood", "Base card, cut 3", "Height added", "Base card, cut 4", "CORE4, cut 3", "Six axes, cut 5"]
TL = sorted(glob.glob(f"{SCR}/me_tiles/defsens_xp_*.tif")); assert len(TL) == 34
with rasterio.open(TL[0]) as q: T0 = q.transform; CRS = q.crs
TI = []
for f in TL:
    with rasterio.open(f) as q: TI.append((f, int(round((q.transform.c - T0.c) / T0.a)), int(round((q.transform.f - T0.f) / T0.e)), q.width, q.height))
assert min(t[1] for t in TI) == 0 and min(t[2] for t in TI) == 0
NC = -(-max(t[1] + t[3] for t in TI) // G); NR = -(-max(t[2] + t[4] for t in TI) // G)
S = np.zeros((7, NR, NC), np.float32); C = np.zeros((NR, NC), np.uint8)
for f, oc, orow, w, h in TI:
    fa = f.replace("me_tiles/defsens_xp_", "me_agree/agree_")
    if not os.path.exists(fa): print(os.path.basename(f), "no Maine forest cell", flush=True); continue
    with rasterio.open(f) as q: a = q.read()
    with rasterio.open(fa) as q: a[:, q.read(1) == 255] = U
    pl, pt = oc % G, orow % G; pr_, pb = (-(pl + w)) % G, (-(pt + h)) % G
    a = np.pad(a, ((0, 0), (pt, pb), (pl, pr_)), constant_values=U); ok = a[0] != U; n_r, n_c = a.shape[1] // G, a.shape[2] // G
    r0, c0 = (orow - pt) // G, (oc - pl) // G
    C[r0:r0 + n_r, c0:c0 + n_c] += ok.reshape(n_r, G, n_c, G).sum((1, 3)).astype(np.uint8)
    for b in range(7): S[b, r0:r0 + n_r, c0:c0 + n_c] += np.where(ok, a[b], 0).astype(np.float32).reshape(n_r, G, n_c, G).sum((1, 3))
    print(os.path.basename(f), int(ok.sum()), flush=True)
V = C >= 5; out = np.full((7, NR, NC), U, np.uint16)
for b in range(6): out[b][V] = np.rint(S[b][V] / C[V] / 10.0).astype(np.uint16)
out[6][V] = np.rint(S[6][V] / C[V] * 1e4).astype(np.uint16)
rr = np.nonzero(V.any(1))[0]; cc = np.nonzero(V.any(0))[0]; r1, r2, c1, c2 = rr[0], rr[-1] + 1, cc[0], cc[-1] + 1
crop = out[:, r1:r2, c1:c2][:, ::-1, :]                                   # south-up source to north-up file
T = Affine(30.0, 0, T0.c + 30.0 * c1, 0, -30.0, T0.f + 30.0 * r2)
os.makedirs(f"{SCR}/me_release30", exist_ok=True); fn = f"{SCR}/me_release30/2026-11-14_me-lsog-definition-probability-30m_DATA.tif"
with rasterio.open(fn, "w", driver="GTiff", height=crop.shape[1], width=crop.shape[2], count=7, dtype="uint16", nodata=U, crs=CRS, transform=T,
                   compress="deflate", predictor=2, tiled=True, blockxsize=512, blockysize=512, BIGTIFF="IF_SAFER") as d:
    d.write(crop)
    for b in range(6): d.set_band_description(b + 1, f"{DEFS[b]} ({NAMES[b]}): mean probability x 1e3"); 
    d.set_band_description(7, "Share of 10 m cells outside predictor training range x 1e4")
    d.update_tags(SCALE="1e-3 (bands 1 to 6), 1e-4 (band 7)", SOURCE="Block mean of 10 m cross-predicted layers (20 km block folds), Maine forest-frame cells only, 30 m cells with >= 5 of 9 such cells", BUILT="2026-11-14", SCRIPT="d19_build_30m.py")
    d.build_overviews([2, 4, 8, 16, 32], Resampling.average)
# independent check: 400 random kept cells recomputed from the 10 m tiles by direct window reads
rng = np.random.default_rng(20261114); kr, kc = np.nonzero(V); pick = rng.choice(len(kr), 400, replace=False); bad = 0; mx = 0
with rasterio.open(fn) as d:
    for k in pick:
        r, c = int(kr[k]), int(kc[k]); blk = np.full((7, 3, 3), U, np.uint16)
        for f, oc, orow, w, h in TI:
            a1, a2, b1, b2 = max(c * 3, oc), min(c * 3 + 3, oc + w), max(r * 3, orow), min(r * 3 + 3, orow + h)
            if a1 >= a2 or b1 >= b2: continue
            fa = f.replace("me_tiles/defsens_xp_", "me_agree/agree_")
            if not os.path.exists(fa): continue
            wn = ((b1 - orow, b2 - orow), (a1 - oc, a2 - oc))
            with rasterio.open(f) as q: t = q.read(window=wn)
            with rasterio.open(fa) as q: t[:, q.read(1, window=wn) == 255] = U
            blk[:, b1 - r * 3:b2 - r * 3, a1 - c * 3:a2 - c * 3] = t
        ok = blk[0] != U; ref = np.rint(blk[:6][:, ok].astype(float).mean(1) / 10.0); got = d.read(list(range(1, 7)), window=((r2 - 1 - r, r2 - r), (c - c1, c - c1 + 1)))[:, 0, 0]
        dd = np.abs(ref - got).max(); mx = max(mx, dd); bad += int(dd > 0)
h = hashlib.sha256(); 
with open(fn, "rb") as fh:
    for ch in iter(lambda: fh.read(1 << 24), b""): h.update(ch)
m = {"file": os.path.basename(fn), "bytes": os.path.getsize(fn), "sha256": h.hexdigest(), "width": int(crop.shape[2]), "height": int(crop.shape[1]), "crs": "EPSG:32619", "cell_m": 30,
     "kept_cells": int(V.sum()), "area_ha": round(float(V.sum()) * 0.09, 1), "row_offset_r1": int(r1), "row_end_r2": int(r2), "col_offset_c1": int(c1),
     "mean_probability": {v: round(float(out[b][V].mean()) / 1e3, 5) for b, v in enumerate(DEFS)}, "mean_probability_10m": {v: round(float(S[b].sum() / C.sum()) / 1e4, 5) for b, v in enumerate(DEFS)},
     "share_extrapolated": round(float(S[6].sum() / C.sum()), 5), "check_cells": 400, "check_mismatch": bad, "check_max_abs_diff": float(mx)}
json.dump(m, open(f"{W}/out/d19_build_30m_DATA.json", "w"), indent=1); print(json.dumps(m), "DONE", flush=True)
