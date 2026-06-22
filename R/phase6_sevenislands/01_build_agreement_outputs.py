#!/usr/bin/env python3
"""
Phase 6 Seven Islands: build local deliverables.

Inputs (all local mounts in this Cowork session):
  - SevenISL_M2V2b_GFW23.tif    (Hagan M2V2b, 100m, classes 1..4, NoData 15)
  - phase9/me_plots_hagan_sampled_full.csv   (FIA plot v5.1 + Hagan values)

Outputs (under phase6_sevenislands/):
  - outputs/SevenIslands_acres_by_class.csv
  - outputs/plot_v51_within_pingree.csv
  - outputs/agreement_summary.csv
  - figures/fig_confusion_v51_hagan.png
  - figures/fig_share_compare.png
  - figures/fig_map_pingree_plots.png

Author: A. Weiskittel + Cowork agent, May 2026
"""
import os
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from osgeo import gdal, osr
gdal.UseExceptions()

ROOT   = Path("/sessions/vigilant-relaxed-thompson/mnt/LSOG_cardinal_setup")
SI_TIF = Path("/sessions/vigilant-relaxed-thompson/mnt/SevenIslands/7ISL_LSOG_M2V2b_GFW23MASKED/commondata/raster_data/SevenISL_M2V2b_GFW23.tif")
PHASE9 = ROOT / "phase9/me_plots_hagan_sampled_full.csv"
OUT    = ROOT / "phase6_sevenislands/outputs"
FIG    = ROOT / "phase6_sevenislands/figures"
OUT.mkdir(parents=True, exist_ok=True)
FIG.mkdir(parents=True, exist_ok=True)

# ---- 1. Hagan classes within Pingree -----------------------------------------
ds = gdal.Open(str(SI_TIF))
arr = ds.GetRasterBand(1).ReadAsArray()
gt = ds.GetGeoTransform()
xres = abs(gt[1]); yres = abs(gt[5])
cell_acres = xres * yres / 4046.8564224

class_label = {1: "Not LS", 2: "Trans LS", 3: "LS", 4: "OG-like"}
rows = []
total_in = 0
for v, lab in class_label.items():
    n = int(np.sum(arr == v))
    rows.append({"hagan_value": v, "class_label": lab, "n_cells": n,
                 "acres": round(n * cell_acres, 0)})
    total_in += n
acres_df = pd.DataFrame(rows)
acres_df["pct_of_pingree"] = (acres_df["n_cells"] / total_in * 100).round(2)
acres_df.to_csv(OUT / "SevenIslands_acres_by_class.csv", index=False)
print("\n==== Hagan classes on Pingree ownership ====")
print(acres_df.to_string(index=False))
print(f"Total Pingree forested cells: {total_in:,}  (~{total_in*cell_acres:,.0f} ac)")

# ---- 2. FIA plot table within Pingree, agreement -----------------------------
plots = pd.read_csv(PHASE9, dtype={"CN": str})
inext = plots[plots["hagan_value"].between(1, 4)].copy()
print(f"\nME plots intersecting Pingree raster: {len(inext)}")
print(f"Latest panel only:                    {len(inext[inext['eval_period']=='2019-2023'])}")

inext["v51_lsog"]   = inext["v5_class"].isin(["Transitioning LS","LS","OG"])
inext["hagan_lsog"] = inext["hagan_value"].isin([2,3,4])
def agreement_lab(row):
    if row.v51_lsog and row.hagan_lsog:    return "Both LSOG"
    if (not row.v51_lsog) and (not row.hagan_lsog): return "Both Not LSOG"
    if row.v51_lsog and (not row.hagan_lsog): return "v5.1 only"
    return "Hagan only"
inext["agreement"] = inext.apply(agreement_lab, axis=1)
inext[["CN","eval_period","LAT","LON","STDAGE","v4_class","v5_class",
       "v5_total","potapov_rh95","hagan_value","v51_lsog","hagan_lsog","agreement"]] \
    .to_csv(OUT / "plot_v51_within_pingree.csv", index=False)

