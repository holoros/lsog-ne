#!/usr/bin/env python3
"""
SAE block prep, 2026-09-27. Runs on Cardinal, where the coordinates live. For each 10 m surface it writes
BLOCK AGGREGATES ONLY (no plot rows, no coordinates, no plot ids) for the small area estimation fit on
firebreather:
  plots side:  per H3 resolution 4 cell, n, positives, sum w, sum w^2, sum w*y, sum w*oof, sum w*e, sum w*e^2
               with e = y - oof, oof the out of fold (cross fitted) probability of the shipped model form;
  map side:    per H3 cell, the systematic 1-in-100 cell sample (every 10th row and column, a 100 m grid) of
               the masked forestland probability surface, its count, mean, and percentiles 1 to 99.
New Brunswick cells are relabeled to anonymous ids (NB_A001...) so no licensed aggregate is joinable to a
place outside Cardinal; the key stays here in _nb_h3_key_SERVER_ONLY.csv (mode 600).
Usage: sae_block_prep.py SURFACE [SURFACE ...]  with SURFACE in ME_TRANS ME_CORE4 ME_CORE4J NB_CORE4L NB_TRANSL
"""
import os, sys, json, time
import numpy as np, pandas as pd, rasterio
from rasterio.enums import Resampling
from pyproj import Transformer
import h3
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
def cell(lat, lng):
    return h3.latlng_to_cell(lat, lng, 4) if hasattr(h3, "latlng_to_cell") else h3.geo_to_h3(lat, lng, 4)
OUT = os.path.expanduser("~/LSOG/2026-09-27_sae-block-prep/out"); os.makedirs(OUT, exist_ok=True)
S = "/fs/scratch/PUOM0008/crsfaaron"; L = os.path.expanduser("~/LSOG")
PLTCN = f"{S}/tolscore_surface/join_validation_plotid_to_pltcn_2026-09-03.csv"
TRUEXY = f"{L}/data/validation_restricted/lsog_train_true.csv"
SEED = 20260927

def me_xy(ids):
    jj = pd.read_csv(PLTCN, dtype=str); xy = pd.read_csv(TRUEXY, dtype={"plot_id": str})
    d = (pd.DataFrame({"plot_id": ids}).merge(jj[["plot_id", "PLT_CN"]], on="plot_id", how="left")
         .merge(xy[["plot_id", "lon", "lat"]].rename(columns={"plot_id": "PLT_CN"}), on="PLT_CN", how="left"))
    return d.lat.values, d.lon.values

def oof_me_trans():
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.model_selection import GroupKFold
    from sklearn.metrics import roc_auc_score
    t = pd.read_csv(f"{L}/products/me-transitioning-10m_2026-09-23/stageA/me_transitioning_training_table_DATA_2026-09-23.csv", dtype={"plot_id": str})
    AE = [f"AE_{i:02d}" for i in range(64)]
    X = t[AE].to_numpy(float); y = (t.total_score >= 4).astype(int).to_numpy(); g = t.spatial_block.to_numpy()
    oof = np.full(len(t), np.nan)
    for tr, te in GroupKFold(n_splits=5).split(X, groups=g):
        m = RandomForestClassifier(n_estimators=300, min_samples_leaf=3, max_features="sqrt", n_jobs=-1, random_state=20260917)
        m.fit(X[tr], y[tr]); oof[te] = m.predict_proba(X[te])[:, 1]
    auc = float(roc_auc_score(y, oof)); log(f"ME_TRANS recomputed OOF AUC {auc:.4f} (Stage A shipped 0.781), mean {100*oof.mean():.2f} vs obs {100*y.mean():.2f}")
    lat, lon = me_xy(t.plot_id.astype(str).values)
    return pd.DataFrame({"y": y, "w": 1.0, "oof": oof, "lat": lat, "lon": lon}), {"oof_auc_recomputed": auc}

def from_s2(oof_csv, jur, xy_fn):
    o = pd.read_csv(oof_csv); o = o[o.jurisdiction == jur].reset_index(drop=True)
    lat, lon = xy_fn(o)
    return pd.DataFrame({"y": o.observed.values, "w": o.w.values, "oof": o.oof_prob.values, "lat": lat, "lon": lon}), {}

def nb_cache_xy(cache, labcol, table):
    def f(o):
        c = pd.read_csv(cache, usecols=["latitude", "longitude", labcol])
        assert len(c) == len(o) and (c[labcol].values == o.observed.values).all(), "cache order mismatch"
        return c.latitude.values, c.longitude.values
    return f

