import numpy as np, pandas as pd
T0 = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
TMP = "/fs/scratch/PUOM0008/crsfaaron/tmp_me_v51_restricted.csv"
R0 = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/out/me_training_table_relabel2023_RESTRICTED.csv"
t = pd.read_csv(T0); t = t[t.state == "ME"]
tm = pd.read_csv(TMP, dtype={"PLT_CN": str}); tm["plot_id"] = ["ME_%05d" % (i - 1) for i in tm.row_idx]
x = t[["plot_id", "total_score"]].merge(tm[["plot_id", "total_score", "s_ht", "s_ht_old"]], on="plot_id", suffixes=("", "_tmp"))
print("H0 rowidx key join", len(x), "ts agree", int((x.total_score == x.total_score_tmp).sum()))
r = pd.read_csv(R0)
y = r[["plot_id", "s_ba", "s_mat", "s_str", "s_can", "s_dw", "s_ht", "total_score"]].merge(tm[["plot_id", "s_ht", "s_ht_old", "s_mat", "s_dw", "total_score"]], on="plot_id", suffixes=("", "_s1"))
print("H1 r0 rows joined to step1 tmp", len(y))
print("H2 r0 s_ht == step1 true s_ht %.1f%%; == fuzzed %.1f%%" % (100 * (y.s_ht == y.s_ht_s1).mean(), 100 * (y.s_ht == y.s_ht_old).mean()))
alt = y.total_score - y.s_ht + y.s_ht_s1
print("H3 jobA with true-coord s_ht: trans+ rate %.2f vs r0 %.2f vs step1 %.2f" % (100 * (alt >= 4).mean(), 100 * (y.total_score >= 4).mean(), 100 * (y.total_score_s1 >= 4).mean()))
print("H4 trans+ label differs r0 vs jobA-true-ht", int(((alt >= 4) != (y.total_score >= 4)).sum()), "; jobA-true-ht vs step1 agree", int(((alt >= 4) == (y.total_score_s1 >= 4)).sum()), "of", len(y))
print("H5 step1 vs r0 trans+ agree", int(((y.total_score >= 4) == (y.total_score_s1 >= 4)).sum()))
d = t[~t.plot_id.isin(r.plot_id)][["plot_id"]].merge(tm[["plot_id", "row_idx"]], on="plot_id", how="left")
print("H6 dropped", len(d), "present in tmp", int(d.row_idx.notna().sum()))
