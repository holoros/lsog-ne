#!/usr/bin/env python3
"""H2 site metrics from EarthDEM clips (descriptive; PREREG amendment A2).

Canopy height on the 2 m strip grid = EarthDEM surface (ITRF2014 ellipsoid) + ITRF2014-to-NAD83(2011) shift
(PROJ EPSG:7912 to EPSG:6319 at the strip epoch, about +1.1 m in Maine, asserted 0.9 to 1.3 m) - GEOID18 N
(grid longitudes 230 to 300, so lon % 360) - 3DEP 1 m bare earth averaged to 2 m - vertical offset dz.

Vertical offset, two passes (red team, before any download):
 1. Every clip with at least 2,500 matched cells, control clips included, gets a clip dz = median of
    (surface - bare earth) over cells within 2 m of the clip's 5th percentile of that difference.
 2. strip_dz = median of clip dz over all clips of the strip. A clip keeps its own dz only when the strip has
    at least 3 clips, the clip dz is within 2 m of strip_dz, and at least 2% of the clip's valid cells sit within
    1.5 m of strip_dz (ground evidence that does not depend on the 5th percentile); otherwise the clip uses
    strip_dz (dz_source = strip). A strip with fewer than 3 clips and a clip without ground evidence is flagged
    and excluded (dz_source = none).
Valid cells: matchtag 1, bitmask 0 (share computed over cells with DEM data; clips under 50% zero are dropped),
DEM and bare earth present. Site window: the 1 ha square (100 m side) centred on the site; at least 625 valid
cells. Sensitivity: every pair also gets cov15 computed with strip_dz (cov15_stripdz).
Per-site and per-clip tables stay in RESTRICTED; the summary carries counts and distributions only."""
import csv, json, os
from collections import defaultdict
from pathlib import Path
import numpy as np
from pyproj import Transformer
import rasterio
from rasterio.warp import reproject, Resampling, transform as wtransform
from rasterio.windows import from_bounds

D = Path(os.environ.get("CSDA_DIR", str(Path.home() / "LSOG/2026-10-22_csda-pilot"))); R = D / "RESTRICTED"
OCC = Path.home() / "LSOG/data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"
ORDER = [o for o in csv.DictReader(open(D / "out/sdx_all102_ORDER_DATA.csv")) if o["collection"] == "pgc-earthdem"]
CELLS = json.load(open(R / "item_cells_RESTRICTED.json"))
G = rasterio.open(D / "ref/us_noaa_g2018u0.tif")
ITRF2NAD = Transformer.from_crs("EPSG:7912", "EPSG:6319", always_xy=True)
pts = [r for r in csv.DictReader(open(OCC)) if r["occ_class"] in ("LS", "Old-growth")]
dtm_meta = {}
for j in (R / "dtm").glob("dtm_*.json"):
    m = json.load(open(j)); dtm_meta[tuple(round(v, 7) for v in m["cell_bounds"])] = next(j.parent.glob(j.stem + "_*.tif"))

def geoid_N(lon, lat):
    x = lon % 360 if G.bounds.left >= 0 else lon
    return float(list(G.sample([(x, lat)]))[0][0])
def epoch(date): y, m, d = map(int, date.split("-")); return y + (m - 0.5) / 12
def nad_shift(lon, lat, ep):
    s = ITRF2NAD.transform(lon, lat, 100.0, ep)[2] - 100.0
    assert 0.9 < s < 1.3, f"unexpected ITRF to NAD83 shift {s}"
    return s

