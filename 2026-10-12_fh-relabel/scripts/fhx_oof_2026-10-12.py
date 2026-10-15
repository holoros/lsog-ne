#!/usr/bin/env python3
"""
fhx_oof_2026-10-12.py: copy of fhx_oof_2026-10-05.py (track fh-relabel). Changed: paths and date tags; FHR_MODE
old reads the October 5 inputs (reproduction gate), new reads the October 12 relabelled table and
rf_trans_final_2026-10-12.pkl. The fixed row and positive counts of the old inputs are kept for old and replaced
for new by the relabelled counts (2,977 rows, 422 positives, 2,969 with time since disturbance) and by the
plot count the copied prep recorded. The sb gate now checks the copied prep of the same mode.
Original docstring follows.
fhx_oof_2026-10-05.py  (track fh-crossfit). Runs on Cardinal only; true coordinates are read here and
never written. Output is BLOCK AGGREGATES (H3 resolution 4) kept on Cardinal.

Purpose: a cross fitted block covariate for the Maine transitioning and above Fay-Herriot fit of
2026-09-27. The published FH used the block mean of the shipped 10 m surface, whose model was fit to the
same FIA plots that form the direct estimates. Here, for every block, the covariate is the mean
probability at that block's plots from a model that never saw that block's plots.

Learner: the shipped Stage A form (2026-09-23_me-transitioning-10m-stageA_DATA.py): RandomForest,
64 AlphaEarth bands, min_samples_leaf 3, max_features sqrt, 500 trees (FINAL_NTREE), seed 20260917,
trained on the shipped 3,015 plot sample (rows with time_since_disturbance present). The 10 m map is not
rebuilt and no map cell is re-predicted.

Variants, each written as block sums sw, swo, swo2, swyo:
  sb    the 2026-09-27 prep OOF, reproduced exactly (5 fold GroupKFold on spatial_block, 300 trees,
        all 3,062 rows). Gate: its block sums equal the prep file to 1e-9.
  lobo  leave one H3 block out: one fit per block with plots, that block's plots held out (primary).
  k5    5 fold GroupKFold on H3 blocks (sensitivity).
  ins   the shipped final model pickle predicted at the plots (in sample reference).
Plots without true coordinates (39) cannot be assigned to a block; they stay in every training set
(they were in the shipped training set) and in no held out set.
"""
import os, sys, json, time, pickle, hashlib
import numpy as np, pandas as pd
import h3
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import GroupKFold
from sklearn.metrics import roc_auc_score

T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
def die(m): log("GATE FAIL " + m); sys.exit(2)
def cell(lat, lng):
    return h3.latlng_to_cell(lat, lng, 4) if hasattr(h3, "latlng_to_cell") else h3.geo_to_h3(lat, lng, 4)

SEED = 20260917
L = os.path.expanduser("~/LSOG"); S = "/fs/scratch/PUOM0008/crsfaaron"
MODE = os.environ.get("FHR_MODE", "new")
if MODE not in ("old", "new"): raise SystemExit("FHR_MODE must be old or new")
FHR = os.path.expanduser("~/LSOG/2026-10-12_fh-relabel/out")
OUT = FHR if MODE == "new" else f"{FHR}/repro_old"
os.makedirs(OUT, exist_ok=True)
TAB = {"old": f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv",
       "new": "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r/me_transitioning_training_table_DATA_2026-10-12.csv"}[MODE]
PLTCN = f"{S}/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
TRUEXY = f"{L}/data/validation_restricted/lsog_train_true.csv"
FINAL = {"old": f"{S}/trans_10m/me-transitioning-10m_2026-09-23/rf_trans_final_2026-09-23.pkl",
         "new": "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-10-12r/rf_trans_final_2026-10-12.pkl"}[MODE]
PREP = f"{OUT}/sae_blocks_ME_TRANS_DATA_2026-10-12.csv"
EXP = {"old": (3062, 418, 3015, 3023),
       "new": (2977, 422, 2969, json.load(open(f"{OUT}/sae_block_prep_summary_ME_TRANS_2026-10-12.json"))["ME_TRANS"]["plots_used"])}[MODE]
AE = [f"AE_{i:02d}" for i in range(64)]

def md5(p):
    h = hashlib.md5()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""): h.update(b)
    return h.hexdigest()

t = pd.read_csv(TAB, dtype={"plot_id": str}, low_memory=False)
log(f"table {len(t)} rows, md5 {md5(TAB)}")
X = t[AE].to_numpy(float); y = (t.total_score >= 4).astype(int).to_numpy()
ship = t.time_since_disturbance.notna().to_numpy()
if len(t) != EXP[0] or int(y.sum()) != EXP[1] or int(ship.sum()) != EXP[2]:
    die(f"rows {len(t)} positives {int(y.sum())} shipped {int(ship.sum())}, expected {EXP[:3]}")
if MODE == "new" and not (y == t.trans_cut4.to_numpy(int)).all(): die("y is not the jobA trans_cut4")
log(f"GATE PASS {EXP[0]} rows, {EXP[1]} positives, {EXP[2]} shipped sample")

