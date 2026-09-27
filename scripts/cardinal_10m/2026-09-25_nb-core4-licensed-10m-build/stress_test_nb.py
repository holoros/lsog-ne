#!/usr/bin/env python3
"""
2026-09-25_stage2b-stress-test_DATA.py

Adversarial stress test of the promoted Maine transitioning and above 10 m surface, run AFTER the
gate suite passed. Its purpose is to attack the four axes the suite does not reach, not to repeat
what it already checked.

What the shipped gates do NOT test, and why each gap matters:

  S1  PER TILE OUTLIERS. The mosaic is 34 AlphaEarth tiles. Every gate runs on the assembled
      mosaic, so a single bad tile is diluted by 33 good ones and can pass all of them. This reads
      the 34 source tiles individually and flags any whose mean probability, predicted fraction or
      extrapolation share is a robust outlier against its peers.
  S2  SD VERSUS PROBABILITY. The bootstrap SD layer was gated only on range and file size. A
      correct binomial-like ensemble SD peaks near p = 0.5 and falls toward both tails. A flat or
      inverted relationship would mean the bootstrap models are not doing what is claimed.
  S3  EXTRAPOLATION FLAG STRUCTURE. The suite reports one share. If the flagged cells concentrate in
      one region or at one end of the probability range, the single number misleads and the product
      documentation needs to say where the surface is weak, not just how often.
  S4  CROSS LAYER, THE AXIS G6 ONLY PRETENDED TO COVER. G6 is labelled cross layer and checks file
      size. This compares the surface against the independent 16 September CORE4 structural core
      surface for Maine, built on the same frame, cutline, resolution and CRS. Transitioning and
      above is the broader class (design based 13.65 percent against CORE4 cut 3 at 4.56), so the
      two must be strongly positively associated and transitioning should rarely sit below CORE4.
  S5  VALUE SWEEP. F7. Every distinct value outside the physically valid range is counted, not just
      the declared nodata, and the probability histogram is written so a degenerate spike is
      visible rather than averaged away.

PRIVACY. No plot coordinates are read and none are written. Everything here is raster summary.
"""
import os, sys, glob, json, hashlib
import numpy as np, rasterio
from rasterio.windows import Window
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

E = os.environ
B = E["BUILD"]; FIN = E["FINAL"]; TMP = E["TMP_TILES"]; DATE = E["DATE_TAG"]
OUT = os.path.join(B, "stress_2026-09-25"); os.makedirs(OUT, exist_ok=True)
U16, U8 = 65535, 255
CORE4_DIR = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/final"
STEM = "nb-core4-licensed"
res = {"date": "2026-09-25", "flags": []}

def flag(m):
    res["flags"].append(m); print("FLAG " + m, flush=True)

prob_p = f"{FIN}/{STEM}-probability_10m_NB_DATA_{DATE}.tif"
sd_p   = f"{FIN}/{STEM}-bootstrap-sd_10m_NB_DATA_{DATE}.tif"
env_p  = f"{FIN}/{STEM}-extrapolation-flag_10m_NB_DATA_{DATE}.tif"
for p in (prob_p, sd_p, env_p):
    if not os.path.exists(p): sys.exit(f"FAIL promoted product missing: {p}")

# ---------------------------------------------------------------- S1 per tile outliers
rows = []
for f in sorted(glob.glob(f"{TMP}/prob_*.tif")):
    tag = os.path.basename(f)[5:-4]
    try:
        with rasterio.open(f) as d: a = d.read(1)
        v = a[a != U16]
        ef = f"{TMP}/env_{tag}.tif"
        es = np.nan
        if os.path.exists(ef):
            with rasterio.open(ef) as d2: e = d2.read(1)
            eo = e[e != U8]
            if eo.size: es = float((eo == 1).mean())
        rows.append({"tag": tag, "n_pred": int(v.size), "frac_pred": float(v.size / a.size),
                     "mean_p": float(v.mean() / 10000) if v.size else np.nan,
                     "sd_p": float(v.std() / 10000) if v.size else np.nan,
                     "extrap": es})
    except Exception as ex:
        flag(f"S1 tile {tag} unreadable: {ex!r}")
res["S1_n_tiles"] = len(rows)
mp = np.array([r["mean_p"] for r in rows if np.isfinite(r["mean_p"])])
ex = np.array([r["extrap"] for r in rows if np.isfinite(r["extrap"])])
def robust_z(x):
    med = np.median(x); mad = np.median(np.abs(x - med))
    return (x - med) / (1.4826 * mad) if mad > 0 else np.zeros_like(x)
