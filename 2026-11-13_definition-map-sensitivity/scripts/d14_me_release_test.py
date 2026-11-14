#!/usr/bin/env python3
"""d14_me_release_test.py (November 14, 2026). Release test of the Maine cross-predicted 10 m layers (six definition
layers and the definition-agreement count), in addition to the position-recovery attack of d11.
Training-point signal (the form of Appendix S1 Section 19.1): at each fitted plot, the layer value at the true cell
minus the mean of the ring of cells 35 to 45 m away, against the same contrast at a control cell 1 km away in a random
direction. A layer that memorised its training plots shows a positive contrast at positive plots and none at controls.
A cross-predicted layer should show none, because no forest saw the plot or any plot in its 20 km block.
Search area: for the agreement layer, the percentile rank of the true cell within the 1.6 km disk around the public
position (d11 reports it for the six definition layers), i.e. the share of the disk an attacker who ranks cells by the
layer would search before reaching the plot. True coordinates stay in memory; aggregates only; groups under 10 suppressed."""
import os, sys, json, math, importlib.util, numpy as np, rasterio
from rasterio.windows import Window
from multiprocessing import Pool
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = os.environ["DS_SCR"]
spec = importlib.util.spec_from_file_location("leak", f"{W}/scripts/d11_me_leak.py"); L = importlib.util.module_from_spec(spec); spec.loader.exec_module(L)   # plots, positions, tile index (module level only)
P, TI, DEFS, U = L.P, L.TI, L.DEFS, L.U; pc, pr, tc, tr = L.pc, L.pr, L.tc, L.tr; B = 2000; _D = {}
def read(x0, y0, n, agree=False):
    nb = 1 if agree else 6; out = np.full((nb, n, n), 255 if agree else U, np.uint16)
    for f, oc, orow, w, h in TI:
        c1, c2, r1, r2 = max(x0, oc), min(x0 + n, oc + w), max(y0, orow), min(y0 + n, orow + h)
        if c1 >= c2 or r1 >= r2: continue
        f2 = f.replace("me_tiles/defsens_xp_", "me_agree/agree_") if agree else f
        if agree and not os.path.exists(f2): continue          # tiles with no forest cell inside Maine have no agreement raster
        if f2 not in _D: _D[f2] = rasterio.open(f2)
        b = _D[f2].read([1] if agree else list(range(1, 7)), window=Window(c1 - oc, r1 - orow, c2 - c1, r2 - r1)); t = out[:, r1 - y0:r2 - y0, c1 - x0:c2 - x0]
        t[:] = np.where(t == (255 if agree else U), b, t)
    return out
yy, xx = np.mgrid[-5:6, -5:6]; RING = (np.hypot(yy, xx) * 10 >= 35) & (np.hypot(yy, xx) * 10 <= 45)
def contrast(c, r):
    a = read(c - 5, r - 5, 11); g = read(c - 5, r - 5, 11, agree=True); A = np.concatenate([a, g]).astype(float); bad = np.concatenate([a == U, g == 255]); res = []
    for b in range(7):
        ok = RING & ~bad[b]
        res.append(np.nan if bad[b, 5, 5] or ok.sum() < 8 else A[b, 5, 5] - A[b][ok].mean())
    return res
def one(i):
    rng = np.random.default_rng([20261114, int(i)]); c, r = int(math.floor(tc[i])), int(math.floor(tr[i])); th = rng.uniform(0, 2 * math.pi)
    rec = {"i": int(i), "a": contrast(c, r), "k": contrast(c + int(round(100 * math.cos(th))), r + int(round(100 * math.sin(th))))}
    c0, r0 = int(math.floor(pc[i])), int(math.floor(pr[i])); R = 160; g = read(c0 - R, r0 - R, 2 * R + 1, agree=True)[0].astype(float); q, p_ = np.mgrid[0:2 * R + 1, 0:2 * R + 1]
    valid = ((q - R) ** 2 + (p_ - R) ** 2 <= R * R) & (g != 255); t_r, t_c = r - (r0 - R), c - (c0 - R); rec["rank"] = np.nan
    if 0 <= t_r <= 2 * R and 0 <= t_c <= 2 * R and valid[t_r, t_c] and valid.sum() >= 9000:
        vv = g[valid]; vt = g[t_r, t_c]; rec["rank"] = float((np.sum(vv < vt) + 0.5 * np.sum(vv == vt)) / vv.size)
    return rec
if __name__ == "__main__":
    with Pool(24) as p: rows = p.map(one, range(len(P)), chunksize=20)
    A = np.array([x["a"] for x in rows]); Kc = np.array([x["k"] for x in rows]); rk = np.array([x["rank"] for x in rows]); rng = np.random.default_rng(20261114)
    names = DEFS + ["agreement_count"]; scale = [1e-4] * 6 + [1.0]; out = {"date": "2026-11-14", "n_fitted_plots": int(len(P)), "ring_m": [35, 45], "control_distance_m": 1000, "bootstrap": B, "layers": {}}
    cnt = P[DEFS].to_numpy(int).sum(1)
    def summ(x):
        x = x[np.isfinite(x)]
        if len(x) < 10: return {"n": int(len(x)), "note": "fewer than 10 plots, suppressed"}
        bt = x[rng.integers(0, len(x), (B, len(x)))].mean(1); return {"n": int(len(x)), "mean": round(float(x.mean()), 5), "ci": [round(float(v), 5) for v in np.quantile(bt, [.025, .975])]}
    for b, nm in enumerate(names):
        pos = (P[nm].to_numpy(int) == 1) if b < 6 else (cnt >= 3); neg = ~pos
        out["layers"][nm] = {"units": "probability" if b < 6 else "definitions (0 to 6)", "positive_group": "plots positive under the definition" if b < 6 else "plots positive under at least three definitions",
                             "true_cell_minus_ring": {"positive": summ(A[pos, b] * scale[b]), "negative": summ(A[neg, b] * scale[b])},
                             "control_1km_minus_ring": {"positive": summ(Kc[pos, b] * scale[b]), "negative": summ(Kc[neg, b] * scale[b])}}
    for gname, sel in (("all", np.ones(len(P), bool)), ("ge3_definitions", cnt >= 3), ("all_six", cnt >= 6)):
        x = rk[sel & np.isfinite(rk)]
        out.setdefault("agreement_layer_percentile_rank_in_disk", {})[gname] = ({"n": int(len(x)), "note": "fewer than 10 plots, suppressed"} if len(x) < 10 else
            {"n": int(len(x)), "median": round(float(np.median(x)), 4), "median_ci": [round(float(v), 4) for v in np.quantile(np.median(x[rng.integers(0, len(x), (B, len(x)))], 1), [.025, .975])],
             "median_search_share_of_disk": round(float(1 - np.median(x)), 4)})
    json.dump(out, open(f"{W}/out/d14_me_release_test_DATA.json", "w"), indent=1); print(json.dumps(out), "DONE", flush=True)
