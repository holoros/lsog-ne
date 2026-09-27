#!/usr/bin/env python3
"""
NB licensed CORE4 Stage A: is the block level attenuation (OOF slope 0.262) structure or thin support?

Reads, on Cardinal only: s2_rf_oof_DATA_2026-09-25.csv (plot OOF probabilities, synthetic NBL ids),
the server side licensed coordinate cache (magp_site_id, lat, lon, label), magp_site_sources.csv
(holder), eco_rast.tif (CEC Level III, two NB classes), the 20 block bootstrap forests.

Writes ONE aggregate JSON. No per holder value, no holder name, no coordinate, no plot row leaves.
Holder is used as a grouping factor and reported only as variance shares, ICC, a permutation p and
a count of holders beyond a tolerance. Ecoregion rows are public class aggregates.

Tests
  T1  variance partition of plot OOF residuals (y - p), weighted: block, ecoregion, holder | block.
      Permutation null for holder | block: holder labels shuffled within block, 500 draws.
  T2  block slope decomposition (predicted on observed, house convention, blocks n >= 20):
      all blocks as s2; between holder (holder means); within holder (block cells centered on
      holder means). 2000 block bootstrap draws for each.
  T3  support: in sample ensemble SD (20 boot forests) by predicted probability decile with
      plot and positive counts, against the binomial reference sqrt(p(1-p)/n_pos_bin).
  T4  ecoregion class calibration: observed and predicted rate, n, per class.
Usage: /usr/bin/python3 this.py   (writes $BUILD/nb_block_residual_structure_2026-09-25.json)
"""
import os, sys, json, pickle, hashlib
import numpy as np, pandas as pd, rasterio
from pyproj import Transformer
sys.path.insert(0, "/users/PUOM0008/crsfaaron/LSOG/nb_magplot")
import nb_cli_lsog_fullscope as P

BUILD = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-10m_2026-09-25"
CACHE = f"{BUILD}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"
ECO_TIF = "/users/PUOM0008/crsfaaron/LSOG/jdi_refine/eco_rast.tif"
ECO_NAMES = {1: "Acadian Plains and Hills", 2: "Maritime Lowlands", 0: "outside raster"}
OUT = f"{BUILD}/nb_block_residual_structure_2026-09-25.json"
rng = np.random.default_rng(20260925)

oof = pd.read_csv(f"{BUILD}/s2_rf_oof_DATA_2026-09-25.csv")
oof = oof[oof.jurisdiction == "NB"].reset_index(drop=True)
cache = pd.read_csv(CACHE, low_memory=False)
AE = [c for c in cache.columns if c.startswith("AE_")]
# reproduce s1's row filter so NBL_i maps to cache row i
assert len(cache) == len(oof), (len(cache), len(oof))
assert (oof.plot_id_export == [f"NBL_{i+1:05d}" for i in range(len(oof))]).all()
assert (cache.core4_cut3.values == oof.observed.values).all(), "label order mismatch between cache and OOF table"
srcs = pd.read_csv(f"{P.CLI}/magp_site_sources.csv", usecols=[P.KEY, "holder"], low_memory=False).drop_duplicates(P.KEY)
hold = cache[[P.KEY]].merge(srcs, on=P.KEY, how="left").holder.values
assert pd.notna(hold).all()

# ecoregion class at licensed coordinates
with rasterio.open(ECO_TIF) as R:
    tr = Transformer.from_crs("EPSG:4326", R.crs, always_xy=True)
    xs, ys = tr.transform(cache.longitude.values, cache.latitude.values)
    eco = np.array([v[0] for v in R.sample(list(zip(xs, ys)))], dtype=int)
eco = np.where(np.isin(eco, [1, 2]), eco, 0)

y = oof.observed.values.astype(float); p = oof.oof_prob.values; w = oof.w.values
r = y - p; blk = oof.blk.values
d = pd.DataFrame({"y": y, "p": p, "w": w, "r": r, "blk": blk, "hold": hold, "eco": eco})

def wmean(x, w): return float(np.sum(w * x) / np.sum(w))
def wss(x, w): return float(np.sum(w * (x - wmean(x, w)) ** 2))

# ---- T1 variance partition
tot = wss(r, w)
def between_ss(g):
    s = 0.0
    for _, sub in d.groupby(g):
        s += np.sum(sub.w) * (wmean(sub.r.values, sub.w.values) - wmean(r, w)) ** 2
    return float(s)
ss_blk = between_ss("blk"); ss_eco = between_ss("eco")
# holder beyond block: SS of holder means after removing block means
d["r_b"] = d.r - d.groupby("blk").apply(lambda s: pd.Series(np.full(len(s), wmean(s.r.values, s.w.values)), index=s.index)).reset_index(level=0, drop=True)
def between_ss_resid(col, val):
    s = 0.0
    for _, sub in d.groupby(col):
        s += np.sum(sub.w) * (wmean(sub[val].values, sub.w.values) - wmean(d[val].values, w)) ** 2
    return float(s)
ss_hold_given_blk = between_ss_resid("hold", "r_b")
null = []
for _ in range(500):
    d["hp"] = d.groupby("blk").hold.transform(lambda s: rng.permutation(s.values))
    null.append(between_ss_resid("hp", "r_b"))
null = np.array(null)
p_hold = float((np.sum(null >= ss_hold_given_blk) + 1) / (len(null) + 1))
# ICC for holder (method of moments, weighted plot residuals, one way)
hs = d.groupby("hold").agg(n=("r", "size"), m=("r", "mean"), v=("r", "var"))
k = len(hs); N = len(d); n0 = (N - np.sum(hs.n ** 2) / N) / (k - 1)
msb = np.sum(hs.n * (hs.m - r.mean()) ** 2) / (k - 1); msw = np.sum((hs.n - 1) * hs.v.fillna(0)) / (N - k)
icc_hold = float(max(0.0, (msb - msw) / (msb + (n0 - 1) * msw)))