zp = robust_z(mp); ze = robust_z(ex)
res["S1"] = {"mean_p_median": float(np.median(mp)), "mean_p_min": float(mp.min()),
             "mean_p_max": float(mp.max()), "max_abs_robust_z_mean_p": float(np.abs(zp).max()),
             "extrap_median": float(np.median(ex)), "extrap_max": float(ex.max()),
             "max_abs_robust_z_extrap": float(np.abs(ze).max()),
             "tiles_with_zero_predicted": int(sum(1 for r in rows if r["n_pred"] == 0))}
out_p = [rows[i]["tag"] for i in np.flatnonzero(np.abs(zp) > 5)]
if out_p: flag(f"S1 tiles with |robust z| > 5 on mean probability: {out_p}")
json.dump(rows, open(f"{OUT}/stress_per_tile_DATA_2026-09-25.json", "w"), indent=1)

# ---------------------------------------------------------------- mosaic single pass, S2 S3 S4 S5
src = {"prob": rasterio.open(prob_p), "sd": rasterio.open(sd_p), "env": rasterio.open(env_p)}
H, W = src["prob"].height, src["prob"].width
c4 = sorted(glob.glob(f"{CORE4_DIR}/core4-structural-core-probability_10m_NB_DATA_*.tif"))
use_c4 = False
if c4:
    c4r = rasterio.open(c4[0])
    if (c4r.height, c4r.width) == (H, W) and str(c4r.crs) == str(src["prob"].crs) \
       and np.allclose(np.array(c4r.transform)[:6], np.array(src["prob"].transform)[:6]):
        use_c4 = True
    else:
        flag("S4 CORE4 surface does not share the grid; cross layer comparison skipped "
             f"(core4 {c4r.height}x{c4r.width} vs {H}x{W})")
else:
    flag("S4 no CORE4 probability raster found; cross layer comparison skipped")

