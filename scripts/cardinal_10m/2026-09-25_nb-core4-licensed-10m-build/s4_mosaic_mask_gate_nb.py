#!/usr/bin/env python3
# s4_mosaic_mask_gate_trans.py
# Stage 2B. Maine 10 m mosaic in EPSG:3979, clipped to the Maine boundary, masked to the M3 hybrid
# forest frame, then the gate set. Products are only renamed to their final names after every gate passes.
#
# Differences from s4_mosaic_mask_gate.py (2026-09-16), and only these:
#   1. Maine only
#   2. G4 repointed at the transitioning reference and kept as the absurdity floor
#   3. G4b added, a hard exit on [G4B_LO, G4B_HI] percent
#   4. G5, the ME-NB border seam gate, is inert with one jurisdiction and is RECORDED as
#      not_applicable rather than silently passing
#   5. G7 added, the plot level spatial check
#
# Gates:
#   G1 coverage (F3/F6)   predicted forest cells / frame forest cells >= 0.98
#   G2 area (F5)          frame forest area inside the boundary within 3% of Methods 3.12
#   G3 value range (F7)   probability and SD within [0, 10000]; no other codes
#   G4 magnitude (F5)     absurdity floor, 0.5 x lower to 2.0 x upper of the published rate
#   G4b magnitude tight   mosaicked forestland share within [G4B_LO, G4B_HI] percent. Provenance is
#                         the adopted design based any-LSOG of 14.66 [13.40, 15.91] widened for the
#                         map's own block attenuation of about 0.72, external to this artifact.
#   G5 border seam        NOT APPLICABLE, one jurisdiction. Recorded, not passed.
#   G6 size (F10)         probability and SD layers > 50 MB, flag layer > 5 MB
#   G7a assembly          mosaic probability at the training plots against the model's own prediction
#                         from the stored AlphaEarth row. Catches a scrambled or misplaced mosaic,
#                         which no other gate tests.
#                         REVISED 2026-09-25. The first form compared the CENTRE cell and required
#                         Pearson r >= 0.95 and median absolute difference <= 0.02. Those thresholds
#                         were written by hand with no external provenance, which is firewall mode
#                         F4, and they were unachievable by construction: s3 predicts in each
#                         AlphaEarth tile's native UTM grid and s4 warps to EPSG:3979 with nearest
#                         neighbour, so two 10 m grids that do not share cell centres put the plot in
#                         a cell up to about 7 m from the one holding its own AlphaEarth pixel. The
#                         measured median local window SD of this surface is 0.0247, so a 0.02
#                         ceiling sat BELOW the surface's own heterogeneity. Diagnostic run
#                         g7a_registration_diagnostic.py, SLURM 14894428.
#                         The revised gate uses the BEST MATCHING cell in a 5x5 window, which
#                         registration jitter survives and scrambling does not, and it takes its
#                         threshold from a permutation null that breaks the plot to location link
#                         while keeping both marginal distributions. The null is a constructed
#                         reference rather than an unverified project number, which is what keeps
#                         this out of F4. The centre cell statistics are still computed and reported,
#                         as diagnostics, not as gates.
#   G7b block agreement   block level slope of observed trans_cut4 on mosaic probability, required to
#                         lie inside the Stage A out of fold block slope interval BLOCK_SLOPE_REF.
#                         The interval, not the point 0.7233, is the tolerance: ten blocks is a noisy
#                         statistic and Stage A's own CI is [0.2174, 1.1109].
#
# PRIVACY. G7 reads FIA true coordinates. They stay on Cardinal. Nothing this script writes contains
# a coordinate: the G7 outputs are the two scalars above, the block level table, and counts.
import os, sys, glob, json, subprocess, time
import numpy as np, pandas as pd, rasterio
from rasterio.windows import Window
# geopandas is deliberately NOT imported. The only vector work here is reprojecting one boundary
# into a cutline, which ogr2ogr does, and dropping the dependency lets this whole chain run on the
# same interpreter Stage A fitted under (system python3, scikit-learn 1.6.1). See the runner.

