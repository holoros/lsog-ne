import os, json, numpy as np, rasterio
from rasterio.windows import Window
sa = os.environ["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES", GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR")
p = "/vsigs/alphaearth_foundations/satellite_embedding/v1/annual/2024/19N/x6sun7b33qgammiuo-0000000000-0000008192.tiff"
with rasterio.open(p) as d:
    print("transform", tuple(d.transform)[:6], d.width, d.height, d.dtypes[0], d.nodata, d.count)
    for r, c in [(100, 100), (4000, 4000), (8000, 7000)]:
        a = d.read(window=Window(c, r, 3, 2))
        print(r, c, a[:4].ravel().tolist(), "sum", int(a.astype("int64").sum()))
