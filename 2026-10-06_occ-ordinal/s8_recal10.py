#!/usr/bin/env python3
# s8_recal10.py  Apply the v3 prior shift recalibration (same formula and targets as f4/f5 on firebreather) to the
# statewide 10 m v3 mosaic, window by window, then gate. Gates: value range, ordering, frame area within 5 percent
# of 7.41 Mha, and the recalibrated statewide mean P(>= transitioning) inside the FIA interval [13.40, 15.91].
# Output stays _PROVISIONAL unless every gate passes.
import os, json, numpy as np, rasterio
from rasterio.windows import Window
E = os.environ; OUT = E["OUT"]; FIN = f"{OUT}/final"
meta = json.load(open(f"{OUT}/v3_meta.json")); pi_s = np.array(meta["pos"]) / meta["n"]
pi_t = np.array([0.1466, 50 / 3062, 10 / 3062]); lor = np.log(pi_t / (1 - pi_t)) - np.log(pi_s / (1 - pi_s))
print("log odds shifts", lor.round(6), flush=True)
src_p = f"{FIN}/occ-ordinal-v3-lsog_10m_state10_ME_DATA_2026-10-06_PROVISIONAL.tif"
dst_p = f"{FIN}/occ-ordinal-v3-lsog-recalibrated_10m_ME_DATA_2026-10-06_PROVISIONAL.tif"
U = 65535; tot = np.zeros(3); n = 0; bad_rng = bad_ord = 0
with rasterio.open(src_p) as s:
    prof = s.profile.copy(); prof.update(count=3, compress="deflate", tiled=True, blockxsize=512, blockysize=512, BIGTIFF="YES")
    with rasterio.open(dst_p, "w", **prof) as d:
        for _, win in s.block_windows(1):
            a = s.read([1, 2, 3], window=win).astype("float64"); v = a[0] != U
            out = np.full(a.shape, U, "uint16")
            if v.any():
                p = a[:, v] / 10000.0
                bad_rng += int(((p < 0) | (p > 1)).sum())
                bad_ord += int(((p[2] > p[1] + 1e-6) | (p[1] > p[0] + 1e-6)).sum())
                pc = np.clip(p, 1e-6, 1 - 1e-6); q = 1 / (1 + np.exp(-(np.log(pc / (1 - pc)) + lor[:, None])))
                q[1] = np.minimum(q[1], q[0]); q[2] = np.minimum(q[2], q[1])
                tot += q.sum(1); n += q.shape[1]
                out[:, v] = np.rint(q * 10000).astype("uint16")
            d.write(out, window=win)
m = 100 * tot / n; ha = n * 100 / 1.033 / 1e4
print(f"cells {n}; forest {ha:.0f} ha; recalibrated means >=trans {m[0]:.2f}%, >=LS {m[1]:.2f}%, OG {m[2]:.3f}%; bad range {bad_rng}, bad order {bad_ord}", flush=True)
fails = []
if bad_rng: fails.append("G3 range")
if bad_ord: fails.append("G3b order")
if abs(ha / 7.41e6 - 1) > 0.05: fails.append("G2 frame area")
if not (13.40 <= m[0] <= 15.91): fails.append("G6 FIA interval")
json.dump({"means_pct": m.tolist(), "forest_ha": ha, "expected_ha": (m / 100 * ha).tolist(), "lor": lor.tolist(), "fails": fails},
          open(f"{OUT}/agg/recal10_v3_DATA.json", "w"), indent=1)
if fails: print("GATES FAILED", fails); raise SystemExit(2)
for f in (src_p, dst_p): os.replace(f, f.replace("_PROVISIONAL", ""))
print("S8 DONE, promoted", flush=True)
