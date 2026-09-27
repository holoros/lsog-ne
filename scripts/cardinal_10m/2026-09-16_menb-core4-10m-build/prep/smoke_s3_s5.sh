#!/usr/bin/env bash
# smoke_s3_s5.sh  synthetic one-tile test of the modified s3 (cell sample) and s5, in a temp BUILD
set -euo pipefail
H=~/LSOG/2026-09-16_menb-core4-10m-build; source $H/config.sh; eval "$PY_ACTIVATE"
REAL=$BUILD; T=/fs/scratch/PUOM0008/crsfaaron/core4_10m/smoke_s3s5; rm -rf $T; mkdir -p $T/tile_tmp $T/final $T/logs
for f in rf_core4_final_2026-09-16.pkl rf_core4_boot_2026-09-16.pkl env_min.npy env_max.npy; do ln -s $REAL/$f $T/$f; done
export BUILD=$T TMP_TILES=$T/tile_tmp FINAL=$T/final SAMPLE_RATE=0.05 AEF_INDEX=$T/idx.csv WIN=256
python3 - << 'PY'
import numpy as np, rasterio, pandas as pd, os
from rasterio.transform import from_origin
from rasterio.warp import transform
T = os.environ["BUILD"]
x0, y0 = transform("EPSG:4326", "EPSG:32619", [-69.0], [45.5]); x0, y0 = x0[0], y0[0]
tr = from_origin(x0, y0, 10, 10); rng = np.random.default_rng(1)
a = rng.integers(-60, 60, (64, 600, 600)).astype("int8")
with rasterio.open(f"{T}/syn.tif", "w", driver="GTiff", height=600, width=600, count=64, dtype="int8", crs="EPSG:32619", transform=tr) as d: d.write(a)
pd.DataFrame({"year": [2024], "path": [f"{T}/syn.tif"], "wgs84_west": [-69.01], "wgs84_east": [-68.9], "wgs84_south": [45.4], "wgs84_north": [45.5]}).to_csv(f"{T}/idx.csv", index=False)
PY
python3 $H/s3_predict_tiles_10m.py 0 1
python3 - << 'PY'
import numpy as np, glob, os, rasterio
T = os.environ["BUILD"]; f = glob.glob(f"{T}/tile_tmp/samp_*.npz"); z = np.load(f[0]); s = z["s"]
with rasterio.open(glob.glob(f"{T}/tile_tmp/prob_*.tif")[0]) as p: a = p.read(1); tr = p.transform
v = a != 65535
print("sample rows", s.shape, "crs", z["crs"], "valid cells", int(v.sum()), "rate", len(s) / v.sum())
r, c = rasterio.transform.rowcol(tr, s[:, 0], s[:, 1])
print("final prob matches raster at sampled cells:", bool(np.all(np.abs(a[r, c] - np.rint(s[:, 2] * 10000)) <= 1)))
print("boot cols", s.shape[1] - 3, "boot mean share", round(100 * s[:, 3:].mean(), 3), "final share", round(100 * s[:, 2].mean(), 3))
# fake final ME raster in EPSG:3979 covering the tile, all valid
from rasterio.warp import reproject, calculate_default_transform
with rasterio.open(glob.glob(f"{T}/tile_tmp/prob_*.tif")[0]) as p:
    t2, w2, h2 = calculate_default_transform(p.crs, "EPSG:3979", p.width, p.height, *p.bounds, resolution=10)
    o = np.full((h2, w2), 65535, "uint16")
    reproject(rasterio.band(p, 1), o, dst_transform=t2, dst_crs="EPSG:3979", src_nodata=65535, dst_nodata=65535)
for J in ("ME", "NB"):
    with rasterio.open(f"{T}/final/core4-structural-core-probability_10m_{J}_DATA_2026-09-16.tif.part", "w", driver="GTiff", height=h2, width=w2, count=1, dtype="uint16", crs="EPSG:3979", transform=t2, nodata=65535) as d:
        d.write(o if J == "ME" else np.full_like(o, 65535), 1)
PY
S5_TARGET=5000 python3 $H/s5_share_bootstrap_interval.py || echo "s5 exit $? (NB has no valid cells in this synthetic test)"