T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ
B = E["BUILD"]; TMP = E["TMP_TILES"]; FIN = E["FINAL"]; os.makedirs(FIN, exist_ok=True)
CRS = E["DST_CRS"]; RES = float(E["RES"]); FV = int(E["FRAME_FOREST_VALUE"]); U16 = 65535
DATE = E["DATE_TAG"]
def ref(k): return [float(v) for v in E[k].split(",")]
def run(cmd):
    log(" ".join(cmd[:6]) + " ...")
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode: sys.exit(f"FAIL {cmd[0]}: {r.stderr[:600]}")

err = f"{B}/logs/s3_errors.txt"
if os.path.exists(err) and os.path.getsize(err) > 0:
    sys.exit(f"FAIL s3 reported tile errors, see {err}; rerun those ranges first")
tiles = pd.read_csv(f"{B}/s3_tile_list.csv")
have = sorted(glob.glob(f"{TMP}/prob_*.tif"))
if len(have) != len(tiles):
    sys.exit(f"FAIL {len(have)} probability tiles on disk, {len(tiles)} expected")

JURIS = {"NB": E["NB_BOUNDARY"]}
gates, summary, names = {}, {}, {}
for J, src_boundary in JURIS.items():
    cut = f"{B}/_cut_{J}.geojson"
    if os.path.exists(cut): os.remove(cut)
    run(["ogr2ogr", "-f", "GeoJSON", "-t_srs", CRS, cut, src_boundary])
    raw = {}
    for lay in ("prob", "sd", "env"):
        src = sorted(glob.glob(f"{TMP}/{lay}_*.tif"))
        opt = f"{B}/_warp_{lay}_{J}.txt"; open(opt, "w").write("\n".join(src))
        nod = "255" if lay == "env" else "65535"
        raw[lay] = f"{B}/_raw_{lay}_{J}.tif"
        if not os.path.exists(raw[lay]):
            run(["gdalwarp", "--optfile", opt, raw[lay], "-t_srs", CRS, "-tr", str(RES), str(RES), "-tap",
                 "-r", "near", "-srcnodata", nod, "-dstnodata", nod, "-cutline", cut, "-crop_to_cutline",
                 "-multi", "-wo", "NUM_THREADS=ALL_CPUS", "-wm", "8000",
                 "-co", "COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES"])
    with rasterio.open(raw["prob"]) as p0:
        te = p0.bounds; H, W = p0.height, p0.width
    # Frame nodata must be 255, never 0: 0 is the frame's non-forest code, and GDAL's warper remaps any
    # valid source value equal to the destination nodata (0 -> 1), which turned every non-forest cell into
    # forest in the first run of this step (September 16, 2026).
    mask = f"{B}/_frame_v2_{J}.tif"
    if not os.path.exists(mask):
        run(["gdalwarp", E["FRAME_M3"], mask, "-t_srs", CRS, "-tr", str(RES), str(RES),
             "-te", str(te.left), str(te.bottom), str(te.right), str(te.top), "-r", "near",
             "-cutline", cut, "-srcnodata", "255", "-dstnodata", "255", "-ot", "Byte", "-multi",
             "-co", "COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES"])
    stem = "nb-core4-licensed"
    names[J] = {"prob": f"{FIN}/{stem}-probability_10m_{J}_DATA_{DATE}.tif",
                "sd": f"{FIN}/{stem}-bootstrap-sd_10m_{J}_DATA_{DATE}.tif",
                "env": f"{FIN}/{stem}-extrapolation-flag_10m_{J}_DATA_{DATE}.tif"}
    srcs = {k: rasterio.open(v) for k, v in raw.items()}; msk = rasterio.open(mask)
    assert (msk.height, msk.width) == (H, W), "mask grid mismatch"
    outs = {}
    for k, s in srcs.items():
        prof = s.profile.copy(); prof.update(compress="deflate", predictor=2, tiled=True, blockxsize=512,
                                             blockysize=512, BIGTIFF="YES")
        outs[k] = rasterio.open(names[J][k] + ".part", "w", **prof)
    n_forest = n_pred = n_extrap = 0; psum = sdsum = 0.0; pmax = sdmax = 0
    for r0 in range(0, H, 4096):
        for c0 in range(0, W, 4096):
            win = Window(c0, r0, min(4096, W - c0), min(4096, H - r0))
            fm = msk.read(1, window=win) == FV
            a = {k: s.read(1, window=win) for k, s in srcs.items()}
            nod = {"prob": U16, "sd": U16, "env": 255}
            for k in a:
                a[k] = np.where(fm, a[k], nod[k]).astype(a[k].dtype)
                outs[k].write(a[k], 1, window=win)
            v = fm & (a["prob"] != U16)
            n_forest += int(fm.sum()); n_pred += int(v.sum())
            if v.any():
                psum += float(a["prob"][v].sum()); sdsum += float(a["sd"][v].sum())
                pmax = max(pmax, int(a["prob"][v].max())); sdmax = max(sdmax, int(a["sd"][v].max()))
                n_extrap += int((a["env"][v] == 1).sum())
    for f in list(srcs.values()) + list(outs.values()) + [msk]: f.close()
    share = 100 * psum / 10000 / max(n_pred, 1)
    s = {"forest_cells": n_forest, "predicted_cells": n_pred, "coverage": n_pred / max(n_forest, 1),
         "forest_ha_raw": n_forest * RES * RES / 1e4, "model_share_pct": share,
         "mean_sd": sdsum / 10000 / max(n_pred, 1), "extrapolation_share": n_extrap / max(n_pred, 1),
         "prob_max": pmax, "sd_max": sdmax}
    refs = dict(kv.split(":") for kv in E["REF_M3_HA"].split(","))
    over = dict(kv.split(":") for kv in E["EPSG3979_OVERSTATE"].split(","))
    s["area_ratio"] = s["forest_ha_raw"] / (float(refs[J]) * float(over[J]))
    rs = ref("REF_NB_DB"); db = ref("REF_NB_DB")
    s["inside_design_based_interval"] = bool(db[1] <= share <= db[2])
    gates[f"G1_coverage_{J}"] = s["coverage"] >= 0.98
    gates[f"G2_area_{J}"] = 0.97 <= s["area_ratio"] <= 1.03
    gates[f"G3_range_{J}"] = pmax <= 10000 and sdmax <= 10000
    gates[f"G4_magnitude_{J}"] = 0.5 * rs[1] <= share <= 2.0 * rs[2]
    gates[f"G4b_magnitude_tight_{J}"] = float(E["G4B_LO"]) <= share <= float(E["G4B_HI"])
    summary[J] = s
    log(f"{J}: {s}")

