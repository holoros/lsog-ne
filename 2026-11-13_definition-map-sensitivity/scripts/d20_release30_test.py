#!/usr/bin/env python3
"""d20_release30_test.py (November 14, 2026). Release test on the built 30 m file of d19 (not on block means computed
in memory, as d18 did). Reads the released GeoTIFF only, plus the plot positions held in memory.
(a) Recovery attack of d18: attacker holds the public FIA position and the file, takes the five highest 3 x 3 local
    maxima among cells whose centres lie within 1.6 km; success = true position in one of those cells (same cell) or in
    one or an edge neighbour (same or adjacent). Null: five pseudo targets at the same displacement, random directions.
(b) Percentile rank of the true cell among the disk cells (rule 2 of m5 and d11), with the pseudo-target rank.
(c) Training-point contrast: true cell minus the mean of its 8 neighbours, and minus the ring 3 cells (90 m) away,
    against the same at a control cell 1 km away in a random direction.
Groups: all fitted plots and plots positive under the layer's definition. Bootstrap over plots (2,000). Aggregates
only; groups under 10 plots suppressed. True coordinates stay in memory."""
import os, json, math, importlib.util, numpy as np, rasterio
from multiprocessing import Pool
from scipy.ndimage import maximum_filter
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = os.environ["DS_SCR"]
spec = importlib.util.spec_from_file_location("leak", f"{W}/scripts/d11_me_leak.py"); L = importlib.util.module_from_spec(spec); spec.loader.exec_module(L)
P, DEFS, U = L.P, L.DEFS, L.U; B = 2000; NPS = 5; H = 54
M = json.load(open(f"{W}/out/d19_build_30m_DATA.json")); FN = f"{SCR}/me_release30/{M['file']}"
with rasterio.open(FN) as d: A = d.read(list(range(1, 7))); T = d.transform; assert d.crs == L.CRS
INV = ~T; pc, pr = INV * np.array(L.Tp.transform(P.plon.values, P.plat.values)); tc, tr = INV * np.array(L.Tt.transform(P["TRUE.LON"].values, P["TRUE.LAT"].values))
NRW, NCL = A.shape[1], A.shape[2]
def win(r0, c0, n):
    o = np.full((6, n, n), U, np.uint16); a1, a2, b1, b2 = max(r0, 0), min(r0 + n, NRW), max(c0, 0), min(c0 + n, NCL)
    if a1 < a2 and b1 < b2: o[:, a1 - r0:a2 - r0, b1 - c0:b2 - c0] = A[:, a1:a2, b1:b2]
    return o
