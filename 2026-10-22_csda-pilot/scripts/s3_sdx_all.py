#!/usr/bin/env python3
"""CSDA pilot, G1 extension (Aaron chose option 1 on October 22): catalog search over all 102 OCC LS and OG
sites, then the PREREG Section 6 selection rules (md5 406c7e96) applied per 10 km group, and site coverage.
Catalog metadata only. Points stay here; SDX gets one bbox per 10 km group of 1 km cells, rounded outward to
0.05 degree. Outputs carry counts and public item ids only, never coordinates or cell ids."""
import csv, json, math, random, time, urllib.request
from collections import defaultdict
from pathlib import Path
from shapely.geometry import box, shape
from shapely.ops import unary_union

HOME = Path.home(); OUT = HOME / "LSOG/2026-10-22_csda-pilot/out"; OUT.mkdir(parents=True, exist_ok=True)
OCC = HOME / "LSOG/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
STAC = "https://csdap.earthdata.nasa.gov/stac/search"; SEED = 20261022
DY = 1000.0 / 111320.0; DX = 1000.0 / (111320.0 * math.cos(math.radians(45.5)))

def hav(a, b):
    R = 6371.0; la1, lo1, la2, lo2 = map(math.radians, (a[1], a[0], b[1], b[0]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * R * math.asin(math.sqrt(h))
def cell(x, y): return (math.floor(x / DX), math.floor(y / DY))
def cellbox(c): return box(c[0] * DX, c[1] * DY, (c[0] + 1) * DX, (c[1] + 1) * DY)

pts = [(r["plotname"], float(r["lon"]), float(r["lat"]), r["occ_class"]) for r in csv.DictReader(open(OCC))]
tgt = [p for p in pts if p[3] in ("Old-growth", "LS")]
# single-linkage 10 km groups over LS and OG sites (union-find)
par = list(range(len(tgt)))
def find(i):
    while par[i] != i: par[i] = par[par[i]]; i = par[i]
    return i
for i in range(len(tgt)):
    for j in range(i + 1, len(tgt)):
        if hav(tgt[i][1:3], tgt[j][1:3]) <= 10.0: par[find(i)] = find(j)
roots = defaultdict(list)
for i, p in enumerate(tgt): roots[find(i)].append(p)
order = sorted(roots, key=lambda r: (-sum(p[3] == "Old-growth" for p in roots[r]), -len(roots[r])))
lab = {r: f"G{k + 1:02d}" for k, r in enumerate(order)}
site_group = {p[0]: lab[find(i)] for i, p in enumerate(tgt)}
role = {}       # cell -> (group, role)
cell_sites = defaultdict(list)
for p in tgt:
    c = cell(p[1], p[2]); r = "OG" if p[3] == "Old-growth" else "LS"
    cell_sites[c].append((p[0], r))
    if c not in role or r == "OG": role[c] = (site_group[p[0]], r)
# the same 40 seeded control cells as s1, reproduced with s1's own OG grouping, labels and draw
og = [p for p in pts if p[3] == "Old-growth"]
ogrp = {p[0]: i for i, p in enumerate(og)}
changed = True
while changed:
    changed = False
    for a1 in og:
        for b1 in og:
            if ogrp[a1[0]] != ogrp[b1[0]] and hav(a1[1:3], b1[1:3]) <= 10.0:
                lo, hi = min(ogrp[a1[0]], ogrp[b1[0]]), max(ogrp[a1[0]], ogrp[b1[0]])
                for k in ogrp:
                    if ogrp[k] == hi: ogrp[k] = lo
                changed = True
osz = defaultdict(int)
for k in ogrp: osz[ogrp[k]] += 1
olab = {g: "ABCDEFGH"[i] for i, g in enumerate(sorted(osz, key=lambda g: -osz[g]))}
def near_og(p): return min((hav(p[1:3], q[1:3]), olab[ogrp[q[0]]]) for q in og)
s1sel = {cell(p[1], p[2]) for p in og} | {cell(p[1], p[2]) for p in pts if p[3] == "LS" and near_og(p)[0] <= 25.0}
cp = []
for p in pts:
    if p[3] in ("Not LS", "Trans LS"):
        d, g = near_og(p); c = cell(p[1], p[2])
        if d <= 25.0 and c not in s1sel: cp.append((c, g))
cp = sorted(set(cp)); random.Random(SEED).shuffle(cp)
s1ctrl = []
for c, g in cp[:40]:
    if c not in s1ctrl: s1ctrl.append(c)
for c in s1ctrl:
    if c in role: continue
    near = min((hav(((c[0] + .5) * DX, (c[1] + .5) * DY), q[1:3]), site_group[q[0]]) for q in tgt)[1]
    role[c] = (near, "control")

cells_by = defaultdict(list)
for c, (g, r) in role.items(): cells_by[g].append((c, r))
qbox = {}
for g, L in cells_by.items():
    u = unary_union([cellbox(c) for c, _ in L]).bounds
    qbox[g] = [math.floor(u[0] * 20) / 20, math.floor(u[1] * 20) / 20, math.ceil(u[2] * 20) / 20, math.ceil(u[3] * 20) / 20]

def post(url, body):
    for k in range(4):
        try:
            req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
            return json.load(urllib.request.urlopen(req, timeout=120))
        except Exception as e:
            err = e; time.sleep(5 * (k + 1))
    raise err
def search(coll, bb):
    body = {"collections": [coll], "bbox": bb, "limit": 200}; d = post(STAC, body); F = list(d["features"])
    while d["features"]:
        nxt = [l for l in d.get("links", []) if l.get("rel") == "next"]
        if not nxt: break
        l = nxt[0]
        if l.get("body"): d = post(l.get("href", STAC), {**body, **l["body"]} if l.get("merge") else l["body"])
        else: d = json.load(urllib.request.urlopen(l["href"], timeout=120))
        F += d["features"]
    return F

items = {}     # (coll,id) -> record with covered cells (kept server side only)
errs = {}
for coll in ("pgc-earthdem", "desis"):
    for g, bb in sorted(qbox.items()):
        try: F = search(coll, bb)
        except Exception as e: errs[f"{coll}|{g}"] = str(e); continue
        for f in F:
            try: geom = shape(f["geometry"])
            except Exception: continue
            cov = [c for c, _ in cells_by[g] if geom.intersects(cellbox(c)) and geom.intersection(cellbox(c)).area / cellbox(c).area >= 0.5]
            if not cov: continue
            p = f["properties"]; a = f.get("assets", {})
            rec = items.setdefault((coll, f["id"]), {"collection": coll, "item_id": f["id"],
                "type": p.get("csda:item_type") or p.get("item_type") or "", "date": (p.get("datetime") or p.get("start_datetime") or "")[:10],
                "cloud": (p["pgc:cloud_area_percent"] * 100) if p.get("pgc:cloud_area_percent") is not None else None,
                "rmse": p.get("pgc:rmse"), "conv": p.get("pgc:avg_convergence_angle"),
                "size_MB": round(sum((v.get("file:size") or 0) for v in a.values() if "data" in (v.get("roles") or [])) / 1e6, 1),
                "cells": set(), "geom": geom})
            rec["cells"].update(cov)

def md(d): return int(d[5:7]), int(d[8:10])
def ed_ok(r):
    m, dd = md(r["date"])
    if m in (12, 1, 2, 3) or (m == 4 and dd <= 15): return False
    return r["type"] == "strip" and r["cloud"] is not None and r["cloud"] <= 15 and r["rmse"] is not None and r["rmse"] <= 1.25
def gcount(r, g, roles=("OG", "LS")): return sum(1 for c in r["cells"] if role[c][0] == g and role[c][1] in roles)
def conv_pen(r): return 0 if r["conv"] and 35 <= r["conv"] <= 45 else (min(abs(r["conv"] - 35), abs(r["conv"] - 45)) if r["conv"] else 99)

ED = [r for r in items.values() if r["collection"] == "pgc-earthdem" and ed_ok(r)]
pick = {}   # item_id -> list of (group, role)
for g in sorted(cells_by):
    inw = [r for r in ED if 2015 <= int(r["date"][:4]) <= 2019 and gcount(r, g) > 0]
    out = [r for r in ED if not (2015 <= int(r["date"][:4]) <= 2019) and gcount(r, g) > 0]
    if inw:
        b = max(inw, key=lambda r: (gcount(r, g), "_lsf_" not in r["item_id"], -r["cloud"], -conv_pen(r)))
        pick.setdefault(b["item_id"], []).append((g, "primary"))
    if out:
        b = max(out, key=lambda r: (gcount(r, g), "_lsf_" not in r["item_id"], -r["cloud"]))
        pick.setdefault(b["item_id"], []).append((g, "repeat"))
DS = {}
for r in items.values():
    if r["collection"] != "desis" or md(r["date"])[0] not in (6, 7, 8): continue
    k, v = r["item_id"].rsplit("-V", 1)
    if k not in DS or v > DS[k]["item_id"].rsplit("-V", 1)[1]: DS[k] = r
dpick = {}
for g in sorted(cells_by):
    C = [r for r in DS.values() if gcount(r, g, ("OG", "LS", "control")) > 0]
    if not C: continue
    b = max(C, key=lambda r: (gcount(r, g), gcount(r, g, ("control",))))
    dpick.setdefault(b["item_id"], []).append((g, "primary"))
    have = {c for c in b["cells"] if role[c][0] == g}
    add = [(len({c for c in r["cells"] if role[c][0] == g} - have), r) for r in C if r is not b]
    add = [x for x in add if x[0] > 0]
    if add:
        a = max(add, key=lambda x: (x[0], gcount(x[1], g)))[1]; dpick.setdefault(a["item_id"], []).append((g, "add-on"))

byid = {r["item_id"]: r for r in items.values()}
def coverage(ids, inwin_only=False):
    cov = set()
    for i in ids:
        r = byid[i]
        if inwin_only and not (2015 <= int(r["date"][:4]) <= 2019): continue
        cov |= r["cells"]
    sites = [s for c in cov for s in cell_sites.get(c, [])]
    og_groups = {site_group[s] for s, rr in sites if rr == "OG"}
    return {"OG_sites": sum(rr == "OG" for _, rr in sites), "LS_sites": sum(rr == "LS" for _, rr in sites),
            "LS_OG_sites": len(sites), "OG_groups_covered": len(og_groups)}
def coverage_site(ids, inwin_only=False):
    """site-level: the 1 ha square (100 m side) around the site point lies wholly inside a selected footprint"""
    gs = [byid[i]["geom"] for i in ids if not (inwin_only and not (2015 <= int(byid[i]["date"][:4]) <= 2019))]
    if not gs: return {"OG_sites": 0, "LS_sites": 0, "LS_OG_sites": 0, "OG_groups_covered": 0}
    U = unary_union(gs); hx = 50 / (111320.0 * math.cos(math.radians(45.5))); hy = 50 / 111320.0
    cov = [p for p in tgt if U.contains(box(p[1] - hx, p[2] - hy, p[1] + hx, p[2] + hy))]
    return {"OG_sites": sum(p[3] == "Old-growth" for p in cov), "LS_sites": sum(p[3] == "LS" for p in cov),
            "LS_OG_sites": len(cov), "OG_groups_covered": len({site_group[p[0]] for p in cov if p[3] == "Old-growth"})}
og_groups_total = len({site_group[p[0]] for p in tgt if p[3] == "Old-growth"})
rows = []
for i, gl in sorted(pick.items(), key=lambda x: byid[x[0]]["date"]):
    r = byid[i]; rows.append({"collection": r["collection"], "item_id": i, "date": r["date"], "cloud_pct": round(r["cloud"], 1),
        "rmse_m": round(r["rmse"], 2), "convergence_deg": round(r["conv"], 1) if r["conv"] else "", "size_MB": r["size_MB"],
        "roles": " ".join(f"{g}:{ro}" for g, ro in gl), "OG_cells": sum(role[c][1] == "OG" for c in r["cells"]),
        "LS_cells": sum(role[c][1] == "LS" for c in r["cells"]), "control_cells": sum(role[c][1] == "control" for c in r["cells"])})
for i, gl in sorted(dpick.items(), key=lambda x: byid[x[0]]["date"]):
    r = byid[i]; rows.append({"collection": "desis", "item_id": i, "date": r["date"], "cloud_pct": "", "rmse_m": "", "convergence_deg": "",
        "size_MB": r["size_MB"], "roles": " ".join(f"{g}:{ro}" for g, ro in gl), "OG_cells": sum(role[c][1] == "OG" for c in r["cells"]),
        "LS_cells": sum(role[c][1] == "LS" for c in r["cells"]), "control_cells": sum(role[c][1] == "control" for c in r["cells"])})
with open(OUT / "sdx_all102_ORDER_DATA.csv", "w", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
gs = {g: {"OG_sites": sum(1 for p in tgt if site_group[p[0]] == g and p[3] == "Old-growth"),
          "LS_sites": sum(1 for p in tgt if site_group[p[0]] == g and p[3] == "LS"),
          "has_inwindow_strip": any(ro == "primary" and g2 == g for i, gl in pick.items() for g2, ro in gl),
          "has_any_strip": any(g2 == g for i, gl in pick.items() for g2, _ in gl),
          "has_desis": any(g2 == g for i, gl in dpick.items() for g2, _ in gl)} for g in sorted(cells_by)}
summ = {"sites": len(tgt), "OG": len(og), "groups": len(cells_by), "OG_groups": og_groups_total,
        "cells": {k: sum(1 for v in role.values() if v[1] == k) for k in ("OG", "LS", "control")},
        "candidates": {"earthdem_all": sum(r["collection"] == "pgc-earthdem" for r in items.values()), "earthdem_eligible": len(ED),
                       "desis_all": sum(r["collection"] == "desis" for r in items.values()), "desis_leafon_tiles": len(DS)},
        "picked": {"earthdem": len(pick), "desis": len(dpick),
                   "earthdem_MB": round(sum(byid[i]["size_MB"] for i in pick), 1), "desis_MB": round(sum(byid[i]["size_MB"] for i in dpick), 1)},
        "coverage_earthdem_any": coverage(pick), "coverage_earthdem_inwindow": coverage(pick, True), "coverage_desis": coverage(dpick),
        "coverage_all_eligible_earthdem": coverage([r["item_id"] for r in ED]),
        "site_coverage_earthdem_any": coverage_site(pick), "site_coverage_earthdem_inwindow": coverage_site(pick, True),
        "site_coverage_all_eligible_earthdem": coverage_site([r["item_id"] for r in ED]), "site_coverage_desis": coverage_site(dpick),
        "groups_detail": gs, "errors": errs, "query_area_km2_total": round(sum(box(*b).area for b in qbox.values()) * 111.32 ** 2 * math.cos(math.radians(45.5)))}
json.dump(summ, open(OUT / "sdx_all102_SUMMARY.json", "w"), indent=1)
# restricted: cell boxes per selected item, for clipped reads (never leaves this server)
RD = OUT.parent / "RESTRICTED"; RD.mkdir(exist_ok=True)
json.dump({i: [[k, role[c][0], role[c][1], list(cellbox(c).bounds)] for k, c in enumerate(sorted(byid[i]["cells"]))]
           for i in list(pick) + list(dpick)}, open(RD / "item_cells_RESTRICTED.json", "w"))
print(json.dumps({k: v for k, v in summ.items() if k != "groups_detail"}, indent=1))
