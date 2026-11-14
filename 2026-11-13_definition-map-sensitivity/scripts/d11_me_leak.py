#!/usr/bin/env python3
"""d11_me_leak.py (November 13, 2026). Location recovery test of November 1 (2026-11-03_models/m5_leak.py form) on the six
Maine cross-predicted definition layers of d4. Attacker holds the public FIA position (ME_PLOT LAT/LON) and the layer;
searches a 1.6 km disk for the true cell. Run at the native 10 m grain (peaks = 5x5 max, 9x9 as sensitivity) and on the
3x3 block mean at 30 m, which is the m5 grain (peaks = 3x3 max, 5x5 as sensitivity). Suppression of peaks within 60 m of
a higher kept peak; success = a top-k peak within 30 m (or 100 m) of the true cell centre. Null = five pseudo targets
per plot at the same displacement from the public point in random directions. Decision rules as m5: rule 1, top-5
success within 30 m exceeds the null by >= 0.05 with a bootstrap interval above zero; rule 2, median percentile rank
of the true cell in the disk >= 0.75. Groups: all fitted plots, and the plots positive under the layer's definition.
True coordinates are held in memory only. No per-plot row is written; groups under 10 plots are suppressed."""
import os, json, math, numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
from multiprocessing import Pool
from pyproj import Transformer
from scipy.ndimage import maximum_filter
E = os.environ; W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = E["DS_SCR"]; VRT = f"{SCR}/me_tiles/defsens_xp.vrt"
PUB = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
DEFS = ["V3", "V1", "V2", "V4", "V9_c3", "V7"]; AE = [f"AE_{i:02d}" for i in range(64)]; U = 65535; R10 = 160; NW = 2 * R10 + 1; NPS = 5; B = 2000; MINN = 10
CFG = {1: dict(CS=10.0, pk=(5, 9), sup2=36), 3: dict(CS=30.0, pk=(3, 5), sup2=4)}
d = pd.read_csv(PUB, low_memory=False)[["plot_id"] + AE]
cw = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
xy = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]]
lab = pd.read_csv(f"{W}/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv", dtype={"PLT_CN": str})
pl = pd.read_csv("/users/PUOM0008/crsfaaron/fia_data/ME_PLOT.csv", usecols=["CN", "LAT", "LON"], dtype={"CN": str}).rename(columns={"CN": "PLT_CN", "LAT": "plat", "LON": "plon"})
d = d.merge(cw, on="plot_id", how="inner").merge(xy, on="PLT_CN", how="inner").merge(lab, on="PLT_CN", how="inner")
d = d[np.isfinite(d[AE].to_numpy(float)).all(1) & d["TRUE.LAT"].notna()].sort_values("plot_id").reset_index(drop=True)
n_fit = len(d); P = d.merge(pl, on="PLT_CN", how="left"); P = P[np.isfinite(P.plat) & np.isfinite(P.plon)].reset_index(drop=True)
# The tiles are south-up, which gdalbuildvrt refuses, so windows are assembled on a common pixel grid anchored at tile 0.
import glob
TL = sorted(glob.glob(f"{SCR}/me_tiles/defsens_xp_*.tif")); assert len(TL) == 34; TI = []
with rasterio.open(TL[0]) as ds0: CRS = ds0.crs; T0 = ds0.transform; INV = ~T0
assert T0.b == 0 and T0.d == 0
for f in TL:
    with rasterio.open(f) as q:
        assert q.crs == CRS and abs(q.transform.a - T0.a) < 1e-9 and abs(q.transform.e - T0.e) < 1e-9
        oc, orow = (q.transform.c - T0.c) / T0.a, (q.transform.f - T0.f) / T0.e; assert abs(oc - round(oc)) < 1e-6 and abs(orow - round(orow)) < 1e-6, f
        TI.append((f, int(round(oc)), int(round(orow)), q.width, q.height))
def read_win(x0, y0):
    out = np.full((6, NW, NW), U, np.uint16); hit = False
    for f, oc, orow, w, h in TI:
        c1, c2, r1, r2 = max(x0, oc), min(x0 + NW, oc + w), max(y0, orow), min(y0 + NW, orow + h)
        if c1 >= c2 or r1 >= r2: continue
        if f not in _DS: _DS[f] = rasterio.open(f)
        blk = _DS[f].read(list(range(1, 7)), window=Window(c1 - oc, r1 - orow, c2 - c1, r2 - r1)); tgt = out[:, r1 - y0:r2 - y0, c1 - x0:c2 - x0]
        tgt[:] = np.where(tgt == U, blk, tgt); hit = True
    return out, hit
