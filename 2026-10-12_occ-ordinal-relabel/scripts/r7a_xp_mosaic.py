#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s16c_xp_mosaic.py  Mosaic the cross-predicted 10 m tiles (s16b) to EPSG:3979 with the Maine cutline, as s4d did for v4.
import os, glob, subprocess, pandas as pd
E = os.environ; OUT = E["OUT"]; FIN = E.get("XPFIN", f"{OUT}/final"); AGG = f"{OUT}/agg"
CUT = "/fs/scratch/PUOM0008/crsfaaron/trans_10m/me-transitioning-10m_2026-09-23/_cut_ME.geojson"
tiles = sorted(glob.glob(f"{OUT}/tiles_xp/ord_xp_*.tif")); print("tiles", len(tiles), flush=True); assert len(tiles) == 34
pd.concat([pd.read_csv(f) for f in glob.glob(f"{OUT}/tiles_xp/cov_*.csv")]).to_csv(f"{AGG}/coverage_xp_DATA.csv", index=False)
open(f"{OUT}/_xp_list.txt", "w").write("\n".join(tiles))
raw = f"{FIN}/occ-ordinal-v5xp-lsog_10m_ME_DATA_2026-10-12.tif"
c = (f"gdalwarp -overwrite -t_srs EPSG:3979 -tr 10 10 -tap -r near -srcnodata 65535 -dstnodata 65535 -cutline {CUT} -crop_to_cutline "
     f"-co COMPRESS=DEFLATE -co TILED=YES -co BIGTIFF=YES -wo NUM_THREADS=ALL_CPUS -multi --optfile {OUT}/_xp_list.txt {raw}")
print("$", c, flush=True); subprocess.run(c, shell=True, check=True); print("S16C DONE", flush=True)
