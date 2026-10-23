#!/usr/bin/env python3
"""Assign USGS 3DEP lidar work units (WESM, public) to OCC sites, for H2(c) and John's lidar question.
WESM is read with a Maine-wide bounding box only; site points never leave this server. Outputs: counts by
class, by 10 km OG group and by acquisition year (no coordinates); the per-site table goes to RESTRICTED."""
import csv, json, math
from collections import Counter, defaultdict
from pathlib import Path
from pyogrio.raw import read
from shapely import from_wkb
from shapely.geometry import Point
from shapely.strtree import STRtree

HOME = Path.home(); D = HOME / "LSOG/2026-10-22_csda-pilot"; (D / "RESTRICTED").mkdir(exist_ok=True)
OCC = HOME / "LSOG/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
U = "/vsicurl/https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/WESM.gpkg"
meta, fids, geoms, fields = read(U, bbox=(-71.2, 42.9, -66.8, 47.6),
                                 columns=["workunit", "project", "collect_start", "collect_end", "ql", "lpc_category"])
names = list(meta["fields"]); F = {n: fields[i] for i, n in enumerate(names)}
G = from_wkb(geoms); n = len(G)
wu = [{k: (str(F[k][i]) if F[k][i] is not None else "") for k in names} for i in range(n)]
tree = STRtree(G)

def hav(a, b):
    R = 6371.0; la1, lo1, la2, lo2 = map(math.radians, (a[1], a[0], b[1], b[0]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R * math.asin(math.sqrt(h))
pts = [(r["plotname"], float(r["lon"]), float(r["lat"]), r["occ_class"], r["project"]) for r in csv.DictReader(open(OCC))]
og = [p for p in pts if p[3] == "Old-growth"]
grp = {p[0]: i for i, p in enumerate(og)}
ch = True
while ch:
    ch = False
    for a in og:
        for b in og:
            if grp[a[0]] != grp[b[0]] and hav(a[1:3], b[1:3]) <= 10:
                lo, hi = sorted((grp[a[0]], grp[b[0]]))
                for k in grp:
                    if grp[k] == hi: grp[k] = lo
                ch = True
sz = Counter(grp.values()); lab = {g: "ABCD"[i] for i, g in enumerate(sorted(sz, key=lambda g: -sz[g]))}

rows = []; agg = defaultdict(Counter)
for p in pts:
    hits = [i for i in tree.query(Point(p[1], p[2])) if G[i].contains(Point(p[1], p[2]))]
    win = [i for i in hits if wu[i]["collect_start"][:4].isdigit() and 2015 <= int(wu[i]["collect_start"][:4]) <= 2019]
    best = max(win, key=lambda i: wu[i]["collect_end"]) if win else None
    yr = wu[best]["collect_start"][:4] if best is not None else "none"
    ql = wu[best]["ql"] if best is not None else ""
    proj = wu[best]["project"] if best is not None else ""
    nall = len(hits)
    cls = p[3]; g = lab[grp[p[0]]] if p[0] in grp else ""
    rows.append({"plotname": p[0], "occ_class": cls, "og_group": g, "wesm_project": proj, "collect_year": yr, "ql": ql, "n_workunits_all_years": nall})
    agg[cls][yr] += 1
    agg[cls + "|ql"][ql or "none"] += 1
    if g: agg["OG_group_" + g][f"{yr} {proj}"] += 1
with open(D / "RESTRICTED/occ_site_lidar_vintage_RESTRICTED.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
# H2(c) feasibility: lidar projects holding both OG and LS sites
proj_cls = defaultdict(Counter)
for r in rows:
    if r["occ_class"] in ("Old-growth", "LS"): proj_cls[r["wesm_project"]][r["occ_class"]] += 1
both = {k: dict(v) for k, v in proj_cls.items() if v["Old-growth"] and v["LS"]}
out = {"workunits_in_maine_bbox": n, "by_class_year": {k: dict(v) for k, v in agg.items() if "|" not in k and not k.startswith("OG_group")},
       "by_class_ql": {k.split("|")[0]: dict(v) for k, v in agg.items() if k.endswith("|ql")},
       "OG_groups": {k: dict(v) for k, v in agg.items() if k.startswith("OG_group")},
       "LS_OG_by_project": {k: dict(v) for k, v in proj_cls.items()}, "projects_with_both_OG_and_LS": both}
json.dump(out, open(D / "out/lidar_vintage_SUMMARY.json", "w"), indent=1); print(json.dumps(out, indent=1))
