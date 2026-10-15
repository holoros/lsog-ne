#!/usr/bin/env python3
"""
plot_rebuild_2026-10-13.py (track sae-refine). Runs on Cardinal only. True coordinates are read here and never
written. Rebuilds, per plot, the record's leave one H3 block out (LOBO) cross fitted probability exactly as
fhx_oof_2026-10-12.py (FHR_MODE=new) does, because that script kept only block sums.
Writes ONE restricted file with columns h3, y, o_lobo (no plot id, no PLT_CN, no coordinates), and an H3 ring 1
adjacency edge list for the 66 record blocks (block ids only).
Gates (hard exits): row, positive and coordinate counts as fhx_oof; per block n, npos, swo_lobo, swo2_lobo,
swyo_lobo equal fhx_blocks_ME_TRANS_DATA_2026-10-12.csv to 1e-9; 66 blocks in the adjacency.
"""
import os, sys, json, time
import numpy as np, pandas as pd, h3
from sklearn.ensemble import RandomForestClassifier
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
def die(m): log("GATE FAIL " + m); sys.exit(2)
def cell(lat, lng):
    return h3.latlng_to_cell(lat, lng, 4) if hasattr(h3, "latlng_to_cell") else h3.geo_to_h3(lat, lng, 4)
def ring1(c):
    return set(h3.grid_disk(c, 1)) if hasattr(h3, "grid_disk") else set(h3.k_ring(c, 1))
SEED = 20260917
L = os.path.expanduser("~/LSOG"); S = "/fs/scratch/PUOM0008/crsfaaron"
REC = f"{L}/2026-10-12_fh-relabel/out"
OUT = f"{L}/2026-10-13_sae-refine/out"
TAB = f"{S}/trans_10m/me-transitioning-10m_2026-10-12r/me_transitioning_training_table_DATA_2026-10-12.csv"
PLTCN = f"{S}/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
TRUEXY = f"{L}/data/validation_restricted/lsog_train_true.csv"
AE = [f"AE_{i:02d}" for i in range(64)]
nplots = json.load(open(f"{REC}/sae_block_prep_summary_ME_TRANS_2026-10-12.json"))["ME_TRANS"]["plots_used"]
EXP = (2977, 422, 2969, nplots)

t = pd.read_csv(TAB, dtype={"plot_id": str}, low_memory=False)
X = t[AE].to_numpy(float); y = (t.total_score >= 4).astype(int).to_numpy()
ship = t.time_since_disturbance.notna().to_numpy()
if len(t) != EXP[0] or int(y.sum()) != EXP[1] or int(ship.sum()) != EXP[2]:
    die(f"rows {len(t)} positives {int(y.sum())} shipped {int(ship.sum())}, expected {EXP[:3]}")
if not (y == t.trans_cut4.to_numpy(int)).all(): die("y is not trans_cut4")
jj = pd.read_csv(PLTCN, dtype=str); xy = pd.read_csv(TRUEXY, dtype={"plot_id": str})
dd = (pd.DataFrame({"plot_id": t.plot_id.astype(str).values}).merge(jj[["plot_id", "PLT_CN"]], on="plot_id", how="left")
      .merge(xy[["plot_id", "lon", "lat"]].rename(columns={"plot_id": "PLT_CN"}), on="PLT_CN", how="left"))
if len(dd) != len(t): die("coordinate join changed the row count")
has = np.isfinite(dd.lat.values)
hc = np.array([cell(a, b) if ok else "" for a, b, ok in zip(dd.lat.values, dd.lon.values, has)], dtype=object)
del dd, xy, jj
if int(has.sum()) != EXP[3]: die(f"plots with coordinates {int(has.sum())}, expected {EXP[3]}")
log(f"GATE PASS counts {EXP}")

def rf(n, seed=SEED):
    return RandomForestClassifier(n_estimators=n, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=seed)
oof = np.full(len(t), np.nan)
blocks = sorted(set(hc[has]))
for i, b in enumerate(blocks):
    te = has & (hc == b); tr = ship & ~te
    oof[te] = rf(500).fit(X[tr], y[tr]).predict_proba(X[te])[:, 1]
    if (i + 1) % 10 == 0: log(f"  lobo {i+1} of {len(blocks)}")
D = pd.DataFrame({"h3": hc[has], "y": y[has], "o_lobo": oof[has]})
if D.o_lobo.isna().any(): die("unpredicted plots")
G = D.assign(o2=D.o_lobo**2, yo=D.y*D.o_lobo).groupby("h3").agg(n=("y", "size"), npos=("y", "sum"),
        swo=("o_lobo", "sum"), swo2=("o2", "sum"), swyo=("yo", "sum")).reset_index()
R = pd.read_csv(f"{REC}/fhx_blocks_ME_TRANS_DATA_2026-10-12.csv", dtype={"h3": str})
C = G.merge(R[["h3", "n", "npos", "swo_lobo", "swo2_lobo", "swyo_lobo"]], on="h3")
if len(C) != len(G) or len(G) != len(R): die(f"block sets differ {len(G)} {len(R)} {len(C)}")
d = max(float(np.abs(C.n_x - C.n_y).max()), float(np.abs(C.npos_x - C.npos_y).max()),
        float(np.abs(C.swo - C.swo_lobo).max()), float(np.abs(C.swo2 - C.swo2_lobo).max()), float(np.abs(C.swyo - C.swyo_lobo).max()))
log(f"block sums vs record fhx_blocks: max abs diff {d:.3e}")
if d > 1e-9: die("LOBO plot predictions do not reproduce the record block sums")
log("GATE PASS per plot LOBO reproduces record block sums")
os.umask(0o077)
D.sample(frac=1.0, random_state=1).to_csv(f"{OUT}/plot_lobo_RESTRICTED.csv", index=False)  # shuffled, no ids
# adjacency over the 66 record blocks
B = pd.read_csv(f"{REC}/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv", dtype={"h3": str})
bs = set(B.h3)
if len(bs) != 66: die(f"record has {len(bs)} blocks")
E = [(a, c) for a in sorted(bs) for c in sorted(ring1(a) & bs) if c != a]
pd.DataFrame(E, columns=["h3_a", "h3_b"]).to_csv(f"{OUT}/h3_ring1_adjacency_66.csv", index=False)
deg = pd.Series([a for a, _ in E]).value_counts().reindex(sorted(bs), fill_value=0)
log(f"adjacency edges {len(E)} (directed), degree min {deg.min()} median {deg.median()} max {deg.max()}, isolated {(deg==0).sum()}")
json.dump({"max_abs_diff_block_sums": d, "n_plots": int(len(D)), "n_blocks_with_plots": len(blocks),
           "edges_directed": len(E), "isolated_blocks": int((deg == 0).sum())}, open(f"{OUT}/plot_rebuild_summary.json", "w"), indent=1)
log("REBUILD_DONE")