# ---- pass 1: read every clip, compute the datum-corrected difference and clip dz ----
clips = {}; clip_log = []
for o in ORDER:
    item = o["item_id"]; cd = R / "clips" / item
    if not cd.exists(): continue
    ep = epoch(o["date"])
    for k, g, role, bb in CELLS[item]:
        cb = tuple(round(v, 7) for v in bb); tag = f"c{k:03d}_{g}_{role}"
        fd, fm, ft = cd / f"dem_{tag}.tif", cd / f"mask_{tag}.tif", cd / f"matchtag_{tag}.tif"
        if not (fd.exists() and fm.exists() and ft.exists() and cb in dtm_meta):
            clip_log.append({"item_id": item, "cell": k, "status": "missing input"}); continue
        with rasterio.open(fd) as d, rasterio.open(fm) as mk, rasterio.open(ft) as mt, rasterio.open(dtm_meta[cb]) as t:
            assert d.crs.is_projected and abs(d.res[0] - 2.0) < 0.01, "expected a 2 m projected strip"
            dsm = d.read(1).astype("float64"); nod = d.nodata
            dtm2 = np.full(dsm.shape, np.nan)
            reproject(t.read(1, masked=True).filled(np.nan).astype("float64"), dtm2, src_transform=t.transform, src_crs=t.crs,
                      dst_transform=d.transform, dst_crs=d.crs, resampling=Resampling.average, src_nodata=np.nan, dst_nodata=np.nan)
            mkv, mtv = mk.read(1), mt.read(1)
            good = (dsm != nod) if nod is not None else np.ones(dsm.shape, bool)
            valid = (mkv == 0) & (mtv == 1) & np.isfinite(dtm2) & good
            mzs = float((mkv[good] == 0).mean()) if good.any() else 0.0
            cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
            diff = dsm + nad_shift(cx, cy, ep) - geoid_N(cx, cy) - dtm2   # surface minus bare earth, in metres
            dv = diff[valid]
            if dv.size < 2500 or mzs < 0.5:
                clip_log.append({"item_id": item, "cell": k, "status": "too few matched cells" if dv.size < 2500 else "bitmask mostly nonzero",
                                 "n": int(dv.size), "mask_zero_share": round(mzs, 3)}); continue
            p5 = np.percentile(dv, 5); dz = float(np.median(dv[dv <= p5 + 2.0]))
            clips[(item, k)] = {"item": item, "k": k, "g": g, "role": role, "bb": bb, "ep": ep, "date": o["date"], "dz": dz,
                                "transform": d.transform, "crs": d.crs, "shape": dsm.shape, "valid": valid,
                                "dsm": dsm, "dtm": dtm2, "dv": dv.astype("float32")}

# ---- pass 2: strip-level offset and the per-clip decision ----
by_strip = defaultdict(list)
for c in clips.values(): by_strip[c["item"]].append(c["dz"])
strip_dz = {k: float(np.median(v)) for k, v in by_strip.items()}
for c in clips.values():
    sdz, n = strip_dz[c["item"]], len(by_strip[c["item"]])
    ground = float((np.abs(c["dv"] - sdz) < 1.5).mean())
    if n >= 3 and abs(c["dz"] - sdz) <= 2.0 and ground >= 0.02: c["dz_used"], c["src"] = c["dz"], "clip"
    elif n >= 3: c["dz_used"], c["src"] = sdz, "strip"
    elif ground >= 0.02 and abs(c["dz"] - sdz) <= 2.0: c["dz_used"], c["src"] = c["dz"], "clip"
    else: c["dz_used"], c["src"] = None, "none"
    clip_log.append({"item_id": c["item"], "cell": c["k"], "group": c["g"], "role": c["role"], "status": "ok" if c["src"] != "none" else "flagged",
                     "dz_clip": round(c["dz"], 2), "dz_strip": round(sdz, 2), "n_clips_strip": n, "ground_share": round(ground, 3), "dz_source": c["src"]})

