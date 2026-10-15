# Figure and area-matched capture from saved aggregates (q1 crashed only at the figure step: pandas Series passed to plot)
import numpy as np, pandas as pd, matplotlib; matplotlib.use("Agg"); import matplotlib.pyplot as plt
A = "agg"; CC = pd.read_csv(f"{A}/capture_curve_DATA.csv"); T = pd.read_csv(f"{A}/cuts_DATA.csv")
rows = []
for b in (1, 2):
    c = T[T.band == b].area_matched_cut.iloc[0]; d = CC[CC.band == b]; r = d.iloc[(d.cut - c).abs().values.argmin()]
    rows.append(dict(band=b, area_matched_cut=c, grid_cut=r.cut, state=r.state, aoi=r.aoi, NotLS=r.NotLS, TransLS=r.TransLS, LS=r.LS, OG=r.OG))
pd.DataFrame(rows).to_csv(f"{A}/area_matched_capture_DATA.csv", index=False); print(pd.DataFrame(rows).round(3).to_string(index=False))
fig, ax = plt.subplots(1, 2, figsize=(7.2, 3.4), dpi=300)
for j, b in enumerate((1, 2)):
    d = CC[CC.band == b].sort_values("cut"); a = ax[j]; xs = d.state.values * 100
    for col, lab, ls, cl in (("OG", "Old-growth (Type 1)", "-", "black"), ("LS", "LS (Type 2)", "-", "0.45"),
                             ("TransLS", "Transitioning", "--", "0.45"), ("NotLS", "Not LS", ":", "black")):
        a.plot(xs, d[col].values * 100, ls, color=cl, lw=1.2, label=lab)
    for rule, lsr in (("Youden", (0, (4, 2))), ("sensitivity 0.90", (0, (1, 1)))):
        r = T[(T.band == b) & (T.rule == rule)].iloc[0]; a.axvline(r.share_state_forest * 100, color="0.6", lw=0.8, ls=lsr)
    am = rows[j]["state"] * 100; a.axvline(am, color="0.6", lw=0.8); a.text(am + 0.6, 4, "FIA area", fontsize=6.5, color="0.4")
    a.set_xlabel("Maine forest flagged (%)", fontsize=8); a.set_ylabel("OCC field points flagged (%)" if j == 0 else "", fontsize=8)
    a.set_title(["P(transitioning or above)", "P(LS or OG)"][j], fontsize=9); a.set_xlim(0, 50); a.set_ylim(0, 101)
    a.spines[["top", "right"]].set_visible(False); a.tick_params(labelsize=7)
ax[1].legend(fontsize=6.5, frameon=False, loc="center right", bbox_to_anchor=(1.0, 0.45))
fig.text(0.01, 0.01, "Vertical lines: Youden cut (dashed), 90% sensitivity cut (dotted), cut matching the FIA area share (solid).", fontsize=6)
fig.tight_layout(rect=(0, 0.04, 1, 1)); fig.savefig(f"{A}/fig_capture_curve.png"); print("fig ok")
