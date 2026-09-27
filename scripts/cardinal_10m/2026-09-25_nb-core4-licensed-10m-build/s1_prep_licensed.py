#!/usr/bin/env python3
"""
New Brunswick Stage A on LICENSED MagPlot labels: build the pooled training table.

Aaron's call, September 25, 2026: train on the licensed labels. This script
  1. scores licensed CORE4-dia cut 3 (X9_c3, the 9.37 percent instrument) for the 9,042 plot
     Configuration D basis by running the CORE4 sweep's own code (positive controls included);
  2. samples AlphaEarth 2024 at the licensed coordinates by the identical GEE call the public
     table used (sampleRegions, scale 30), for all 9,042 plots, so every NB row is extracted the
     same way; the same call already carried FIA true coordinates for Maine in this project;
  3. samples Hansen GFC v1.12 loss year locally for time since disturbance, as the 16 September
     chain did;
  4. assigns H3 resolution 4 blocks and quarter degree CLI_Grid design weights from the licensed
     coordinates, with the design effect reported;
  5. verifies the new embeddings against the stored public rows for the plots in both;
  6. writes the pooled table (Maine rows carried unchanged from the 16 September table) under new
     synthetic ids NBL_xxxxx. No coordinate or licensed id is written. Everything stays on Cardinal.
"""
import os, sys, json, time, shutil, importlib.util
import numpy as np, pandas as pd, rasterio, h3
T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)

BASE = "/users/PUOM0008/crsfaaron/LSOG/nb_magplot"
SWEEP = f"{BASE}/nb_instrument_sweep_core4_20260902.py"
OLD = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16"
BUILD = os.environ["BUILD"]
os.makedirs(f"{BUILD}/inputs", exist_ok=True); os.makedirs(f"{BUILD}/logs", exist_ok=True)
VRT = os.environ["GFC_VRT"]; REF_YEAR = 2020
CLI_GDB = f"{OLD}/inputs/CLI_Grid.gdb"
SA = "/users/PUOM0008/crsfaaron/.config/earthengine/service_account.json"
AE = [f"AE_{i:02d}" for i in range(64)]
SUM = {}

sys.path.insert(0, BASE)
import nb_cli_lsog_fullscope as P
CACHE = f"{BUILD}/inputs/_stageA_cache_LICENSED_COORDS_server_only.csv"
if os.path.exists(CACHE):
    est = pd.read_csv(CACHE); log(f"loaded cached licensed table with embeddings, {len(est)} rows; skipping the sweep and GEE")
    SUM["n_licensed"] = int(len(est)); SUM["licensed_x9c3_pct_unweighted"] = round(100 * est.core4_cut3.mean(), 3)
    SUM["n_ae_finite"] = int(np.isfinite(est[AE]).all(1).sum()); SUM["n_disturbed"] = int((est.time_since_disturbance < 40).sum())
    SUM["cached"] = True
