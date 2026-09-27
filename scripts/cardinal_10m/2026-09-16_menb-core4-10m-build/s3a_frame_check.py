#!/usr/bin/env python3
# s3a_frame_check.py  F1/F4/F5 on the forest frame before any prediction: value coding, and forest area
# inside each jurisdiction against the published hybrid-frame areas (Methods 3.12), at 30 m.
import os, sys, json, numpy as np, rasterio, geopandas as gpd
from rasterio.features import geometry_mask
E = os.environ
with rasterio.open(E["FRAME_M3"]) as f:
    a = f.read(1); tr = f.transform; crs = f.crs; nod = f.nodata; px = abs(tr.a * tr.e)
vals, cnts = np.unique(a, return_counts=True)
print("frame values:", dict(zip(vals.tolist(), cnts.tolist())), "nodata:", nod, "crs:", crs, "pixel m2:", px)
fv = int(E["FRAME_FOREST_VALUE"])
if fv not in vals: sys.exit(f"FAIL forest value {fv} not present in frame")
refs = dict(kv.split(":") for kv in E["REF_M3_HA"].split(","))
over = dict(kv.split(":") for kv in E["EPSG3979_OVERSTATE"].split(","))
out, fail = {}, False
for j, path in [("ME", E["ME_BOUNDARY"]), ("NB", E["NB_BOUNDARY"])]:
    g = gpd.read_file(path).to_crs(crs)
    inside = ~geometry_mask(g.geometry, a.shape, tr, invert=False)
    ha = float(((a == fv) & inside).sum() * px / 1e4)
    expect = float(refs[j]) * float(over[j])
    ratio = ha / expect
    out[j] = {"forest_ha_raw": ha, "expected_raw_ha": expect, "ratio": ratio}
    ok = 0.97 <= ratio <= 1.03
    fail |= not ok
    print(f"{'PASS' if ok else 'FAIL'} {j} frame forest {ha:,.0f} ha vs expected {expect:,.0f} ha (ratio {ratio:.3f})")
json.dump(out, open(f"{E['BUILD']}/s3a_frame_check.json", "w"), indent=2)
sys.exit(2 if fail else 0)