def one(i):
    rng = np.random.default_rng([20261117, int(i)]); n = 2 * H + 1; r0, c0 = int(math.floor(pr[i])) - H, int(math.floor(pc[i])) - H; a = win(r0, c0, n); ok = a[0] != U
    q, p_ = np.mgrid[0:n, 0:n]; valid = ok & (np.hypot(c0 + p_ + 0.5 - pc[i], r0 + q + 0.5 - pr[i]) <= 1600.0 / 30.0)
    t_r, t_c = int(math.floor(tr[i])) - r0, int(math.floor(tc[i])) - c0; dc = math.hypot(tc[i] - pc[i], tr[i] - pr[i])
    if valid.sum() < 5 or not (0 <= t_r < n and 0 <= t_c < n and valid[t_r, t_c]): return {}
    ps = []
    for j in range(NPS):
        for t in range(200):
            th = rng.uniform(0, 2 * math.pi); q_r, q_c = int(math.floor(pr[i] + dc * math.sin(th))) - r0, int(math.floor(pc[i] + dc * math.cos(th))) - c0
            if 0 <= q_r < n and 0 <= q_c < n and valid[q_r, q_c]: ps.append((q_r, q_c)); break
    if not ps: return {}
    th = rng.uniform(0, 2 * math.pi); gt_r, gt_c = t_r + r0, t_c + c0; k_r, k_c = gt_r + int(round(33.3 * math.sin(th))), gt_c + int(round(33.3 * math.cos(th)))
    def ring(b, R, Cc, k):
        w = win(R - k, Cc - k, 2 * k + 1)[b].astype(np.float64); v = w != U
        if not v[k, k]: return np.nan
        ctr = w[k, k]; v[1:-1, 1:-1] = False
        return (ctr - w[v].mean()) / 1e3 if v.sum() >= 4 else np.nan
    rec = {"cells": int(valid.sum())}
    for b, v in enumerate(DEFS):
        Af = a[b].astype(np.float64) / 1e3; Am = np.where(valid, Af, -1.0); mf = maximum_filter(Am, size=3, mode="constant", cval=-1.0); r, c = np.nonzero(valid & (Am == mf)); val = Am[r, c]
        o = np.lexsort((rng.random(len(val)), -val))[:5]; kr, kc = r[o], c[o]
        def hit(rr, cc):
            d1 = np.abs(kr - rr) + np.abs(kc - cc); return float((d1 == 0).any()), float((d1 <= 1).any())
        vv = Af[valid]
        def rank(rr, cc): return (np.sum(vv < Af[rr, cc]) + 0.5 * np.sum(vv == Af[rr, cc])) / vv.size
        at = hit(t_r, t_c); nl = np.mean([hit(*x) for x in ps], axis=0)
        rec[v] = (at[0], at[1], float(nl[0]), float(nl[1]), rank(t_r, t_c), float(np.mean([rank(*x) for x in ps])),
                  ring(b, gt_r, gt_c, 1), ring(b, gt_r, gt_c, 3), ring(b, k_r, k_c, 1), ring(b, k_r, k_c, 3))
    return rec
if __name__ == "__main__":
    with Pool(24) as p: rows = p.map(one, range(len(P)), chunksize=20)
    rng = np.random.default_rng(20261117); out = {"date": "2026-11-14", "file": M["file"], "sha256": M["sha256"], "n_fitted_plots": int(len(P)), "n_tested": int(sum(1 for r in rows if r)),
           "median_cells_in_disk": float(np.median([r["cells"] for r in rows if r])), "bootstrap": B, "layers": {}}
    def ci(x):
        x = x[np.isfinite(x)]; m = len(x); bt = x[rng.integers(0, m, (B, m))].mean(1); return {"n": int(m), "mean": round(float(x.mean()), 4), "ci": [round(float(z), 4) for z in np.quantile(bt, [.025, .975])]}
    for v in DEFS:
        idx = np.array([k for k, r in enumerate(rows) if v in r]); X = np.array([rows[k][v] for k in idx], float); lay = {}
        for gname, sel in (("all", np.ones(len(idx), bool)), ("positive", P[v].to_numpy(int)[idx] == 1)):
            x = X[sel]
            if len(x) < 10: lay[gname] = {"n": int(len(x)), "note": "fewer than 10 plots, suppressed"}; continue
            lay[gname] = {"n": int(len(x)),
                "same_cell": {"attack": round(float(x[:, 0].mean()), 4), "null": round(float(x[:, 2].mean()), 4), "diff": ci(x[:, 0] - x[:, 2])},
                "same_or_adjacent": {"attack": round(float(x[:, 1].mean()), 4), "null": round(float(x[:, 3].mean()), 4), "diff": ci(x[:, 1] - x[:, 3])},
                "rank_true_median": round(float(np.median(x[:, 4])), 4), "rank_pseudo_median": round(float(np.median(x[:, 5])), 4),
                "contrast_adjacent": ci(x[:, 6]), "contrast_90m": ci(x[:, 7]), "control_adjacent": ci(x[:, 8]), "control_90m": ci(x[:, 9])}
        out["layers"][v] = lay; print(v, json.dumps(lay.get("positive")), flush=True)
    json.dump(out, open(f"{W}/out/d20_release30_test_DATA.json", "w"), indent=1); print("DONE", flush=True)