_DS = {}
Tp = Transformer.from_crs(4269, CRS, always_xy=True); Tt = Transformer.from_crs(4326, CRS, always_xy=True)
pc, pr = INV * np.array(Tp.transform(P.plon.values, P.plat.values)); tc, tr = INV * np.array(Tt.transform(P["TRUE.LON"].values, P["TRUE.LAT"].values))
def peaks(A, valid, size, sup2, rng):
    Af = np.where(valid, A, -1.0); mf = maximum_filter(Af, size=size, mode="constant", cval=-1.0); r, c = np.nonzero(valid & (Af == mf))
    v = Af[r, c]; o = np.lexsort((rng.random(len(v)), -v)); r, c = r[o], c[o]; kr, kc = [], []
    for i in range(len(r)):
        if len(kr) >= 20: break
        if kr and np.min((np.array(kr) - r[i]) ** 2 + (np.array(kc) - c[i]) ** 2) <= sup2: continue
        kr.append(r[i]); kc.append(c[i])
    return np.array(kr), np.array(kc)
def stats(A, valid, pk, t_r, t_c, CS, rr_, cc_):
    o = {}
    for nm, (kr, kc) in pk.items():
        dd = np.sqrt((kr - t_r) ** 2 + (kc - t_c) ** 2) * CS if len(kr) else np.array([np.inf])
        for k in (1, 5, 20):
            dk = dd[:k].min(); o[f"{nm}_s{k}_30"] = float(dk <= 30); o[f"{nm}_s{k}_100"] = float(dk <= 100)
    vt = A[t_r, t_c]; vv = A[valid]; o["pr"] = (np.sum(vv < vt) + 0.5 * np.sum(vv == vt)) / vv.size
    return o
def one(i):
    rng = np.random.default_rng([20261101, int(i)]); c0, r0 = int(math.floor(pc[i])), int(math.floor(pr[i])); x0, y0 = c0 - R10, r0 - R10
    rec = {"i": int(i)}
    A6, hit = read_win(x0, y0)
    if not hit: rec["status"] = "edge"; return rec
    V6 = A6[0] != U; rec["status"] = "ok"
    for g, cf in CFG.items():
        n = NW // g; R = (n - 1) // 2; CS = cf["CS"]
        if g == 1: Ag = A6.astype(np.float64); Vg = V6
        else:
            m = V6.reshape(n, g, n, g); cnt = m.sum((1, 3)); Vg = cnt >= 5
            Ag = np.where(V6, A6, 0).astype(np.float64).reshape(6, n, g, n, g).sum((2, 4)) / np.maximum(cnt, 1)
        rr_, cc_ = np.mgrid[0:n, 0:n]; valid = ((rr_ - R) ** 2 + (cc_ - R) ** 2 <= R * R) & Vg
        if valid.sum() < 1000 / (g * g) * 9: rec[f"g{g}_status"] = "few_valid"; continue
        t_r, t_c = int(math.floor((tr[i] - y0) / g)), int(math.floor((tc[i] - x0) / g)); pr_f, pc_f = (pr[i] - y0) / g, (pc[i] - x0) / g
        dc = math.hypot(tc[i] - pc[i], tr[i] - pr[i]) / g
        ind = 0 <= t_r < n and 0 <= t_c < n and (t_r - R) ** 2 + (t_c - R) ** 2 <= R * R
        if not (ind and valid[t_r, t_c]): rec[f"g{g}_status"] = "outside" if not ind else "true_invalid"; continue
        ps = []
        for j in range(NPS):
            for t in range(200):
                th = rng.uniform(0, 2 * math.pi); q_r, q_c = int(math.floor(pr_f + dc * math.sin(th))), int(math.floor(pc_f + dc * math.cos(th)))
                if 0 <= q_r < n and 0 <= q_c < n and valid[q_r, q_c]: ps.append((q_r, q_c)); break
        rec[f"g{g}_status"] = "ok"; rec[f"g{g}_npseudo"] = len(ps)
        for b, v in enumerate(DEFS):
            A = Ag[b]; pk = {f"p{s}": peaks(A, valid, s, cf["sup2"], rng) for s in cf["pk"]}
            for k, x in stats(A, valid, pk, t_r, t_c, CS, rr_, cc_).items(): rec[f"g{g}_{v}_a_{k}"] = x
            if ps:
                S = pd.DataFrame([stats(A, valid, pk, q_r, q_c, CS, rr_, cc_) for q_r, q_c in ps])
                for k in S.columns: rec[f"g{g}_{v}_n_{k}"] = float(S[k].mean())
                rec[f"g{g}_{v}_n_prmed"] = float(S["pr"].median())
    return rec
