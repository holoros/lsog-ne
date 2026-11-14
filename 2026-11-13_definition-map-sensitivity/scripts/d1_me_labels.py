#!/usr/bin/env python3
"""d1_me_labels.py (November 13, 2026). Maine plot-level labels for the six definitions of
PREREG 2026-11-13_menb-definition-map-sensitivity. Scoring is copied from ~/LSOG/2026-11-03_models/m1_labels.py
(the corrected plot-level rule of Appendix S1 Section 19.1); two variants are added with the axis definitions of
instrument_sweep/me_instrument_sweep.R: V3 (deadwood on fixed 18 and 36 snags per acre) and V4 (maturity as
maximum diameter, 0 or 1). No coordinate is read. The per-plot table stays in RESTRICTED; only counts are printed."""
import os, json, numpy as np, pandas as pd
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); DB = "/users/PUOM0008/crsfaaron/fia_data"
NE = os.path.expanduser("~/LSOG/output_unified/lsog_ne_plot_table.csv")
pl = pd.read_csv(f"{DB}/ME_PLOT.csv", usecols=["CN", "INVYR"], dtype={"CN": str}); pl = pl[pl.INVYR.between(2019, 2023)]
co = pd.read_csv(f"{DB}/ME_COND.csv", usecols=["PLT_CN", "CONDID", "COND_STATUS_CD", "CONDPROP_UNADJ", "STDAGE"], dtype={"PLT_CN": str})
fc = co[(co.COND_STATUS_CD == 1) & co.PLT_CN.isin(pl.CN)]
ne = pd.read_csv(NE, usecols=["state", "eval_period", "CN", "snag_thresh_1", "snag_thresh_2", "potapov_rh95"], dtype={"CN": str})
ne = ne[(ne.state == "ME") & (ne.eval_period == "2019-2023")]
T1 = ne.snag_thresh_1.unique(); T2 = ne.snag_thresh_2.unique(); assert len(T1) == 1 and len(T2) == 1; T1 = float(T1[0]); T2 = float(T2[0])
tr = pd.read_csv(f"{DB}/ME_TREE.csv", usecols=["PLT_CN", "STATUSCD", "DIA", "TPA_UNADJ"], dtype={"PLT_CN": str})
tr = tr[tr.PLT_CN.isin(fc.PLT_CN)].copy(); tr["ba"] = 0.005454154 * tr.DIA ** 2 * tr.TPA_UNADJ
lv = tr[(tr.STATUSCD == 1) & tr.DIA.notna() & (tr.DIA >= 1)].copy()
def rsum(s): return s.sum() if s.notna().all() else np.nan
def wsd(g):
    x = g.DIA.values; w = g.TPA_UNADJ.values; n = len(x)
    if n < 2 or np.isnan(w).any(): return np.nan
    mu = (w * x).sum() / w.sum(); return np.sqrt((w * (x - mu) ** 2).sum() / (w.sum() * (n - 1) / n))
live = lv.groupby("PLT_CN").apply(lambda g: pd.Series({"bal": rsum(g.ba[g.DIA >= 20]), "bat": rsum(g.ba), "sd": wsd(g), "md": g.DIA.max()})).reset_index()
sn = tr[(tr.STATUSCD == 2) & tr.DIA.notna() & (tr.DIA >= 5)].groupby("PLT_CN").TPA_UNADJ.apply(rsum).rename("snag").reset_index()
age = fc.sort_values(["PLT_CN", "CONDPROP_UNADJ", "CONDID"], ascending=[True, False, True], na_position="last").drop_duplicates("PLT_CN")[["PLT_CN", "STDAGE"]].rename(columns={"STDAGE": "age"})
A = age.merge(live, on="PLT_CN", how="left").merge(sn, on="PLT_CN", how="left"); A["snag"] = A.snag.fillna(0)
A = A.merge(ne[["CN", "potapov_rh95"]].rename(columns={"CN": "PLT_CN", "potapov_rh95": "ht"}), on="PLT_CN", how="left")
A = A.sort_values("PLT_CN").reset_index(drop=True)          # stable key order before anything is derived
def step(v, t1, t2=None):
    v = np.asarray(v, float); s = np.where(np.isfinite(v) & (v >= t1), 1, 0)
    if t2 is not None: s = np.where(np.isfinite(v) & (v >= t2), 2, s)
    return s
s_ba = step(A.bal, 40, 80); s_str = step(A.sd, 5, 8); s_can = step(A.bat, 100, 150)
s_mat_pub = step(A.age, 80, 120); miss = A.age.isna().values | (A.age.values == 0); s_mat_pub[miss] = step(A.md.values[miss], 24)
s_mat_md = step(A.md, 24); s_dw_q = step(A.snag, T1, T2); s_dw_f = step(A.snag, 18, 36); s_ht = step(A.ht, 18, 25)
six = s_ba + s_mat_pub + s_str + s_can + s_dw_q + s_ht
F = {"V3": (s_ba + s_mat_pub + s_str + s_can + s_dw_f + s_ht) >= 4, "V1": six >= 4, "V2": (six - s_ht) >= 4,
     "V4": (s_ba + s_mat_md + s_str + s_can + s_dw_q + s_ht) >= 4, "V9_c3": (s_ba + s_mat_md + s_str + s_can) >= 3, "V7": six >= 6}
L = pd.DataFrame({"PLT_CN": A.PLT_CN.values, **{k: v.astype(int) for k, v in F.items()}})
L.to_csv(f"{W}/RESTRICTED/me_def_labels_by_cn2023_RESTRICTED.csv", index=False)
prev = pd.read_csv(os.path.expanduser("~/LSOG/2026-11-03_models/labels_corrected_by_cn2023_RESTRICTED.csv"), dtype={"PLT_CN": str}).sort_values("PLT_CN").reset_index(drop=True)
same = prev.PLT_CN.equals(L.PLT_CN)
out = {"n_plots": int(len(L)), "T1": T1, "T2": T2, "n_pos": {k: int(v.sum()) for k, v in F.items()},
       "identical_to_m1": {"ids": bool(same), "V1": bool(same and (prev.trans_corr.values == L.V1.values).all()),
                           "V7": bool(same and (prev.ls_corr.values == L.V7.values).all()), "V9_c3": bool(same and (prev.core4_corr.values == L.V9_c3.values).all())}}
json.dump(out, open(f"{W}/out/d1_me_labels_DATA.json", "w"), indent=1); print(json.dumps(out))
