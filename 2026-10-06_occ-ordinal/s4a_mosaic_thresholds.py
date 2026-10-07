#!/usr/bin/env python3
# s4a_mosaic_thresholds.py  Cardinal side only (the AE tiles and per point OCC scores live here):
#   1. screening thresholds from OCC out of fold scores (Youden J), written as two numbers
#   2. coverage table summed over tiles
#   3. gdalwarp mosaics to EPSG:3979, statewide 30 m clipped to Maine, study 10 m per tile extent
#   4. a 20 m display copy of the study tile holding the most OCC points
# Gates, the class layer and the figures run on firebreather (f2_gates_map_figure.R).
import os, glob, json, subprocess, numpy as np, pandas as pd
from sklearn.metrics import roc_curve
E = os.environ; W = E["W"]; OUT = f"{W}/out"; AGG = f"{OUT}/agg"; FIN = f"{OUT}/final"; os.makedirs(FIN, exist_ok=True)
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
def sh(c): print("$", c, flush=True); subprocess.run(c, shell=True, check=True)

O = pd.read_csv(f"{OUT}/occ_oof_scores_RESTRICTED.csv")
def youden(yb, s):
    f, t, th = roc_curve(yb, s); k = int(np.argmax(t - f)); return float(th[k]), float(t[k]), float(1 - f[k])
t2, se2, sp2 = youden(O.occ_class.isin(["LS", "Old-growth"]).values, O.new_ge2.values)
sub = O[O.occ_class.isin(["LS", "Old-growth"])]
t1, se1, sp1 = youden((sub.occ_class == "Old-growth").values, sub.new_og.values)
TH = dict(type2_cut=t2, type2_sens=se2, type2_spec=sp2, type1_cut_within_type2=t1, type1_sens=se1, type1_spec_vs_LS=sp1)
json.dump(TH, open(f"{AGG}/screening_thresholds_DATA.json", "w"), indent=1); print(TH)

for mode, res in (("state30", 30), ("study", 10)):
    tiles = sorted(glob.glob(f"{OUT}/tiles_{mode}/ord_{mode}_*.tif"))
    cov = pd.concat([pd.read_csv(f) for f in glob.glob(f"{OUT}/tiles_{mode}/cov_*.csv")])
    cov.to_csv(f"{AGG}/coverage_{mode}_DATA.csv", index=False)
    print(mode, len(tiles), "tiles; predicted share", cov.predicted.sum() / max(cov.forest_cells.sum(), 1), flush=True)
    lst = f"{OUT}/_{mode}_list.txt"; open(lst, "w").write("\n".join(tiles))
    crop = "-crop_to_cutline" if mode == "state30" else ""
    sh(f"gdalwarp -overwrite -t_srs EPSG:3979 -tr {res} {res} -tap -r near -srcnodata 65535 -dstnodata 65535 "
       f"-cutline {CUT} {crop} -co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS "
       f"--optfile {lst} {FIN}/occ-ordinal-lsog_{res}m_{mode}_ME_DATA_2026-10-06_PROVISIONAL.tif")

st = pd.read_csv(f"{OUT}/study_tiles.csv").sort_values("n_points", ascending=False)
top = f"{OUT}/tiles_study/ord_study_{int(st.tile_index.iloc[0]):04d}.tif"
sh(f"gdalwarp -overwrite -t_srs EPSG:3979 -tr 20 20 -r near -srcnodata 65535 -dstnodata 65535 -co COMPRESS=DEFLATE "
   f"{top} {FIN}/occ-ordinal-lsog_20m_study-display_DATA_2026-10-06.tif")
print("S4A DONE", flush=True)
