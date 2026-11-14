#!/usr/bin/env python3
"""d18_grain_attack.py (November 14, 2026). Release test, part 3 (Aaron: find the finest grain at which the six Maine
definition layers can be released). The position-recovery attack of d11 on block means of the 10 m layers at 30, 50,
100, 250, 500 and 1,000 m, on a fixed grid (aligned to multiples of the grain, as a released raster would be).
Attacker: holds the public FIA position and the coarse layer, searches the cells whose centres lie within 1.6 km, and
takes the five highest local maxima (3 x 3). Success A: the true position is inside one of those cells. Success B:
inside one of them or an edge-adjacent cell. Null: five pseudo targets per plot at the same displacement from the
public position in random directions. Reported for all fitted plots and for the plots positive under the layer's
definition, as attack minus null with a bootstrap interval. True coordinates in memory; aggregates only."""
import os, json, math, importlib.util, numpy as np
from multiprocessing import Pool
from scipy.ndimage import maximum_filter
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity")
spec = importlib.util.spec_from_file_location("rel", f"{W}/scripts/d14_me_release_test.py"); Rm = importlib.util.module_from_spec(spec); spec.loader.exec_module(Rm)
P, DEFS, U, pc, pr, tc, tr = Rm.P, Rm.DEFS, Rm.U, Rm.pc, Rm.pr, Rm.tc, Rm.tr; GR = [3, 5, 10, 25, 50, 100]; B = 2000; NPS = 5
def one(i):
    rng = np.random.default_rng([20261116, int(i)]); rec = {}
    for g in GR:
        h = int(math.ceil(160.0 / g)); n = 2 * h + 1; gc, gr_ = int(math.floor(pc[i] / g)), int(math.floor(pr[i] / g)); x0, y0 = (gc - h) * g, (gr_ - h) * g
        a = Rm.read(x0, y0, n * g); ok10 = a[0] != U; cnt = ok10.reshape(n, g, n, g).sum((1, 3)); V = cnt >= 0.5 * g * g
        A = np.where(ok10, a, 0).astype(np.float64).reshape(6, n, g, n, g).sum((2, 4)) / np.maximum(cnt, 1)
        q, p_ = np.mgrid[0:n, 0:n]; cx = x0 + (p_ + 0.5) * g; cy = y0 + (q + 0.5) * g; valid = V & (np.hypot(cx - pc[i], cy - pr[i]) <= 160.0)
        t_c, t_r = int(math.floor((tc[i] - x0) / g)), int(math.floor((tr[i] - y0) / g)); dc = math.hypot(tc[i] - pc[i], tr[i] - pr[i])
        if valid.sum() < 5 or not (0 <= t_r < n and 0 <= t_c < n and valid[t_r, t_c]): continue
        ps = []
        for j in range(NPS):
            for t in range(200):
                th = rng.uniform(0, 2 * math.pi); q_c, q_r = int(math.floor((pc[i] + dc * math.cos(th) - x0) / g)), int(math.floor((pr[i] + dc * math.sin(th) - y0) / g))
                if 0 <= q_r < n and 0 <= q_c < n and valid[q_r, q_c]: ps.append((q_r, q_c)); break
        if not ps: continue
        rec[f"g{g}_cells"] = int(valid.sum())
        for b, v in enumerate(DEFS):
            Af = np.where(valid, A[b], -1.0); mf = maximum_filter(Af, size=3, mode="constant", cval=-1.0); r, c = np.nonzero(valid & (Af == mf)); val = Af[r, c]
            o = np.lexsort((rng.random(len(val)), -val))[:5]; kr, kc = r[o], c[o]
            def hit(rr, cc):
                d1 = np.abs(kr - rr) + np.abs(kc - cc); return float((d1 == 0).any()), float((d1 <= 1).any())
            a_ = hit(t_r, t_c); nl = np.mean([hit(*x) for x in ps], axis=0)
            rec[f"g{g}_{v}"] = (a_[0], a_[1], float(nl[0]), float(nl[1]))
    return rec
if __name__ == "__main__":
    with Pool(24) as p: rows = p.map(one, range(len(P)), chunksize=20)
    rng = np.random.default_rng(20261116); out = {"date": "2026-11-14", "n_fitted_plots": int(len(P)), "disk_radius_m": 1600, "top_k": 5, "pseudo_targets": NPS, "bootstrap": B, "grains": {}}
    for g in GR:
        G = {"grain_m": 10 * g, "median_cells_in_disk": float(np.median([r[f"g{g}_cells"] for r in rows if f"g{g}_cells" in r])), "layers": {}}
        for v in DEFS:
            idx = np.array([k for k, r in enumerate(rows) if f"g{g}_{v}" in r]); X = np.array([rows[k][f"g{g}_{v}"] for k in idx]); lay = {}
            for gname, sel in (("all", np.ones(len(idx), bool)), ("positive", P[v].to_numpy(int)[idx] == 1)):
                x = X[sel]; m = len(x)
                if m < 10: lay[gname] = {"n": int(m), "note": "fewer than 10 plots, suppressed"}; continue
                bi = rng.integers(0, m, (B, m)); o = {"n": int(m)}
                for nm, ca, cn in (("same_cell", 0, 2), ("same_or_adjacent", 1, 3)):
                    dd = x[:, ca] - x[:, cn]; bt = dd[bi].mean(1)
                    o[nm] = {"attack": round(float(x[:, ca].mean()), 4), "null": round(float(x[:, cn].mean()), 4), "diff": round(float(dd.mean()), 4), "ci": [round(float(z), 4) for z in np.quantile(bt, [.025, .975])]}
                lay[gname] = o
            G["layers"][v] = lay
        out["grains"][str(10 * g)] = G; print(10 * g, json.dumps({v: G["layers"][v]["positive"].get("same_or_adjacent") for v in DEFS}), flush=True)
    json.dump(out, open(f"{W}/out/d18_grain_attack_DATA.json", "w"), indent=1); print("DONE", flush=True)
