#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s2_fit_compare_occv2: copy of s2_fit_compare.py on the V2 OCC points (October 7, 2026); every output carries _occv2.
# s2_fit_compare.py  Ordinal (Frank and Hall cumulative) random forest on pooled OCC + Maine FIA labels,
# grouped out of fold evaluation, and the multi map comparison at the OCC points.
# Classes: 0 Not LSOG < 1 Transitioning LS < 2 LS < 3 OG. Layers: P(>=1), P(>=2) = Type 2 pool, P(3) = Type 1.
# Only aggregates are written to the shareable out/agg folder. No coordinates are read by this script.
import os, json, pickle, numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt

E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; os.makedirs(AGG, exist_ok=True)
SEED = 20261006; rng = np.random.default_rng(SEED)
NT = int(E.get("NTREE", "500")); LEAF = int(E.get("LEAF", "3"))
AEC = [f"AE_{k:02d}" for k in range(64)]
log = open(f"{AGG}/s2_log_occv2.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

occ = pd.read_csv(f"{OUT}/occ_points_ae_maps_occv2_RESTRICTED.csv")
fia = pd.read_csv(E["TRAIN_TABLE"])
fia = fia[fia.state == "ME"].copy()
CMAP_O = {"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}
CMAP_F = {"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3}
occ["y"] = occ.occ_class.map(CMAP_O); fia["y"] = fia.lsog_class.map(CMAP_F)
assert occ.y.notna().all() and fia.y.notna().all(), "unmapped class label"
L("FIA trans_cut4 vs y>=1 crosstab:\n" + pd.crosstab(fia.trans_cut4, fia.y >= 1).to_string())
occ = occ[np.isfinite(occ[AEC]).all(1)].copy()
fia = fia[np.isfinite(fia[AEC]).all(1)].copy()
occ["grp"] = "O" + occ.site.astype(str); fia["grp"] = "F" + fia.spatial_block.astype(str)
occ["src"] = "OCC"; fia["src"] = "FIA"; fia["occ_id"] = fia.plot_id
D = pd.concat([occ[["occ_id", "src", "grp", "y"] + AEC], fia[["occ_id", "src", "grp", "y"] + AEC]], ignore_index=True)
L(f"pooled n = {len(D)}; by source and class:\n" + pd.crosstab(D.src, D.y).to_string())
X = D[AEC].values.astype("float32"); y = D.y.values.astype(int)

def fit_cum(Xt, yt, seed):
    ms = []
    for k in (1, 2, 3):
        m = RandomForestClassifier(n_estimators=NT, min_samples_leaf=LEAF, max_features="sqrt",
                                   n_jobs=-1, random_state=seed + k)
        m.fit(Xt, (yt >= k).astype(int)); ms.append(m)
    return ms
def pred_cum(ms, Xn):
    p = np.column_stack([m.predict_proba(Xn)[:, 1] for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1])
    return p

# out of fold, grouped by FIA spatial block and OCC 2 km site, stratified on class
OOF = np.full((len(D), 3), np.nan)
cv = StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=SEED)
for f, (tr, te) in enumerate(cv.split(X, y, D.grp)):
    OOF[te] = pred_cum(fit_cum(X[tr], y[tr], SEED + 10 * f), X[te])
    L(f"fold {f}: test n={len(te)}, OG in test={int((y[te] == 3).sum())}")
D[["new_ge1", "new_ge2", "new_og"]] = OOF

def auc_ci(yb, s, g, B=2000):
    ok = np.isfinite(s); yb, s, g = yb[ok], s[ok], g[ok]
    if yb.sum() == 0 or yb.sum() == len(yb): return (np.nan,) * 3 + (len(yb), int(yb.sum()))
    a = roc_auc_score(yb, s); ug = np.unique(g); idx = {u: np.where(g == u)[0] for u in ug}; bs = []
    for _ in range(B):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], s[ii]))
    return a, np.percentile(bs, 2.5), np.percentile(bs, 97.5), len(yb), int(yb.sum())

O = D[D.src == "OCC"].merge(occ[["occ_id", "occ_class", "project", "m30_tolscore", "m10_core4", "m10_trans", "m10_trans_sd", "m10_trans_env"]], on="occ_id")
CONTR = {"Trans+ vs Not": (lambda yy: yy >= 1, None, "new_ge1"),
         "Type 2 pool (LS+OG) vs rest": (lambda yy: yy >= 2, None, "new_ge2"),
         "Type 1 (OG) vs rest": (lambda yy: yy == 3, None, "new_og"),
         "Type 1 (OG) vs LS": (lambda yy: yy == 3, lambda yy: yy >= 2, "new_og")}
MAPS = {"30 m tolerance score (Sep 4)": "m30_tolscore", "10 m CORE4 (Sep 16)": "m10_core4",
        "10 m transitioning (Sep 23, Zenodo)": "m10_trans"}
rows = []
for cname, (fy, fsub, newcol) in CONTR.items():
    sub = O if fsub is None else O[fsub(O.y.values)]
    yb = fy(sub.y.values).astype(int); g = sub.grp.values
    for mlab, col in list(MAPS.items()) + [("New ordinal, out of fold", newcol)]:
        a, lo, hi, n, npos = auc_ci(yb, sub[col].values.astype(float), g)
        rows.append(dict(contrast=cname, map=mlab, auc=a, lo=lo, hi=hi, n=n, n_pos=npos))
