# Sizes the MOSVR knee sensitivity surface: support-vector count and prediction rate on 1M rows.
import os, time, json, numpy as np, pandas as pd
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
B = os.environ["BUILD"]; FEAT = [f"AE_{i:02d}" for i in range(64)] + ["time_since_disturbance"]
d = pd.read_csv(f"{B}/core4_training_table_DATA_2026-09-16.csv")
X = d[FEAT].to_numpy(float); y = d.core4_cut3.to_numpy(float); w = d.w.to_numpy(float)
sx = StandardScaler().fit(X); my, sy = y.mean(), y.std()
t = time.time(); m = SVR(kernel="rbf", C=16, gamma=2 / 65, epsilon=0.1, cache_size=4000)
m.fit(sx.transform(X), (y - my) / sy, sample_weight=w); tf = time.time() - t
Z = sx.transform(X[np.random.default_rng(0).integers(0, len(X), 200000)])
t = time.time(); m.predict(Z); tp = (time.time() - t) / 200000 * 1e6
out = {"n_sv": int(len(m.support_)), "fit_s": tf, "predict_s_per_1M_rows_1core": tp,
       "forest_cells_10m_est": 1.94e9}
out["core_hours_final_only_10m"] = out["forest_cells_10m_est"] / 1e6 * tp / 3600
out["core_hours_final_plus_20boot_10m"] = out["core_hours_final_only_10m"] * 21
out["core_hours_final_only_30m"] = out["core_hours_final_only_10m"] / 9
print(json.dumps(out, indent=1)); json.dump(out, open(f"{B}/logs/svr_cost_probe.json", "w"), indent=1)
