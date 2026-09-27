#!/usr/bin/env python3
# tsd_extract_hansen_v112.py  (2026-09-16, at Aaron's request to carry the Hansen GFC v1.12 refresh)
# Rebuilds ONLY the time_since_disturbance covariate of topo_disturbance_extract_2026-09-03.py from
# Hansen GFC-2024-v1.12 lossyear, with the identical point set, id order, NB holder filter and mask,
# REF_YEAR = 2020 and 40-year no-loss sentinel. v1.12 appends loss year 24 (2024) and, per the
# September 7 probe, does not reprocess 2001 to 2023. ME true coordinates are read from the restricted
# crosswalk on Cardinal and never written anywhere. Output carries plot_id and derived values only,
# plus the v1.11 value for a change audit.
import numpy as np, pandas as pd, rasterio, os
R = "/fs/scratch/PUOM0008/crsfaaron"
VRT = f"{R}/hansen_gfc_v112/gfc_lossyear_v112_menb.vrt"
OLD = f"{R}/tolscore_surface/pooled_nojurisd_disturb_2026-09-04/topo_disturbance_covariates_2026-09-03.csv"
OUT = f"{R}/core4_10m/menb-core4-10m_2026-09-16/inputs/tsd_hansen_v112_DATA_2026-09-16.csv"
REF_YEAR = 2020
me = pd.read_csv(f"{R}/tmp_me_v51_restricted.csv")
pts = [pd.DataFrame({"plot_id": [f"ME_{i:05d}" for i in range(len(me))],
                     "lat": me["TRUE.LAT"].astype(float).values, "lon": me["TRUE.LON"].astype(float).values})]
nb = pd.read_csv("/users/PUOM0008/crsfaaron/LSOG/output_unified/nb_train_true_v51_public.csv")
print("NB holders present 16/20:", int(nb["Holder"].isin([16, 20]).sum()) if "Holder" in nb else "no Holder column")
if "Holder" in nb.columns:
    nb = nb[~nb["Holder"].isin([16, 20])].copy()
AE = [f"AE_{i:02d}" for i in range(64)]
m = (nb[AE].notna().all(axis=1) & np.isfinite(nb["total_score"]) & np.isfinite(nb["canopy_ht_m"])
     & np.isfinite(nb["lon"]) & np.isfinite(nb["lat"]))
nbf = nb[m].reset_index(drop=True)
pts.append(pd.DataFrame({"plot_id": [f"NB_{i+1:05d}" for i in range(len(nbf))],
                         "lat": nbf["lat"].values, "lon": nbf["lon"].values}))
pts = pd.concat(pts, ignore_index=True)
with rasterio.open(VRT) as g:
    assert str(g.crs) == "EPSG:4326", g.crs
    ly = np.array([v[0] for v in g.sample(list(zip(pts.lon, pts.lat)))], dtype=float)
dist = (ly > 0) & (ly <= 24)
tsd = np.where(dist, REF_YEAR - (2000 + ly), 40.0)
out = pd.DataFrame({"plot_id": pts.plot_id, "lossyear_v112": np.where(dist, ly, 0.0),
                    "time_since_disturbance": np.maximum(tsd, 0.0)})
old = pd.read_csv(OLD, usecols=["plot_id", "lossyear", "time_since_disturbance"]).rename(
    columns={"lossyear": "lossyear_v111", "time_since_disturbance": "tsd_v111"})
out = out.merge(old, on="plot_id", how="left")
chg = out[out.time_since_disturbance != out.tsd_v111]
print("points", len(out), "ME", int(out.plot_id.str.startswith("ME_").sum()), "NB", int(out.plot_id.str.startswith("NB_").sum()))
print("lossyear 24 (2024) plots:", int((out.lossyear_v112 == 24).sum()))
print("tsd changed vs v1.11:", len(chg), "of which v1.11 no-loss -> v1.12 loss:", int(((chg.tsd_v111 == 40) & (chg.time_since_disturbance < 40)).sum()))
print("lossyear changed for 2001-2023 values:", int(((out.lossyear_v111 > 0) & (out.lossyear_v111 != out.lossyear_v112)).sum()))
print("v1.11 tsd missing:", int(out.tsd_v111.isna().sum()))
out.to_csv(OUT, index=False)
print("written", OUT, os.path.getsize(OUT))
