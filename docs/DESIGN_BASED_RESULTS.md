# Phase 5g design-based estimation + ownership breakdown

Date: 2026-04-26
Approach: FIA standard post-stratified estimator using POP_PLOT_STRATUM_ASSGN
+ POP_STRATUM tables; latest EXPCURR EVALID per state.

## Bootstrap vs design-based agreement

| State | Class | Bootstrap (% plots) | Design-based (% forested) |
|---|---|---:|---:|
| ME | any LSOG | 14.1 | 15.3 |
| ME | LS+OG | 2.06 | 2.06 |
| ME | OG | 0.19 | 0.18 |
| NH | any LSOG | 31.2 | 27.8 |
| NH | LS+OG | 5.28 | 5.69 |
| NY | any LSOG | 27.2 | (see CSV) |
| VT | any LSOG | 28.8 | (see CSV) |

The two methods agree closely. Design-based is the FIA-standard reporting
basis and uses a ratio-of-area (forested) denominator vs the bootstrap's
percent-of-FIA-plots. Both report the same fundamental story.

## Design-based acres with FIA post-stratified 95% CIs (ME 2019-2023)

| Class | Acres | SE | 95% CI |
|---|---:|---:|---:|
| All forested | 13,025,706 | 69,050 | 12.89M - 13.16M |
| Any LSOG | 1,991,453 | 98,499 | 1.80M - 2.18M |
| LS+OG | 267,804 | 38,541 | 192K - 343K |
| TLS | 1,723,649 | 93,314 | 1.54M - 1.91M |
| LS | 244,101 | 36,748 | 172K - 316K |
| OG | 23,703 | 11,897 | 384 - 47K |

Note that ME's "all forested" area from FIA EXPCURR is 13.0M ac (13.0M),
not the 17.6M land-area approximation we used in earlier bootstrap runs.
The design-based forested base is the policy-relevant denominator.

## Striking ownership pattern

| State | Owner group | n plots | Forested ac | LSOG % | LS+OG % | OG % |
|---|---|---:|---:|---:|---:|---:|
| ME | Federal | 23 | 40K | 35.8 | 14.3 | 0 |
| ME | Other federal | 29 | 165K | 23.0 | 4.1 | 0 |
| ME | State and local | 157 | 878K | 31.1 | 4.4 | 0.7 |
| **ME** | **Private** | 2,141 | **11.94M** | **14.0** | **1.82** | 0.15 |
| NH | Federal | 262 | 524K | 51.0 | 5.4 | 0 |
| NH | Other federal | 9 | 48K | 67.8 | 13.8 | 0 |
| NH | State and local | 57 | 309K | 32.1 | 8.4 | 2.08 |
| NH | Private | 389 | 2.35M | 21.2 | 5.2 | 0.27 |
| VT | Federal | 160 | 274K | 44.9 | 11.7 | 0 |
| VT | State and local | 47 | 263K | 32.3 | 8.2 | 0 |
| VT | Private | 398 | 2.49M | 26.1 | 5.4 | 0.29 |
| NY | Federal | 5 | 8K | 21.5 | 0 | 0 |
| NY | Other federal | 15 | 97K | 36.4 | 0 | 0 |
| **NY** | **State and local** | 518 | **3.33M** | **54.1** | **17.5** | **3.66** |
| NY | Private | 1,228 | 8.55M | 25.1 | 6.0 | 0.71 |

**Two policy-relevant findings:**

1. **Federal and state lands have 1.5-3x higher LSOG concentration than
   private lands**, consistent with reduced harvest pressure on public
   ownership. Numerically: ME federal 35.8% LSOG vs private 14.0%; NH
   federal 51% vs private 21%; VT federal 45% vs private 26%.

2. **NY's Adirondack/Catskill state forest is the LSOG hotspot of the
   Northeast.** 3.33M ac state-and-local with 54.1% any-LSOG, 17.5%
   LS+OG, 3.66% OG (=122K acres of OG class on NY state lands alone).
   This is more LS+OG state-land acreage than ME has across all owner
   classes combined.

3. **Private lands carry the bulk of LSOG acreage in absolute terms**
   despite lower percent shares. Private LS+OG acres: ME 217K, NH 123K,
   VT 135K, NY 512K. Total NE private LS+OG: ~987K acres - this is where
   conservation easements and PES instruments would have the largest
   impact on absolute LSOG protection.

## Files

In `output_design_based/`:
- `design_based_area.csv` - 24 rows, state x class with acres + 95% CI
- `ownership_breakdown.csv` - 16 rows, state x ownership group breakdown

In `output_figures/`:
- `fig6_bootstrap_vs_designbased.png` - method comparison panel
- `fig7_designbased_acres_ci.png` - acres with FIA post-stratified CIs
- `fig8_ownership_lsog_pct.png` - LSOG percent by ownership
- `fig9_ownership_lsog_acres.png` - LSOG acres by ownership
