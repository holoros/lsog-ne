#!/usr/bin/env python3
"""d5_me_aggregate.py (November 13, 2026). Maine definition-to-map outcomes of the PREREG, from the cross-predicted
tiles of d4. Cells are forest-frame cells inside the Maine cutline. Pass A: histogram of probability per definition.
Thresholds: for each definition the top share of cells equal to its design-based rate (rank rule), found on the
pooled histogram. Pass B: flags, agreement count (0 to 6), pairwise overlap, and a table by 20 km block (EPSG:3979)
for the block bootstrap. Writes an agreement-count raster per tile to scratch and aggregates only to out/."""
import os, sys, json, glob, pickle, numpy as np, pandas as pd, rasterio
from multiprocessing import Pool
from rasterio.features import geometry_mask
from shapely.geometry import shape
from shapely.ops import transform as shp_transform, unary_union
from pyproj import Transformer
from scipy.stats import spearmanr
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = os.environ["DS_SCR"]; TT = f"{SCR}/me_tiles"; AG = f"{SCR}/me_agree"; os.makedirs(AG, exist_ok=True)
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
B = pickle.load(open(f"{SCR}/me_defsens_xp_bundle.pkl", "rb")); DEFS = B["defs"]; ND = len(DEFS); BS = B["BS"]; del B
DESIGN = {"V3": 22.69, "V1": 15.92, "V2": 12.46, "V4": 9.50, "V9_c3": 5.10, "V7": 2.26}
DLO = {"V3": 21.20, "V1": 14.61, "V2": 11.28, "V4": 8.45, "V9_c3": 4.32, "V7": 1.72}; DHI = {"V3": 24.18, "V1": 17.23, "V2": 13.65, "V4": 10.54, "V9_c3": 5.89, "V7": 2.80}
FOREST_MHA = 7.06; U = 65535; NB_ = 2000; SEED = 20260917
gj = json.load(open(CUT)); geom3979 = unary_union([shape(f["geometry"]) for f in gj["features"]])
tiles = sorted(glob.glob(f"{TT}/defsens_xp_*.tif")); assert len(tiles) == 34
def load(path):
    with rasterio.open(path) as ds:
        g = shp_transform(Transformer.from_crs(3979, ds.crs, always_xy=True).transform, geom3979)
        inside = geometry_mask([g], out_shape=(ds.height, ds.width), transform=ds.transform, invert=True)
        a = ds.read(); prof = ds.profile; tr = ds.transform; crs = ds.crs
    ok = inside & (a[0] != U)
    return a, ok, prof, tr, crs
def pass_a(path):
    a, ok, *_ = load(path); h = np.zeros((ND, 10001), np.int64)
    for j in range(ND): h[j] = np.bincount(a[j][ok].astype(np.int64), minlength=10001)[:10001]
    return h, int(ok.sum()), int(a[ND][ok].sum())
def pass_b(args):
    path, thr = args; a, ok, prof, tr, crs = load(path); tag = os.path.basename(path)[11:15]
    rr, cc = np.nonzero(ok); n = len(rr)
    if n == 0: return None
    P = a[:ND, rr, cc].astype(np.int64); F = P >= np.asarray(thr)[:, None]; cnt = F.sum(0)
    xs = tr.c + (cc + 0.5) * tr.a + (rr + 0.5) * tr.b; ys = tr.f + (cc + 0.5) * tr.d + (rr + 0.5) * tr.e
    fx, fy = Transformer.from_crs(crs, 3979, always_xy=True).transform(xs, ys)
    blk = np.floor(fx / BS).astype(np.int64) * 100000 + np.floor(fy / BS).astype(np.int64)
    u, inv = np.unique(blk, return_inverse=True); nb = len(u)
    T = {"block": u, "n": np.bincount(inv, minlength=nb)}
    for j, v in enumerate(DEFS):
        T[f"p_{v}"] = np.bincount(inv, P[j], minlength=nb); T[f"f_{v}"] = np.bincount(inv, F[j], minlength=nb)
    for k in range(ND + 1): T[f"c{k}"] = np.bincount(inv, cnt == k, minlength=nb)
    for i in range(ND):
        for j in range(i + 1, ND): T[f"i_{DEFS[i]}__{DEFS[j]}"] = np.bincount(inv, F[i] & F[j], minlength=nb)
    out = np.full(ok.shape, 255, np.uint8); out[rr, cc] = cnt.astype(np.uint8)
    prof.update(count=1, dtype="uint8", nodata=255)
    with rasterio.open(f"{AG}/agree_{tag}.tif", "w", **prof) as d: d.write(out, 1)
    return pd.DataFrame(T)
