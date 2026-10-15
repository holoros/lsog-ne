#!/usr/bin/env python3
# 2026-10-15 Hagan questions (2), (7), (1) on the v5xp cross-predicted, area-calibrated 10 m layer.
# (2) objective cut points chosen from the OCC field points, with 10 km cluster bootstrap and grouped CV,
#     and the share of Maine forest (statewide and inside the OCC AOI) each cut flags;
# (7) does the neighbourhood density of high-probability cells separate OG (FSC Type 1) from LS (Type 2)?
# (1) Hansen forest loss after the field visit at each point (loss year 2021 or later), by class.
# RESTRICTED INPUTS (OCC points) are read on Cardinal only. Only aggregates and one figure leave the server.
import os, json, sys, numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
from pyproj import Transformer
from scipy.cluster.hierarchy import fcluster, linkage
from sklearn.metrics import roc_auc_score
import matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
SEED = 20261015; rng = np.random.default_rng(SEED)
W = "/users/PUOM0008/crsfaaron/LSOG"; RUN = f"{W}/2026-10-15_hagan-threshold-density"; AGG = f"{RUN}/agg"
os.makedirs(AGG, exist_ok=True); LOG = open(f"{RUN}/run_log.txt", "w")
def L(m): print(m, flush=True); LOG.write(str(m) + "\n"); LOG.flush()
def die(m): L("GATE FAIL " + m); sys.exit(2)
OCC = f"{W}/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
R10 = "/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/finalxp/occ-ordinal-v5xp-lsog-areacal_10m_ME_DATA_2026-10-12.tif"
LOSS = f"{W}/2026-10-12_occ-ordinal-relabel/out/structure/lossyear30.tif"
AOI50 = f"{RUN}/aoi_mask50_RESTRICTED.tif"   # AOI rasterized on a 50 m grid sharing the 10 m origin (job script)
U = 65535; TGT = {1: 0.1466, 2: 0.0207, 3: 0.0021}

# ---------------- points
o = pd.read_csv(OCC); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
L(f"points {len(o)} {o.occ_class.value_counts().to_dict()}")
if not 460 <= len(o) <= 469: die("point count")
cls = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}).values
if np.isnan(cls.astype(float)).any(): die("unknown class label")
x, y = Transformer.from_crs(4326, 3979, always_xy=True).transform(o.lon.values, o.lat.values)
g10 = fcluster(linkage(np.c_[x, y], "single"), 10000, "distance")
L(f"10 km clusters {len(set(g10))}; OG clusters {len(set(g10[cls == 3]))}; LS clusters {len(set(g10[cls == 2]))}")

# ---------------- sample point values and neighbourhoods at 10 m
RADII = [0, 50, 100, 250, 500]
with rasterio.open(R10) as s:
    rr, cc = rasterio.transform.rowcol(s.transform, x, y)
    pv = np.full((len(o), 3), np.nan); foc = {}
    for i, (r, c) in enumerate(zip(rr, cc)):
        h = 50; win = Window(c - h, r - h, 2 * h + 1, 2 * h + 1)
        a = s.read([1, 2, 3], window=win, boundless=True, fill_value=U).astype("float64")
        a[a == U] = np.nan; a /= 1e4
        pv[i] = a[:, h, h]
        yy, xx = np.mgrid[-h:h + 1, -h:h + 1] * 10.0; d = np.hypot(xx, yy)
        for rad in RADII[1:]:
            m = d <= rad
            for b in (1, 2):
                foc[(i, rad, b)] = a[b][m]
L(f"point cells with nodata: {int(np.isnan(pv[:, 0]).sum())}")
ok = ~np.isnan(pv[:, 0])
if np.nanmin(pv) < 0 or np.nanmax(pv) > 1: die("probability range")
if (pv[ok, 2] > pv[ok, 1] + 1e-4).any() or (pv[ok, 1] > pv[ok, 0] + 1e-4).any(): die("layer ordering at points")

# ---------------- (2) cut points
CON = {"Trans+ vs Not LS": (1, cls >= 1), "LS pool vs rest": (2, cls >= 2), "OG vs rest": (3, cls == 3)}
def stats(sc, yv, cut): p = sc >= cut; return p[yv].mean(), (~p[~yv]).mean()
def youden(sc, yv):
    cuts = np.unique(sc); best = (-1, None)
    for c in cuts:
        se, sp = stats(sc, yv, c); j = se + sp - 1
        if j > best[0]: best = (j, c)
    return best[1]
def sens_cut(sc, yv, target=0.90):
    return np.quantile(sc[yv], 1 - target, method="lower")
