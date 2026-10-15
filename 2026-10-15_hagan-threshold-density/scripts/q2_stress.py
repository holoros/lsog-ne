#!/usr/bin/env python3
# 2026-10-15 stress test of the q1 answers to John Hagan (red-team findings 4, 5, 6, 9, 13 and Aaron's v5 question).
# A. density feature recomputed with valid cells only in the denominator, plus forest fraction as its own feature
#    and a forest-fraction-adjusted test (logistic with both, cluster bootstrap);
# B. cluster-bootstrap sampling intervals for sensitivity and specificity at the fixed cut 0.048, counting nodata points as misses;
# C. v5 against v5xp: share of forest flagged at each cut, and capture at OCC points on both layers;
# D. FIA plots (true positions, server side): v5xp held-out capture, false-pass rate and implied precision at the cuts,
#    and the aspen / balsam poplar pass rate at 0.048;
# E. Hansen loss within the 3 x 3 30 m window (about 45 m) in 2021 or later, by class;
# F. leave-one-project-out cut choice.
# RESTRICTED inputs stay on Cardinal. Only aggregates are written.
import os, sys, json, numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
from pyproj import Transformer
from scipy.cluster.hierarchy import fcluster, linkage
from sklearn.metrics import roc_auc_score
from sklearn.linear_model import LogisticRegression
SEED = 20261015; rng = np.random.default_rng(SEED)
W = "/users/PUOM0008/crsfaaron/LSOG"; RUN = f"{W}/2026-10-15_hagan-threshold-density"; AGG = f"{RUN}/agg_stress"; os.makedirs(AGG, exist_ok=True)
LOG = open(f"{RUN}/stress_log.txt", "w")
def L(m): print(m, flush=True); LOG.write(str(m) + "\n"); LOG.flush()
def die(m): L("GATE FAIL " + m); sys.exit(2)
RL = f"{W}/2026-10-12_occ-ordinal-relabel"
OCC = f"{W}/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
XP = "/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/finalxp/occ-ordinal-v5xp-lsog-areacal_10m_ME_DATA_2026-10-12.tif"
V5 = f"{RL}/out/final/occ-ordinal-v5-lsog-areacal_10m_ME_DATA_2026-10-12.tif"
LOSS = f"{RL}/out/structure/lossyear30.tif"; U = 65535; CUTS = [0.037, 0.048]
o = pd.read_csv(OCC); o = o[o.lon.between(-71.10, -66.90) & o.lat.between(43.0, 47.5)].reset_index(drop=True)
cls = o.occ_class.map({"Not LS": 0, "Trans LS": 1, "LS": 2, "Old-growth": 3}).values
tf = Transformer.from_crs(4326, 3979, always_xy=True); x, y = tf.transform(o.lon.values, o.lat.values)
g10 = fcluster(linkage(np.c_[x, y], "single"), 10000, "distance")
def read_pts(path, xs, ys, h=0):
    out = []
    with rasterio.open(path) as s:
        rr, cc = rasterio.transform.rowcol(s.transform, xs, ys)
        for r, c in zip(rr, cc):
            a = s.read([1, 2, 3], window=Window(c - h, r - h, 2 * h + 1, 2 * h + 1), boundless=True, fill_value=U).astype("float64")
            a[a == U] = np.nan; out.append(a / 1e4)
    return out
# ---------------- A. density with valid denominators
win = read_pts(XP, x, y, 50); yy, xx = np.mgrid[-50:51, -50:51] * 10.0; d = np.hypot(xx, yy)
pt = np.array([w[:, 50, 50] for w in win]); ok = ~np.isnan(pt[:, 0])
L(f"OCC points {len(o)}, with map value {int(ok.sum())}, nodata by class {pd.Series(cls[~ok]).value_counts().to_dict()}")
sel = ok & (cls >= 2); yv = cls[sel] == 3; gg = g10[sel]; ug = np.unique(gg); idx = np.where(sel)[0]
F = {}
for rad in (100, 250, 500):
    m = d <= rad
    b2 = [win[i][1][m] for i in idx]
    F[f"forest fraction {rad} m"] = np.array([np.mean(~np.isnan(v)) for v in b2])
    F[f"share of FOREST cells >= 0.037, {rad} m"] = np.array([np.nanmean(np.where(np.isnan(v), np.nan, (v >= 0.037).astype(float))) for v in b2])
    F[f"share of ALL cells >= 0.037, {rad} m (q1 feature)"] = np.array([np.mean(np.nan_to_num(v, nan=-1) >= 0.037) for v in b2])
