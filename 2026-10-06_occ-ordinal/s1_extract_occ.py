#!/usr/bin/env python3
# s1_extract_occ.py  OCC (Hagan) LSOG study points: AlphaEarth 2024 embeddings and existing map
# values at each point. Runs on Cardinal only. Coordinates are read here and never written out:
# the output table carries occ_id, class, project, site cluster, 64 AE bands and map values.
# Firewall controls: F1 (points outside Maine dropped and logged), F2 (nodata stays NaN, never 0),
# F6 (coverage of points by every map reported both ways), F7 (AE -128 sentinel and range test).
import os, sys, json, numpy as np, pandas as pd, rasterio
from pyproj import Transformer
from scipy.cluster.hierarchy import fcluster, linkage

E = os.environ
OUT = E["OUT"]; os.makedirs(OUT, exist_ok=True)
sa = E["EE_SA"]; os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = sa
os.environ.update(GS_USER_PROJECT=json.load(open(sa))["project_id"], CPL_VSIL_GS_REQUESTER_PAYS="YES",
                  GDAL_DISABLE_READDIR_ON_OPEN="EMPTY_DIR")
log = open(f"{OUT}/s1_log.txt", "w")
def L(m): print(m, flush=True); log.write(m + "\n"); log.flush()

d = pd.read_csv(E["OCC_CSV"])
L(f"read {len(d)} OCC points; classes {d.occ_class.value_counts().to_dict()}")
inme = d.lon.between(-71.10, -66.90) & d.lat.between(43.0, 47.5)
for _, r in d[~inme].iterrows():
    L(f"DROP {r.occ_id} class={r.occ_class} project={r.project}: outside Maine bounding box (coordinate typo suspected)")
d = d[inme].reset_index(drop=True)

# site clusters in metres (EPSG:3979), single linkage at 2 km, for grouped CV and the cluster bootstrap
x, y = Transformer.from_crs(4326, 3979, always_xy=True).transform(d.lon.values, d.lat.values)
d["site"] = fcluster(linkage(np.column_stack([x, y]), "single"), t=2000, criterion="distance")
L(f"site clusters at 2 km: {d.site.nunique()}; points per site median {d.site.value_counts().median():.0f}, max {d.site.value_counts().max()}")
L("classes by number of sites: " + str(d.groupby("occ_class").site.nunique().to_dict()))

def dequant(v):
    v = v.astype("float32"); v = np.where(v == -128, np.nan, v)
    xq = (np.abs(v) / 127.5) ** 2 * np.sign(v)
    return np.where(np.abs(xq) <= 1.0, xq, np.nan)

# AlphaEarth 2024 at points
idx = pd.read_csv(E["TILE_LIST"])   # the 34 Maine AE 2024 tiles of the transitioning build, row order = tile index
AE = np.full((len(d), 64), np.nan, "float32"); TILE = np.full(len(d), -1)
for ti, t in idx[(idx.wgs84_east >= d.lon.min()) & (idx.wgs84_west <= d.lon.max()) &
                (idx.wgs84_north >= d.lat.min()) & (idx.wgs84_south <= d.lat.max())].iterrows():
    need = np.where(np.isnan(AE[:, 0]) & d.lon.between(t.wgs84_west, t.wgs84_east).values &
                    d.lat.between(t.wgs84_south, t.wgs84_north).values)[0]
    if not len(need): continue
    with rasterio.open("/vsigs/" + t.path[5:]) as ds:
        tx, ty = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(d.lon.values[need], d.lat.values[need])
        x0, x1 = sorted((ds.bounds.left, ds.bounds.right)); y0, y1 = sorted((ds.bounds.bottom, ds.bounds.top))  # AE tiles are south up
        inb = (tx >= x0) & (tx < x1) & (ty >= y0) & (ty < y1)
        if not inb.any(): continue
        vals = np.array(list(ds.sample(list(zip(tx[inb], ty[inb])))))
        AE[need[inb]] = dequant(vals); TILE[need[inb]] = ti
ok_ae = np.isfinite(AE).all(1)
L(f"AE 2024 complete at {ok_ae.sum()} of {len(d)} points")
for k in range(64): d[f"AE_{k:02d}"] = AE[:, k]
st = pd.Series(TILE[TILE >= 0]).value_counts().rename_axis("tile_index").reset_index(name="n_points")
st.to_csv(f"{OUT}/study_tiles.csv", index=False); L(f"study tiles: {len(st)}")

# existing maps at points
MAPS = json.loads(E["MAPS_JSON"])
for name, (path, scale) in MAPS.items():
    with rasterio.open(path) as ds:
        tx, ty = Transformer.from_crs(4326, ds.crs, always_xy=True).transform(d.lon.values, d.lat.values)
        v = np.array([s[0] for s in ds.sample(list(zip(tx, ty)), masked=True)], dtype=object)
        arr = np.array([np.nan if (vv is np.ma.masked or (ds.nodata is not None and vv == ds.nodata)) else float(vv) for vv in v])
        arr = arr / scale
        d[name] = arr
        L(f"map {name}: valid at {np.isfinite(arr).sum()} of {len(d)} points; range [{np.nanmin(arr):.4f}, {np.nanmax(arr):.4f}]")

d.drop(columns=["lat", "lon", "plotname"]).to_csv(f"{OUT}/occ_points_ae_maps_RESTRICTED.csv", index=False)
L("WROTE occ_points_ae_maps_RESTRICTED.csv (no coordinates, no plot names)")