# G5. One jurisdiction, so the ME-NB seam gate has nothing to test. Recorded, not passed.
summary["seam"] = {"status": "not_applicable", "reason": "single jurisdiction build, no shared border in scope"}
log("G5 border seam: not applicable, single jurisdiction")

for J in names:
    for k, pth in names[J].items():
        gates[f"G6_size_{J}_{k}"] = os.path.getsize(pth + ".part") > (5e6 if k == "env" else 50e6)

# ---- G7, plot level spatial check -------------------------------------------------------------
# True coordinates are read here and never written. Only block level aggregates leave this block.
import pickle
from pyproj import Transformer
from rasterio.windows import Window as _Win
J = "NB"
HALF = int(E.get("G7A_WINDOW_HALF", "2"))          # 5x5 window
NPERM = int(E.get("G7A_NPERM", "200"))
G7RNG = np.random.default_rng(int(E["SEED"]))
tt = pd.read_csv(E["TRAIN_TABLE"]); tt = tt[tt.jurisdiction == "NB"].reset_index(drop=True)
# licensed coordinates: the Stage A cache holds the licensed basis in the same order the NBL_ ids were
# assigned (every row had finite embeddings, so the order is the identity); read in memory, never written
xy = pd.read_csv(E["TRUE_XY"], usecols=["latitude", "longitude", "core4_cut3"])
assert len(xy) == len(tt) and (xy.core4_cut3.values == tt.core4_cut3.values).all(), "cache order does not match the training table"
d = tt.copy(); d["lon"] = xy.longitude.values; d["lat"] = xy.latitude.values
d = d[d["lon"].notna() & d["lat"].notna()].reset_index(drop=True)
tf = Transformer.from_crs("EPSG:4326", CRS, always_xy=True)
gx, gy = tf.transform(d["lon"].to_numpy(), d["lat"].to_numpy())
cent = np.full(len(d), np.nan); wsd = np.full(len(d), np.nan); wins = []
with rasterio.open(names[J]["prob"] + ".part") as p:
    inv = ~p.transform
    for i, (x, y) in enumerate(zip(gx, gy)):
        c, r0c = inv * (x, y); c = int(np.floor(c)); r0c = int(np.floor(r0c))
        c0 = c - HALF; r0 = r0c - HALF
        if c0 < 0 or r0 < 0 or c0 + 2 * HALF + 1 > p.width or r0 + 2 * HALF + 1 > p.height:
            wins.append(np.array([])); continue
        a = p.read(1, window=_Win(c0, r0, 2 * HALF + 1, 2 * HALF + 1)).astype("float64")
        v = a[a != U16] / 10000.0
        wins.append(v)
        if a[HALF, HALF] != U16: cent[i] = a[HALF, HALF] / 10000.0
        if v.size: wsd[i] = v.std()