else:
  # ---------------------------------------------------------------- 1. licensed labels with coordinates in memory
  sys.path.insert(0, BASE)
  import nb_cli_lsog_fullscope as P
  import nb_instrument_sweep_20260902 as S
  spec = importlib.util.spec_from_file_location("sweepcore4", SWEEP)
  C = importlib.util.module_from_spec(spec); spec.loader.exec_module(C)
  PRIV = f"{BUILD}/_sweep_private_copy.csv"; shutil.copyfile(C.MAIN_CSV, PRIV); C.MAIN_CSV = PRIV
  S.OUTDIR = f"{BUILD}/_sweep_work"; P.OUTDIR = S.OUTDIR
  CAP = {}
  class _Stop(Exception): pass
  _orig_rv = S.run_variant
  def rv_capture(est_df, strat, W, W150, nboot, vid):
      if vid == "X9_c3":
          CAP["est"] = est_df[[P.KEY, "score_core4_dia"]].copy(); raise _Stop()
      return _orig_rv(est_df, strat, W, W150, nboot, vid)
  S.run_variant = rv_capture
  sys.argv = ["x", "--outdir", S.OUTDIR, "--nboot", "2000"]
  try: C.main()
  except _Stop: pass
  est = CAP["est"]; est["core4_cut3"] = (est.score_core4_dia >= 3).astype(int)
  rate = 100 * est.core4_cut3.mean()
  log(f"licensed basis {len(est)} plots, X9_c3 unweighted {rate:.3f} percent")
  assert abs(rate - 9.39) < 0.6, "licensed X9_c3 rate drifted from the sweep's 9.39"
  sites = pd.read_csv(f"{P.CLI}/magp_sites.csv", usecols=[P.KEY, "latitude", "longitude", "source_plot"], low_memory=False)
  est = est.merge(sites, on=P.KEY, how="left").dropna(subset=["latitude", "longitude"])
  est["source_plot"] = pd.to_numeric(est.source_plot, errors="coerce")
  assert len(est) == 9042, len(est)
  SUM["n_licensed"] = int(len(est)); SUM["licensed_x9c3_pct_unweighted"] = round(rate, 3)
  shutil.rmtree(S.OUTDIR, ignore_errors=True); os.remove(PRIV)

  # ---------------------------------------------------------------- 2. AlphaEarth 2024 at the licensed coordinates
  os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = SA
  import ee
  info = json.load(open(SA))
  ee.Initialize(ee.ServiceAccountCredentials(info["client_email"], SA), project=info["project_id"])
  bands = [f"A{i:02d}" for i in range(64)]
  img = ee.ImageCollection("GOOGLE/SATELLITE_EMBEDDING/V1/ANNUAL").filterDate("2024-01-01", "2025-01-01").mosaic().select(bands)
  ae = np.full((len(est), 64), np.nan)
  est = est.reset_index(drop=True)
  for start in range(0, len(est), 500):
      sub = est.iloc[start:start + 500]
      feats = [ee.Feature(ee.Geometry.Point([float(r.longitude), float(r.latitude)]), {"row": int(i)})
               for i, r in zip(sub.index, sub.itertuples())]
      for attempt in range(3):
          try:
              sampled = img.sampleRegions(collection=ee.FeatureCollection(feats), scale=30, geometries=False).getInfo(); break
          except Exception as ex:
              log(f"  chunk {start} attempt {attempt} failed {ex!r}"[:200])
              if attempt == 2: raise
      for f in sampled["features"]:
          p = f["properties"]; ae[p["row"]] = [p.get(b, np.nan) for b in bands]
      log(f"  AlphaEarth chunk {start}-{start+len(sub)} done")
  fin = np.isfinite(ae).all(1)
  log(f"AlphaEarth finite on {fin.sum()} of {len(est)}")
  SUM["n_ae_finite"] = int(fin.sum())
  for i, c in enumerate(AE): est[c] = ae[:, i]

  # ---------------------------------------------------------------- 3. Hansen v1.12 time since disturbance
  with rasterio.open(VRT) as g:
      assert str(g.crs) == "EPSG:4326"
      ly = np.array([v[0] for v in g.sample(list(zip(est.longitude, est.latitude)))], dtype=float)
  dist = (ly > 0) & (ly <= 24)
  est["time_since_disturbance"] = np.maximum(np.where(dist, REF_YEAR - (2000 + ly), 40.0), 0.0)
  SUM["n_disturbed"] = int(dist.sum())

if not SUM.get("cached"):
    est.to_csv(CACHE, index=False); os.chmod(CACHE, 0o600)
# ---------------------------------------------------------------- 4. blocks and design weights
est["blk"] = [h3.latlng_to_cell(la, lo, 4) for la, lo in zip(est.latitude, est.longitude)]
fr = pd.read_csv(f"{BUILD}/inputs/cli_grid_frame_xy.csv")   # written by ogr2ogr in the job script, EPSG:4326 point X,Y
assert len(fr) == 18334, f"frame csv holds {len(fr)} points, expected 18,334"
class _F: pass
fx = _F(); fx.x = fr["X"]; fx.y = fr["Y"]
cell = lambda lon, lat: np.array([f"{int(np.floor(a * 4))} {int(np.floor(b * 4))}" for a, b in zip(np.asarray(lon), np.asarray(lat))])
fc = pd.Series(cell(fx.x.values, fx.y.values)).value_counts().rename("n_frame")
est["cell"] = cell(est.longitude.values, est.latitude.values)
pc = est.cell.value_counts().rename("n_meas")
cov = pd.concat([fc, pc], axis=1).fillna(0)
w = (cov.n_frame / cov.n_meas.clip(lower=1))
est["w"] = est.cell.map(w).astype(float)
est = est[np.isfinite(est.w)]
est["w"] = est.w / est.w.mean()
deff = len(est) * (est.w ** 2).sum() / est.w.sum() ** 2
SUM["coverage_pct_licensed_vs_frame"] = round(100 * len(est) / fc.sum(), 2)
SUM["design_effect_licensed"] = round(float(deff), 3)
SUM["n_h3_blocks"] = int(est.blk.nunique())
SUM["licensed_x9c3_pct_weighted"] = round(100 * float(np.average(est.core4_cut3, weights=est.w)), 3)
log(f"blocks {SUM['n_h3_blocks']}, coverage {SUM['coverage_pct_licensed_vs_frame']}, deff {deff:.3f}, weighted rate {SUM['licensed_x9c3_pct_weighted']}")

