#!/usr/bin/env python3
# s4_mosaic_gates_fig.py  Mosaic the ordinal tiles to EPSG:3979, clip to Maine, run gates, derive
# screening thresholds from OCC out of fold scores (Youden J), write a Type 1 / Type 2 class layer,
# and draw the map figure. Gates are hard exits: products stay *_PROVISIONAL until every gate passes.
import os, sys, glob, json, subprocess, numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from sklearn.metrics import roc_curve
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, BoundaryNorm

E = os.environ; W = E["W"]; OUT = f"{W}/out"; AGG = f"{OUT}/agg"; FIN = f"{OUT}/final"; os.makedirs(FIN, exist_ok=True)
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
log = open(f"{AGG}/s4_log.txt", "a")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()
def sh(c): L("$ " + c); subprocess.run(c, shell=True, check=True)
fails = []

# thresholds from OCC out of fold scores (screening only; they inherit OCC's sampling, not an area calibration)
O = pd.read_csv(f"{OUT}/occ_oof_scores_RESTRICTED.csv")
yb2 = O.occ_class.isin(["LS", "Old-growth"]).values; yb1 = (O.occ_class == "Old-growth").values
def youden(yb, s):
    f, t, th = roc_curve(yb, s); j = t - f; k = int(np.argmax(j)); return float(th[k]), float(t[k]), float(1 - f[k])
t2, se2, sp2 = youden(yb2, O.new_ge2.values)
sub = O[O.occ_class.isin(["LS", "Old-growth"])]
t1, se1, sp1 = youden((sub.occ_class == "Old-growth").values, sub.new_og.values)
TH = dict(type2_cut=t2, type2_sens=se2, type2_spec=sp2, type1_cut_within_type2=t1, type1_sens=se1, type1_spec_vs_LS=sp1)
json.dump(TH, open(f"{AGG}/screening_thresholds_DATA.json", "w"), indent=1); L("thresholds " + json.dumps(TH))