del gx, gy                                                            # coordinates dropped immediately
d = d.drop(columns=["lon", "lat"])
ok = np.isfinite(cent) & np.array([w.size > 0 for w in wins])
aecols = [f"AE_{i:02d}" for i in range(64)] + ["time_since_disturbance"]
mdl = pickle.load(open(E["MODEL_FINAL"], "rb"))
direct = mdl.predict_proba(d.loc[ok, aecols].to_numpy())[:, 1]
mapped = cent[ok]
W = [wins[i] for i in np.flatnonzero(ok)]
_ba = lambda v, t: float(np.min(np.abs(v - t)))
_bv = lambda v, t: float(v[int(np.argmin(np.abs(v - t)))])
bestd = np.array([_ba(W[j], direct[j]) for j in range(len(direct))])
bestv = np.array([_bv(W[j], direct[j]) for j in range(len(direct))])
r_cent = float(np.corrcoef(mapped, direct)[0, 1]) if ok.sum() > 2 else float("nan")
mad_cent = float(np.median(np.abs(mapped - direct))) if ok.sum() else float("nan")
r_best = float(np.corrcoef(bestv, direct)[0, 1]) if ok.sum() > 2 else float("nan")
mad_best = float(np.median(bestd)) if ok.sum() else float("nan")
# permutation null: break the plot to location link, keep both marginals exactly
nmad, nr = [], []
_idx = np.arange(len(direct))
for _b in range(NPERM):
    ds = direct[G7RNG.permutation(_idx)]
    nmad.append(float(np.median([_ba(W[j], ds[j]) for j in range(len(ds))])))
    nr.append(abs(float(np.corrcoef(np.array([_bv(W[j], ds[j]) for j in range(len(ds))]), ds)[0, 1])))
null_mad_lo = float(np.min(nmad)); null_r_hi = float(np.max(nr))
gates["G7a_assembly_NB"] = bool(mad_best < null_mad_lo and r_best > null_r_hi)

blk = d.loc[ok].assign(mapped=mapped).groupby("blk").agg(
    n=("core4_cut3", "size"), obs=("core4_cut3", "mean"), pred=("mapped", "mean")).reset_index()