rows = []; cuts_used = {}
for name, (b, yv_all) in CON.items():
    sc = pv[ok, b - 1]; yv = yv_all[ok]; gg = g10[ok]
    auc = roc_auc_score(yv, sc)
    for rule, fn in (("Youden", youden), ("sensitivity 0.90", sens_cut)):
        c0 = fn(sc, yv); se0, sp0 = stats(sc, yv, c0)
        bc, bse, bsp = [], [], []
        ug = np.unique(gg)
        for _ in range(1000):
            pick = rng.choice(ug, len(ug)); idx = np.concatenate([np.where(gg == k)[0] for k in pick])
            if yv[idx].all() or (~yv[idx]).all(): continue
            c = fn(sc[idx], yv[idx]); se, sp = stats(sc[idx], yv[idx], c); bc.append(c); bse.append(se); bsp.append(sp)
        # grouped cross-validation: cut chosen without the held-out clusters, 20 repeats of 5 folds
        cvse, cvsp = [], []
        for rep in range(20):
            perm = rng.permutation(ug); fold = {k: i % 5 for i, k in enumerate(perm)}; f = np.array([fold[k] for k in gg])
            pred = np.zeros(len(sc), bool)
            for k in range(5):
                tr = f != k
                if yv[tr].all() or (~yv[tr]).all(): continue
                pred[f == k] = sc[f == k] >= fn(sc[tr], yv[tr])
            cvse.append(pred[yv].mean()); cvsp.append((~pred[~yv]).mean())
        q = lambda v: (float(np.percentile(v, 2.5)), float(np.percentile(v, 97.5)))
        rows.append(dict(contrast=name, band=b, auc=auc, rule=rule, cut=c0, cut_lo=q(bc)[0], cut_hi=q(bc)[1],
                         sens=se0, spec=sp0, sens_cv=np.mean(cvse), spec_cv=np.mean(cvsp),
                         sens_cv_lo=q(cvse)[0], sens_cv_hi=q(cvse)[1], spec_cv_lo=q(cvsp)[0], spec_cv_hi=q(cvsp)[1],
                         n_pos=int(yv.sum()), n_neg=int((~yv).sum())))
        cuts_used[(name, rule)] = c0
T = pd.DataFrame(rows)

# capture by class at each cut on the LS pool band and the trans band
cap = []
for (name, rule), c in cuts_used.items():
    b = CON[name][0]; sc = pv[ok, b - 1]; cl = cls[ok]
    cap.append(dict(contrast=name, rule=rule, cut=c, **{f"pass_{k}": float((sc[cl == v] >= c).mean()) for k, v in
                (("NotLS", 0), ("TransLS", 1), ("LS", 2), ("OG", 3))}))
CAP = pd.DataFrame(cap)

# ---------------- area flagged by each cut: systematic 1-in-25 cell subsample, statewide and inside the AOI
with rasterio.open(AOI50) as m5: AM = m5.read(1) > 0
grid = np.linspace(0.0, 0.6, 241); state = {b: [] for b in (1, 2, 3)}; inaoi = {b: [] for b in (1, 2, 3)}
with rasterio.open(R10) as s:
    for _, win in s.block_windows(1):
        a = s.read([1, 2, 3], window=win)[:, ::5, ::5]; v = a[0] != U
        if not v.any(): continue
        ri = (win.row_off + np.arange(0, win.height, 5)) // 5; ci = (win.col_off + np.arange(0, win.width, 5)) // 5
        ri = np.clip(ri, 0, AM.shape[0] - 1); ci = np.clip(ci, 0, AM.shape[1] - 1); m = AM[np.ix_(ri, ci)]
        for b in (1, 2, 3):
            state[b].append(a[b - 1][v].astype("float32") / 1e4); inaoi[b].append(a[b - 1][v & m].astype("float32") / 1e4)
SV = {b: np.concatenate(state[b]) for b in state}; AV = {b: np.concatenate(inaoi[b]) for b in inaoi}
L(f"area subsample cells: state {len(SV[1])}, AOI {len(AV[1])} ({len(AV[1]) / len(SV[1]):.3f} of state)")
for b in (1, 2, 3):
    mu = float(SV[b].mean()); L(f"band {b} statewide mean {mu:.4f} target {TGT[b]}")
    if abs(mu - TGT[b]) > 0.25 * TGT[b] + 0.002: die(f"band {b} statewide mean far from calibration target")
FOREST_HA_STATE = 7.39e6
aoi_share = len(AV[1]) / len(SV[1])
T["share_state_forest"] = [float((SV[b] >= c).mean()) for b, c in zip(T.band, T.cut)]
T["share_aoi_forest"] = [float((AV[b] >= c).mean()) for b, c in zip(T.band, T.cut)]
T["ha_state"] = T.share_state_forest * FOREST_HA_STATE
T["ha_aoi"] = T.share_aoi_forest * FOREST_HA_STATE * aoi_share
T["area_matched_cut"] = [float(np.quantile(SV[b], 1 - TGT[b])) for b in T.band]
T.to_csv(f"{AGG}/cuts_DATA.csv", index=False); CAP.to_csv(f"{AGG}/cut_capture_DATA.csv", index=False)
L(T.round(4).to_string(index=False)); L(CAP.round(3).to_string(index=False))
# capture curve: share of forest flagged vs share of OCC classes captured, LS pool band
cc_rows = []
for b in (1, 2):
    sc = pv[ok, b - 1]; cl = cls[ok]
    for c in grid:
        cc_rows.append(dict(band=b, cut=c, state=float((SV[b] >= c).mean()), aoi=float((AV[b] >= c).mean()),
                            NotLS=float((sc[cl == 0] >= c).mean()), TransLS=float((sc[cl == 1] >= c).mean()),
                            LS=float((sc[cl == 2] >= c).mean()), OG=float((sc[cl == 3] >= c).mean())))
