"""Vantor form boxes: per OG group, bbox of the tranche 1 cells rounded outward to 0.1 degree,
then widened to at least 0.2 x 0.2 degree so no box localizes a site to finer than about 15 km."""
import math, json, runpy, io, contextlib
with contextlib.redirect_stdout(io.StringIO()):
    g = runpy.run_path("scripts/s1_sdx_search.py", run_name="boxes")
out = {}
for grp, L in sorted(g["cells_by"].items()):
    b = g["unary_union"]([g["cellbox"](c) for c, _ in L]).bounds
    x0, y0, x1, y1 = math.floor(b[0]*10)/10, math.floor(b[1]*10)/10, math.ceil(b[2]*10)/10, math.ceil(b[3]*10)/10
    while x1 - x0 < 0.2 - 1e-9: x0 -= 0.1 if (x1-x0) < 0.15 else 0; x1 += 0.1 if (x1-x0) < 0.2 - 1e-9 else 0
    while y1 - y0 < 0.2 - 1e-9: y0 -= 0.1 if (y1-y0) < 0.15 else 0; y1 += 0.1 if (y1-y0) < 0.2 - 1e-9 else 0
    km2 = (x1-x0)*111.32*math.cos(math.radians((y0+y1)/2))*(y1-y0)*111.32
    out[grp] = {"UL_lat": round(y1,1), "UL_lon": round(x0,1), "LR_lat": round(y0,1), "LR_lon": round(x1,1), "area_km2": round(km2)}
json.dump(out, open("out/vantor_form_boxes_DATA.json","w"), indent=1); print(json.dumps(out))
