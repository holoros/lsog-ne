#!/usr/bin/env python3
# s5_share_bootstrap_interval.py  (added 2026-09-25)
# s4 reports each jurisdiction's model-based share as a point with a mean per-pixel SD, which is not an
# interval. This scores a random sample of forest cells (the samp_*.npz files s3 writes, which already
# hold the final and all N_BOOT block-bootstrap model probabilities) and reports, per jurisdiction, the
# sample share under the final model and the 2.5 and 97.5 percentiles of the sample share across the
# bootstrap models. Cells are kept only where the final masked mosaic from s4 holds a valid value, so
# the sample shares the s4 population's boundary and forest frame. About TARGET cells per jurisdiction.
# With N_BOOT = 20 the percentile limits sit near the extremes of 20 values, and the interval carries
# model-fitting (block resampling) uncertainty only, not residual or design variance. Both are stated.
import os, glob, json, sys
import numpy as np, rasterio
from rasterio.warp import transform as wtrans
E = os.environ; B = E["BUILD"]; TMP = E["TMP_TILES"]; FIN = E["FINAL"]; DATE = "2026-09-27"
TARGET = int(E.get("S5_TARGET", "1000000")); rng = np.random.default_rng(int(E["SEED"]) + 5)
files = sorted(glob.glob(f"{TMP}/samp_*.npz"))
tiles = sorted(glob.glob(f"{TMP}/prob_*.tif"))
if len(files) != len(tiles): sys.exit(f"FAIL {len(files)} sample files for {len(tiles)} tiles")
by_crs = {}
for f in files:
    z = np.load(f, allow_pickle=False); s = z["s"]
    if len(s): by_crs.setdefault(str(z["crs"]), []).append(s)
res = {}
for J in ("NB",):
    fin = f"{FIN}/nb-trans-licensed-probability_10m_{J}_DATA_{DATE}.tif"
    fin = fin if os.path.exists(fin) else fin + ".part"
    keep = []
    with rasterio.open(fin) as r:
        for crs, parts in by_crs.items():
            S = np.vstack(parts)
            x, y = wtrans(crs, r.crs, S[:, 0].tolist(), S[:, 1].tolist())
            vals = np.array([v[0] for v in r.sample(zip(x, y))])
            ok = vals != 65535
            keep.append(S[ok, 2:])
    K = np.vstack(keep)
    n_all = len(K)
    if n_all > TARGET: K = K[rng.choice(n_all, TARGET, replace=False)]
    final_share = 100 * K[:, 0].mean()
    boot = 100 * K[:, 1:].mean(0)
    res[J] = {"n_cells_available": int(n_all), "n_cells_scored": int(len(K)),
              "sample_share_final_pct": float(final_share),
              "boot_share_pct": boot.tolist(), "n_boot": int(len(boot)),
              "pct_2p5": float(np.percentile(boot, 2.5)), "pct_97p5": float(np.percentile(boot, 97.5)),
              "boot_mean_pct": float(boot.mean()), "boot_sd_pct": float(boot.std(ddof=1)),
              "sampling_se_final_pct": float(100 * K[:, 0].std(ddof=1) / np.sqrt(len(K))),
              "source_raster": os.path.basename(fin)}
    print(J, {k: v for k, v in res[J].items() if k != "boot_share_pct"}, flush=True)
res["note"] = ("percentile interval across block-bootstrap refits; model-fitting uncertainty only; "
               "sample drawn from s3 seeded Bernoulli cell samples within the s4 masked mosaic")
json.dump(res, open(f"{FIN}/nb-trans-licensed-10m-share-bootstrap-interval_DATA_{DATE}.json", "w"), indent=2)
print("S5_DONE")
