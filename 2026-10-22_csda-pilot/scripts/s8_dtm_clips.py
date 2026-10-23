#!/usr/bin/env python3
"""Bare-earth DTM clips for the H2 canopy height model: USGS 3DEP 1 m DEM (public) over every pilot cell.
TNM Access is queried with one bounding box per 10 km group (rounded outward to 0.05 degree, as for SDX);
cell windows are read from the public COGs on prd-tnm. Points never leave this server; outputs are
restricted clips plus a count summary. Where tiles overlap, the newest publication wins and its project is
recorded so the DTM can be matched to the WESM collection later."""
import json, math, time, urllib.parse, urllib.request
from collections import defaultdict
from pathlib import Path
import rasterio
from rasterio.merge import merge
from rasterio.warp import transform_bounds
from rasterio.windows import from_bounds

D = Path.home() / "LSOG/2026-10-22_csda-pilot"; R = D / "RESTRICTED"
CELLS = json.load(open(R / "item_cells_RESTRICTED.json"))
cells = {}
for item, L in CELLS.items():
    for k, g, role, bb in L: cells[tuple(round(v, 7) for v in bb)] = (g, role)
by_g = defaultdict(list)
for bb, (g, role) in cells.items(): by_g[g].append(bb)
API = "https://tnmaccess.nationalmap.gov/api/v1/products"
BUF = 150 / 111320.0
out = R / "dtm"; out.mkdir(exist_ok=True)
summ = {"cells": len(cells), "groups": len(by_g), "tiles": 0, "cells_done": 0, "cells_missing": 0, "projects": defaultdict(int)}

def q(bb):
    p = {"datasets": "Digital Elevation Model (DEM) 1 meter", "bbox": ",".join(f"{v:.2f}" for v in bb), "max": 200, "prodFormats": "GeoTIFF"}
    for k in range(4):
        try: return json.load(urllib.request.urlopen(API + "?" + urllib.parse.urlencode(p), timeout=120)).get("items", [])
        except Exception as e: err = e; time.sleep(10 * (k + 1))
    raise err

idx = 0
for g, L in sorted(by_g.items()):
    x0 = math.floor(min(b[0] for b in L) * 20) / 20; y0 = math.floor(min(b[1] for b in L) * 20) / 20
    x1 = math.ceil(max(b[2] for b in L) * 20) / 20; y1 = math.ceil(max(b[3] for b in L) * 20) / 20
    items = q((x0, y0, x1, y1)); summ["tiles"] += len(items)
    tiles = []
    for it in items:
        bb = it.get("boundingBox") or {}
        tiles.append({"url": it["downloadURL"], "pub": it.get("publicationDate", ""), "title": it.get("title", ""),
                      "bb": (bb.get("minX"), bb.get("minY"), bb.get("maxX"), bb.get("maxY"))})
    for cb in L:
        idx += 1
        win = (cb[0] - BUF, cb[1] - BUF, cb[2] + BUF, cb[3] + BUF)
        hit = [t for t in tiles if None not in t["bb"] and not (t["bb"][2] < win[0] or t["bb"][0] > win[2] or t["bb"][3] < win[1] or t["bb"][1] > win[3])]
        hit.sort(key=lambda t: t["pub"], reverse=True)
        srcs = []
        try:
            seen = set()
            for t in hit:
                key = t["url"].rsplit("/", 1)[-1].split("_")[2:4] if "USGS_1M" in t["url"] else t["url"]
                if str(key) in seen: continue
                seen.add(str(key)); srcs.append(rasterio.open("/vsicurl/" + t["url"]))
            if not srcs: summ["cells_missing"] += 1; continue
            def hkey(c):
                e = c.to_epsg() if c else None
                return e if e else (c.to_dict().get("proj"), c.to_dict().get("zone"))
            crs = srcs[0].crs; keep = [s for s in srcs if hkey(s.crs) == hkey(crs)]
            drop = [s for s in srcs if s not in keep]
            if drop: print("cell", idx, "dropped", len(drop), "tiles in another CRS", flush=True); summ["tiles_dropped_crs"] = summ.get("tiles_dropped_crs", 0) + len(drop)
            for s_ in drop: s_.close()
            srcs = keep
            b = transform_bounds("EPSG:4326", crs, *win)
            arr, tr = merge(srcs, bounds=b, res=1.0, nodata=-9999.0)
            prof = {"driver": "GTiff", "dtype": "float32", "count": 1, "width": arr.shape[2], "height": arr.shape[1],
                    "crs": crs, "transform": tr, "nodata": -9999.0, "compress": "deflate"}
            with rasterio.open(out / f"dtm_{idx:03d}_{cells[cb][0]}_{cells[cb][1]}.tif", "w", **prof) as dst: dst.write(arr.astype("float32"))
            json.dump({"cell_bounds": cb, "group": cells[cb][0], "role": cells[cb][1], "tiles": [t["title"] for t in hit]},
                      open(out / f"dtm_{idx:03d}.json", "w"))
            summ["cells_done"] += 1
            for t in hit[:1]: summ["projects"][t["title"].split(" ")[-1] if t["title"] else "?"] += 1
        except Exception as e:
            summ["cells_missing"] += 1; print("cell", idx, "error", str(e)[:200], flush=True)
        finally:
            for s in srcs: s.close()
summ["projects"] = dict(summ["projects"])
json.dump(summ, open(D / "out/dtm_clips_SUMMARY.json", "w"), indent=1); print(json.dumps(summ, indent=1))