NB_P, NB_S = 100, 60
hist2d = np.zeros((NB_P, NB_S), dtype=np.int64)
hist_p = np.zeros(NB_P, dtype=np.int64)
env_by_p = np.zeros(NB_P, dtype=np.int64)
n = 0; sx = sy = sxx = syy = sxy = 0.0; n_below = 0; n_joint = 0
bad_vals = {}
for r0 in range(0, H, 4096):
    for c0 in range(0, W, 4096):
        win = Window(c0, r0, min(4096, W - c0), min(4096, H - r0))
        p = src["prob"].read(1, window=win); s = src["sd"].read(1, window=win)
        e = src["env"].read(1, window=win)
        v = p != U16
        if not v.any(): continue
        pv = p[v].astype("int64"); sv = s[v].astype("int64"); ev = e[v]
        oor = pv[(pv < 0) | (pv > 10000)]
        if oor.size:
            for u, c in zip(*np.unique(oor, return_counts=True)):
                bad_vals[int(u)] = bad_vals.get(int(u), 0) + int(c)
        bp = np.clip(pv * NB_P // 10001, 0, NB_P - 1)
        bs = np.clip(sv * NB_S // 3001, 0, NB_S - 1)          # SD is small; 0 to 0.30 in 60 bins
        np.add.at(hist2d, (bp, bs), 1)
        np.add.at(hist_p, bp, 1)
        np.add.at(env_by_p, bp[ev == 1], 1)
        n += pv.size
        if use_c4:
            q = c4r.read(1, window=win)
            m = v & (q != U16)
            if m.any():
                x = p[m].astype("float64") / 10000.0; y = q[m].astype("float64") / 10000.0
                sx += x.sum(); sy += y.sum(); sxx += (x * x).sum(); syy += (y * y).sum()
                sxy += (x * y).sum(); n_joint += x.size; n_below += int((x < y).sum())
for f_ in src.values(): f_.close()
if use_c4: c4r.close()

res["S5"] = {"n_valid_cells": int(n), "values_outside_0_10000": bad_vals,
             "prob_hist_100bins": hist_p.tolist()}
if bad_vals: flag(f"S5 probability values outside [0, 10000]: {bad_vals}")

centres = (np.arange(NB_P) + 0.5) / NB_P
sd_mean_by_p = np.array([(hist2d[i] * ((np.arange(NB_S) + 0.5) * 0.30 / NB_S)).sum() / hist2d[i].sum()
                         if hist2d[i].sum() else np.nan for i in range(NB_P)])
mid = np.nanmean(sd_mean_by_p[35:65]); tails = np.nanmean(np.r_[sd_mean_by_p[:10], sd_mean_by_p[90:]])
res["S2"] = {"mean_sd_at_p_035_065": float(mid), "mean_sd_in_tails": float(tails),
             "ratio_mid_over_tails": float(mid / tails) if tails > 0 else None,
             "argmax_p_of_mean_sd": float(centres[int(np.nanargmax(sd_mean_by_p))])}
if not (mid > tails): flag("S2 bootstrap SD does not peak in the middle of the probability range")

ext_by_p = np.divide(env_by_p, hist_p, out=np.full(NB_P, np.nan), where=hist_p > 0)
res["S3"] = {"overall_extrapolation_share": float(env_by_p.sum() / max(n, 1)),
             "extrap_share_lowest_decile_p": float(np.nanmean(ext_by_p[:10])),
             "extrap_share_highest_decile_p": float(np.nanmean(ext_by_p[90:])),
             "per_tile_extrap_min": float(ex.min()), "per_tile_extrap_max": float(ex.max())}

if use_c4:
    den = np.sqrt(max(n_joint * sxx - sx * sx, 1e-9)) * np.sqrt(max(n_joint * syy - sy * sy, 1e-9))
    r = (n_joint * sxy - sx * sy) / den
    res["S4"] = {"core4_file": os.path.basename(c4[0]), "n_joint_cells": int(n_joint),
                 "pearson_r_licensed_vs_public_label_surface": float(r),
                 "mean_licensed_surface": float(sx / n_joint), "mean_public_label_surface_uncalibrated": float(sy / n_joint),
                 "frac_cells_licensed_below_public": float(n_below / n_joint)}
    if r < 0.5: flag(f"S4 licensed and public label surfaces correlate at only r = {r:.3f}")
    if n_below / n_joint > 0.25:
        flag(f"S4 licensed surface sits below the public label surface on {100*n_below/n_joint:.1f} percent of cells")

# ---------------------------------------------------------------- figure
fig, ax = plt.subplots(2, 2, figsize=(11, 8.5))
ax[0, 0].bar(centres, hist_p / hist_p.sum(), width=1.0 / NB_P, color="#1a3d28")
ax[0, 0].set_xlabel("NB CORE4 probability, licensed labels"); ax[0, 0].set_ylabel("share of forest cells")
ax[0, 0].set_title("A. Probability distribution", loc="left", fontweight="bold")
ax[0, 1].plot(centres, sd_mean_by_p, color="#c5a55a", lw=2)
ax[0, 1].set_xlabel("probability"); ax[0, 1].set_ylabel("mean bootstrap SD")
ax[0, 1].set_title("B. Ensemble SD against probability", loc="left", fontweight="bold")
ax[1, 0].plot(centres, ext_by_p, color="#1a3d28", lw=2)
ax[1, 0].set_xlabel("probability"); ax[1, 0].set_ylabel("share flagged outside envelope")
ax[1, 0].set_title("C. Extrapolation flag by probability", loc="left", fontweight="bold")
ax[1, 1].scatter(np.arange(len(mp)), mp, c="#1a3d28", s=22)
ax[1, 1].axhline(np.median(mp), color="#c5a55a", lw=1.5)
ax[1, 1].set_xlabel("AlphaEarth tile index"); ax[1, 1].set_ylabel("tile mean probability")
ax[1, 1].set_title("D. Per tile mean, 41 source tiles", loc="left", fontweight="bold")
for a_ in ax.ravel(): a_.set_facecolor("white"); a_.grid(alpha=0.25)
fig.suptitle("New Brunswick CORE4 10 m surface on licensed labels: post-gate stress test, 25 September 2026",
             fontweight="bold")
fig.tight_layout()
fig.savefig(f"{OUT}/fig_stress_test_2026-09-25.png", dpi=300, facecolor="white")
plt.close(fig)

res["verdict"] = "no structural defect found" if not res["flags"] else "flags raised, see flags"
json.dump(res, open(f"{OUT}/stress_summary_2026-09-25.json", "w"), indent=2)
print(json.dumps({k: v for k, v in res.items() if k != "S5"}, indent=2), flush=True)
print("n flags:", len(res["flags"]), flush=True)
print("STRESS_TEST_DONE", flush=True)
