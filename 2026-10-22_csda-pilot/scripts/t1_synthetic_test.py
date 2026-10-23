#!/usr/bin/env python3
"""Synthetic end-to-end test of s9 and s10 before any vendor data exist. Builds a test tree under
~/LSOG/2026-10-22_csda-pilot/TEST with fake EarthDEM clips made from the public 3DEP bare earth:
surface = bare earth + canopy + geoid N - ITRF-to-NAD83 shift + a known strip offset (3.0 m), on a 2 m grid.
Canopy is 22 m with 30% gaps for OG sites and 22 m with 10% gaps for LS sites, so the test knows the answer:
cov15 near 0.70 for OG and 0.90 for LS, dz near 3.0 m, AUC near 1. Nothing here leaves the server."""
import csv, json, os, shutil, math
from pathlib import Path
import numpy as np
import rasterio
from rasterio.warp import reproject, Resampling, transform as wtransform
from rasterio.transform import from_origin
from pyproj import Transformer

D = Path.home() / "LSOG/2026-10-22_csda-pilot"; T = D / "TEST"
if T.exists(): shutil.rmtree(T)
(T / "RESTRICTED/clips").mkdir(parents=True); (T / "out").mkdir(); (T / "ref").mkdir()
os.chmod(T, 0o700)
shutil.copy(D / "out/sdx_all102_ORDER_DATA.csv", T / "out/sdx_all102_ORDER_DATA.csv")
shutil.copy(D / "RESTRICTED/item_cells_RESTRICTED.json", T / "RESTRICTED/item_cells_RESTRICTED.json")
shutil.copy(D / "RESTRICTED/occ_site_lidar_vintage_RESTRICTED.csv", T / "RESTRICTED/occ_site_lidar_vintage_RESTRICTED.csv")
os.symlink(D / "RESTRICTED/dtm", T / "RESTRICTED/dtm"); os.symlink(D / "ref/us_noaa_g2018u0.tif", T / "ref/us_noaa_g2018u0.tif")
G = rasterio.open(D / "ref/us_noaa_g2018u0.tif"); IT = Transformer.from_crs("EPSG:7912", "EPSG:6319", always_xy=True)
order = [o for o in csv.DictReader(open(D / "out/sdx_all102_ORDER_DATA.csv")) if o["collection"] == "pgc-earthdem"]
cells = json.load(open(D / "RESTRICTED/item_cells_RESTRICTED.json"))
dtm = {}
for j in (D / "RESTRICTED/dtm").glob("dtm_*.json"):
    m = json.load(open(j)); dtm[tuple(round(v, 7) for v in m["cell_bounds"])] = next(j.parent.glob(j.stem + "_*.tif"))
rng = np.random.default_rng(20261022); made = 0; closed_done = False
for o in order[:6]:
    item = o["item_id"]; y, mo = int(o["date"][:4]), int(o["date"][5:7]); ep = y + (mo - .5) / 12
    out = T / "RESTRICTED/clips" / item; out.mkdir()
    for k, g, role, bb in cells[item]:
        cb = tuple(round(v, 7) for v in bb)
        if cb not in dtm: continue
        with rasterio.open(dtm[cb]) as t:
            b = t.bounds; tr = from_origin(b.left, b.top, 2.0, 2.0)
            w, h = int((b.right - b.left) // 2), int((b.top - b.bottom) // 2)
            g2 = np.full((h, w), np.nan)
            reproject(t.read(1, masked=True).filled(np.nan), g2, src_transform=t.transform, src_crs=t.crs, dst_transform=tr,
                      dst_crs=t.crs, resampling=Resampling.average, src_nodata=np.nan, dst_nodata=np.nan)
            cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
            N = float(list(G.sample([(cx % 360, cy)]))[0][0]); sh = 1.11   # independent of s9's PROJ helper (red team)
            gap = 0.30 if role == "OG" else 0.10
            canopy = np.where(rng.random((h, w)) < gap, rng.uniform(0, 3, (h, w)), rng.normal(22, 2, (h, w)))
            # roads and clearings: 8% of cells are open ground, except one closed OG clip with no ground and no gaps,
            # which the strip-level safeguard must catch (its own dz would absorb canopy)
            if role == "OG" and not closed_done:
                canopy = rng.normal(22, 2, (h, w)); closed_done = True; closed_tag = (item, k); print("closed clip", item[-24:], k)
            else:
                canopy[rng.random((h, w)) < 0.08] = 0.0
            dsm = g2 + canopy + N - sh + 3.0
            dsm = np.where(np.isfinite(dsm), dsm, -9999.0).astype("float32")
            prof = {"driver": "GTiff", "width": w, "height": h, "count": 1, "crs": t.crs, "transform": tr, "compress": "deflate"}
            tag = f"c{k:03d}_{g}_{role}"
            with rasterio.open(out / f"dem_{tag}.tif", "w", dtype="float32", nodata=-9999.0, **prof) as d: d.write(dsm, 1)
            with rasterio.open(out / f"mask_{tag}.tif", "w", dtype="uint8", **prof) as d: d.write(np.zeros((h, w), "uint8"), 1)
            with rasterio.open(out / f"matchtag_{tag}.tif", "w", dtype="uint8", **prof) as d: d.write(np.ones((h, w), "uint8"), 1)
            made += 1
print("synthetic clips:", made)
