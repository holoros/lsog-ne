#!/usr/bin/env python3
# RELABEL COPY (r-series, October 11-12, 2026): FIA labels from the 2019-2023 remeasurement scored on the v5.1 card (r0_relabel.py);
# calibration targets are the design-based 232301 rates 14.66 / 2.07 / 0.21 percent; V2 OCC points throughout; outputs v5 / v5xp.
# s17d_xj_seam.py  Border seam of the rebuilt 10 m layers on the shared Maine and New Brunswick border (October 7, 2026),
# with the distance bands of the G5 gate in the September CORE4 build (500 m to 3 km on each side of the shared border,
# border geometry from xj_border.py), forest frame cells only (both layers are frame masked). Layers compared: softwood share (the same
# quantity on both sides), raw P(>= transitioning) before calibration, and the area calibrated P(>= transitioning). The
# calibrated step is expected, since each side is calibrated to its own design-based rate under its own definition.
import os, sys, json, numpy as np, pandas as pd, rasterio
from rasterio.windows import from_bounds
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import xj_border as XB
E = os.environ; OUT = E["OUT"]; AGG = f"{OUT}/agg"; U = 65535
XP = "/fs/scratch/PUOM0008/crsfaaron/occ_relabel_2026-10-12/finalxp"; NBF = f"{OUT}/final_nb"
L = {("ME", "raw"): (f"{XP}/occ-ordinal-v5xp-lsog_10m_ME_DATA_2026-10-12.tif", {"p_trans": 1, "softwood": 4}),
     ("ME", "cal"): (f"{XP}/occ-ordinal-v5xp-lsog-areacal_10m_ME_DATA_2026-10-12.tif", {"p_trans": 1}),
     ("NB", "raw"): (f"{NBF}/nb-lsog-v4_10m_NB_DATA_2026-10-06.tif", {"p_trans": 1, "softwood": 3}),
     ("NB", "cal"): (f"{NBF}/nb-lsog-v4-areacal_10m_NB_DATA_2026-10-07.tif", {"p_trans": 1})}
print("shared border length on the 100 m grid, km", round(float(XB.BORDER_KM_LENGTH), 1), flush=True)
near = XB.DIST <= 3000; acc = {}; S20 = 200     # 20 km blocks of the 100 m grid
for r0 in range(0, XB.H_, S20):
    for c0 in range(0, XB.W_, S20):
        if not near[r0:r0 + S20, c0:c0 + S20].any(): continue
        bb = (XB.X0 + c0 * XB.RES, XB.Y1 - (r0 + S20) * XB.RES, XB.X0 + (c0 + S20) * XB.RES, XB.Y1 - r0 * XB.RES)
        for (J, kind), (path, bands) in L.items():
            with rasterio.open(path) as r:
                w = from_bounds(*bb, transform=r.transform).round_offsets().round_lengths()
                arr = {nm: r.read(b, window=w, boundless=True, fill_value=U) for nm, b in bands.items()}; wt = r.window_transform(w)
            h, ww = next(iter(arr.values())).shape
            cc, rr = np.meshgrid(np.arange(ww), np.arange(h))
            dist = XB.dist_xy(wt.c + (cc.ravel() + 0.5) * wt.a, wt.f + (rr.ravel() + 0.5) * wt.e).reshape(h, ww)
            for nm, a in arr.items():
                v = a != U
                for lo in range(0, 3000, 500):
                    m = v & (dist > lo) & (dist <= lo + 500)
                    if m.any():
                        c = acc.setdefault((J, kind, nm, lo), [0, 0.0, 0.0]); x = a[m].astype("float64") / 1e4
                        c[0] += int(m.sum()); c[1] += float(x.sum()); c[2] += float((x ** 2).sum())
rows = [dict(side=J, layer=f"{nm} ({kind})", band_lo_m=lo, band_hi_m=lo + 500, n=n, mean=s / n, sd=np.sqrt(max(q / n - (s / n) ** 2, 0)))
        for (J, kind, nm, lo), (n, s, q) in sorted(acc.items())]
S = pd.DataFrame(rows); S.to_csv(f"{AGG}/xj_border_seam_DATA.csv", index=False)
st = []
for lay in S.layer.unique():
    a = S[(S.layer == lay) & (S.band_lo_m == 0)].set_index("side"); b = S[(S.layer == lay) & (S.band_lo_m == 2500)].set_index("side")
    if {"ME", "NB"} <= set(a.index):
        st.append(dict(layer=lay, step_0_500m_nb_minus_me=round(a.loc["NB", "mean"] - a.loc["ME", "mean"], 4),
                       step_2500_3000m_nb_minus_me=round(b.loc["NB", "mean"] - b.loc["ME", "mean"], 4),
                       pooled_sd_0_500m=round(float(np.sqrt((a.loc["NB", "sd"] ** 2 + a.loc["ME", "sd"] ** 2) / 2)), 4),
                       n_me=int(a.loc["ME", "n"]), n_nb=int(a.loc["NB", "n"])))
T = pd.DataFrame(st); T.to_csv(f"{AGG}/xj_border_seam_steps_DATA.csv", index=False); print(S.round(4).to_string(index=False)); print(T.to_string(index=False)); print("S17D DONE")