if __name__ == "__main__":
    with Pool(12) as p: A = p.map(pass_a, tiles)
    H = sum(x[0] for x in A); N = sum(x[1] for x in A); NX = sum(x[2] for x in A)
    thr, ach = [], {}
    for j, v in enumerate(DEFS):
        top = np.cumsum(H[j][::-1])[::-1] / N                      # share of cells with value >= t
        t = int(np.argmin(np.abs(top - DESIGN[v] / 100.0))); thr.append(t); ach[v] = round(100 * float(top[t]), 4)
    with Pool(12) as p: parts = [x for x in p.map(pass_b, [(t, thr) for t in tiles]) if x is not None]
    Bk = pd.concat(parts).groupby("block", as_index=False).sum().sort_values("block").reset_index(drop=True)
    Bk.to_pickle(f"{SCR}/me_block_table.pkl")
    n = Bk.n.to_numpy(float); tot = n.sum(); assert int(tot) == N
    def stats(w):
        d = (n * w).sum(); r = {"any": 1 - (Bk.c0 * w).sum() / d, "half": sum((Bk[f"c{k}"] * w).sum() for k in range(3, ND + 1)) / d, "all": (Bk[f"c{ND}"] * w).sum() / d}
        m = np.array([(Bk[f"p_{v}"] * w).sum() / d / 100.0 for v in DEFS]); r["mapped"] = m
        r["slope"] = float(np.polyfit([DESIGN[v] for v in DEFS], m, 1)[0])
        r["union_over_max"] = r["any"] / max((Bk[f"f_{v}"] * w).sum() / d for v in DEFS); return r
    s0 = stats(np.ones(len(Bk))); rng = np.random.default_rng(SEED); bs = []
    for _ in range(NB_):
        w = np.bincount(rng.integers(0, len(Bk), len(Bk)), minlength=len(Bk)).astype(float); bs.append(stats(w))
    ci = lambda f: [round(float(x), 4) for x in np.percentile([f(b) for b in bs], [2.5, 97.5])]
    out = {"jurisdiction": "Maine", "defs": DEFS, "cells_in_maine_forest_frame": int(N), "frame_area_Mha_at_100m2": round(N / 1e8, 4), "extrapolation_flag_share_pct": round(100 * NX / N, 3),
           "n_blocks": int(len(Bk)), "bootstrap": {"unit": "20 km block", "reps": NB_, "seed": SEED},
           "threshold_x1e4": dict(zip(DEFS, thr)), "flagged_share_pct_achieved": ach, "design_pct": DESIGN,
           "mapped_mean_prob_pct": {v: {"est": round(float(s0["mapped"][j]), 3), "ci": ci(lambda b, j=j: b["mapped"][j])} for j, v in enumerate(DEFS)},
           "extent_tracking": {"slope_mapped_on_design": round(s0["slope"], 4), "ci": ci(lambda b: b["slope"]),
                               "spearman": round(float(spearmanr([DESIGN[v] for v in DEFS], s0["mapped"])[0]), 4),
                               "mapped_inside_design_interval": {v: bool(DLO[v] <= s0["mapped"][j] <= DHI[v]) for j, v in enumerate(DEFS)}},
           "agreement_share_pct": {k: {"est": round(100 * s0[k], 3), "ci": [round(100 * x, 3) for x in ci(lambda b, k=k: b[k])],
                                        "Mha_at_7.06": round(FOREST_MHA * s0[k], 3)} for k in ("any", "half", "all")},
           "agreement_count_share_pct": {str(k): round(100 * float(Bk[f"c{k}"].sum() / tot), 3) for k in range(ND + 1)},
           "union_over_largest_single": {"est": round(s0["union_over_max"], 4), "ci": ci(lambda b: b["union_over_max"])},
           "all_over_smallest_single": round(float(Bk[f"c{ND}"].sum() / min(Bk[f"f_{v}"].sum() for v in DEFS)), 4), "jaccard": {}, "overlap_of_smaller": {}, "block_share_spearman": {}}
    big = Bk.n >= 10000
    for i in range(ND):
        for j in range(i + 1, ND):
            a, b = DEFS[i], DEFS[j]; I = float(Bk[f"i_{a}__{b}"].sum()); fa, fb = float(Bk[f"f_{a}"].sum()), float(Bk[f"f_{b}"].sum())
            out["jaccard"][f"{a}|{b}"] = round(I / (fa + fb - I), 4); out["overlap_of_smaller"][f"{a}|{b}"] = round(I / min(fa, fb), 4)
            out["block_share_spearman"][f"{a}|{b}"] = round(float(spearmanr(Bk[f"f_{a}"][big] / Bk.n[big], Bk[f"f_{b}"][big] / Bk.n[big])[0]), 4)
    out["blocks_in_spearman"] = int(big.sum())
    json.dump(out, open(f"{W}/out/d5_me_aggregate_DATA.json", "w"), indent=1); print(json.dumps(out)[:1500]); print("DONE")
