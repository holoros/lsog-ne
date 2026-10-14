import pandas as pd
T0 = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/me_transitioning_training_table_DATA_2026-09-23.csv"
TMP = "/fs/scratch/PUOM0008/crsfaaron/tmp_me_v51_restricted.csv"
R0 = "/users/PUOM0008/crsfaaron/LSOG/2026-10-12_occ-ordinal-relabel/out/me_training_table_relabel2023_RESTRICTED.csv"
J = "/fs/scratch/PUOM0008/crsfaaron/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
t = pd.read_csv(T0); t = t[t.state == "ME"][["plot_id", "total_score"]]
tm = pd.read_csv(TMP, dtype={"PLT_CN": str}); tm["plot_id"] = ["ME_%05d" % (i - 1) for i in tm.row_idx]
j = pd.read_csv(J, dtype={"PLT_CN": str})
j = j[j.plot_id.str.startswith("ME")]
print("J ME rows", len(j), "unique plot_id", j.plot_id.nunique())
x = tm[["plot_id", "PLT_CN"]].merge(j[["plot_id", "PLT_CN"]], on="plot_id", how="left", suffixes=("", "_J"))
print("J PLT_CN missing", int(x.PLT_CN_J.isna().sum()), "J PLT_CN != step1 PLT_CN (non-missing)", int(((x.PLT_CN != x.PLT_CN_J) & x.PLT_CN_J.notna()).sum()))
pl = pd.read_csv("/users/PUOM0008/crsfaaron/fia_data/ME_PLOT.csv", usecols=["CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "INVYR"], dtype={"CN": str})
k = ["STATECD", "UNITCD", "COUNTYCD", "PLOT"]
u = pd.read_csv("/users/PUOM0008/crsfaaron/LSOG/output_unified/lsog_ne_plot_table.csv", dtype={"CN": str}, usecols=["state", "CN", "INVYR"])
u = u[u.state == "ME"].merge(pl[["CN"] + k], on="CN")
lat = u.sort_values(k + ["INVYR"]).groupby(k).tail(1)[k + ["INVYR"]]
miss = x[x.PLT_CN_J.isna()][["plot_id", "PLT_CN"]].merge(pl.rename(columns={"CN": "PLT_CN"})[["PLT_CN"] + k], on="PLT_CN", how="left").merge(lat, on=k, how="left")
print("39-gap plots: latest attr INVYR", miss.INVYR.value_counts(dropna=False).sort_index().to_dict())
r = pd.read_csv(R0, usecols=["plot_id"])
print("of 39-gap plots in r0", int(miss.plot_id.isin(r.plot_id).sum()))
tt = t.merge(tm[["plot_id", "PLT_CN"]], on="plot_id").merge(pl.rename(columns={"CN": "PLT_CN"})[["PLT_CN"] + k], on="PLT_CN").merge(lat, on=k, how="left")
tt["in_r0"] = tt.plot_id.isin(r.plot_id)
print("all 3062 latest INVYR x in_r0", tt.groupby([tt.INVYR.between(2019, 2023), "in_r0"]).size().to_dict())
