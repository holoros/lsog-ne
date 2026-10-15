#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s17e_xj_oof.py  Red team correction to s17c (October 7, 2026). s17c scored each model on its own jurisdiction in sample
# (final forests on their own training plots), which pulls own-side means toward the labels. Here every prediction is
# out of sample: the Maine instrument is the s16a cross-predicted ensemble (each Maine row scored by the fold model
# that excluded its 20 km block, each NB plot by the mean of the five fold models); the NB instrument is the s12 form
# refit out of fold on NB (same grouped folds, seed, weights and relabeling as s12) and the final NB forests on Maine.
import os, json, pickle, numpy as np, pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.metrics import roc_auc_score
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; rng = np.random.default_rng(20261008); NB_ = 1000; SEED = 20261006
AEC = [f"AE_{k:02d}" for k in range(64)]; S5 = ["chm_mean", "chm_max", "chm_sd", "chm_mean3", "chm_max3"]
ME_F = AEC + S5 + ["tsd"]; NB_F = AEC + ["tsd"] + S5
me = pd.read_csv(f"{OUT}/xj_me_table_RESTRICTED.csv"); nb = pd.read_csv(f"{OUT}/xj_nb_table_RESTRICTED.csv")
XB = pickle.load(open(f"{OUT}/rf_xp_bundle.pkl", "rb")); NBB = pickle.load(open(f"{OUT}/nb/nb_v4_bundle.pkl", "rb"))
assert NBB["trans"]["form"] == "new" and NBB["core4"]["form"] == "new"
def pred_cum(ms, X):
    p = np.column_stack([m.predict_proba(X)[:, 1] if hasattr(m, "predict_proba") else np.full(len(X), m) for m in ms])
    p[:, 1] = np.minimum(p[:, 1], p[:, 0]); p[:, 2] = np.minimum(p[:, 2], p[:, 1]); return p
XM = me[ME_F].values.astype("float32"); XNm = nb[ME_F].values.astype("float32")
Pme_me = np.full((len(me), 3), np.nan)
for k in range(XB["K"]):
    m = me.fold_xp.values == k
    if m.any(): Pme_me[m] = pred_cum(XB["lsog"][k], XM[m])
Pme_nb = np.mean([pred_cum(XB["lsog"][k], XNm) for k in range(XB["K"])], axis=0)
Xn = nb[NB_F].values.astype("float32"); grp = nb.blk.values; HN = nb.HN.values.astype(bool); w = np.where(HN, 3.0, 1.0)
rf = lambda s: RandomForestClassifier(n_estimators=500, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=s)
folds = list(StratifiedGroupKFold(5, shuffle=True, random_state=SEED).split(Xn, nb.y_tr.values, grp))
Pnb_nb = {}
for lab, col in (("trans", "y_tr"), ("core4", "y_c4")):
    yn = nb[col].values.astype(int).copy(); yn[HN] = 0; p = np.full(len(nb), np.nan)
    for k, (tr, te) in enumerate(folds): p[te] = rf(SEED + k).fit(Xn[tr], yn[tr], sample_weight=w[tr]).predict_proba(Xn[te])[:, 1]
    Pnb_nb[lab] = p
Pnb_me = {lab: NBB[lab]["model"].predict_proba(me[NB_F].values.astype("float32"))[:, 1] for lab in ("trans", "core4")}
fit = json.load(open(f"{AGG}/nb_v4_fit_DATA.json"))
print("NB OOF mean check (s12 vs here):", {lab: (round(fit[lab]["mean_oof_new_pct"], 2), round(100 * Pnb_nb[lab].mean(), 2)) for lab in Pnb_nb}, flush=True)
isF = (me.src == "FIA").values; O = ~isF; y = me.y.values; gF = me.grp.values[isF]; gO = me.grp.values[O]; gN = nb.blk.astype(str).values
def auc_ci(yb, sc, gg):
    yb = yb.astype(int); a = roc_auc_score(yb, sc); ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}; bs = []
    for _ in range(NB_):
        ii = np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])
        if 0 < yb[ii].sum() < len(ii): bs.append(roc_auc_score(yb[ii], sc[ii]))
    return round(a, 3), round(np.percentile(bs, 2.5), 3), round(np.percentile(bs, 97.5), 3)
rows = []
def add(model, scored, label, yb, sc, gg, own):
    a = auc_ci(yb, sc, gg); rows.append(dict(model=model, scored_on=scored, own_jurisdiction=own, label=label, n=len(yb), n_pos=int(np.sum(yb)),
                                             auc=a[0], lo=a[1], hi=a[2], mean_pred_pct=round(100 * float(np.mean(sc)), 2), obs_rate_pct=round(100 * float(np.mean(yb)), 2)))