A = pd.DataFrame(rows); A.to_csv(f"{AGG}/occ_multimap_auc_DATA_occv2.csv", index=False)
L("AUC at OCC points (site cluster bootstrap 95% CI):\n" + A.round(3).to_string(index=False))

# FIA out of fold, for comparison with the shipped transitioning AUC
F = D[D.src == "FIA"]
for k, col in ((1, "new_ge1"), (2, "new_ge2"), (3, "new_og")):
    a, lo, hi, n, npos = auc_ci((F.y.values >= k).astype(int), F[col].values, F.grp.values, B=500)
    L(f"FIA OOF AUC y>={k}: {a:.3f} [{lo:.3f}, {hi:.3f}] n={n} pos={npos}")

# class summaries and the cutoffs John and Aaron discussed
S = O.groupby("occ_class")[["m30_tolscore", "m10_core4", "m10_trans", "new_ge1", "new_ge2", "new_og"]].median()
S.to_csv(f"{AGG}/occ_class_median_scores_DATA_occv2.csv"); L("median score by OCC class:\n" + S.round(3).to_string())
cut = []
for col in ("m10_core4", "m10_trans"):
    for c in (0.06, 0.297):
        cut.append({"map": col, "cut": c, **{k: float((v[col] > c).mean()) for k, v in O.groupby("occ_class")}})
C = pd.DataFrame(cut); C.to_csv(f"{AGG}/occ_cut_capture_DATA_occv2.csv", index=False)
L("share of each OCC class above a cut:\n" + C.round(3).to_string(index=False))
L(f"extrapolation flag set at {int((O.m10_trans_env == 1).sum())} of {int(O.m10_trans_env.notna().sum())} OCC points")
L("map coverage at OCC points: " + str({c: int(O[c].notna().sum()) for c in MAPS.values()}) + f" of {len(O)}")

# final model on all pooled data, for prediction
ms = fit_cum(X, y, SEED)
pickle.dump(ms, open(f"{OUT}/rf_ordinal_final_occv2.pkl", "wb"))
np.save(f"{OUT}/env_min_occv2.npy", X.min(0)); np.save(f"{OUT}/env_max_occv2.npy", X.max(0))
O[["occ_id", "occ_class", "project", "grp", "new_ge1", "new_ge2", "new_og", "m30_tolscore", "m10_core4", "m10_trans"]].to_csv(
    f"{OUT}/occ_oof_scores_occv2_RESTRICTED.csv", index=False)

# Figure: AUC forest plot plus score distributions by OCC class
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9})
fig, ax = plt.subplots(1, 2, figsize=(10, 4.6), gridspec_kw={"width_ratios": [1.15, 1]})
cols = {"30 m tolerance score (Sep 4)": "#9a9a9a", "10 m CORE4 (Sep 16)": "#6a8fb3",
        "10 m transitioning (Sep 23, Zenodo)": "#2f5d8a", "New ordinal, out of fold": "#c0592b"}
ylab = []; yi = 0
for cname in CONTR:
    for mlab in cols:
        r = A[(A.contrast == cname) & (A.map == mlab)].iloc[0]
        ax[0].errorbar(r.auc, yi, xerr=[[r.auc - r.lo], [r.hi - r.auc]], fmt="o", color=cols[mlab], ms=4, capsize=2)
        yi -= 1
    ylab.append((yi + 2.5, f"{cname}\n(n = {int(r.n)}, positives = {int(r.n_pos)})")); yi -= 0.8
ax[0].axvline(0.5, color="k", lw=0.6, ls=":")
ax[0].set_yticks([p for p, _ in ylab]); ax[0].set_yticklabels([t for _, t in ylab])
ax[0].set_xlabel("AUC at OCC field points (95% site bootstrap CI)"); ax[0].set_xlim(0.3, 1.0)
for s in ("top", "right"): ax[0].spines[s].set_visible(False)
ax[0].legend(handles=[plt.Line2D([], [], marker="o", ls="", color=c, label=l) for l, c in cols.items()],
             loc="lower left", fontsize=7, frameon=False)
order = ["Not LS", "Trans LS", "LS", "Old-growth"]
for j, (col, lab) in enumerate([("m10_trans", "10 m transitioning"), ("new_ge2", "New P(LS or OG)"), ("new_og", "New P(OG)")]):
    data = [O.loc[O.occ_class == c, col].dropna().values for c in order]
    pos = np.arange(4) + (j - 1) * 0.27
    bp = ax[1].boxplot(data, positions=pos, widths=0.22, patch_artist=True, showfliers=False)
    cc = ["#2f5d8a", "#c0592b", "#7a2e12"][j]
    for b in bp["boxes"]: b.set(facecolor=cc, alpha=0.55, edgecolor=cc)
    for m in bp["medians"]: m.set(color="k")
    ax[1].plot([], [], color=cc, lw=6, alpha=0.55, label=lab)
ax[1].set_xticks(range(4)); ax[1].set_xticklabels([f"{c}\n(n = {int((O.occ_class == c).sum())})" for c in order])
ax[1].set_ylabel("Score at point"); ax[1].legend(fontsize=7, frameon=False, loc="upper left")
for s in ("top", "right"): ax[1].spines[s].set_visible(False)
fig.text(0.01, 0.97, "a", weight="bold", fontsize=11); fig.text(0.53, 0.97, "b", weight="bold", fontsize=11)
fig.tight_layout(); fig.savefig(f"{AGG}/fig_occ_multimap_comparison_occv2.png", dpi=300); plt.close(fig)
L("S2 DONE")
