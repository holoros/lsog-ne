#!/usr/bin/env python3
# s_smoke_check_trans.py  Gating check for the single tile smoke test.
# Exits non-zero if anything is wrong, so the array's afterok dependency will not release.
# Confirms: three layers written, probability in range, extrapolation flag share plausible,
# and that the tile actually read AlphaEarth through /vsigs/ rather than failing quietly.
import os, sys, glob, json
import numpy as np, rasterio
E = os.environ; B = E["BUILD"]; TMP = E["TMP_TILES"]
err = f"{B}/logs/s3_errors.txt"
if os.path.exists(err) and os.path.getsize(err) > 0:
    sys.exit("SMOKE FAIL: s3 logged a tile error, most likely the GCS credential:\n"
             + open(err).read()[:800])
tags = sorted({os.path.basename(p)[5:-4] for p in glob.glob(f"{TMP}/prob_*.tif")})
if not tags: sys.exit("SMOKE FAIL: no probability tile written")
tag = tags[0]
need = [f"{TMP}/{k}_{tag}.tif" for k in ("prob", "sd", "env")] + [f"{TMP}/samp_{tag}.npz"]
miss = [p for p in need if not os.path.exists(p)]
if miss: sys.exit("SMOKE FAIL: missing " + ", ".join(miss))
out = {"tag": tag}
with rasterio.open(f"{TMP}/prob_{tag}.tif") as p:
    a = p.read(1); v = a != 65535
    out["predicted_cells"] = int(v.sum())
    if v.sum() == 0: sys.exit("SMOKE FAIL: tile predicted zero cells; frame or AlphaEarth read is wrong")
    out["prob_min"] = int(a[v].min()); out["prob_max"] = int(a[v].max())
    out["prob_mean_pct"] = float(a[v].mean()) / 100.0
    if out["prob_max"] > 10000: sys.exit(f"SMOKE FAIL: probability out of range, max {out['prob_max']}")
with rasterio.open(f"{TMP}/sd_{tag}.tif") as q:
    b = q.read(1); w = b != 65535
    out["sd_max"] = int(b[w].max()) if w.any() else None
    if out["sd_max"] is not None and out["sd_max"] > 10000: sys.exit("SMOKE FAIL: SD out of range")
with rasterio.open(f"{TMP}/env_{tag}.tif") as f:
    c = f.read(1); u = c != 255
    out["extrapolation_share"] = float((c[u] == 1).mean()) if u.any() else None
if out["extrapolation_share"] is not None and out["extrapolation_share"] > 0.50:
    sys.exit(f"SMOKE FAIL: extrapolation flag share {out['extrapolation_share']:.3f} exceeds 0.50; "
             "the envelope or the feature order is wrong")
json.dump(out, open(f"{B}/logs/smoke_check_{E['DATE_TAG']}.json", "w"), indent=2)
print("SMOKE PASS", json.dumps(out), flush=True)
