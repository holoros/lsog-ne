#!/usr/bin/env python3
"""
2026-09-25_g7a-registration-diagnostic_DATA.py

Why G7a failed on the Maine transitioning 10 m mosaic, and whether the failure is the surface or
the gate.

G7a compared the mosaic probability at each training plot against the model's own prediction from
that plot's stored AlphaEarth row, and required Pearson r >= 0.95 and median absolute difference
<= 0.02. It returned r = 0.9099 and median |diff| = 0.0290. Those two thresholds were written by
hand three days ago with no external provenance, which is firewall mode F4, a gate anchored to an
unverified internal number.

The physical reason a perfect match is impossible: s3 predicts in each AlphaEarth tile's native UTM
grid, and s4 gdalwarps to EPSG:3979 at 10 m with nearest neighbour and -tap alignment. Two 10 m
grids in different projections do not share cell centres, so a plot coordinate lands in a cell
offset by up to about half a cell diagonal, roughly 7 m, from the cell holding its own AlphaEarth
pixel. At 10 m in heterogeneous forest the neighbour's probability differs.

This script separates the two explanations with a statistic that registration jitter survives and
scrambling does not, and it gets its threshold from a permutation null rather than from judgement.

  OBSERVED  for each plot, read a 5x5 window of mosaic probability centred on the plot's cell.
            Record the centre value, the window range, the window SD, the model's direct
            prediction, and the best matching cell in the window.
  NULL      shuffle the plot-to-location assignment B times, breaking the spatial link while
            keeping both marginal distributions exactly. Recompute the same statistics.

If the surface is correctly registered, the direct prediction falls inside the local window range
far more often than the null allows, and the best matching cell correlates far more tightly than
the centre cell. If the surface is scrambled, observed and null are indistinguishable.

PRIVACY. FIA true coordinates are read here and stay on Cardinal. Nothing written contains a
coordinate: the outputs are summary statistics, a null distribution and per plot rows keyed only by
a row index with no location.
"""
import os, sys, json, pickle, hashlib
import numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
from pyproj import Transformer

E = os.environ
B = E["BUILD"]; FIN = E["FINAL"]; CRS = E["DST_CRS"]; DATE = E["DATE_TAG"]
OUTD = os.path.join(B, "g7_diag_2026-09-25"); os.makedirs(OUTD, exist_ok=True)
U16 = 65535
HALF = 2            # 5x5 window
NPERM = 200
SEED = 20260925
rng = np.random.default_rng(SEED)

def md5(p):
    h = hashlib.md5()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()

def fail(m):
    print("FAIL " + m, flush=True)
    with open(os.path.join(OUTD, "error_log.txt"), "a") as f: f.write(m + "\n")
    sys.exit(2)

# ---- plot linkage, identical to s4 ------------------------------------------------------------
tt = pd.read_csv(E["TRAIN_TABLE"], dtype={"plot_id": str})
jj = pd.read_csv(E["PLOTID_PLTCN"], dtype=str)                 # integer64 key as character
xy = pd.read_csv(E["TRUE_XY"], dtype={"plot_id": str})
d = (tt.merge(jj[["plot_id", "PLT_CN"]], on="plot_id", how="left")
       .merge(xy[["plot_id", "lon", "lat"]].rename(columns={"plot_id": "PLT_CN"}),
              on="PLT_CN", how="left"))
d = d[d["lon"].notna() & d["lat"].notna()].reset_index(drop=True)
tf = Transformer.from_crs("EPSG:4326", CRS, always_xy=True)
gx, gy = tf.transform(d["lon"].to_numpy(), d["lat"].to_numpy())

prob_path = os.path.join(FIN, f"me-transitioning-and-above-probability_10m_ME_DATA_{DATE}.tif.part")
if not os.path.exists(prob_path): fail(f"probability raster not found at {prob_path}")
print("probability raster md5", md5(prob_path), flush=True)

cent = np.full(len(d), np.nan)
wmin = np.full(len(d), np.nan); wmax = np.full(len(d), np.nan)
wsd  = np.full(len(d), np.nan); wn = np.zeros(len(d), dtype=int)
wins = []
with rasterio.open(prob_path) as p:
    inv = ~p.transform
    for i, (x, y) in enumerate(zip(gx, gy)):
        c, r = inv * (x, y)
        c = int(np.floor(c)); r = int(np.floor(r))
        c0 = c - HALF; r0 = r - HALF
        if c0 < 0 or r0 < 0 or c0 + 2 * HALF + 1 > p.width or r0 + 2 * HALF + 1 > p.height:
            wins.append(np.array([])); continue
        a = p.read(1, window=Window(c0, r0, 2 * HALF + 1, 2 * HALF + 1)).astype("float64")
        v = a[a != U16] / 10000.0
        wins.append(v)
        cv = a[HALF, HALF]
        if cv != U16: cent[i] = cv / 10000.0
        if v.size:
            wmin[i] = v.min(); wmax[i] = v.max(); wsd[i] = v.std(); wn[i] = v.size
