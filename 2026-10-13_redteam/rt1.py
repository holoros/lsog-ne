#!/usr/bin/env python3
# Red-team re-derivation of label-source claims. Aggregates only to stdout.
import numpy as np, pandas as pd
DB = "/users/PUOM0008/crsfaaron/fia_data"
T0 = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
J = "/fs/scratch/PUOM0008/crsfaaron/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
TMP = "/fs/scratch/PUOM0008/crsfaaron/tmp_me_v51_restricted.csv"
R0 = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/out/me_training_table_relabel2023_RESTRICTED.csv"
u = pd.read_csv("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", dtype={"CN": str})
u = u[u.state == "ME"].copy()
print("A1 ME plot-table rows", len(u), "INVYR bins", u.INVYR.apply(lambda y: "2004-08" if y <= 2008 else ("2009-13" if y <= 2013 else ("2014-18" if y <= 2018 else ("2019-23" if y <= 2023 else ">=2024")))).value_counts().to_dict())
print("A2 snag_thresh_1 unique", sorted(u.snag_thresh_1.dropna().unique())[:5], "thresh_2", sorted(u.snag_thresh_2.dropna().unique())[:5], "na", int(u.snag_thresh_1.isna().sum()))
# step1 replicate: latest per location
pl = pd.read_csv(f"{DB}/ME_PLOT.csv", dtype={"CN": str, "PREV_PLT_CN": str})
k = ["STATECD", "UNITCD", "COUNTYCD", "PLOT"]
m = u.merge(pl[["CN"] + k].drop_duplicates(), on="CN")
m = m.sort_values(k + ["INVYR"]).groupby(k, as_index=False).tail(1)
print("A3 latest-per-location rows", len(m), "INVYR", m.INVYR.value_counts().sort_index().to_dict())
# map location -> label PLT_CN key
pk = pl[["CN", "INVYR"] + k].rename(columns={"CN": "PLT_CN", "INVYR": "INVYR_key"})
t = pd.read_csv(T0); t = t[t.state == "ME"].copy()
j = pd.read_csv(J, dtype={"PLT_CN": str})[["plot_id", "PLT_CN"]]
t = t.merge(j, on="plot_id", how="left")
print("B1 T0 ME rows", len(t), "PLT_CN missing", int(t.PLT_CN.isna().sum()))
t = t.merge(pk, on="PLT_CN", how="left")
print("B2 key INVYR", t.INVYR_key.value_counts().sort_index().to_dict())
t = t.merge(m[k + ["CN", "INVYR", "ba_large", "max_dia", "sd_dia", "ba_total", "snag_tpa", "potapov_rh95", "STDAGE", "snag_thresh_1", "snag_thresh_2"]], on=k, how="left")
print("B3 attribute visit INVYR", t.INVYR.value_counts(dropna=False).sort_index().to_dict(), "attrCN==key", int((t.CN == t.PLT_CN).sum()))
ge = lambda x, th: x.notna() & (x >= th)
s = pd.DataFrame({
 "s_ba": np.where(ge(t.ba_large, 80), 2, np.where(ge(t.ba_large, 40), 1, 0)),
 "s_mat": np.where(ge(t.max_dia, 24), 1, 0),
 "s_str": np.where(ge(t.sd_dia, 8), 2, np.where(ge(t.sd_dia, 5), 1, 0)),
 "s_can": np.where(ge(t.ba_total, 150), 2, np.where(ge(t.ba_total, 100), 1, 0)),
 "s_dw": np.where(ge(t.snag_tpa, 36), 2, np.where(ge(t.snag_tpa, 18), 1, 0)),
 "s_ht_fuzzpt": np.where(ge(t.potapov_rh95, 25), 2, np.where(ge(t.potapov_rh95, 18), 1, 0))}, index=t.index)
for c in ["s_ba", "s_mat", "s_str", "s_can", "s_dw"]:
    print("C1 step1-rule vs T0", c, "agree", int((s[c] == t[c]).sum()), "of", len(t))
