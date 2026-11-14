#!/usr/bin/env python3
"""d17_ring_profile.py (November 14, 2026). Release test, part 2, asked for by Aaron after d14: the same ring contrast
on the earlier cross-predicted rebuilt Maine layers (refit of November 6, 10 m, bands 1 and 2), and, for both
products, the contrast as a function of ring distance (10 to 15 m, 35 to 45 m, 95 to 105 m, 295 to 305 m).
A value memorised at the plot cell falls off within a cell or two and is diluted by distance. Real spatial structure
(a plot that qualifies sits in a patch that scores higher than its surroundings) grows with distance.
Positive plots: V1 (six-axis score of 4 or more) for band 1 of the rebuilt layers, V7 (6 or more) for band 2, and each
definition's own positives for the definition layers. FIA plots only. True coordinates in memory; aggregates only."""
import os, json, math, importlib.util, numpy as np, rasterio
from rasterio.windows import Window
from multiprocessing import Pool
from pyproj import Transformer
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity")
spec = importlib.util.spec_from_file_location("rel", f"{W}/scripts/d14_me_release_test.py"); Rm = importlib.util.module_from_spec(spec); spec.loader.exec_module(Rm)
P, DEFS, U, tc, tr = Rm.P, Rm.DEFS, Rm.U, Rm.tc, Rm.tr; H = 31; N = 2 * H + 1; B = 2000
REB = "/fs/scratch/PUOM0008/crsfaaron/retrain_2026-11-06/finalxp/retrain-v5xp-corrlab-lsog_10m_ME_DATA_2026-11-06.tif"
with rasterio.open(REB) as q: INV = ~q.transform; RW, RH = q.width, q.height; T = Transformer.from_crs(4326, q.crs, always_xy=True)
rc, rr = INV * np.array(T.transform(P["TRUE.LON"].values, P["TRUE.LAT"].values)); _R = [None]
yy, xx = np.mgrid[-H:H + 1, -H:H + 1]; D = np.hypot(yy, xx) * 10; RINGS = {"10-15m": (D >= 10) & (D <= 15), "35-45m": (D >= 35) & (D <= 45), "95-105m": (D >= 95) & (D <= 105), "295-305m": (D >= 295) & (D <= 305)}
def prof(A, bad):
    out = []
    for b in range(A.shape[0]):
        for nm, m in RINGS.items():
            ok = m & ~bad[b]; out.append(np.nan if bad[b, H, H] or ok.sum() < 0.6 * m.sum() else float(A[b, H, H] - A[b][ok].mean()))
    return out
def reb(c, r):
    if _R[0] is None: _R[0] = rasterio.open(REB)
    if c - H < 0 or r - H < 0 or c + H >= RW or r + H >= RH: return [np.nan] * 8
    a = _R[0].read([1, 2], window=Window(c - H, r - H, N, N)); return prof(a.astype(float), a == U)
def dfl(c, r):
    a = Rm.read(c - H, r - H, N); return prof(a.astype(float), a == U)
def one(i):
    rng = np.random.default_rng([20261115, int(i)]); th = rng.uniform(0, 2 * math.pi); dx, dy = int(round(100 * math.cos(th))), int(round(100 * math.sin(th)))
    c, r = int(math.floor(tc[i])), int(math.floor(tr[i])); c2, r2 = int(math.floor(rc[i])), int(math.floor(rr[i]))
    return dfl(c, r) + dfl(c + dx, r + dy) + reb(c2, r2) + reb(c2 + dx, r2 + dy)
if __name__ == "__main__":
    with Pool(24) as p: X = np.array(p.map(one, range(len(P)), chunksize=20)) * 1e-4
    rng = np.random.default_rng(20261115); nr = len(RINGS); rn = list(RINGS)
    def summ(x):
        x = x[np.isfinite(x)]
        if len(x) < 10: return {"n": int(len(x)), "note": "fewer than 10 plots, suppressed"}
        bt = x[rng.integers(0, len(x), (B, len(x)))].mean(1); return {"n": int(len(x)), "mean": round(float(x.mean()), 5), "ci": [round(float(v), 5) for v in np.quantile(bt, [.025, .975])]}
    out = {"date": "2026-11-14", "n_fitted_plots": int(len(P)), "units": "probability", "control_distance_m": 1000, "bootstrap": B, "definition_layers": {}, "rebuilt_xp_layers_2026-11-06": {}}
    for b, v in enumerate(DEFS):
        pos = P[v].to_numpy(int) == 1
        out["definition_layers"][v] = {rn[k]: {"true_cell_positive": summ(X[pos, b * nr + k]), "control_positive": summ(X[pos, 6 * nr + b * nr + k]), "true_cell_negative": summ(X[~pos, b * nr + k])} for k in range(nr)}
    o = 12 * nr
    for b, (nm, v) in enumerate((("band1_transitioning_or_above", "V1"), ("band2_late_successional_or_old_growth", "V7"))):
        pos = P[v].to_numpy(int) == 1
        out["rebuilt_xp_layers_2026-11-06"][nm] = {"positive_label": v, **{rn[k]: {"true_cell_positive": summ(X[pos, o + b * nr + k]), "control_positive": summ(X[pos, o + 2 * nr + b * nr + k]), "true_cell_negative": summ(X[~pos, o + b * nr + k])} for k in range(nr)}}
    json.dump(out, open(f"{W}/out/d17_ring_profile_DATA.json", "w"), indent=1); print("DONE", flush=True)