def wilson(k, n, z=1.96):
    p = k / n; den = 1 + z * z / n; c = (p + z * z / (2 * n)) / den; hh = z * np.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return [round(c - hh, 4), round(c + hh, 4)]
if __name__ == "__main__":
    with Pool(24) as p: rows = p.map(one, range(len(P)), chunksize=20)
    D = pd.DataFrame(rows).sort_values("i").reset_index(drop=True); assert (D.i.values == np.arange(len(P))).all()
    res = {"date": "2026-11-13", "form": "m5_leak.py of 2026-11-03", "n_fitted_plots": int(n_fit), "n_with_public_position": int(len(P)), "status": D.status.value_counts().to_dict(),
           "disk_radius_m": 1600, "pseudo_targets_per_plot": NPS, "bootstrap": B, "seed": 20261101, "layers": {}}
    rng = np.random.default_rng(20261101)
    for g, cf in CFG.items():
        okg = (D.status == "ok") & (D.get(f"g{g}_status") == "ok") & (D.get(f"g{g}_npseudo", 0) > 0); res[f"g{g}_status"] = D.loc[D.status == "ok", f"g{g}_status"].value_counts().to_dict()
        p1, p2 = (f"p{s}" for s in cf["pk"])
        for v in DEFS:
            lay = {}
            for gname, sel in (("train_all", okg), ("train_pos", okg & (P[v].to_numpy(int) == 1))):
                G = D[sel]; n = len(G); o = {"n_plots": int(n)}
                if n < MINN: o["note"] = "fewer than 10 plots, suppressed"; lay[gname] = o; continue
                idx = rng.integers(0, n, size=(B, n))
                for pkn in (p1, p2):
                    for k in (1, 5, 20):
                        for tol in (30, 100):
                            c = f"{pkn}_s{k}_{tol}"; a = G[f"g{g}_{v}_a_{c}"].to_numpy(float); nn = G[f"g{g}_{v}_n_{c}"].to_numpy(float); bd = a[idx].mean(1) - nn[idx].mean(1)
                            o[f"success_{pkn}_top{k}_within{tol}m"] = {"attack": round(float(a.mean()), 4), "attack_wilson95": wilson(int(a.sum()), n), "pseudo_null": round(float(nn.mean()), 4),
                                "diff": round(float(a.mean() - nn.mean()), 4), "diff_boot95": [round(float(x), 4) for x in np.quantile(bd, [.025, .975])]}
                prt = G[f"g{g}_{v}_a_pr"].to_numpy(float); prn = G[f"g{g}_{v}_n_prmed"].to_numpy(float)
                o["pct_rank_true_median"] = round(float(np.median(prt)), 4); o["pct_rank_true_median_boot95"] = [round(float(x), 4) for x in np.quantile(np.median(prt[idx], 1), [.025, .975])]
                o["pct_rank_pseudo_median"] = round(float(np.median(prn)), 4)
                s = o[f"success_{p1}_top5_within30m"]; s2 = o[f"success_{p2}_top5_within30m"]; r1 = s["diff"] >= 0.05 and s["diff_boot95"][0] > 0; r2 = o["pct_rank_true_median"] >= 0.75
                o["decision"] = {"rule1_diff": s["diff"], "rule1_ci": s["diff_boot95"], "rule1_met": bool(r1), "rule1_diff_sens": s2["diff"], "rule1_ci_sens": s2["diff_boot95"],
                                 "rule2_median_pct_rank": o["pct_rank_true_median"], "rule2_pseudo_median": o["pct_rank_pseudo_median"], "rule2_met": bool(r2), "leak": bool(r1 or r2)}
                lay[gname] = o
            res["layers"][f"g{g * 10}m_{v}"] = lay; print(g, v, json.dumps({k: x.get("decision") for k, x in lay.items()}), flush=True)
    json.dump(res, open(f"{W}/out/d11_me_leak_DATA.json", "w"), indent=1); print("DONE", flush=True)
