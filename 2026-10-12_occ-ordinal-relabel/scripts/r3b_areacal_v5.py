#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s4e_areacal_me.py  Replaces the s4d prior shift. Red team, 7 October 2026: s4d shifted from the UNWEIGHTED training
# prevalence (572 / 3482) although the forests were fit with weight 3 on 229 hard negatives (learned prior about
# 572 / 3940). Shifted correctly, the statewide transitioning mean stays near 16.4 percent, outside the FIA interval,
# because the OCC sample also changes P(x | y). The defensible calibration is therefore an area anchored logit intercept:
# for each cumulative layer k, delta_k is solved so the forest area mean equals the FIA rate (14.66 percent design based
# for transitioning or above; the unweighted FIA sample rates 50 / 3062 and 10 / 3062 for the LS or OG pool and OG).
# Agreement with those rates is then true by construction and is reported as such, never as validation.
# Gates (location, range, magnitude, cross layer): G1 coverage of the M3 frame inside Maine >= 0.98; G2 forest area
# within 5 percent of 7.41 Mha (EPSG:3979 overstatement 1.033); G3 values in [0, 1] and ordering; G7 each delta
# finite and |delta| < 2 logits (a larger shift means the raw layer is unusable, not calibrated). Reported, not gated:
# the area mean under the weighted prior shift, for the record.
import os, json, subprocess, numpy as np, rasterio
from rasterio.features import geometry_mask
E = os.environ; OUT = E["OUT"]; FIN = f"{OUT}/final"; AGG = f"{OUT}/agg"
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
RAW = f"{FIN}/occ-ordinal-v5-lsog_10m_ME_DATA_2026-10-12.tif"
DST = f"{FIN}/occ-ordinal-v5-lsog-areacal_10m_ME_DATA_2026-10-12_PROVISIONAL.tif"
def sh(c): print("$", c, flush=True); subprocess.run(c, shell=True, check=True)
U = 65535; tgt = np.array([0.1466, 0.0207, 0.0021])
meta = json.load(open(f"{OUT}/v4_meta.json")); n_hn = meta["n_hard_neg"]; wN = meta["n"] + 2 * n_hn    # 229 hard negatives at weight 3 (v345_falsepos)
pi_u = np.array(meta["pos"]) / meta["n"]; pi_w = np.array(meta["pos"]) / wN
lg = lambda p: np.log(p / (1 - p)); sg = lambda z: 1 / (1 + np.exp(-z))
# ---- pass 1: systematic subsample (every 7th row and column of each block)
sub = []
with rasterio.open(RAW) as s:
    for _, win in s.block_windows(1):
        a = s.read([1, 2, 3], window=win)[:, ::7, ::7].reshape(3, -1); v = a[0] != U
        if v.any(): sub.append(a[:, v].astype("float32") / 1e4)
S = np.concatenate(sub, 1); S = np.clip(S, 1e-6, 1 - 1e-6); Z = lg(S); print("subsample", S.shape[1], flush=True)
def mean_at(k, d): return float(sg(Z[k] + d).mean())
delta = np.zeros(3)
for k in range(3):
    lo, hi = -6.0, 6.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if mean_at(k, mid) > tgt[k]: hi = mid
        else: lo = mid
    delta[k] = (lo + hi) / 2
lor_w = lg(tgt) - lg(pi_w); lor_u = lg(tgt) - lg(pi_u)
rep = {"raw_mean_pct": (100 * S.mean(1)).tolist(), "delta_areacal": delta.tolist(),
       "weighted_prior_shift": {"pi_train_weighted": pi_w.tolist(), "lor": lor_w.tolist(), "mean_pct": [100 * mean_at(k, lor_w[k]) for k in range(3)]},
       "unweighted_prior_shift_s4d": {"pi_train_unweighted": pi_u.tolist(), "lor": lor_u.tolist(), "mean_pct": [100 * mean_at(k, lor_u[k]) for k in range(3)]}}
print(json.dumps(rep, indent=1), flush=True)
fails = [f"G7 delta {k}" for k in range(3) if not (np.isfinite(delta[k]) and abs(delta[k]) < 2)]
# ---- pass 2: apply to every cell
with rasterio.open(E["FRAME_M3"]) as fr:
    gj = json.load(open(CUT)); inside = ~geometry_mask([f["geometry"] for f in gj["features"]], out_shape=(fr.height, fr.width), transform=fr.transform)
    frame30 = int(((fr.read(1) == int(E["FRAME_FOREST_VALUE"])) & inside).sum())
tot = np.zeros(3); n = 0; bad_r = bad_o = 0
with rasterio.open(RAW) as s:
    prof = s.profile.copy(); prof.update(count=4, compress="deflate", tiled=True, blockxsize=512, blockysize=512, BIGTIFF="YES")
    with rasterio.open(DST, "w", **prof) as d:
        for _, win in s.block_windows(1):
            a = s.read([1, 2, 3, 4], window=win).astype("float64"); v = a[0] != U; o = np.full(a.shape, U, "uint16")
            if v.any():
                p = np.clip(a[:3, v] / 1e4, 1e-6, 1 - 1e-6); q = sg(lg(p) + delta[:, None])
                q[1] = np.minimum(q[1], q[0]); q[2] = np.minimum(q[2], q[1])
                bad_r += int(((q < 0) | (q > 1)).sum()); bad_o += int(((q[2] > q[1] + 1e-9) | (q[1] > q[0] + 1e-9)).sum())
                tot += q.sum(1); n += q.shape[1]; o[:3, v] = np.rint(q * 1e4).astype("uint16"); o[3, v] = a[3, v].astype("uint16")
            d.write(o, window=win)
m = 100 * tot / n; ha = n * 100 / 1.033 / 1e4; share = n / (9 * frame30)
rep.update({"coverage_inside_ME": share, "forest_ha": ha, "means_areacal_pct": m.tolist(), "expected_ha_areacal": (m / 100 * ha).tolist(),
            "targets_pct": (100 * tgt).tolist(), "note": "means equal the targets by construction; not a validation"})
if share < 0.98: fails.append("G1 coverage")
if abs(ha / 7.41e6 - 1) > 0.05: fails.append("G2 area")
if bad_r or bad_o: fails.append("G3 range or order")
if np.max(np.abs(m - 100 * tgt)) > 0.25: fails.append("G7 area mean does not reproduce target (subsample bias)")
rep["fails"] = fails; json.dump(rep, open(f"{AGG}/v4_areacal_gates_DATA.json", "w"), indent=1); print(json.dumps(rep, indent=1), flush=True)
if fails: print("GATES FAILED", fails); raise SystemExit(2)
os.replace(DST, DST.replace("_PROVISIONAL", "")); DST = DST.replace("_PROVISIONAL", "")
for r_ in (30, 100):
    sh(f"gdalwarp -overwrite -tr {r_} {r_} -tap -r average -srcnodata 65535 -dstnodata 65535 -co COMPRESS=DEFLATE -co TILED=YES "
       f"-wo NUM_THREADS=ALL_CPUS -multi {DST} {FIN}/occ-ordinal-v5-lsog-areacal_{r_}m-from10m_ME_DATA_2026-10-12.tif")
print("S4E DONE", flush=True)
