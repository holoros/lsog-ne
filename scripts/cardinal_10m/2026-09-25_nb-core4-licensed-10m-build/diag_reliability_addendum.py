#!/usr/bin/env python3
"""T5 addendum to nb_block_residual_structure_2026-09-25.json: reliability of the NB block rates and
the disattenuated block slope, computed exactly as Stage A did for Maine (s2 convention: unweighted
regression of predicted on observed block rates, blocks with >= 20 plots, block bootstrap 2000).
reliability = 1 - mean_b[obs_b (1 - obs_b) / n_b] / var_b(obs_b); slope_dis = slope / reliability."""
import json, numpy as np, pandas as pd
BUILD = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/nb-core4-licensed-10m_2026-09-25"
J = f"{BUILD}/nb_block_residual_structure_2026-09-25.json"
rng = np.random.default_rng(20260925)
o = pd.read_csv(f"{BUILD}/s2_rf_oof_DATA_2026-09-25.csv"); o = o[o.jurisdiction == "NB"]
bt = pd.DataFrame({"blk": o.blk, "y": o.observed * o.w, "p": o.oof_prob * o.w, "w": o.w, "n": 1}).groupby("blk").sum()
bt = bt[bt.n >= 20]; obs = (bt.y / bt.w).to_numpy(); pred = (bt.p / bt.w).to_numpy(); n = bt.n.to_numpy()
def sl(i): return float(np.polyfit(obs[i], pred[i], 1)[0])
def rel(i):
    v = np.var(obs[i], ddof=1); e = np.mean(obs[i] * (1 - obs[i]) / n[i]); return float(1 - e / v)
idx = np.arange(len(obs)); s0 = sl(idx); r0 = rel(idx)
draws = [rng.integers(0, len(obs), len(obs)) for _ in range(2000)]
S = np.array([sl(i) for i in draws]); R = np.array([rel(i) for i in draws]); D = S / np.clip(R, 0.05, None)
res = json.load(open(J))
res["T5_reliability_disattenuation_s2_convention"] = {
    "n_blocks": int(len(obs)), "slope_pred_on_obs": s0, "slope_ci": [float(np.percentile(S, 2.5)), float(np.percentile(S, 97.5))],
    "reliability_block_rates": r0, "reliability_ci": [float(np.percentile(R, 2.5)), float(np.percentile(R, 97.5))],
    "slope_disattenuated": s0 / r0, "slope_disattenuated_ci": [float(np.percentile(D, 2.5)), float(np.percentile(D, 97.5))],
    "mean_block_n": float(n.mean()), "sd_obs_block_rates": float(np.std(obs, ddof=1)),
    "maine_reference": {"slope": 0.7233, "reliability": 0.8175, "slope_disattenuated": 0.8847, "n_blocks": 10}}
json.dump(res, open(J, "w"), indent=2); print(json.dumps(res["T5_reliability_disattenuation_s2_convention"], indent=2))