del gx, gy                                                      # coordinates dropped immediately
d = d.drop(columns=["lon", "lat"])

# ---- direct model prediction ------------------------------------------------------------------
aecols = [f"AE_{i:02d}" for i in range(64)]
mdl = pickle.load(open(E["MODEL_FINAL"], "rb"))
direct = mdl.predict_proba(d[aecols].to_numpy())[:, 1]

ok = np.isfinite(cent) & (wn > 0)
print(f"plots with coords {len(d)}, with a centre value and a window {int(ok.sum())}", flush=True)
if ok.sum() < 1000: fail(f"only {int(ok.sum())} usable plots, expected thousands")

dk = direct[ok]; ck = cent[ok]
lo = wmin[ok]; hi = wmax[ok]; sd = wsd[ok]
W = [wins[i] for i in np.flatnonzero(ok)]

def best_abs(vals, t):                       # closest cell in the window to the direct prediction
    return np.min(np.abs(vals - t))
def best_val(vals, t):
    return vals[int(np.argmin(np.abs(vals - t)))]

in_range = (dk >= lo) & (dk <= hi)
bestd = np.array([best_abs(W[j], dk[j]) for j in range(len(dk))])
bestv = np.array([best_val(W[j], dk[j]) for j in range(len(dk))])

obs = {
    "n": int(ok.sum()),
    "r_centre_vs_direct": float(np.corrcoef(ck, dk)[0, 1]),
    "median_abs_diff_centre": float(np.median(np.abs(ck - dk))),
    "r_bestcell_vs_direct": float(np.corrcoef(bestv, dk)[0, 1]),
    "median_abs_diff_bestcell": float(np.median(bestd)),
    "frac_direct_in_window_range": float(in_range.mean()),
    "median_window_sd": float(np.median(sd)),
    "median_window_range": float(np.median(hi - lo)),
    "window_cells": int(2 * HALF + 1) ** 2,
}

# ---- permutation null: break the plot-to-location link, keep both marginals --------------------
perm = {"frac_in_range": [], "r_centre": [], "median_abs_diff_centre": [], "median_abs_diff_bestcell": []}
idx = np.arange(len(dk))
for b in range(NPERM):
    s = rng.permutation(idx)
    ds = dk[s]
    perm["frac_in_range"].append(float(((ds >= lo) & (ds <= hi)).mean()))
    perm["r_centre"].append(float(np.corrcoef(ck, ds)[0, 1]))
    perm["median_abs_diff_centre"].append(float(np.median(np.abs(ck - ds))))
    perm["median_abs_diff_bestcell"].append(
        float(np.median([best_abs(W[j], ds[j]) for j in range(len(ds))])))

def q(v): 
    a = np.array(v); return {"mean": float(a.mean()), "p02_5": float(np.percentile(a, 2.5)),
                             "p97_5": float(np.percentile(a, 97.5)), "max": float(a.max()),
                             "min": float(a.min())}
nullsum = {k: q(v) for k, v in perm.items()}

z = ((obs["frac_direct_in_window_range"] - nullsum["frac_in_range"]["mean"])
     / max(np.std(perm["frac_in_range"]), 1e-12))
verdict = ("registration jitter, surface correctly assembled"
           if obs["frac_direct_in_window_range"] > nullsum["frac_in_range"]["max"]
           and obs["r_bestcell_vs_direct"] > obs["r_centre_vs_direct"]
           else "NOT explained by registration; investigate assembly")

out = {"date": "2026-09-25", "seed": SEED, "n_permutations": NPERM,
       "observed": obs, "null": nullsum,
       "z_frac_in_range_vs_null": float(z),
       "verdict": verdict,
       "g7a_thresholds_as_shipped": {"min_r": float(E["G7A_MIN_R"]), "max_mad": float(E["G7A_MAX_MAD"])},
       "note": ("the shipped G7a thresholds were written by hand with no external provenance. "
                "This run measures what the reprojection physically permits.")}
json.dump(out, open(os.path.join(OUTD, "g7a_registration_diagnostic_2026-09-25.json"), "w"), indent=2)
pd.DataFrame({"row": np.flatnonzero(ok), "direct": dk, "centre": ck, "best_cell": bestv,
              "window_min": lo, "window_max": hi, "window_sd": sd,
              "direct_in_range": in_range}).to_csv(
    os.path.join(OUTD, f"g7a_per_plot_DATA_2026-09-25.csv"), index=False)
pd.DataFrame(perm).to_csv(os.path.join(OUTD, "g7a_permutation_null_DATA_2026-09-25.csv"), index=False)
print(json.dumps(out, indent=2), flush=True)
print("G7A_DIAGNOSTIC_DONE", flush=True)