F["cell value P(LS or OG)"] = pt[sel, 1]
def cboot(fn, n=1000):
    v = []
    for _ in range(n):
        pick = rng.choice(ug, len(ug)); ii = np.concatenate([np.where(gg == q)[0] for q in pick])
        if yv[ii].all() or (~yv[ii]).all(): continue
        try: v.append(fn(ii))
        except Exception: pass
    return np.percentile(v, [2.5, 97.5])
rows = []
for k, v in F.items():
    lo, hi = cboot(lambda ii: roc_auc_score(yv[ii], v[ii]))
    rows.append(dict(feature=k, auc=roc_auc_score(yv, v), lo=lo, hi=hi, med_OG=np.median(v[yv]), med_LS=np.median(v[~yv])))
# adjusted: does forest-cell share add to forest fraction? leave-one-cluster-out logistic, AUC of combined vs fraction only
for rad in (250, 500):
    ff, sh = F[f"forest fraction {rad} m"], F[f"share of FOREST cells >= 0.037, {rad} m"]
    for name, X in ((f"LOCO logistic, forest fraction only, {rad} m", np.c_[ff]), (f"LOCO logistic, fraction + forest-cell share, {rad} m", np.c_[ff, sh])):
        p = np.zeros(len(yv))
        for q in ug:
            te = gg == q; tr = ~te
            if yv[tr].all() or (~yv[tr]).all(): p[te] = yv[tr].mean(); continue
            p[te] = LogisticRegression(C=1e3, max_iter=1000).fit(X[tr], yv[tr]).predict_proba(X[te])[:, 1]
        rows.append(dict(feature=name, auc=roc_auc_score(yv, p), lo=np.nan, hi=np.nan, med_OG=np.nan, med_LS=np.nan))
DA = pd.DataFrame(rows); DA.to_csv(f"{AGG}/density_stress_DATA.csv", index=False); L(DA.round(3).to_string(index=False))
# ---------------- B. sampling intervals at fixed cuts (all points, nodata counted as not flagged)
ga = g10; uga = np.unique(ga); pos = cls >= 2; val = np.nan_to_num(pt[:, 1], nan=-1)
rb = []
for c in CUTS:
    f = val >= c; se = f[pos].mean(); sp = (~f[~pos]).mean(); bs = []
    for _ in range(2000):
        pick = rng.choice(uga, len(uga)); ii = np.concatenate([np.where(ga == q)[0] for q in pick])
        if pos[ii].all() or (~pos[ii]).all(): continue
        bs.append((f[ii][pos[ii]].mean(), (~f[ii][~pos[ii]]).mean()))
    bs = np.array(bs); rb.append(dict(cut=c, n=len(val), sens=se, sens_lo=np.percentile(bs[:, 0], 2.5), sens_hi=np.percentile(bs[:, 0], 97.5),
        spec=sp, spec_lo=np.percentile(bs[:, 1], 2.5), spec_hi=np.percentile(bs[:, 1], 97.5),
        LS=f[cls == 2].mean(), OG=f[cls == 3].mean(), Trans=f[cls == 1].mean(), NotLS=f[cls == 0].mean()))
B = pd.DataFrame(rb); B.to_csv(f"{AGG}/fixed_cut_sampling_DATA.csv", index=False); L(B.round(3).to_string(index=False))
# ---------------- C. v5 against v5xp
pv5 = np.array([w[:, 0, 0] for w in read_pts(V5, x, y, 0)])
rc = []
for lay, path, P in (("v5xp", XP, pt), ("v5", V5, pv5)):
    vals = []
    with rasterio.open(path) as s:
        for _, w_ in s.block_windows(1):
            a = s.read(2, window=w_)[::5, ::5]; a = a[a != U]
            if a.size: vals.append(a.astype("float32") / 1e4)
    V = np.concatenate(vals)
    for c in CUTS:
        f = np.nan_to_num(P[:, 1], nan=-1) >= c
        rc.append(dict(layer=lay, cut=c, forest_flagged=float((V >= c).mean()), mean_band2=float(V.mean()),
                       LS=f[cls == 2].mean(), OG=f[cls == 3].mean(), Trans=f[cls == 1].mean(), NotLS=f[cls == 0].mean()))
    rc.append(dict(layer=lay, cut="cut giving 12.2% of forest", forest_flagged=0.122, mean_band2=float(V.mean()),
                   LS=np.nan, OG=np.nan, Trans=np.nan, NotLS=float(np.quantile(V, 1 - 0.122))))