# ---- site metrics ----
rows = []
for c in clips.values():
    if c["role"] == "control": continue
    bb = c["bb"]
    for p in pts:
        lon, lat = float(p["lon"]), float(p["lat"])
        if not (bb[0] <= lon < bb[2] and bb[1] <= lat < bb[3]): continue
        rec = {"plotname": p["plotname"], "occ_class": p["occ_class"], "item_id": c["item"], "date": c["date"], "group": c["g"],
               "dz_source": c["src"], "dz_used": round(c["dz_used"], 2) if c["dz_used"] is not None else "", "dz_strip": round(strip_dz[c["item"]], 2)}
        xs, ys = wtransform("EPSG:4326", c["crs"], [lon], [lat]); x, y = xs[0], ys[0]
        w = from_bounds(x - 50, y - 50, x + 50, y + 50, transform=c["transform"]).round_offsets().round_lengths()
        r0, c0 = int(w.row_off), int(w.col_off)
        if r0 < 0 or c0 < 0 or r0 + w.height > c["shape"][0] or c0 + w.width > c["shape"][1]:
            rec["skip"] = "window outside clip"; rows.append(rec); continue
        sl = (slice(r0, r0 + int(w.height)), slice(c0, c0 + int(w.width)))
        v = c["valid"][sl]
        base = (c["dsm"][sl] + nad_shift(lon, lat, c["ep"]) - geoid_N(lon, lat) - c["dtm"][sl])[v]
        rec.update(valid_share=round(float(v.mean()), 3), n_valid=int(v.sum()))
        if v.sum() >= 625 and c["dz_used"] is not None:
            chm = base - c["dz_used"]
            rec.update(cov15=round(float((chm > 15).mean()), 4), mean_h=round(float(chm.mean()), 2),
                       p95_h=round(float(np.percentile(chm, 95)), 2), p05_h=round(float(np.percentile(chm, 5)), 2),
                       cov15_stripdz=round(float(((base - strip_dz[c["item"]]) > 15).mean()), 4))
        rows.append(rec)

cols = ["plotname", "occ_class", "item_id", "date", "group", "dz_source", "dz_used", "dz_strip", "valid_share", "n_valid",
        "cov15", "cov15_stripdz", "mean_h", "p95_h", "p05_h", "skip"]
json.dump(clip_log, open(R / "h2_clip_coreg_RESTRICTED.json", "w"), indent=1)
with open(R / "h2_site_chm_RESTRICTED.csv", "w", newline="") as fh:
    wr = csv.DictWriter(fh, fieldnames=cols); wr.writeheader(); [wr.writerow({k: r.get(k, "") for k in cols}) for r in rows]
ok = [r for r in rows if "cov15" in r]
def med(x): return round(float(np.median(x)), 3) if len(x) else None
summ = {"site_strip_pairs": len(rows), "pairs_with_metrics": len(ok), "windows_outside_clip": sum("skip" in r for r in rows),
        "sites_with_metrics": {c: len({r["plotname"] for r in ok if r["occ_class"] == c}) for c in ("Old-growth", "LS")},
        "clips": {s: sum(c["status"] == s for c in clip_log) for s in ("ok", "flagged", "too few matched cells", "bitmask mostly nonzero", "missing input")},
        "dz_source_pairs": {s: sum(r.get("dz_source") == s for r in ok) for s in ("clip", "strip")},
        "dz_clip_quantiles_m": [round(float(q), 2) for q in np.percentile([c["dz"] for c in clips.values()], [5, 50, 95])] if clips else None,
        "p05_h_median": med([r["p05_h"] for r in ok]),
        "valid_share_median_by_class": {k: med([r["valid_share"] for r in ok if r["occ_class"] == k]) for k in ("Old-growth", "LS")},
        "cov15_median_by_class_clipdz": {k: med([r["cov15"] for r in ok if r["occ_class"] == k]) for k in ("Old-growth", "LS")},
        "cov15_median_by_class_stripdz": {k: med([r["cov15_stripdz"] for r in ok if r["occ_class"] == k]) for k in ("Old-growth", "LS")}}
json.dump(summ, open(D / "out/h2_chm_SUMMARY.json", "w"), indent=1); print(json.dumps(summ, indent=1))
