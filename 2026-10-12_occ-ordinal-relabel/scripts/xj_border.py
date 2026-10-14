# xj_border.py  Distance to the shared Maine and New Brunswick border without shapely or geopandas (not installed for
# /usr/bin/python3 on Cardinal). Both boundary polygons are rasterized on a 100 m EPSG:3979 grid over the border region;
# the border is the set of boundary cells of either polygon that lie within 1 km of the other polygon (the 1 km
# tolerance of the September G5 seam gate, for boundary sources that differ in generalization). Distances are to the
# nearest border cell, so they carry up to about 70 m of grid error, small against the 500 m bands and 25 km subsets.
import json, numpy as np, rasterio
from rasterio.features import rasterize
from rasterio.transform import from_origin
from scipy.ndimage import binary_dilation, binary_erosion, distance_transform_edt
from pyproj import Transformer
ME_GJ = "/fs/scratch/PUOM0008/crsfaaron/core4_10m/menb-core4-10m_2026-09-16/inputs/me_boundary_3979.geojson"
NB_GJ = "/fs/scratch/PUOM0008/crsfaaron/canada_landcover/nb_boundary_3979.geojson"
RES = 100.0
def _geoms(p): return [f["geometry"] for f in json.load(open(p))["features"]]
def _bbox(gs):
    xs, ys = [], []
    def walk(c):
        if isinstance(c[0], (int, float)): xs.append(c[0]); ys.append(c[1])
        else:
            for k in c: walk(k)
    for g in gs: walk(g["coordinates"])
    return min(xs), min(ys), max(xs), max(ys)
_me, _nb = _geoms(ME_GJ), _geoms(NB_GJ)
a, b = _bbox(_me), _bbox(_nb)
X0, Y0, X1, Y1 = max(a[0], b[0]) - 60000, max(a[1], b[1]) - 60000, min(a[2], b[2]) + 60000, min(a[3], b[3]) + 60000
W_, H_ = int((X1 - X0) / RES) + 1, int((Y1 - Y0) / RES) + 1
T_ = from_origin(X0, Y1, RES, RES)
me = rasterize([(g, 1) for g in _me], out_shape=(H_, W_), transform=T_, fill=0).astype(bool)
nb = rasterize([(g, 1) for g in _nb], out_shape=(H_, W_), transform=T_, fill=0).astype(bool)
edge_me = me & ~binary_erosion(me); edge_nb = nb & ~binary_erosion(nb)
seed = (edge_me & binary_dilation(nb, iterations=10)) | (edge_nb & binary_dilation(me, iterations=10))
DIST = distance_transform_edt(~seed) * RES          # metres to the shared border on the 100 m grid
BORDER_KM_LENGTH = seed.sum() * RES / 1000 / 2      # two edges, rough length of shared border
def dist_xy(x, y):
    c = np.floor((np.asarray(x) - X0) / RES).astype(int); r = np.floor((Y1 - np.asarray(y)) / RES).astype(int)
    ok = (r >= 0) & (r < H_) & (c >= 0) & (c < W_); out = np.full(len(c), np.inf); out[ok] = DIST[r[ok], c[ok]]; return out
def border_km(lon, lat):
    x, y = Transformer.from_crs(4326, 3979, always_xy=True).transform(np.asarray(lon), np.asarray(lat)); return dist_xy(x, y) / 1000