# true coordinates, same join as sae_block_prep.py me_xy
jj = pd.read_csv(PLTCN, dtype=str); xy = pd.read_csv(TRUEXY, dtype={"plot_id": str})
dd = (pd.DataFrame({"plot_id": t.plot_id.astype(str).values}).merge(jj[["plot_id", "PLT_CN"]], on="plot_id", how="left")
      .merge(xy[["plot_id", "lon", "lat"]].rename(columns={"plot_id": "PLT_CN"}), on="PLT_CN", how="left"))
if len(dd) != len(t): die("coordinate join changed the row count")
has = np.isfinite(dd.lat.values)
hc = np.array([cell(a, b) if ok else "" for a, b, ok in zip(dd.lat.values, dd.lon.values, has)], dtype=object)
del dd, xy, jj
log(f"plots with coordinates {int(has.sum())}, without {int((~has).sum())}")
if int(has.sum()) != EXP[3]: die(f"expected {EXP[3]} plots with coordinates as in the prep, got {int(has.sum())}")

def rf(n, seed=SEED):
    return RandomForestClassifier(n_estimators=n, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=seed)

P = {}
# sb: exact reproduction of the prep OOF
oof = np.full(len(t), np.nan)
for tr, te in GroupKFold(n_splits=5).split(X, groups=t.spatial_block.to_numpy()):
    oof[te] = rf(300).fit(X[tr], y[tr]).predict_proba(X[te])[:, 1]
P["sb"] = oof; log(f"sb AUC all rows {roc_auc_score(y, oof):.4f}")

# lobo: one fit per H3 block
oof = np.full(len(t), np.nan)
blocks = sorted(set(hc[has]))
for i, b in enumerate(blocks):
    te = has & (hc == b); tr = ship & ~te
    oof[te] = rf(500).fit(X[tr], y[tr]).predict_proba(X[te])[:, 1]
    if (i + 1) % 10 == 0: log(f"  lobo {i+1} of {len(blocks)}")
P["lobo"] = oof
# k5: 5 fold over H3 blocks
oof = np.full(len(t), np.nan)
idx = np.flatnonzero(has)
for tr_i, te_i in GroupKFold(n_splits=5).split(X[idx], groups=hc[idx]):
    te = np.zeros(len(t), bool); te[idx[te_i]] = True
    tr = ship & ~te
    oof[te] = rf(500).fit(X[tr], y[tr]).predict_proba(X[te])[:, 1]
P["k5"] = oof
# ins: shipped final model at its own training plots
final = pickle.load(open(FINAL, "rb"))
if final.n_features_in_ != 64: die("final model is not 64 feature")
P["ins"] = final.predict_proba(X)[:, 1]
log(f"final model md5 {md5(FINAL)}")

summ = {"seed": SEED, "n_rows": int(len(t)), "n_with_coords": int(has.sum()), "n_blocks_with_plots": len(blocks)}
for k, v in P.items():
    m = has & np.isfinite(v)
    summ[f"auc_{k}"] = float(roc_auc_score(y[m], v[m])); summ[f"mean_{k}_pct"] = float(100 * v[m].mean())
    summ[f"auc_{k}_shipped_rows"] = float(roc_auc_score(y[m & ship], v[m & ship]))
summ["obs_pct_with_coords"] = float(100 * y[has].mean())
log(json.dumps(summ))

D = pd.DataFrame({"h3": hc[has], "y": y[has], "ship": ship[has].astype(int)})
for k, v in P.items():
    D[f"o_{k}"] = v[has]
    if np.isnan(D[f"o_{k}"]).any(): die(f"variant {k} left plots unpredicted")
agg = {"n": ("y", "size"), "npos": ("y", "sum"), "n_ship": ("ship", "sum")}
for k in P:
    D[f"o2_{k}"] = D[f"o_{k}"] ** 2; D[f"yo_{k}"] = D.y * D[f"o_{k}"]
    agg.update({f"swo_{k}": (f"o_{k}", "sum"), f"swo2_{k}": (f"o2_{k}", "sum"), f"swyo_{k}": (f"yo_{k}", "sum")})
G = D.groupby("h3").agg(**agg).reset_index()
G["sw"] = G.n.astype(float); G["swy"] = G.npos.astype(float)

pr = pd.read_csv(PREP, dtype={"h3": str}); pr = pr[pr.n.notna()]
C = G.merge(pr[["h3", "n", "swo", "swy"]], on="h3", suffixes=("", "_prep"))
if len(C) != len(G) or len(G) != len(pr): die(f"block sets differ: new {len(G)} prep {len(pr)} matched {len(C)}")
dn = float(np.abs(C.n - C.n_prep).max()); dy = float(np.abs(C.swy - C.swy_prep).max()); do = float(np.abs(C.swo_sb - C.swo).max())
log(f"prep reproduction: max |dn| {dn}, max |dswy| {dy}, max |dswo| {do:.3e}")
if dn > 0 or dy > 0 or do > 1e-9: die("the prep OOF is not reproduced; block sums differ")
summ["prep_reproduced_max_abs_swo_diff"] = do
log("GATE PASS prep block sums reproduced exactly")

G.to_csv(f"{OUT}/fhx_blocks_ME_TRANS_DATA_2026-10-12.csv", index=False)
json.dump(summ, open(f"{OUT}/fhx_oof_summary_2026-10-12.json", "w"), indent=1)
log("OOF_DONE")
