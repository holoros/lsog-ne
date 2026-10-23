"""Vantor form boxes for the G1 extension: per 10 km LS group (all102 grouping), bbox of its cells rounded outward
to 0.1 degree and widened to at least 0.2 x 0.2 degree; boxes that overlap or touch are merged. OG tract boxes (A to D)
are the existing four. Output: boxes only (tract scale, no site or cell coordinates)."""
import json, math
cells = json.load(open("RESTRICTED/item_cells_RESTRICTED.json"))
by = {}
for item, L in cells.items():
    for k, g, role, bb in L:
        if role != "LS": continue
        b = by.setdefault(g, [180, 90, -180, -90]); b[0] = min(b[0], bb[0]); b[1] = min(b[1], bb[1]); b[2] = max(b[2], bb[2]); b[3] = max(b[3], bb[3])
def rnd(b):
    x0, y0, x1, y1 = math.floor(b[0]*10)/10, math.floor(b[1]*10)/10, math.ceil(b[2]*10)/10, math.ceil(b[3]*10)/10
    if x1 - x0 < 0.2: x0 -= 0.1 if x1 - x0 < 0.15 else 0; x1 = max(x1, x0 + 0.2)
    if y1 - y0 < 0.2: y0 -= 0.1 if y1 - y0 < 0.15 else 0; y1 = max(y1, y0 + 0.2)
    return [round(x0, 1), round(y0, 1), round(x1, 1), round(y1, 1)]
boxes = [(rnd(b), [g]) for g, b in sorted(by.items())]
merged = True
while merged:
    merged = False
    for i in range(len(boxes)):
        for j in range(i + 1, len(boxes)):
            a, b = boxes[i][0], boxes[j][0]
            if not (a[2] < b[0] or b[2] < a[0] or a[3] < b[1] or b[3] < a[1]):
                boxes[i] = ([min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])], boxes[i][1] + boxes[j][1]); del boxes[j]; merged = True; break
        if merged: break
out = []
for b, gs in boxes:
    km2 = (b[2]-b[0])*111.32*math.cos(math.radians((b[1]+b[3])/2))*(b[3]-b[1])*111.32
    out.append({"groups": gs, "UL_lat": b[3], "UL_lon": b[0], "LR_lat": b[1], "LR_lon": b[2], "area_km2": round(km2)})
json.dump(out, open("out/vantor_form_boxes_LS_DATA.json", "w"), indent=1); print(json.dumps(out))
