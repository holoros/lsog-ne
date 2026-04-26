# Phase 5h: carbon stocks, forest type breakdown, OG plot diagnostics

Date: 2026-04-26
Inputs: unified plot table + state TREE.csv files for biomass

## Carbon density by LSOG class (Mg C/ha live aboveground)

| State | Not LSOG | TLS | LS | OG |
|---|---:|---:|---:|---:|
| ME | 38.9 | 72.3 | 91.4 | **139.0** |
| NH | 55.7 | 90.6 | 113.5 | **143.1** |
| NY | 46.7 | 93.1 | 120.8 | **139.2** |
| VT | 52.8 | 90.2 | 114.0 | n/a (n=1) |

**OG plots have 2.6 to 3.6x the live aboveground carbon of Not-LSOG plots.**
Direct LD 1529 carbon-mandate relevance. Going Not-LSOG -> OG:

- ME: 38.9 -> 139.0 Mg C/ha (3.6x)
- NH: 55.7 -> 143.1 Mg C/ha (2.6x)
- NY: 46.7 -> 139.2 Mg C/ha (3.0x)

## OG plot diagnostics (n=14 OG plots in 2019-2023 panel)

| State | n_OG | Typical BA | Typical max DBH | Typical STDAGE | RH95 |
|---|---:|---|---|---|---|
| NY | 7 | 175-238 | 25-38 in | 100-147 yr | 19-23 m |
| ME | 5 | 160-256 | 25-34 in | 69-100 yr | 18-23 m |
| NH | 1 | 184-246 | 26-30 in | 92-130 yr | 21-22 m |
| VT | 1 | 215 | 32 in | 103 yr | 22 m |

These are real mature stands: high BA, large trees, decades of stand age,
LiDAR-detected mature canopy. The proxy correctly identifies them.

## Mean dimension scores by class (out of 2 per dim)

| Dim | Not LSOG | TLS | LS | OG |
|---|---:|---:|---:|---:|
| ba_large | 0.01 | 0.20 | 0.86 | **1.83** |
| maturity | 0.27 | 0.83 | 1.09 | 1.36 |
| structure | 0.06 | 0.28 | 0.72 | 1.06 |
| canopy | 0.53 | 1.49 | 1.87 | **2.00** |
| deadwood | 0.19 | 0.90 | 0.88 | 0.97 |
| height | 0.39 | 0.65 | 0.85 | 1.00 |

OG plots score near max on canopy (2.00 = always max) and ba_large (1.83).
The most discriminating dims for OG are large-tree BA and total BA.

## Near-OG plot diagnostics: what's limiting them?

For plots with score 6-7 (LS class, just below OG threshold of 8), the
average gap from the 2-pt max per dimension:

| Dim | Avg gap | Interpretation |
|---|---:|---|
| canopy | 0.13 | almost maxed - canopy stocking present |
| maturity | 0.91 | partial signal (often max_dia near 24in) |
| deadwood | 1.12 | snag TPA below percentile threshold |
| ba_large | 1.14 | not enough trees DBH>=20 in |
| height | 1.15 | Potapov RH95 between 18-25 m, not >25 |
| structure | 1.28 | sd_dia low - lacking vertical heterogeneity |

**Near-OG plots are most often limited by structural complexity (sd_dia)
and large-tree BA.** They have plenty of total stocking but lack the
vertical heterogeneity and large-tree component that distinguish true OG.
Biologically sensible.

## Forest type breakdown (highlights)

ME by FORTYPCD group:
- Spruce-fir (most common in ME): mostly Not LSOG and TLS
- Maple-beech-birch: highest LSOG share among major types
- Aspen-birch: mostly Not LSOG (regenerating)

Full table in `output_extras/fortyp_by_class.csv`. Maine-specific facet
in `output_figures/fig11_fortyp_class_ME.png`.

## Files

In `output_extras/`:
- `carbon_by_class.csv` - state x class with mean Mg C/ha + 95% bootstrap CI
- `fortyp_by_class.csv` - state x forest-type-group x class counts and pct
- `og_dim_score_means.csv` - mean dim scores by class
- `og_plot_detail.csv` - all 14 OG plots in 2019-2023 panel with characteristics
- `near_og_gap_means.csv` - average gap-to-2pt-max for near-OG plots

In `output_figures/`:
- `fig10_carbon_by_class.png` - carbon Mg C/ha by class with CIs
- `fig11_fortyp_class_ME.png` - Maine forest-type composition

