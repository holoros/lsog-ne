#!/usr/bin/env python3
# s4_mosaic_mask_gate.py
# Per-jurisdiction 10 m mosaics in EPSG:3979, clipped to each boundary, masked to the M3 hybrid forest
# frame, then the gate set. Products are only renamed to their final names after every gate passes.
# Gates (references from config.sh, all published):
#   G1 coverage (F3/F6)   predicted forest cells / frame forest cells >= 0.98 in each jurisdiction
#   G2 area (F5)          frame forest area inside each boundary within 3% of Methods 3.12
#   G3 value range (F7)   probability and SD within [0, 10000]; no other codes
#   G4 magnitude (F5)     model-based share within absurdity bounds of the published sample rate
#                         (0.5 x lower, 2 x upper); position against the design-based interval reported
#   G5 border seam        forest frame, shared ME-NB border only, 0-500 m bands; |jump| <= mean SD there
#   G6 size (F10)         probability and SD layers > 50 MB, flag layer > 5 MB
import os, sys, glob, json, subprocess, time
import numpy as np, pandas as pd, rasterio, geopandas as gpd
from rasterio.windows import Window, from_bounds
from rasterio.features import rasterize
from scipy.ndimage import distance_transform_edt
from shapely.ops import unary_union
from shapely.geometry import box

T0 = time.time()
def log(m): print(f"[{time.time()-T0:8.1f}s] {m}", flush=True)
E = os.environ
B = E["BUILD"]; TMP = E["TMP_TILES"]; FIN = E["FINAL"]; os.makedirs(FIN, exist_ok=True)
CRS = E["DST_CRS"]; RES = float(E["RES"]); FV = int(E["FRAME_FOREST_VALUE"]); U16 = 65535
DATE = "2026-09-16"
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

bounds = {"ME": gpd.read_file(E["ME_BOUNDARY"]).to_crs(CRS), "NB": gpd.read_file(E["NB_BOUNDARY"]).to_crs(CRS)}
gates, summary = {}, {}
names = {}
for J, g in bounds.items():
    cut = f"{B}/_cut_{J}.geojson"; g.to_file(cut, driver="GeoJSON")
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
    # Frame nodata must be 255, never 0: 0 is the frame's non-forest code, and GDAL's warper remaps any valid
    # source value equal to the destination nodata (0 -> 1), which turned every non-forest cell into forest
    # in the first run of this step (September 16, 2026). _frame_v2 names keep the bad cache from being reused.
    mask = f"{B}/_frame_v2_{J}.tif"
    if not os.path.exists(mask):
        run(["gdalwarp", E["FRAME_M3"], mask, "-t_srs", CRS, "-tr", str(RES), str(RES),
             "-te", str(te.left), str(te.bottom), str(te.right), str(te.top), "-r", "near",
             "-cutline", cut, "-srcnodata", "255", "-dstnodata", "255", "-ot", "Byte", "-multi",
             "-co", "COMPRESS=DEFLATE", "-co", "TILED=YES", "-co", "BIGTIFF=YES"])
    stem = f"core4-structural-core"
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
    rs = ref("REF_ME_SAMPLE_RATE" if J == "ME" else "REF_NB_PUBLIC_RATE")
    db = ref("REF_ME_DB" if J == "ME" else "REF_NB_DB")
    s["inside_design_based_interval"] = bool(db[1] <= share <= db[2])
    gates[f"G1_coverage_{J}"] = s["coverage"] >= 0.98
    gates[f"G2_area_{J}"] = 0.97 <= s["area_ratio"] <= 1.03
    gates[f"G3_range_{J}"] = pmax <= 10000 and sdmax <= 10000
    gates[f"G4_magnitude_{J}"] = 0.5 * rs[1] <= share <= 2.0 * rs[2]
    summary[J] = s
    log(f"{J}: {s}")

# G5 border seam on the forest frame, shared border only, in 20 km pieces
line = unary_union(bounds["ME"].geometry).boundary.intersection(unary_union(bounds["NB"].geometry).buffer(1000))  # 1 km tolerance for boundary sources that differ in generalization
rows = []
if line.is_empty:
    gates["G5_seam"] = False; log("FAIL shared border is empty")
else:
    segs = [line.intersection(box(x, y, x + 20000, y + 20000))
            for x in np.arange(line.bounds[0] - 1, line.bounds[2], 20000)
            for y in np.arange(line.bounds[1] - 1, line.bounds[3], 20000)]
    acc = {}
    for seg in segs:
        if seg.is_empty: continue
        bb = seg.buffer(3000).bounds
        for J in ("ME", "NB"):
            with rasterio.open(names[J]["prob"] + ".part") as p, rasterio.open(names[J]["sd"] + ".part") as q:
                w = from_bounds(*bb, transform=p.transform).round_offsets().round_lengths()
                pa = p.read(1, window=w, boundless=True, fill_value=U16)
                qa = q.read(1, window=w, boundless=True, fill_value=U16)
                wt = p.window_transform(w)
            ln = rasterize([(seg, 1)], out_shape=pa.shape, transform=wt, fill=0, all_touched=True)
            dist = distance_transform_edt(ln == 0) * RES
            v = pa != U16
            for lo in range(0, 3000, 500):
                m = v & (dist > lo) & (dist <= lo + 500)
                if m.any():
                    k = (J, lo); c = acc.setdefault(k, [0, 0.0, 0.0])
                    c[0] += int(m.sum()); c[1] += float(pa[m].sum()) / 10000; c[2] += float(qa[m].sum()) / 10000
    for (J, lo), (n, ps, ss) in sorted(acc.items()):
        rows.append({"side": J, "band_lo_m": lo, "band_hi_m": lo + 500, "n": n, "mean_prob": ps / n, "mean_sd": ss / n})
    seam = pd.DataFrame(rows); seam.to_csv(f"{FIN}/core4-border-seam-forest-frame_10m_DATA_{DATE}.csv", index=False)
    a0 = seam[(seam.band_lo_m == 0)].set_index("side")
    jump = float(a0.loc["NB", "mean_prob"] - a0.loc["ME", "mean_prob"])
    tol = float(a0["mean_sd"].mean())
    summary["seam"] = {"jump_nb_minus_me": jump, "tolerance_mean_sd": tol}
    gates["G5_seam"] = abs(jump) <= tol
    log(f"seam jump {jump:.4f} vs tolerance {tol:.4f}")

for J in names:
    for k, pth in names[J].items():
        gates[f"G6_size_{J}_{k}"] = os.path.getsize(pth + ".part") > (5e6 if k == "env" else 50e6)
summary["gates"] = {k: bool(v) for k, v in gates.items()}
json.dump(summary, open(f"{FIN}/core4-10m-build-summary_DATA_{DATE}.json", "w"), indent=2)
failed = [k for k, v in gates.items() if not v]
if failed:
    log("GATES FAILED, products left as .part: " + ", ".join(failed)); sys.exit(2)
for J in names:
    for pth in names[J].values():
        os.replace(pth + ".part", pth)
subprocess.run(["bash", "-c", f"cd {FIN} && sha256sum *.tif *.csv *.json > SHA256SUMS.txt"])
log("ALL GATES PASS; products promoted in " + FIN)
