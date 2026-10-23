#!/usr/bin/env python3
"""CSDA pilot, step 3 (gate G2): catalog search only, nothing ordered or downloaded.

Footprint: fixed 1 km lat/lon-snapped grid cells (same grid as the October 16 Planet orders) holding
OCC OG points, OCC LS points within 25 km of any OG point, and up to 40 Not LS or transitioning control
cells within 25 km (seeded draw). Points never leave this server. What goes to SDX is one bounding box
per OG group, built from 1 km cells and rounded outward to 0.05 degrees, so it is coarser than the cells.
Item geometries are then intersected with the cells here, and only counts per group and class leave.
Outputs carry no coordinates.
"""
import csv, json, math, random, sys, time, urllib.request
from collections import defaultdict
from pathlib import Path
from shapely.geometry import box, shape
from shapely.ops import unary_union

HOME = Path.home()
OUT = HOME / "LSOG/2026-10-22_csda-pilot/out"; OUT.mkdir(parents=True, exist_ok=True)
OCC = HOME / "LSOG/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
STAC = "https://csdap.earthdata.nasa.gov/stac/search"
SEED = 20261022
DY = 1000.0 / 111320.0; DX = 1000.0 / (111320.0 * math.cos(math.radians(45.5)))

def hav(a, b):
    R = 6371.0; la1, lo1, la2, lo2 = map(math.radians, (a[1], a[0], b[1], b[0]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R * math.asin(math.sqrt(h))

pts = [(r["plotname"], float(r["lon"]), float(r["lat"]), r["occ_class"]) for r in csv.DictReader(open(OCC))]
og = [p for p in pts if p[3] == "Old-growth"]
# single-linkage 10 km groups of OG points
grp = {p[0]: i for i, p in enumerate(og)}
changed = True
while changed:
    changed = False
    for a in og:
        for b in og:
            if grp[a[0]] != grp[b[0]] and hav(a[1:3], b[1:3]) <= 10.0:
                g = min(grp[a[0]], grp[b[0]]); old = max(grp[a[0]], grp[b[0]])
                for k in grp:
                    if grp[k] == old: grp[k] = g
                changed = True
sizes = defaultdict(int)
for k in grp: sizes[grp[k]] += 1
order = sorted(sizes, key=lambda g: -sizes[g]); lab = {g: "ABCDEFGH"[i] for i, g in enumerate(order)}

def cell(x, y): return (math.floor(x / DX), math.floor(y / DY))
def cellbox(c): return box(c[0] * DX, c[1] * DY, (c[0] + 1) * DX, (c[1] + 1) * DY)

sel = {}   # cell -> (group, role)
for p in og: sel[cell(p[1], p[2])] = (lab[grp[p[0]]], "OG")
def nearest_group(p):
    d = [(hav(p[1:3], q[1:3]), lab[grp[q[0]]]) for q in og]; return min(d)
for p in pts:
    if p[3] == "LS":
        d, g = nearest_group(p)
        if d <= 25.0: sel.setdefault(cell(p[1], p[2]), (g, "LS"))
ctrl = []
for p in pts:
    if p[3] in ("Not LS", "Trans LS"):
        d, g = nearest_group(p)
        c = cell(p[1], p[2])
        if d <= 25.0 and c not in sel: ctrl.append((c, g))
ctrl = sorted(set(ctrl)); random.Random(SEED).shuffle(ctrl)
for c, g in ctrl[:40]: sel.setdefault(c, (g, "control"))

cells_by = defaultdict(list)
for c, (g, role) in sel.items(): cells_by[g].append((c, role))
qboxes = {}
for g, L in cells_by.items():
    u = unary_union([cellbox(c) for c, _ in L]).bounds
    qboxes[g] = [math.floor(u[0] * 20) / 20, math.floor(u[1] * 20) / 20, math.ceil(u[2] * 20) / 20, math.ceil(u[3] * 20) / 20]

def post(body):
    for k in range(4):
        try:
            req = urllib.request.Request(STAC, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
            return json.load(urllib.request.urlopen(req, timeout=120))
        except Exception as e:
            time.sleep(5 * (k + 1)); err = e
    raise err

def search(coll, bb, extra=None):
    body = {"collections": [coll], "bbox": bb, "limit": 200}
    if extra: body.update(extra)
    feats = []; d = post(body); feats += d["features"]
    while True:
        nxt = [l for l in d.get("links", []) if l.get("rel") == "next"]
        if not nxt or not d["features"]: break
        l = nxt[0]
        if l.get("body"):
            nb = {**body, **l["body"]} if l.get("merge") else l["body"]
            req = urllib.request.Request(l.get("href", STAC), data=json.dumps(nb).encode(), headers={"Content-Type": "application/json"})
            d = json.load(urllib.request.urlopen(req, timeout=120))
        else:
            d = json.load(urllib.request.urlopen(l["href"], timeout=120))
        feats += d["features"]
        if len(feats) > 20000: break
    return feats

def season(dt):
    m = int(dt[5:7]); dd = int(dt[8:10])
    if m in (12, 1, 2, 3): return "winter (snow likely)"
    if m == 4 or m == 11 or (m == 10 and dd >= 20): return "leaf-off"
    if m in (6, 7, 8): return "leaf-on"
    return "shoulder"

COLLS = ["pgc-earthdem", "desis", "blacksky", "planet", "maxar-legion", "maxar-sdx", "pixxel", "satellogic", "airbus-optical", "airbus-dem"]  # tomorrow dropped: precipitation radar swaths
rows = []; counts = {}
for coll in COLLS:
    seen = {}
    for g, bb in qboxes.items():
        extra = None
        if coll == "planet":
            extra = {"filter-lang": "cql2-json", "filter": {"op": "like", "args": [{"property": "pl:item_type"}, "SkySat%"]}}
        try: F = search(coll, bb, extra)
        except Exception as e:
            counts[(coll, g)] = f"ERR {e}"; continue
        counts[(coll, g)] = len(F)
        for f in F:
            try: geom = shape(f["geometry"])
            except Exception: continue
            cov = defaultdict(int)
            for c, role in cells_by[g]:
                cb = cellbox(c)
                if geom.intersects(cb) and geom.intersection(cb).area / cb.area >= 0.5: cov[role] += 1
            if not cov: continue
            p = f["properties"]; a = f.get("assets", {})
            size = sum((v.get("file:size") or 0) for k, v in a.items() if "data" in (v.get("roles") or []))
            r = seen.setdefault(f["id"], {
                "collection": coll, "item_id": f["id"],
                "vendor_type": p.get("csda:item_type") or p.get("pl:item_type") or p.get("item_type") or p.get("prod_type") or "",
                "sensor": ",".join(p.get("instruments", [])) if p.get("instruments") else (p.get("blacksky:sensorName") or p.get("eo:instrument") or p.get("desis_specific_sensor") or ""),
                "date": (p.get("datetime") or p.get("start_datetime") or "")[:10],
                "gsd_m": p.get("gsd") or p.get("eo:gsd") or p.get("blacksky:gsd") or "",
                "off_nadir_deg": p.get("view:off_nadir", p.get("eo:off_nadir", "")),
                "convergence_deg": p.get("pgc:avg_convergence_angle", ""),
                "cloud_pct": p.get("eo:cloud_cover", (p.get("pgc:cloud_area_percent") * 100 if p.get("pgc:cloud_area_percent") is not None else "")),
                "rmse_m": p.get("pgc:rmse", ""),
                "size_MB": round(size / 1e6, 1), "groups": set(), "OG_cells": 0, "LS_cells": 0, "control_cells": 0, "by_group": {}})
            r["groups"].add(g)
            for role in ("OG", "LS", "control"): r[f"{role}_cells"] += cov.get(role, 0)
            r["by_group"][g] = f"{g}:{cov.get('OG',0)}/{cov.get('LS',0)}/{cov.get('control',0)}"
    for r in seen.values():
        r["season"] = season(r["date"]) if r["date"] else ""
        r["groups"] = "".join(sorted(r["groups"])); r["cells_by_group_OG_LS_ctrl"] = " ".join(r["by_group"][g] for g in sorted(r["by_group"])); rows.append(r)

cols = ["collection", "item_id", "vendor_type", "sensor", "date", "season", "gsd_m", "off_nadir_deg", "convergence_deg", "cloud_pct", "rmse_m", "size_MB", "groups", "OG_cells", "LS_cells", "control_cells", "cells_by_group_OG_LS_ctrl"]
rows.sort(key=lambda r: (r["collection"], r["date"]))
with open(OUT / "sdx_candidates_ALL_DATA.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=cols); w.writeheader(); [w.writerow({k: r[k] for k in cols}) for r in rows]
summ = {"seed": SEED, "groups": {g: {"OG_points": sizes[[k for k, v in lab.items() if v == g][0]],
        "cells": {role: sum(1 for _, r in cells_by[g] if r == role) for role in ("OG", "LS", "control")},
        "query_box_area_km2": round(box(*qboxes[g]).area * 111.32 ** 2 * math.cos(math.radians(45.5)), 0)} for g in sorted(cells_by)},
        "hits_by_collection_group": {f"{c}|{g}": v for (c, g), v in counts.items()},
        "control_pool_cells": len({c for c, _ in ctrl}), "n_candidates": len(rows)}
json.dump(summ, open(OUT / "sdx_search_SUMMARY.json", "w"), indent=1)
print(json.dumps(summ, indent=1))
