#!/usr/bin/env python3
"""
2026-09-25_model-disclosure-risk_DATA.py

Can the fitted random forest be deposited without exposing FIA plot locations?

The concern, stated precisely. FIA true plot coordinates are restricted. The model was fitted on 64
AlphaEarth band values extracted AT those true coordinates. AlphaEarth 2024 is a public global
raster. A decision tree's split thresholds are constraints on those same band values, so in
principle an attacker could read a leaf's constraints, search the public raster for cells satisfying
them, and narrow the candidates for a training plot's location. Whether that is a real exposure or a
theoretical one depends on a property of the fitted model that nobody has measured: how many
training plots share a leaf, and how distinguishable one plot is from another inside the forest.

If leaves are singletons, the forest has memorised individual plots and each one is a distinct
target. If leaves routinely hold several plots, a leaf's constraints identify a group, not a plot,
and the exposure is bounded by the group size.

Three measurements, none of which needs the raster:

  M1  HYPERPARAMETERS. min_samples_leaf is decisive on its own. At the sklearn default of 1,
      singleton leaves are permitted by construction.
  M2  LEAF OCCUPANCY. Apply the forest to the training rows and count, across every tree and leaf,
      how many training plots land together. Report the share of plot-leaf assignments that are
      singletons and the occupancy distribution.
  M3  WITHIN-FOREST DISTINGUISHABILITY, the statistic that matters. For each training plot, the
      random forest proximity to every other training plot is the fraction of trees placing them in
      the same leaf. A plot whose highest proximity to any other plot is near 1.0 is hidden inside a
      group. A plot whose highest proximity is low is individually distinguishable, and it is those
      plots an attacker could target. Report the distribution of each plot's maximum proximity and
      the count of plots that are effectively alone.

PRIVACY. Reads the training table's band values on Cardinal. Writes only distributions and counts.
No coordinate, no plot identifier and no band value leaves this script.
"""
import os, sys, json, pickle
import numpy as np, pandas as pd

E = os.environ
B = E["BUILD"]
OUT = os.path.join(B, "disclosure_2026-09-25"); os.makedirs(OUT, exist_ok=True)
SEED = 20260925
rng = np.random.default_rng(SEED)

tt = pd.read_csv(E["TRAIN_TABLE"], dtype={"plot_id": str})
aec = [f"AE_{i:02d}" for i in range(64)]
X = tt[aec].to_numpy()
n = X.shape[0]
print(f"training rows {n}, features {X.shape[1]}", flush=True)

res = {"date": "2026-09-25", "n_training_rows": int(n)}

# ---- M1 hyperparameters -----------------------------------------------------------------------
mdl = pickle.load(open(E["MODEL_FINAL"], "rb"))
hp = {k: getattr(mdl, k, None) for k in
      ("n_estimators", "max_depth", "min_samples_leaf", "min_samples_split",
       "max_features", "class_weight", "bootstrap", "random_state")}
hp = {k: (v if isinstance(v, (int, float, str, bool, type(None))) else str(v)) for k, v in hp.items()}
res["M1_hyperparameters"] = hp
print("M1", json.dumps(hp), flush=True)

# ---- M2 leaf occupancy ------------------------------------------------------------------------
L = mdl.apply(X)                          # (n, n_trees) leaf index per tree
ntree = L.shape[1]
singles = 0; total = 0; occ_hist = {}
for t in range(ntree):
    _, counts = np.unique(L[:, t], return_counts=True)
    for c in counts:
        occ_hist[int(c)] = occ_hist.get(int(c), 0) + 1
    # each plot's leaf occupancy in this tree
    occ = counts[np.searchsorted(np.unique(L[:, t]), L[:, t])]
    singles += int((occ == 1).sum()); total += n
res["M2_leaf_occupancy"] = {
    "n_trees": int(ntree),
    "share_of_plot_leaf_assignments_that_are_singletons": round(singles / total, 4),
    "leaf_size_histogram_leafsize_to_count": {str(k): v for k, v in sorted(occ_hist.items())[:20]},
    "median_leaf_size": float(np.median(np.repeat(list(occ_hist.keys()),
                                                  list(occ_hist.values())))),
}
print("M2", json.dumps(res["M2_leaf_occupancy"])[:400], flush=True)

# ---- M3 within-forest distinguishability -------------------------------------------------------
# proximity(i, j) = share of trees where i and j share a leaf. Computed per tree with bincount so
# the full n x n matrix is never held for all trees at once.
prox = np.zeros((n, n), dtype=np.uint16)
for t in range(ntree):
    col = L[:, t]
    order = np.argsort(col, kind="stable")
    s = col[order]
    bounds = np.flatnonzero(np.r_[True, s[1:] != s[:-1], True])
    for a, b in zip(bounds[:-1], bounds[1:]):
        if b - a > 1:
            idx = order[a:b]
            prox[np.ix_(idx, idx)] += 1
    if t % 100 == 0: print(f"  proximity tree {t}/{ntree}", flush=True)
np.fill_diagonal(prox, 0)
pmax = prox.max(axis=1) / ntree
n_ge = {f"n_plots_with_max_proximity_ge_{q}": int((pmax >= q).sum()) for q in (0.9, 0.75, 0.5, 0.25)}
res["M3_distinguishability"] = {
    "median_max_proximity": float(np.median(pmax)),
    "p05_max_proximity": float(np.percentile(pmax, 5)),
    "min_max_proximity": float(pmax.min()),
    **n_ge,
    "n_plots_effectively_alone_max_prox_lt_0p25": int((pmax < 0.25).sum()),
    "note": ("max proximity is the share of the forest's 500 trees placing a plot in the same leaf "
             "as its single closest other training plot. High means the plot is hidden inside a "
             "group of indistinguishable plots. Low means it is individually targetable."),
}
print("M3", json.dumps(res["M3_distinguishability"]), flush=True)

pd.DataFrame({"max_proximity": np.round(pmax, 4)}).to_csv(
    os.path.join(OUT, "max_proximity_distribution_DATA_2026-09-25.csv"), index=False)
json.dump(res, open(os.path.join(OUT, "model_disclosure_risk_2026-09-25.json"), "w"), indent=2)
print("DISCLOSURE_RISK_DONE", flush=True)