CC = pd.DataFrame(cc_rows); CC.to_csv(f"{AGG}/capture_curve_DATA.csv", index=False)

# ---------------- (7) neighbourhood density, OG vs LS
sel = ok & (cls >= 2); yv = cls[sel] == 3; gg = g10[sel]; idx_sel = np.where(sel)[0]
cut2 = cuts_used[("LS pool vs rest", "Youden")]
feat = {"point value, P(LS or OG)": pv[sel, 1], "point value, P(OG)": pv[sel, 2]}
for rad in RADII[1:]:
    feat[f"{rad} m mean, P(LS or OG)"] = np.array([np.nanmean(foc[(i, rad, 1)]) for i in idx_sel])
    feat[f"{rad} m mean, P(OG)"] = np.array([np.nanmean(foc[(i, rad, 2)]) for i in idx_sel])
    feat[f"{rad} m share above LS-pool cut"] = np.array([np.nanmean(foc[(i, rad, 1)] >= cut2) for i in idx_sel])
dr = []; ug = np.unique(gg)
for k, v in feat.items():
    a0 = roc_auc_score(yv, v); bs = []
    for _ in range(1000):
        pick = rng.choice(ug, len(ug)); ii = np.concatenate([np.where(gg == q)[0] for q in pick])
        if yv[ii].all() or (~yv[ii]).all(): continue
        bs.append(roc_auc_score(yv[ii], v[ii]))
    dr.append(dict(feature=k, auc=a0, lo=np.percentile(bs, 2.5), hi=np.percentile(bs, 97.5),
                   median_OG=float(np.median(v[yv])), median_LS=float(np.median(v[~yv])), n_OG=int(yv.sum()), n_LS=int((~yv).sum()),
                   clusters_OG=len(set(gg[yv])), clusters_LS=len(set(gg[~yv]))))
D = pd.DataFrame(dr); D.to_csv(f"{AGG}/og_vs_ls_density_DATA.csv", index=False); L(D.round(3).to_string(index=False))

# ---------------- (1) Hansen loss after the visit
with rasterio.open(LOSS) as s:
    ly = np.array([v[0] for v in s.sample(zip(x, y))])
H = pd.DataFrame(dict(cls=o.occ_class, project=o.project, loss_any=ly > 0, loss_2021_on=ly >= 21, loss_2023_on=ly >= 23))
HH = H.groupby(["cls", "project"]).agg(n=("loss_any", "size"), loss_since_2001=("loss_any", "sum"),
                                     loss_2021_on=("loss_2021_on", "sum"), loss_2023_on=("loss_2023_on", "sum")).reset_index()
HH.to_csv(f"{AGG}/hansen_loss_after_visit_DATA.csv", index=False); L(HH.to_string(index=False))

# ---------------- figure: capture curve, no locations
fig, ax = plt.subplots(1, 2, figsize=(7.2, 3.4), dpi=300)
for j, b in enumerate((1, 2)):
    d = CC[CC.band == b]; a = ax[j]
    for col, lab, ls in (("OG", "Old-growth (Type 1)", "-"), ("LS", "LS (Type 2)", "-"), ("TransLS", "Transitioning", "--"), ("NotLS", "Not LS", ":")):
        a.plot(d.state * 100, d[col] * 100, ls, color="black" if col in ("OG", "NotLS") else "0.45", lw=1.2, label=lab)
    for rule, mk in (("Youden", "o"), ("sensitivity 0.90", "s")):
        r = T[(T.band == b) & (T.rule == rule)].iloc[0]
        a.axvline(r.share_state_forest * 100, color="0.7", lw=0.6); a.plot([], [], mk, color="0.7", label=f"{rule} cut")
    a.set_xlabel("Maine forest flagged (%)"); a.set_ylabel("OCC field points flagged (%)" if j == 0 else "")
    a.set_title(["P(transitioning or above)", "P(LS or OG)"][j], fontsize=9); a.set_xlim(0, 60); a.set_ylim(0, 101)
    a.spines[["top", "right"]].set_visible(False); a.tick_params(labelsize=8)
ax[1].legend(fontsize=6.5, frameon=False, loc="lower right")
fig.tight_layout(); fig.savefig(f"{AGG}/fig_capture_curve.png"); L("DONE")
