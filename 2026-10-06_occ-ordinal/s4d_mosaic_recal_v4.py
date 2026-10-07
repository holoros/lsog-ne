#!/usr/bin/env python3
# s4d_mosaic_recal_v4.py  Mosaic the 10 m v4 tiles to EPSG:3979 (Maine cutline), recalibrate the three cumulative
# LSOG layers to FIA prevalence by prior shift (as f4 on firebreather), gate, then aggregate the gated 10 m
# products to 30 m and 100 m by averaging (fine first, then aggregate). Products stay _PROVISIONAL unless every
# gate passes. Gates: coverage of the M3 frame >= 0.98; values in [0, 1]; ordering; frame area within 5 percent
# of 7.41 Mha; recalibrated statewide mean P(>= transitioning) inside the FIA interval [13.40, 15.91].
import os, glob, json, subprocess, numpy as np, pandas as pd, rasterio
E = os.environ; OUT = E["OUT"]; FIN = f"{OUT}/final"; AGG = f"{OUT}/agg"; os.makedirs(FIN, exist_ok=True)
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
def sh(c): print("$", c, flush=True); subprocess.run(c, shell=True, check=True)
tiles = sorted(glob.glob(f"{OUT}/tiles_v4/ord_v4_*.tif")); print("tiles", len(tiles), flush=True)
cov = pd.concat([pd.read_csv(f) for f in glob.glob(f"{OUT}/tiles_v4/cov_*.csv")]); cov.to_csv(f"{AGG}/coverage_v4_DATA.csv", index=False)
# G1 is measured inside Maine only: the tiles also hold New Hampshire and Quebec frame cells that the structure
# layers (Maine extent) do not cover and the cutline removes, so the tile level share is not the Maine coverage.
import json as _j
from rasterio.features import geometry_mask
with rasterio.open(E["FRAME_M3"]) as fr:
    gj = _j.load(open(CUT)); geoms = [f["geometry"] for f in gj["features"]]
    inside = ~geometry_mask(geoms, out_shape=(fr.height, fr.width), transform=fr.transform)
    frame_me_cells30 = int(((fr.read(1) == int(E["FRAME_FOREST_VALUE"])) & inside).sum())
print(f"M3 frame forest inside Maine: {frame_me_cells30} cells at 30 m", flush=True)
open(f"{OUT}/_v4_list.txt", "w").write("\n".join(tiles))
raw = f"{FIN}/occ-ordinal-v4-lsog_10m_ME_DATA_2026-10-06_PROVISIONAL.tif"
sh(f"gdalwarp -overwrite -t_srs EPSG:3979 -tr 10 10 -tap -r near -srcnodata 65535 -dstnodata 65535 -cutline {CUT} -crop_to_cutline "
   f"-co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS -multi --optfile {OUT}/_v4_list.txt {raw}")
meta = json.load(open(f"{OUT}/v4_meta.json")); pi_s = np.array(meta["pos"]) / meta["n"]
pi_t = np.array([0.1466, 50 / 3062, 10 / 3062]); lor = np.log(pi_t / (1 - pi_t)) - np.log(pi_s / (1 - pi_s))
print("log odds shifts", lor.round(5), flush=True)
rec = f"{FIN}/occ-ordinal-v4-lsog-recalibrated_10m_ME_DATA_2026-10-06_PROVISIONAL.tif"
U = 65535; tot = np.zeros(3); tot_raw = np.zeros(3); n = 0; bad_rng = bad_ord = 0; swsum = 0.0; ncls = np.zeros(3)
with rasterio.open(raw) as s:
    prof = s.profile.copy(); prof.update(count=4, compress="deflate", tiled=True, blockxsize=512, blockysize=512, BIGTIFF="YES")
    with rasterio.open(rec, "w", **prof) as d:
        for _, win in s.block_windows(1):
            a = s.read([1, 2, 3, 4], window=win).astype("float64"); v = a[0] != U
            o = np.full(a.shape, U, "uint16")
            if v.any():
                p = a[:3, v] / 1e4; bad_rng += int(((p < 0) | (p > 1)).sum())
                bad_ord += int(((p[2] > p[1] + 1e-6) | (p[1] > p[0] + 1e-6)).sum()); tot_raw += p.sum(1)
                pc = np.clip(p, 1e-6, 1 - 1e-6); q = 1 / (1 + np.exp(-(np.log(pc / (1 - pc)) + lor[:, None])))
                q[1] = np.minimum(q[1], q[0]); q[2] = np.minimum(q[2], q[1]); tot += q.sum(1); n += q.shape[1]
                sw = a[3, v] / 1e4; swsum += sw.sum(); ncls += np.bincount(np.where(sw < 0.35, 0, np.where(sw > 0.65, 2, 1)), minlength=3)
                o[:3, v] = np.rint(q * 1e4).astype("uint16"); o[3, v] = a[3, v].astype("uint16")
            d.write(o, window=win)
m = 100 * tot / n; mr = 100 * tot_raw / n; ha = n * 100 / 1.033 / 1e4
share = n / (9 * frame_me_cells30); print(f"G1 coverage inside Maine {share:.4f} (10 m cells predicted / 9 x 30 m frame cells)", flush=True)
res = {"coverage": share, "forest_ha": ha, "means_raw_pct": mr.tolist(), "means_recal_pct": m.tolist(),
       "expected_ha_recal": (m / 100 * ha).tolist(), "softwood_share_mean": swsum / n,
       "composition_area_share_HW_MX_SW": (ncls / n).tolist(), "lor": lor.tolist(), "bad_range": bad_rng, "bad_order": bad_ord}
fails = []
if share < 0.98: fails.append("G1 coverage")
if bad_rng: fails.append("G3 range")
if bad_ord: fails.append("G3b order")
if abs(ha / 7.41e6 - 1) > 0.05: fails.append("G2 frame area")
if not (13.40 <= m[0] <= 15.91): fails.append("G6 FIA interval")
res["fails"] = fails; json.dump(res, open(f"{AGG}/v4_recal_gates_DATA.json", "w"), indent=1); print(json.dumps(res, indent=1), flush=True)
if fails: print("GATES FAILED", fails); raise SystemExit(2)
for f in (raw, rec): os.replace(f, f.replace("_PROVISIONAL", ""))
rec = rec.replace("_PROVISIONAL", "")
for r_ in (30, 100):   # aggregate the gated 10 m recalibrated layers; average over predicted cells only
    sh(f"gdalwarp -overwrite -tr {r_} {r_} -tap -r average -srcnodata 65535 -dstnodata 65535 -co COMPRESS=DEFLATE -co TILED=YES "
       f"-wo NUM_THREADS=ALL_CPUS -multi {rec} {FIN}/occ-ordinal-v4-lsog-recalibrated_{r_}m-from10m_ME_DATA_2026-10-06.tif")
print("S4D DONE", flush=True)
