# Diagnose s4 G1/G2: why the 10 m frame mosaic holds ~14% more forest than the 30 m frame inside the boundary.
import os, json, numpy as np, rasterio, geopandas as gpd, subprocess
from rasterio.enums import Resampling
from rasterio.features import geometry_mask
E = os.environ; B = E["BUILD"]; out = {}
print(subprocess.run(["bash", "-c", "which gdalwarp; gdalwarp --version"], capture_output=True, text=True).stdout)
with rasterio.open(E["FRAME_M3"]) as f:
    print("30m frame", f.crs, f.res, f.nodata, f.bounds, f.dtypes)
for J in ("ME", "NB"):
    fr = f"{B}/_frame_{J}.tif"; pr = f"{B}/_raw_prob_{J}.tif"
    with rasterio.open(fr) as m, rasterio.open(pr) as p:
        print(J, "frame10", m.crs, m.res, m.nodata, m.width, m.height, m.bounds)
        print(J, "prob10 ", p.crs, p.res, p.nodata, p.width, p.height, p.bounds)
        k = 10
        a = m.read(1, out_shape=(m.height // k, m.width // k), resampling=Resampling.nearest)
        q = p.read(1, out_shape=(p.height // k, p.width // k), resampling=Resampling.nearest)
        vals, cnts = np.unique(a, return_counts=True)
        print(J, "frame10 values (decimated)", dict(zip(vals.tolist(), (cnts * k * k).tolist())))
        miss = (a == 1) & (q == 65535)
        print(J, "forest cells", int((a == 1).sum()) * k * k, "missing pred", int(miss.sum()) * k * k)
        # where are missing cells: by row/col decile
        rr, cc = np.nonzero(miss)
        if len(rr):
            print(J, "missing rows pct", np.percentile(rr / a.shape[0], [5, 25, 50, 75, 95]).round(2).tolist(),
                  "cols pct", np.percentile(cc / a.shape[1], [5, 25, 50, 75, 95]).round(2).tolist())
        np.save(f"{B}/logs/diag_{J}_frame_dec.npy", a); np.save(f"{B}/logs/diag_{J}_prob_dec.npy", q)
    # 30 m frame inside the same boundary, counted two ways
    g = gpd.read_file(E[f"{J}_BOUNDARY"]).to_crs("EPSG:3979")
    with rasterio.open(E["FRAME_M3"]) as f:
        a30 = f.read(1); ins = ~geometry_mask(g.geometry, a30.shape, f.transform)
        print(J, "30m frame forest inside boundary ha", float(((a30 == 1) & ins).sum() * 900 / 1e4))
        print(J, "30m frame forest anywhere ha", float((a30 == 1).sum() * 900 / 1e4))