for mode, res in (("state30", 30), ("study", 10)):
    tiles = sorted(glob.glob(f"{OUT}/tiles_{mode}/ord_{mode}_*.tif"))
    if not tiles: L(f"{mode}: no tiles"); continue
    cov = pd.concat([pd.read_csv(f) for f in glob.glob(f"{OUT}/tiles_{mode}/cov_*.csv")])
    share = cov.predicted.sum() / cov.forest_cells.sum()
    L(f"{mode}: {len(tiles)} tiles, predicted share of frame forest {share:.4f}")
    if share < 0.98: fails.append(f"{mode} G1 coverage {share:.4f} < 0.98 (AE nodata inside frame)")
    vrt = f"{OUT}/_{mode}.vrt"; open(f"{OUT}/_{mode}_list.txt", "w").write("\n".join(tiles))
    prov = f"{FIN}/occ-ordinal-lsog_{res}m_{mode}_ME_DATA_2026-10-06_PROVISIONAL.tif"
    sh(f"gdalwarp -overwrite -t_srs EPSG:3979 -tr {res} {res} -tap -r near -srcnodata 65535 -dstnodata 65535 "
       f"-cutline {CUT} -crop_to_cutline -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS "
       f"--optfile {OUT}/_{mode}_list.txt {prov}")
    with rasterio.open(prov) as ds:
        dec = max(1, int(round(max(ds.width, ds.height) / 3000)))
        a = ds.read(out_shape=(4, ds.height // dec, ds.width // dec), resampling=Resampling.nearest).astype("float32")
        a[a == 65535] = np.nan; p = a[:3] / 10000.0
        v = np.isfinite(p[0])
        rng_ok = np.nanmax(p) <= 1.0 and np.nanmin(p) >= 0.0
        mono = bool(np.all(p[2][v] <= p[1][v] + 1e-9) and np.all(p[1][v] <= p[0][v] + 1e-9))
        L(f"{mode}: range ok {rng_ok}, monotone {mono}, mean P(>=trans) {np.nanmean(p[0]):.4f}, "
          f"mean P(>=LS) {np.nanmean(p[1]):.4f}, mean P(OG) {np.nanmean(p[2]):.5f}, extrapolation share {np.nanmean(a[3]):.4f}")
        if not rng_ok: fails.append(f"{mode} G3 value range")
        if not mono: fails.append(f"{mode} G3b ordinal monotonicity")
        if mode == "state30":
            m1 = float(np.nanmean(p[0])) * 100
            # G5 absurdity bound: FIA design based transitioning and above is 14.66 [13.40, 15.91] (Section 4.4).
            # OCC oversamples the upper classes, so a shift upward is expected; outside 5 to 40 percent is absurd.
            L(f"G5 state mean P(>=trans) = {m1:.2f} percent vs FIA 14.66 [13.40, 15.91]")
            if not (5 <= m1 <= 40): fails.append(f"G5 magnitude {m1:.2f} outside [5, 40]")
            T2 = (p[1] >= t2); T1 = T2 & (p[2] >= t1)
            L(f"screening class shares of forest: Type 2 pool {np.nanmean(np.where(v, T2, np.nan))*100:.2f} percent, "
              f"Type 1 {np.nanmean(np.where(v, T1, np.nan))*100:.3f} percent (OCC Youden cuts, not area calibrated)")
            STATE = (p, v, T1, T2, ds.bounds)
        else:
            STUDY = (p, v, ds.bounds)
if fails:
    L("GATES FAILED: " + " | ".join(fails)); sys.exit(2)
for f in glob.glob(f"{FIN}/*_PROVISIONAL.tif"):
    os.replace(f, f.replace("_PROVISIONAL", "")); L("promoted " + os.path.basename(f))

# figure, statewide 30 m
p, v, T1, T2, b = STATE
ext = [b.left, b.right, b.bottom, b.top]
fig, ax = plt.subplots(1, 4, figsize=(13, 5.2))
for k, (arr, lab) in enumerate([(p[0], "P(transitioning or above)"), (p[1], "P(LS or OG), Type 2 pool"), (p[2], "P(OG), Type 1")]):
    vmax = 1.0 if k < 2 else max(0.05, float(np.nanpercentile(p[2], 99.9)))
    im = ax[k].imshow(np.where(v, arr, np.nan), extent=ext, cmap="YlGnBu", vmin=0, vmax=vmax, interpolation="nearest")
    ax[k].set_title(lab, fontsize=9); ax[k].set_axis_off()
    fig.colorbar(im, ax=ax[k], fraction=0.035, pad=0.01)
cls = np.where(v, 0, np.nan); cls = np.where(T2 & v, 1, cls); cls = np.where(T1 & v, 2, cls)
cm = ListedColormap(["#e6e2d3", "#6aa36f", "#1f4e2c"])
ax[3].imshow(cls, extent=ext, cmap=cm, norm=BoundaryNorm([-0.5, 0.5, 1.5, 2.5], 3), interpolation="nearest")
ax[3].set_title("Screening classes (OCC Youden cuts)", fontsize=9); ax[3].set_axis_off()
ax[3].legend(handles=[plt.Rectangle((0, 0), 1, 1, color=c) for c in cm.colors], labels=["Other forest", "Type 2 (LS)", "Type 1 (OG)"],
             loc="lower right", fontsize=7, frameon=False)
for k, t in enumerate("abcd"): ax[k].text(0.02, 0.98, t, transform=ax[k].transAxes, weight="bold", va="top")
fig.tight_layout(); fig.savefig(f"{AGG}/fig_occ_ordinal_state30.png", dpi=300); plt.close(fig)

if "STUDY" in dir():
    p, v, b = STUDY; ext = [b.left, b.right, b.bottom, b.top]
    fig, ax = plt.subplots(1, 2, figsize=(10, 5.5))
    for k, (arr, lab) in enumerate([(p[1], "P(LS or OG), Type 2 pool, 10 m"), (p[2], "P(OG), Type 1, 10 m")]):
        vmax = 1.0 if k == 0 else max(0.05, float(np.nanpercentile(p[2], 99.9)))
        im = ax[k].imshow(np.where(v, arr, np.nan), extent=ext, cmap="YlGnBu", vmin=0, vmax=vmax, interpolation="nearest")
        ax[k].set_title(lab, fontsize=9); ax[k].set_axis_off(); fig.colorbar(im, ax=ax[k], fraction=0.035, pad=0.01)
        ax[k].text(0.02, 0.98, "ab"[k], transform=ax[k].transAxes, weight="bold", va="top")
    fig.tight_layout(); fig.savefig(f"{AGG}/fig_occ_ordinal_study10.png", dpi=300); plt.close(fig)
L("S4 DONE")