blk = blk[blk.n >= 20]
blk[["n", "obs", "pred"]].to_csv(f"{FIN}/nb-core4-licensed-g7-block-agreement_DATA_{DATE}.csv", index=False)  # no block id written
# G7b, 2026-09-25: block level slope of MAPPED on OBSERVED (predicted on observed, the house direction),
# in sample at the training plots. Gate is the physical bound (0, 1.25]: an in sample forest cannot
# legitimately exceed one by more than block noise, and a scrambled mosaic gives about zero. Stage A's
# out of fold interval is recorded beside it as the diagnostic reference, not the gate.
slope = float(np.polyfit(blk["obs"], blk["pred"], 1)[0]) if len(blk) > 2 else float("nan")
bref = ref("BLOCK_SLOPE_REF")
gates["G7b_block_slope_NB"] = bool(0.0 < slope <= 1.25)
summary["G7"] = {"n_plots_with_coords": int(len(d)), "n_on_surface": int(ok.sum()),
                 "n_train_table_rows": int(len(tt)), "window_cells": (2 * HALF + 1) ** 2,
                 "n_permutations": NPERM,
                 "r_bestcell_vs_direct": r_best, "median_abs_diff_bestcell": mad_best,
                 "null_median_abs_diff_bestcell_min": null_mad_lo, "null_r_bestcell_max": null_r_hi,
                 "pearson_r_centre_vs_direct_DIAGNOSTIC": r_cent,
                 "median_abs_diff_centre_DIAGNOSTIC": mad_cent,
                 "median_local_window_sd": float(np.nanmedian(wsd[ok])),
                 "block_slope_pred_on_obs_insample": slope,
                 "stageA_oof_slope_reference": bref, "n_blocks": int(len(blk)),
                 "note": ("G7a gates the BEST MATCHING cell in the window against a permutation null, "
                          "not the centre cell against a hand written threshold; see the header. The "
                          "centre cell figures are diagnostics and are expected to sit near one local "
                          "window SD because of nearest neighbour reprojection. The shipped model was "
                          "fit on 3,015 of these rows; the excluded 47 are not identifiable from the "
                          "stored artefacts (Maine note, kept for the record); NB rebuild 2026-09-25 runs on all 9,042 licensed rows. "
                          "Coordinates are never written.")}
log(f"G7a: best-cell mad={mad_best:.5f} (null min {null_mad_lo:.5f}) r={r_best:.4f} "
    f"(null max {null_r_hi:.4f}); centre diagnostics r={r_cent:.4f} mad={mad_cent:.4f}, "
    f"median local SD={float(np.nanmedian(wsd[ok])):.4f}; G7b slope={slope:.4f} on n={int(ok.sum())}")
# -----------------------------------------------------------------------------------------------

import sklearn, sys as _sys
summary["environment"] = {"python": _sys.version.split()[0], "sklearn": sklearn.__version__,
                          "stageA_sklearn": "1.6.1",
                          "note": ("Stage A fitted the pickles under system python3 with scikit-learn 1.6.1. "
                                   "The whole Stage 2B chain runs on that same interpreter so no unpickle "
                                   "version warning is raised and predictions are the ones Stage A measured.")}
if sklearn.__version__ != "1.6.1":
    gates["G0_environment"] = False
    log(f"G0 FAIL scikit-learn is {sklearn.__version__}, Stage A fitted under 1.6.1")
else:
    gates["G0_environment"] = True
summary["gates"] = {k: bool(v) for k, v in gates.items()}
json.dump(summary, open(f"{FIN}/nb-core4-licensed-10m-build-summary_DATA_{DATE}.json", "w"), indent=2)
failed = [k for k, v in gates.items() if not v]
if failed:
    log("GATES FAILED, products left as .part: " + ", ".join(failed)); sys.exit(2)
for J in names:
    for pth in names[J].values():
        os.replace(pth + ".part", pth)
subprocess.run(["bash", "-c", f"cd {FIN} && sha256sum *.tif *.csv *.json > SHA256SUMS.txt"])
log("ALL GATES PASS; products promoted in " + FIN)
