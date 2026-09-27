#!/usr/bin/env python3
"""
New Brunswick Stage A, TRANSITIONING AND ABOVE on LICENSED MagPlot labels, 2026-09-27.

Reuses the 25 September licensed CORE4 Stage A extraction unchanged (same 9,042 plots, same AlphaEarth
2024 rows at the licensed coordinates, same Hansen time since disturbance, same H3 blocks and CLI_Grid
weights) and swaps only the label: the five axis licensed score from nb_cli_lsog_fullscope.score_plots,
total_score >= 4, the Configuration D any-LSOG instrument (31.47 [29.17, 33.31]).
Positive controls before anything is written: the unweighted rate must reproduce the published 9,042
basis score distribution (31.30 percent at >= 4 on the PUBLISHED rows), every cached plot must score, and
the cache order must match the CORE4 table row for row. No coordinate or licensed id leaves Cardinal.
"""
import os, sys, json, time
import numpy as np, pandas as pd
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ; BUILD = E["BUILD"]
os.makedirs(f"{BUILD}/inputs", exist_ok=True); os.makedirs(f"{BUILD}/logs", exist_ok=True)
BASE = "/users/PUOM0008/crsfaaron/LSOG/nb_magplot"
sys.path.insert(0, BASE)
import nb_cli_lsog_fullscope as P
SUM = {"date": "2026-09-27", "label": "licensed five axis total_score >= 4 (Configuration D any-LSOG)"}

cache = pd.read_csv(E["CORE4_CACHE"])
tab = pd.read_csv(E["CORE4_TABLE"]); nbt = tab[tab.jurisdiction == "NB"].reset_index(drop=True)
assert len(cache) == len(nbt) == 9042, (len(cache), len(nbt))
assert (cache.core4_cut3.values == nbt.core4_cut3.values).all(), "cache order does not match the CORE4 table"
log("cache and CORE4 table aligned, 9,042 rows")

lab = P.score_plots(f"{P.CLI}/magp_trees.csv", f"{P.CLI}/magp_tree_header.csv", "CLI licensed")
lab = lab[[P.KEY, "total_score", "any_lsog"]].drop_duplicates(P.KEY)
m = cache[[P.KEY]].merge(lab, on=P.KEY, how="left")
assert len(m) == 9042 and m.any_lsog.notna().all(), f"{int(m.any_lsog.isna().sum())} cached plots did not score"
y = m.any_lsog.astype(int).values
rate = 100 * y.mean()
log(f"licensed transitioning and above, unweighted {rate:.3f} percent, {int(y.sum())} positives")
assert abs(rate - 31.30) < 0.8, "unweighted rate drifted from the published 9,042 basis distribution"
dist = pd.Series(m.total_score.astype(int)).value_counts().sort_index()
SUM["score_distribution_n"] = {int(k): int(v) for k, v in dist.items()}
SUM["n"] = 9042; SUM["positives"] = int(y.sum()); SUM["rate_unweighted_pct"] = round(rate, 3)
SUM["rate_weighted_pct"] = round(100 * float(np.average(y, weights=nbt.w.values)), 3)
ct = pd.crosstab(nbt.core4_cut3.values, y)
SUM["crosstab_core4_by_trans"] = {f"core4_{i}_trans_{j}": int(ct.loc[i, j]) for i in ct.index for j in ct.columns}
log(f"weighted {SUM['rate_weighted_pct']}; crosstab {SUM['crosstab_core4_by_trans']}")

c2 = cache.drop(columns=["core4_cut3"]).copy(); c2["trans_ge4"] = y
CO = f"{BUILD}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"
c2.to_csv(CO, index=False); os.chmod(CO, 0o600)
out = nbt.drop(columns=["core4_cut3"]).copy(); out["trans_ge4"] = y
out.to_csv(f"{BUILD}/trans_training_table_DATA_2026-09-27.csv", index=False)
json.dump(SUM, open(f"{BUILD}/s1_prep_summary_2026-09-27.json", "w"), indent=2)
log("S1_DONE")