# ---- T2 block slope decomposition
def blocks(df, key):
    b = df.groupby(key).apply(lambda s: pd.Series({"n": len(s), "obs": wmean(s.y.values, s.w.values), "pred": wmean(s.p.values, s.w.values)}))
    return b[b.n >= 20]
def slope(b, wcol="n"):
    x = b.obs.values; z = b.pred.values; ww = b[wcol].values
    xm = np.average(x, weights=ww); zm = np.average(z, weights=ww)
    return float(np.sum(ww * (x - xm) * (z - zm)) / np.sum(ww * (x - xm) ** 2))
def boot_slope(b, B=2000):
    out = []
    for _ in range(B):
        i = rng.integers(0, len(b), len(b)); out.append(slope(b.iloc[i]))
    return [float(np.percentile(out, 2.5)), float(np.percentile(out, 97.5))]
B_all = blocks(d, "blk"); s_all = slope(B_all); ci_all = boot_slope(B_all)
B_hold = blocks(d, "hold"); s_between = slope(B_hold); ci_between = boot_slope(B_hold)
# within holder: block-by-holder cells, centered on holder means (n >= 20 cells)
d["cell"] = d.blk.astype(str) + "|" + d.hold.astype(str)
C = blocks(d, "cell")
C["hold"] = [c.split("|")[1] for c in C.index]
hm = d.groupby("hold").apply(lambda s: pd.Series({"ho": wmean(s.y.values, s.w.values), "hp": wmean(s.p.values, s.w.values)}))
hm.index = hm.index.astype(str)
C = C.join(hm, on="hold"); C["obs"] = C.obs - C.ho; C["pred"] = C.pred - C.hp
s_within = slope(C); ci_within = boot_slope(C)
# holder level residual summary, no per holder values: SD and IQR of the 38 holder mean residuals (n >= 20), count beyond +-2 SE
hr = d.groupby("hold").apply(lambda s: pd.Series({"n": len(s), "res": wmean(s.r.values, s.w.values), "obs": wmean(s.y.values, s.w.values)}))
hr = hr[hr.n >= 20]; hr["se"] = np.sqrt(hr.obs * (1 - hr.obs) / hr.n)
n_beyond = int(np.sum(np.abs(hr.res) > 2 * hr.se))

# ---- T3 support
boots = pickle.load(open(f"{BUILD}/rf_core4_boot_2026-09-25.pkl", "rb"))
X = cache[AE + ["time_since_disturbance"]].values if "time_since_disturbance" in cache.columns else None
if X is None:
    tt = pd.read_csv(f"{BUILD}/core4_training_table_DATA_2026-09-25.csv")
    tt = tt[tt.jurisdiction == "NB"].reset_index(drop=True); X = tt[AE + ["time_since_disturbance"]].values
PB = np.column_stack([m.predict_proba(X)[:, 1] for m in boots]); sd = PB.std(1); pm = PB.mean(1)
dec = pd.cut(pm, bins=[0, .05, .1, .15, .2, .3, .4, .5, .6, .8, 1.0], include_lowest=True)
T3 = []
for iv, sub in pd.DataFrame({"pm": pm, "sd": sd, "y": y, "dec": dec}).groupby("dec", observed=True):
    npos = int(sub.y.sum()); pbar = float(sub.pm.mean())
    T3.append({"p_bin": str(iv), "n": int(len(sub)), "n_pos": npos, "obs_rate": float(sub.y.mean()),
               "mean_ensemble_sd": float(sub.sd.mean()),
               "binomial_ref_sd": float(np.sqrt(pbar * (1 - pbar) / max(npos, 1)))})

# ---- T4 ecoregion
T4 = [{"ecoregion": ECO_NAMES[int(e)], "n": int(len(s)), "obs_rate_pct": 100 * wmean(s.y.values, s.w.values),
       "pred_rate_pct": 100 * wmean(s.p.values, s.w.values)} for e, s in d.groupby("eco")]

res = {"n_plots": int(len(d)), "n_positives": int(y.sum()), "n_blocks_ge20": int(len(B_all)), "n_holders_ge20": int(len(hr)),
       "T1_variance_partition": {"total_wss": tot, "share_block": ss_blk / tot, "share_ecoregion": ss_eco / tot,
                                 "share_holder_given_block": ss_hold_given_blk / tot,
                                 "share_holder_given_block_null_p95": float(np.percentile(null, 95)) / tot,
                                 "perm_p_holder_given_block": p_hold, "icc_holder_plot_residual": icc_hold},
       "T2_block_slope_pred_on_obs": {"all_blocks": [s_all] + ci_all, "between_holder": [s_between] + ci_between,
                                      "within_holder_cells": [s_within] + ci_within, "n_cells_within": int(len(C)),
                                      "holder_mean_residual_sd": float(hr.res.std()), "holder_mean_residual_iqr": float(hr.res.quantile(.75) - hr.res.quantile(.25)),
                                      "holders_beyond_2se": n_beyond},
       "T3_support_by_p_bin": T3, "T4_ecoregion": T4,
       "inputs_md5": {k: hashlib.md5(open(v, "rb").read()).hexdigest() for k, v in
                      {"oof": f"{BUILD}/s2_rf_oof_DATA_2026-09-25.csv", "boot_pkl": f"{BUILD}/rf_core4_boot_2026-09-25.pkl"}.items()},
       "script_md5": hashlib.md5(open(__file__, "rb").read()).hexdigest()}
json.dump(res, open(OUT, "w"), indent=2)
print(json.dumps(res, indent=2))