print("C1 s_ht from plot-table potapov vs T0 s_ht agree", int((s.s_ht_fuzzpt == t.s_ht).sum()))
# T0 internal consistency
cls = np.select([t.total_score >= 8, t.total_score >= 6, t.total_score >= 4], ["OG", "LS", "Transitioning LS"], "Not LSOG")
print("C2 T0 lsog_class != class(total_score)", int((cls != t.lsog_class).sum()), "trans_cut4==(ts>=4)", int(((t.total_score >= 4).astype(int) == t.trans_cut4).sum()))
print("C2b T0 total_score == sum axes", int((t[["s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht"]].sum(1) == t.total_score).sum()))
# tmp (true-coord potapov) vs T0
tm = pd.read_csv(TMP, dtype={"PLT_CN": str})
x = t.merge(tm[["PLT_CN", "s_ht", "s_ht_old", "total_score", "total_score_old", "canopy_ht_m", "canopy_ht_m_old"]], on="PLT_CN", suffixes=("", "_tmp"))
print("D1 T0 vs tmp rows", len(x), "s_ht==tmp.s_ht(true)", int((x.s_ht == x.s_ht_tmp).sum()), "s_ht==tmp.s_ht_old(fuzzed)", int((x.s_ht == x.s_ht_old).sum()),
      "ts==tmp.ts", int((x.total_score == x.total_score_tmp).sum()), "ts==tmp.ts_old", int((x.total_score == x.total_score_old).sum()))
print("D2 plot-table potapov == tmp canopy_ht_m(true)", int(np.isclose(x.potapov_rh95, x.canopy_ht_m).sum()), "== canopy_ht_m_old", int(np.isclose(x.potapov_rh95, x.canopy_ht_m_old).sum()),
      "T0.canopy_ht_m==true", int(np.isclose(x.canopy_ht_m_tmp if 'canopy_ht_m_tmp' in x else x.canopy_ht_m, x.canopy_ht_m).sum()))
print("D3 T0 canopy_ht_m == tmp true", int(np.isclose(x["canopy_ht_m"], x["canopy_ht_m_tmp"]).sum()) if "canopy_ht_m_tmp" in x.columns else "n/a")
# jobA rescoring at attribute visit (my implementation following r0 rules) vs r0 output
r = pd.read_csv(R0)
y = t.merge(r[["plot_id", "s_mat", "s_dw", "s_ht", "total_score", "lsog_class"]], on="plot_id", suffixes=("", "_r0"))
print("E1 r0 rows", len(r), "joined", len(y))
for c in ["s_ba", "s_str", "s_can", "s_ht"]:
    pass
for c in ["s_mat", "s_dw", "s_ht"]:
    print("E2 T0 vs r0 agree", c, round(100 * (y[c] == y[c + "_r0"]).mean(), 1))
print("E3 total_score agree %.1f" % (100 * (y.total_score == y.total_score_r0).mean()),
      "trans+ agree", int(((y.total_score >= 4) == (y.total_score_r0 >= 4)).sum()), "of", len(y))
c1 = np.select([y.total_score >= 8, y.total_score >= 6, y.total_score >= 4], [3, 2, 1], 0)
c2 = np.select([y.total_score_r0 >= 8, y.total_score_r0 >= 6, y.total_score_r0 >= 4], [3, 2, 1], 0)
c0 = y.lsog_class.map({"Not LSOG": 0, "Transitioning LS": 1, "LS": 2, "OG": 3})
print("E4 class agree direct", int((c1 == c2).sum()), "nonadjacent", int((abs(c1 - c2) > 1).sum()), "; carried-col vs r0", int((c0 == c2).sum()), "nonadj", int((abs(c0 - c2) > 1).sum()))
print("E5 unweighted trans+ step1 %.2f jobA %.2f" % (100 * (y.total_score >= 4).mean(), 100 * (y.total_score_r0 >= 4).mean()))
print("E6 crosstab direct\n", pd.crosstab(c1, c2).to_string())
# STDAGE coverage at attribute visit
print("F1 STDAGE at attr visit: na", int(t.STDAGE.isna().sum()), "zero", int((t.STDAGE == 0).sum()), ">=80", int((t.STDAGE >= 80).sum()))
# 3062 -> 2977: why dropped
d = t[~t.plot_id.isin(r.plot_id)]
print("G1 dropped", len(d), "by attr INVYR", d.INVYR.value_counts(dropna=False).to_dict(), "trans+ rate dropped %.1f" % (100 * (d.total_score >= 4).mean()))