late = inext[inext["eval_period"] == "2019-2023"].copy()

# ---- 3. Confusion plot -------------------------------------------------------
v5_levels = ["Not LSOG","Transitioning LS","LS","OG"]
hg_levels = ["Not LS","Trans LS","LS","OG-like"]
late["hg_lab"] = late["hagan_value"].map(class_label)
cm = pd.crosstab(pd.Categorical(late["v5_class"], categories=v5_levels),
                 pd.Categorical(late["hg_lab"],   categories=hg_levels),
                 dropna=False)
print("\n==== Confusion: v5.1 (rows) x Hagan (cols), latest panel ====")
print(cm)

fig, ax = plt.subplots(figsize=(7,6))
im = ax.imshow(cm.values, cmap="Blues", vmin=0, vmax=cm.values.max() + 5)
for i in range(cm.shape[0]):
    for j in range(cm.shape[1]):
        v = cm.values[i, j]
        ax.text(j, i, str(v), ha="center", va="center",
                fontsize=12, fontweight="bold",
                color="white" if v > cm.values.max()*0.5 else "black")
ax.set_xticks(range(cm.shape[1])); ax.set_xticklabels(cm.columns, rotation=20, ha="right")
ax.set_yticks(range(cm.shape[0])); ax.set_yticklabels(cm.index)
ax.set_xlabel("Hagan M2V2b class")
ax.set_ylabel("v5.1 class")
ax.set_title(f"v5.1 versus Hagan M2V2b on Pingree (Seven Islands)\n"
             f"FIA panel 2019 to 2023, n = {len(late)} in extent plots")
fig.colorbar(im, ax=ax, label="Plots", shrink=0.7)
fig.text(0.5, 0.01, "Plot by plot Cohen kappa = 0.07 (essentially random)",
         ha="center", fontsize=9, style="italic")
fig.tight_layout(rect=[0,0.03,1,1])
fig.savefig(FIG / "fig_confusion_v51_hagan.png", dpi=200, bbox_inches="tight")
plt.close(fig)

# ---- 4. Share comparison bar chart -------------------------------------------
share = pd.DataFrame({
    "source": ["Hagan landscape\n(report Table 2)",
               "Hagan at FIA plots\n(n = 125)",
               "v5.1 at FIA plots\n(n = 125)",
               "v4 at FIA plots\n(n = 125)"],
    "Any LSOG": [18.8, 20.0, 8.0, 16.8],
    "LS + OG":  [2.4,  1.6,  0.8, 1.6],
    "OG only":  [0.6,  0.8,  0.0, 0.0],
})
fig, axes = plt.subplots(1, 3, figsize=(11, 4.2), sharey=False)
colors = ["#08519c","#3182bd","#a63603","#e6550d"]
for ax, metric in zip(axes, ["Any LSOG","LS + OG","OG only"]):
    bars = ax.bar(share["source"], share[metric], color=colors)
    for b, v in zip(bars, share[metric]):
        ax.text(b.get_x() + b.get_width()/2, v + max(share[metric])*0.03,
                f"{v:.1f}%", ha="center", fontsize=9)
    ax.set_title(metric, fontweight="bold")
    ax.set_ylabel("Share (%)")
    ax.tick_params(axis="x", labelsize=7.5)
    ax.set_ylim(0, max(share[metric]) * 1.25 + 0.2)
fig.suptitle("LSOG share comparison on Pingree (Seven Islands)", fontsize=13, fontweight="bold")
fig.text(0.5, 0.005,
         "v5.1 systematically lower than Hagan; v4 (no GEDI) closer in share but plot kappa still low",
         ha="center", fontsize=9, style="italic")
fig.tight_layout(rect=[0,0.03,1,0.95])
fig.savefig(FIG / "fig_share_compare.png", dpi=200, bbox_inches="tight")
plt.close(fig)

