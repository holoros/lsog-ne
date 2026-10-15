#!/usr/bin/env python3
# t2_slope_ref.py (October 12, 2026). G7b of s4 regresses block-mean OBSERVED label on block-mean MAPPED probability
# (np.polyfit(pred, obs)), with no minimum block size, but BLOCK_SLOPE_REF was taken from Stage A slopes(), which
# regresses PREDICTED on OBSERVED for blocks of at least 5 plots. This recomputes the Stage A out-of-fold reference in the
# s4 direction and grouping, with a 2,000-replicate block bootstrap (seed 20260917), for the relabelled fit and, as a
# check on the September gate, for the earlier labels on the same plots. Aggregates only.
import numpy as np, pandas as pd, json
O = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_trans-relabel/out"
o = pd.read_csv(f"{O}/t1_oof_RESTRICTED.csv")
t = pd.read_csv("/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r/me_transitioning_training_table_DATA_2026-10-12.csv", usecols=["plot_id", "spatial_block"])
o = o.merge(t, on="plot_id")
def s4slope(y, p, b):
    g = pd.DataFrame({"y": y, "p": p, "b": b}).groupby("b").agg(obs=("y", "mean"), pred=("p", "mean"))
    return float(np.polyfit(g.pred, g.obs, 1)[0]) if len(g) > 2 else np.nan
res = {}
for lab, yc, pc in [("relabel_jobA", "y_new", "oof_new"), ("step1_sameplots", "y_old", "oof_old")]:
    y, p, b = o[yc].to_numpy(), o[pc].to_numpy(), o.spatial_block.to_numpy()
    pt = s4slope(y, p, b); ub = np.unique(b); r = np.random.default_rng(20260917); R = []
    for _ in range(2000):
        pick = r.choice(ub, len(ub), replace=True)
        idx = np.concatenate([np.where(b == q)[0] for q in pick]); bb = np.concatenate([np.full((b == q).sum(), i) for i, q in enumerate(pick)])
        s = s4slope(y[idx], p[idx], bb)
        if np.isfinite(s): R.append(s)
    res[lab] = dict(slope=round(pt, 4), ci=[round(float(np.percentile(R, 2.5)), 4), round(float(np.percentile(R, 97.5)), 4)], n_blocks=int(len(ub)), n_plots=int(len(y)))
print(json.dumps(res, indent=1)); json.dump(res, open(f"{O}/agg/t2_g7b_reference_DATA_2026-10-12.json", "w"), indent=1)
