#!/usr/bin/env python3
# r0_relabel.py  Aaron, October 11, 2026: relabel the Maine FIA training table from the 2004-2008 visits (EVALID 230801)
# to the 2019-2023 remeasurement of the same plot (EVALID 232301 panel), scored with the v5.1 six-axis rubric of
# jobA_design_based_rfia.R (the instrument behind 14.66% [13.40, 15.91], LS or OG 2.07% and OG 0.21%), so labels,
# predictors (2024) and calibration targets share one panel and one definition. Classes: v51 >= 8 OG, 6-7 LS,
# 4-5 transitioning, else not LSOG. Plot positions do not change between visits (FIA remeasures the same location),
# so the AlphaEarth bands in the table and the true coordinates keyed by the original PLT_CN still apply.
# Outputs (restricted, Cardinal only): relabelled table with the original columns, and plot_id -> descendant CN map.
import numpy as np, pandas as pd, os
W2 = os.path.expanduser("~/LSOG/2026-10-12_occ-ordinal-relabel"); DB = "/users/PUOM0008/crsfaaron/fia_data"
T0 = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
J = "/fs/scratch/PUOM0008/crsfaaron/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
t = pd.read_csv(T0); t = t[t.state == "ME"].copy(); n0 = len(t)
j = pd.read_csv(J, dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]; t = t.merge(j, on="plot_id", how="left")
pl = pd.read_csv(f"{DB}/ME_PLOT.csv", usecols=["CN", "PREV_PLT_CN", "INVYR"], dtype={"CN": str, "PREV_PLT_CN": str})
child = dict(zip(pl.loc[pl.PREV_PLT_CN.notna(), "PREV_PLT_CN"], pl.loc[pl.PREV_PLT_CN.notna(), "CN"])); inv = dict(zip(pl.CN, pl.INVYR))
def desc(cn):
    a, hit = cn, None
    if not isinstance(cn, str): return None
    for _ in range(4):
        a = child.get(a)
        if a is None: break
        if 2019 <= inv.get(a, 0) <= 2023: hit = a
    return hit
t["CN_2023"] = [desc(c) for c in t.PLT_CN]
u = pd.read_csv("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", dtype={"CN": str}); u = u[(u.state == "ME") & u.INVYR.between(2019, 2023)]
ge = lambda x, th: x.notna() & (x >= th)
u["s_ba"] = np.where(ge(u.ba_large, 80), 2, np.where(ge(u.ba_large, 40), 1, 0))
u["s_mat"] = np.where(ge(u.STDAGE, 120), 2, np.where(ge(u.STDAGE, 80), 1, np.where((u.STDAGE.isna() | (u.STDAGE == 0)) & ge(u.max_dia, 24), 1, 0)))
u["s_str"] = np.where(ge(u.sd_dia, 8), 2, np.where(ge(u.sd_dia, 5), 1, 0)); u["s_can"] = np.where(ge(u.ba_total, 150), 2, np.where(ge(u.ba_total, 100), 1, 0))
u["s_dw"] = np.where(u.snag_tpa.notna() & (u.snag_tpa >= u.snag_thresh_2), 2, np.where(u.snag_tpa.notna() & (u.snag_tpa >= u.snag_thresh_1), 1, 0))
u["s_ht"] = np.where(ge(u.potapov_rh95, 25), 2, np.where(ge(u.potapov_rh95, 18), 1, 0))
u["v51"] = u[["s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht"]].sum(1)
S = ["s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht"]
t = t.drop(columns=S + ["total_score", "any_lsog", "og", "lsog_class", "trans_cut4"]).merge(
    u[["CN"] + S + ["v51"]].rename(columns={"CN": "CN_2023"}), on="CN_2023", how="left")
old = pd.read_csv(T0); old = old[old.state == "ME"][["plot_id", "lsog_class"]].rename(columns={"lsog_class": "class_0408"})
keep = t.v51.notna(); print(f"rows {n0}; with a 2019-2023 descendant {int(t.CN_2023.notna().sum())}; scored {int(keep.sum())}")
t = t[keep].copy(); t["v51"] = t.v51.astype(int)
t["total_score"] = t.v51; t["any_lsog"] = (t.v51 >= 4).astype(int); t["trans_cut4"] = (t.v51 >= 4).astype(int); t["og"] = (t.v51 >= 8).astype(int)
t["lsog_class"] = np.select([t.v51 >= 8, t.v51 >= 6, t.v51 >= 4], ["OG", "LS", "Transitioning LS"], "Not LSOG")
x = t.merge(old, on="plot_id"); print(pd.crosstab(x.class_0408, x.lsog_class).to_string())
print("class counts:", t.lsog_class.value_counts().to_dict(), "; Trans+ unweighted %.2f%%, LS or OG %.2f%%, OG %.2f%%" % (100 * (t.v51 >= 4).mean(), 100 * (t.v51 >= 6).mean(), 100 * (t.v51 >= 8).mean()))
cols = list(pd.read_csv(T0, nrows=1).columns)
t[cols].to_csv(f"{W2}/out/me_training_table_relabel2023_RESTRICTED.csv", index=False)
t[["plot_id", "PLT_CN", "CN_2023"]].to_csv(f"{W2}/out/desc_map_RESTRICTED.csv", index=False)
x.groupby(["class_0408", "lsog_class"]).size().rename("n").reset_index().to_csv(f"{W2}/out/agg/r0_class_change_DATA.csv", index=False)
print("R0 DONE")
