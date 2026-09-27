# Rebuilds nb_public_plot_xy.csv with the exact synth_id rule of pooled_train_2026-09-03.py (lines 32-38).
# NB public CLI plots only. Rows outside the training mask get NBX_ ids so coverage uses all scored plots.
import numpy as np, pandas as pd, os
L = os.path.expanduser("~/LSOG")
B = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16"
nb = pd.read_csv(f"{L}/output_unified/nb_train_true_v51_public.csv")
AE = [f"AE_{i:02d}" for i in range(64)]
mask = nb[AE].notna().all(axis=1) & np.isfinite(nb["total_score"]) & np.isfinite(nb["canopy_ht_m"]) \
       & np.isfinite(nb["lon"]) & np.isfinite(nb["lat"])
nb["plot_id_export"] = None
nb.loc[mask, "plot_id_export"] = [f"NB_{i+1:05d}" for i in range(int(mask.sum()))]
rest = (~mask) & np.isfinite(nb["lon"]) & np.isfinite(nb["lat"])
nb.loc[rest, "plot_id_export"] = [f"NBX_{i+1:05d}" for i in range(int(rest.sum()))]
print("state values", nb["state"].value_counts(dropna=False).to_dict())
out = nb.loc[nb.plot_id_export.notna(), ["plot_id_export", "lon", "lat", "total_score", "canopy_ht_m"]]
s = pd.read_csv(f"{B}/inputs/samp_dat_core4_DATA_2026-09-02.csv")
j = out.merge(s[s.jurisdiction == "NB"], left_on="plot_id_export", right_on="plot_id", suffixes=("", "_s"))
print("rows total", len(nb), "mask", int(mask.sum()), "NBX", int(rest.sum()),
      "sample NB", int((s.jurisdiction == "NB").sum()), "joined", len(j))
print("total_score agree", float((j.total_score == j.total_score_s).mean()),
      "canopy agree", float(np.isclose(j.canopy_ht_m, j.canopy_ht_m_s).mean()))
assert not out.plot_id_export.str.startswith("ME_").any()
print("lon range", out.lon.min(), out.lon.max(), "lat range", out.lat.min(), out.lat.max())
assert out.lon.between(-69.2, -63.6).all() and out.lat.between(44.4, 48.2).all(), "coordinate outside NB box"
out[["plot_id_export", "lon", "lat"]].to_csv(f"{B}/inputs/nb_public_plot_xy.csv", index=False)
print("written", len(out))