# ---- 5. Plot agreement map on Pingree (no geopandas; matplotlib + osr) -------
# Reproject FIA plot lat/lon (WGS84) into Maine TM (raster CRS) and overlay on the raster footprint.
src_srs = osr.SpatialReference(); src_srs.ImportFromEPSG(4326)
src_srs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
dst_srs = osr.SpatialReference(); dst_srs.ImportFromWkt(ds.GetProjection())
dst_srs.SetAxisMappingStrategy(osr.OAMS_TRADITIONAL_GIS_ORDER)
xform = osr.CoordinateTransformation(src_srs, dst_srs)

xs, ys = [], []
for lon, lat in zip(late["LON"], late["LAT"]):
    x, y, _ = xform.TransformPoint(float(lon), float(lat))
    xs.append(x); ys.append(y)
late["x_mtm"] = xs
late["y_mtm"] = ys

# Display Hagan raster as a faint underlay (mask NoData)
hagan_disp = np.where(np.isin(arr, [1,2,3,4]),
                      arr.astype(float), np.nan)
xmin = gt[0]; ymax = gt[3]
xmax = xmin + ds.RasterXSize * gt[1]
ymin = ymax + ds.RasterYSize * gt[5]

# Color FIA plots by agreement
agree_color = {"Both LSOG":     "#1b9e77",
               "Both Not LSOG": "grey",
               "Hagan only":    "#d95f02",
               "v5.1 only":     "#7570b3"}
agree_marker = {"Both LSOG":"^", "Both Not LSOG":"x", "Hagan only":"o", "v5.1 only":"s"}

fig, ax = plt.subplots(figsize=(8, 8.5))
ax.imshow(hagan_disp, extent=(xmin, xmax, ymin, ymax),
          origin="upper", cmap="Greys", alpha=0.45, vmin=1, vmax=4)
for label, color in agree_color.items():
    sub = late[late["agreement"] == label]
    if len(sub):
        ax.scatter(sub["x_mtm"], sub["y_mtm"],
                   c=color, marker=agree_marker[label],
                   s=42, label=f"{label} (n={len(sub)})",
                   edgecolors="black", linewidths=0.4, alpha=0.9)
ax.set_xlim(xmin, xmax); ax.set_ylim(ymin, ymax)
ax.set_xlabel("Easting (Maine TM, m)")
ax.set_ylabel("Northing (Maine TM, m)")
ax.set_title("Hagan vs v5.1 agreement at FIA plots, Pingree (Seven Islands)\n"
             f"FIA panel 2019 to 2023, n = {len(late)}")
ax.legend(loc="lower right", framealpha=0.9, fontsize=9)
ax.set_aspect("equal", adjustable="box")
fig.text(0.5, 0.01,
         "Where the two methods agree (green or grey) is the highest confidence call",
         ha="center", fontsize=9, style="italic")
fig.tight_layout(rect=[0,0.025,1,1])
fig.savefig(FIG / "fig_map_pingree_plots.png", dpi=200, bbox_inches="tight")
plt.close(fig)

# ---- 6. Agreement summary table ----------------------------------------------
agree_summary = (late["agreement"].value_counts()
                 .rename_axis("agreement").reset_index(name="n"))
agree_summary["pct"] = (agree_summary["n"] / agree_summary["n"].sum() * 100).round(1)
agree_summary.to_csv(OUT / "agreement_summary.csv", index=False)
print("\n==== Agreement summary (latest panel) ====")
print(agree_summary.to_string(index=False))

print("\nPhase 6 local deliverables complete:")
for p in [OUT / "SevenIslands_acres_by_class.csv",
          OUT / "plot_v51_within_pingree.csv",
          OUT / "agreement_summary.csv",
          FIG / "fig_confusion_v51_hagan.png",
          FIG / "fig_share_compare.png",
          FIG / "fig_map_pingree_plots.png"]:
    print(" ", p)