hnF = me.HN.values.astype(bool)[isF]
add("Maine (cross-predicted)", "Maine FIA plots outside hard negatives", "Maine transitioning or above", (y[isF] >= 1)[~hnF], Pme_me[isF, 0][~hnF], gF[~hnF], True)
add("Maine (cross-predicted)", "Maine FIA plots outside hard negatives", "Maine LS or OG", (y[isF] >= 2)[~hnF], Pme_me[isF, 1][~hnF], gF[~hnF], True)
add("Maine (cross-predicted)", "NB CLI plots outside aspen negatives", "NB transitioning", nb.y_tr.values[~HN], Pme_nb[~HN, 0], gN[~HN], False)
add("Maine (cross-predicted)", "NB CLI plots outside aspen negatives", "NB CORE4, scored with P(LS or OG)", nb.y_c4.values[~HN], Pme_nb[~HN, 1], gN[~HN], False)
add("NB (out of fold)", "NB CLI plots outside aspen negatives", "NB transitioning", nb.y_tr.values[~HN], Pnb_nb["trans"][~HN], gN[~HN], True)
add("NB (out of fold)", "NB CLI plots outside aspen negatives", "NB CORE4", nb.y_c4.values[~HN], Pnb_nb["core4"][~HN], gN[~HN], True)
add("NB (final)", "Maine FIA plots outside hard negatives", "Maine transitioning or above", (y[isF] >= 1)[~hnF], Pnb_me["trans"][isF][~hnF], gF[~hnF], False)
add("NB (final)", "Maine FIA plots outside hard negatives", "Maine LS or OG, scored with P(CORE4)", (y[isF] >= 2)[~hnF], Pnb_me["core4"][isF][~hnF], gF[~hnF], False)
add("Maine (cross-predicted)", "OCC field points", "Field transitioning or above", y[O] >= 1, Pme_me[O, 0], gO, True)
add("Maine (cross-predicted)", "OCC field points", "Field LS or OG", y[O] >= 2, Pme_me[O, 1], gO, True)
add("NB (final)", "OCC field points", "Field transitioning or above", y[O] >= 1, Pnb_me["trans"][O], gO, False)
add("NB (final)", "OCC field points", "Field LS or OG, scored with P(CORE4)", y[O] >= 2, Pnb_me["core4"][O], gO, False)
T1 = pd.DataFrame(rows); T1.to_csv(f"{AGG}/xj_transfer_auc_oof_DATA.csv", index=False); print(T1.to_string(index=False), flush=True)
def boot_mean(v, gg):
    ug = np.unique(gg); idx = {u: np.where(gg == u)[0] for u in ug}
    return np.array([v[np.concatenate([idx[u] for u in rng.choice(ug, len(ug))])].mean() for _ in range(NB_)])
r2 = []
for sub, mF, mN in (("all forest plots", np.ones(isF.sum(), bool), np.ones(len(nb), bool)),
                    ("within 25 km of the border", me.border_km.values[isF] <= 25, nb.border_km.values <= 25)):
    for model, layer, vF, vN in (("Maine (cross-predicted)", "P(>= transitioning)", Pme_me[isF, 0], Pme_nb[:, 0]),
                                 ("Maine (cross-predicted)", "P(LS or OG)", Pme_me[isF, 1], Pme_nb[:, 1]),
                                 ("NB", "P(transitioning)", Pnb_me["trans"][isF], Pnb_nb["trans"]),
                                 ("NB", "P(CORE4)", Pnb_me["core4"][isF], Pnb_nb["core4"])):
        bF = boot_mean(vF[mF], gF[mF]); bN = boot_mean(vN[mN], gN[mN]); rat = bN / bF
        r2.append(dict(subset=sub, instrument=model, layer=layer, n_me=int(mF.sum()), n_nb=int(mN.sum()),
                       mean_me=round(100 * vF[mF].mean(), 2), me_lo=round(100 * np.percentile(bF, 2.5), 2), me_hi=round(100 * np.percentile(bF, 97.5), 2),
                       mean_nb=round(100 * vN[mN].mean(), 2), nb_lo=round(100 * np.percentile(bN, 2.5), 2), nb_hi=round(100 * np.percentile(bN, 97.5), 2),
                       ratio_nb_me=round(vN[mN].mean() / vF[mF].mean(), 3), ratio_lo=round(np.percentile(rat, 2.5), 3), ratio_hi=round(np.percentile(rat, 97.5), 3)))
    for lab, yF, yN in (("labels: transitioning (ME FIA y>=1, NB trans_ge4)", y[isF] >= 1, nb.y_tr.values), ("labels: ME LS or OG, NB CORE4", y[isF] >= 2, nb.y_c4.values)):
        bF = boot_mean(yF[mF].astype(float), gF[mF]); bN = boot_mean(yN[mN].astype(float), gN[mN]); rat = bN / bF
        r2.append(dict(subset=sub, instrument="labels", layer=lab, n_me=int(mF.sum()), n_nb=int(mN.sum()), mean_me=round(100 * yF[mF].mean(), 2),
                       me_lo=round(100 * np.percentile(bF, 2.5), 2), me_hi=round(100 * np.percentile(bF, 97.5), 2), mean_nb=round(100 * yN[mN].mean(), 2),
                       nb_lo=round(100 * np.percentile(bN, 2.5), 2), nb_hi=round(100 * np.percentile(bN, 97.5), 2),
                       ratio_nb_me=round(yN[mN].mean() / yF[mF].mean(), 3), ratio_lo=round(np.percentile(rat, 2.5), 3), ratio_hi=round(np.percentile(rat, 97.5), 3)))
T2 = pd.DataFrame(r2); T2.to_csv(f"{AGG}/xj_one_instrument_oof_DATA.csv", index=False); print(T2.to_string(index=False), flush=True)
print("S17E DONE", flush=True)