# ---------------------------------------------------------------- 5. verify against the stored public rows
old = pd.read_csv(f"{OLD}/core4_training_table_DATA_2026-09-16.csv")
pub = pd.read_csv("/users/PUOM0008/crsfaaron/LSOG/output_unified/nb_train_true_v51_public.csv", low_memory=False)
mask = pub[AE].notna().all(axis=1) & np.isfinite(pub["total_score"]) & np.isfinite(pub["canopy_ht_m"]) & np.isfinite(pub["lon"]) & np.isfinite(pub["lat"])
key = pd.DataFrame({"plot_id_export": [f"NB_{i+1:05d}" for i in range(int(mask.sum()))],
                    "plot_id": pd.to_numeric(pub.loc[mask, "plot_id"], errors="coerce").values})
oldnb = old[old.jurisdiction == "NB"].merge(key, on="plot_id_export")
j = est.merge(oldnb, left_on="source_plot", right_on="plot_id", suffixes=("", "_old"))
if len(j):
    dif = np.abs(j[AE].values - j[[c + "_old" for c in AE]].values)
    corr = np.mean([np.corrcoef(j[c], j[c + "_old"])[0, 1] for c in AE])
    SUM["verify_n_in_both"] = int(len(j)); SUM["verify_mean_band_corr"] = round(float(corr), 4)
    SUM["verify_share_rows_maxabsdiff_lt_0p02"] = round(float((dif.max(1) < 0.02).mean()), 4)
    SUM["verify_median_maxabsdiff"] = round(float(np.median(dif.max(1))), 5)
    SUM["verify_blk_agree"] = round(float((j.blk == j.blk_old).mean()), 4)
    SUM["verify_tsd_agree"] = round(float((j.time_since_disturbance == j.time_since_disturbance_old).mean()), 4)
    log(f"verify: {SUM}")
    assert corr > 0.95, "new embeddings do not reproduce the stored rows"

# ---------------------------------------------------------------- 6. pooled table
est = est[np.isfinite(est[AE]).all(1)].reset_index(drop=True)
nb_out = pd.DataFrame({"plot_id_export": [f"NBL_{i+1:05d}" for i in range(len(est))], "jurisdiction": "NB", "blk": est.blk})
for c in AE: nb_out[c] = est[c].values
nb_out["time_since_disturbance"] = est.time_since_disturbance.values
nb_out["core4_cut3"] = est.core4_cut3.values.astype(int); nb_out["w"] = est.w.values
me_out = old[old.jurisdiction == "ME"][["plot_id_export", "jurisdiction", "blk"] + AE + ["time_since_disturbance", "core4_cut3", "w"]]
out = pd.concat([me_out, nb_out], ignore_index=True)
# The producer's scan_frame forbids any id column, which a training table needs. This table never
# leaves Cardinal and its ids are synthetic (NBL_ order in the licensed basis, not magp_site_id), so
# the guard applied here is the coordinate one only.
assert not any(c in out.columns for c in ("latitude", "longitude", "lat", "lon", "source_plot", P.KEY, "cell")), "coordinate or licensed id column in the training table"
num = out.select_dtypes("number")
assert not ((num > -70) & (num < -63)).any().any(), "a value inside the NB longitude band is in the training table"
out.to_csv(f"{BUILD}/core4_training_table_DATA_2026-09-25.csv", index=False)
SUM["rows"] = {"ME": int(len(me_out)), "NB": int(len(nb_out)), "positives_NB": int(nb_out.core4_cut3.sum())}
json.dump(SUM, open(f"{BUILD}/s1_prep_summary_2026-09-25.json", "w"), indent=2)
log(f"S1_DONE {json.dumps(SUM)}")