C = pd.DataFrame(rc); C.to_csv(f"{AGG}/v5_vs_v5xp_DATA.csv", index=False); L(C.round(4).to_string(index=False))
# ---------------- D. FIA plots at true positions, v5xp (held out by 20 km block)
E = {"TRAIN_TABLE": f"{RL}/out/me_training_table_relabel2023_RESTRICTED.csv", "PLOTID_PLTCN": f"{RL}/out/plotid_to_cn2023_RESTRICTED.csv",
     "ME_COORDS": f"{RL}/out/me_coords_by_cn2023_RESTRICTED.csv"}
me = pd.read_csv(E["ME_COORDS"], dtype={"PLT_CN": str})[["PLT_CN", "TRUE.LAT", "TRUE.LON"]]
j = pd.read_csv(E["PLOTID_PLTCN"], dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
cond = pd.read_csv("/fs/scratch/PUOM0008/crsfaaron/FIA/ME_COND.csv", usecols=["PLT_CN", "FORTYPCD", "CONDPROP_UNADJ"], dtype={"PLT_CN": str})
cond = cond.sort_values("CONDPROP_UNADJ", ascending=False).drop_duplicates("PLT_CN")
f = pd.read_csv(E["TRAIN_TABLE"]); f = f[f.state == "ME"].merge(j, on="plot_id", how="left").merge(me, on="PLT_CN", how="left").merge(cond, on="PLT_CN", how="left")
f = f[f["TRUE.LAT"].notna()].reset_index(drop=True); L(f"FIA plots with true positions {len(f)} {f.lsog_class.value_counts().to_dict()}")
if len(f) < 2500: die("FIA plot count")
fx, fy = tf.transform(f["TRUE.LON"].values, f["TRUE.LAT"].values)
fp = np.array([w[:, 0, 0] for w in read_pts(XP, fx, fy, 0)]); fv = np.nan_to_num(fp[:, 1], nan=-1)
fpos = f.lsog_class.isin(["LS", "OG"]).values; asp = f.FORTYPCD.isin([901, 904]).values
rd = []
for c in CUTS:
    fl = fv >= c
    rd.append(dict(cut=c, n=len(f), n_pool=int(fpos.sum()), capture_pool=fl[fpos].mean(), pass_trans=fl[(f.lsog_class == "Transitioning LS").values].mean(),
                   pass_not=fl[(f.lsog_class == "Not LSOG").values].mean(), share_flagged=fl.mean(),
                   precision_unweighted=fl[fpos].sum() / max(fl.sum(), 1), n_aspen=int(asp.sum()), pass_aspen=fl[asp].mean()))
D = pd.DataFrame(rd); D.to_csv(f"{AGG}/fia_heldout_cut_DATA.csv", index=False); L(D.round(3).to_string(index=False))
# ---------------- E. Hansen within about 45 m
with rasterio.open(LOSS) as s:
    rr, cc = rasterio.transform.rowcol(s.transform, x, y); hl = []
    for r, c in zip(rr, cc):
        a = s.read(1, window=Window(c - 1, r - 1, 3, 3), boundless=True, fill_value=0); hl.append((a.max(), (a >= 21).any()))
hl = np.array(hl)
H = pd.DataFrame(dict(cls=o.occ_class, any_since_2001=hl[:, 0] > 0, any_2021_on=hl[:, 1].astype(bool))).groupby("cls").agg(n=("any_since_2001", "size"),
    any_since_2001=("any_since_2001", "sum"), any_2021_on=("any_2021_on", "sum")).reset_index()
H.to_csv(f"{AGG}/hansen_3x3_DATA.csv", index=False); L(H.to_string(index=False))
# ---------------- F. leave one project out: the 90% sensitivity cut chosen without each project
rf = []
for prj in o.project.unique():
    tr = (o.project != prj).values & ok
    sc = pt[tr, 1]; yp = cls[tr] >= 2
    c = np.quantile(sc[yp], 0.10, method="lower") if yp.sum() > 5 else np.nan
    rf.append(dict(left_out=prj, n_train=int(tr.sum()), cut_90=c))
FF = pd.DataFrame(rf); FF.to_csv(f"{AGG}/lopo_cut_DATA.csv", index=False); L(FF.round(4).to_string(index=False)); L("DONE")