SURF = {
 "ME_TRANS": dict(ras=f"{L}/products/me-transitioning-10m_2026-09-23/me-transitioning-and-above-probability_10m_ME_DATA_2026-09-23.tif",
                  plots=oof_me_trans),
 "ME_CORE4": dict(ras=f"{S}/core4_10m/menb-core4-10m_2026-09-16/final/core4-structural-core-probability_10m_ME_DATA_2026-09-16.tif",
                  plots=lambda: from_s2(f"{S}/core4_10m/menb-core4-10m_2026-09-16/s2_rf_oof_DATA_2026-09-16.csv", "ME",
                                        lambda o: me_xy(o.plot_id_export.astype(str).values))),
 "ME_CORE4J": dict(ras=f"{S}/core4_10m/menb-core4-10m_2026-09-16/final/core4-structural-core-probability-jurcal_10m_ME_DATA_2026-09-16.tif",
                  plots=lambda: from_s2(f"{S}/core4_10m/menb-core4-10m_2026-09-16/s2_rf_oof_DATA_2026-09-16.csv", "ME",
                                        lambda o: me_xy(o.plot_id_export.astype(str).values))),
 "NB_CORE4L": dict(ras=f"{L}/products/nb-core4-licensed-10m_2026-09-25/nb-core4-licensed-probability_10m_NB_DATA_2026-09-25.tif",
                   plots=lambda: from_s2(f"{S}/core4_10m/nb-core4-licensed-10m_2026-09-25/s2_rf_oof_DATA_2026-09-25.csv", "NB",
                                         nb_cache_xy(f"{S}/core4_10m/nb-core4-licensed-10m_2026-09-25/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv", "core4_cut3", None))),
 "NB_TRANSL": dict(ras=f"{S}/trans_10m/nb-trans-licensed-10m_2026-09-27/final/nb-trans-licensed-probability_10m_NB_DATA_2026-09-27.tif",
                   plots=lambda: from_s2(f"{S}/trans_10m/nb-trans-licensed-10m_2026-09-27/s2_rf_oof_DATA_2026-09-27.csv", "NB",
                                         nb_cache_xy(f"{S}/trans_10m/nb-trans-licensed-10m_2026-09-27/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv", "trans_ge4", None))),
}

def map_blocks(path):
    if not os.path.exists(path):
        alt = path.replace("/products/", "/X/")
        raise SystemExit(f"raster missing {path}")
    with rasterio.open(path) as r:
        H, W = r.height // 10, r.width // 10
        a = r.read(1, out_shape=(H, W), resampling=Resampling.nearest)
        nd = r.nodata; dt = r.dtypes[0]; T = r.transform; crs = r.crs
    ok = (a != nd) if nd is not None else np.isfinite(a)
    rr, cc = np.nonzero(ok)
    v = a[rr, cc].astype("float64"); v = v / 10000.0 if dt.startswith("uint") else v
    # centres of the decimated cells in the full grid: row i*10 + 4.5
    xs = T.c + (cc * 10 + 5) * T.a; ys = T.f + (rr * 10 + 5) * T.e
    lon, lat = Transformer.from_crs(crs, "EPSG:4326", always_xy=True).transform(xs, ys)
    hc = np.array([cell(la, lo) for la, lo in zip(lat, lon)])
    df = pd.DataFrame({"h3": hc, "p": v})
    q = df.groupby("h3").p.quantile([i / 100 for i in range(1, 100)]).unstack()
    q.columns = [f"q{int(round(c*100)):02d}" for c in q.columns]
    g = df.groupby("h3").p.agg(n_cells="size", map_mean="mean").join(q).reset_index()
    log(f"  raster {os.path.basename(path)} dtype {dt} nodata {nd}, sampled cells {len(df)}, blocks {len(g)}, mean {v.mean():.4f}")
    return g

res = {}
for sname in sys.argv[1:]:
    log(f"== {sname}")
    cfg = SURF[sname]
    P, meta = cfg["plots"]()
    miss = int(np.isnan(P.lat).sum()); P = P[np.isfinite(P.lat)].reset_index(drop=True)
    P["h3"] = [cell(a, b) for a, b in zip(P.lat, P.lon)]
    P["e"] = P.y - P.oof
    P = P.assign(wy=P.w * P.y, wo=P.w * P.oof, we=P.w * P.e, we2=P.w * P.e ** 2, w2=P.w ** 2, wy2=P.w * P.y ** 2)
    pb = P.groupby("h3").agg(n=("y", "size"), npos=("y", "sum"), sw=("w", "sum"), sw2=("w2", "sum"), swy=("wy", "sum"),
                             swo=("wo", "sum"), swe=("we", "sum"), swe2=("we2", "sum")).reset_index()
    mb = map_blocks(cfg["ras"])
    B = mb.merge(pb, on="h3", how="outer")
    if sname.startswith("NB"):
        key = B[["h3"]].copy(); key["anon"] = [f"NB_A{i+1:03d}" for i in range(len(key))]
        kp = f"{OUT}/_nb_h3_key_{sname}_SERVER_ONLY.csv"; key.to_csv(kp, index=False); os.chmod(kp, 0o600)
        B["h3"] = key.anon.values
    B.to_csv(f"{OUT}/sae_blocks_{sname}_DATA_2026-09-27.csv", index=False)
    res[sname] = {**meta, "plots_used": int(len(P)), "plots_without_coords": miss, "blocks_total": int(len(B)),
                  "blocks_with_plots": int(pb.shape[0]), "blocks_with_map": int(mb.shape[0]),
                  "plots_in_blocks_without_map": int(B.loc[B.n_cells.isna(), "n"].sum()),
                  "map_cells_in_blocks_without_plots": int(B.loc[B.n.isna(), "n_cells"].sum()),
                  "weighted_obs_pct": float(100 * P.wy.sum() / P.w.sum()), "weighted_oof_pct": float(100 * P.wo.sum() / P.w.sum()),
                  "map_mean_pct_sample": float(100 * (mb.map_mean * mb.n_cells).sum() / mb.n_cells.sum())}
    log(json.dumps(res[sname]))
json.dump(res, open(f"{OUT}/sae_block_prep_summary_{'_'.join(sys.argv[1:])}_2026-09-27.json", "w"), indent=2)
log("PREP_DONE")
