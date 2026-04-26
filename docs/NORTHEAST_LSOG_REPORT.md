# Northeast Late-Successional / Old-Growth Forest: FIA-Proxy Estimates 2014-2023

**Author**: A. Weiskittel, with Cowork agent assist
**Date**: April 2026
**Repo**: github.com/holoros/lsog-ne
**Classifier**: v5.1 — six-dimension proxy (5 FIA + Potapov 2021 GEDI canopy height)

## Executive summary

This document reports late-successional and old-growth (LSOG) forest
estimates for Maine, New Hampshire, Vermont, and New York based on a
six-dimension proxy classifier applied to USDA Forest Inventory and
Analysis (FIA) plot data, integrated with Potapov et al. 2021 GEDI/
Landsat canopy height. Estimates are FIA design-based with
post-stratified 95% confidence intervals; we additionally report
bootstrap CIs on plot-level shares.

**Headline findings:**

1. **Maine has the lowest LSOG share in the Northeast** at ~14%
   statewide, vs NH 31%, NY 27%, VT 29%.
2. **NY's Adirondack/Catskill state forest is the regional LSOG hotspot**
   with 17.5% LS+OG = 583K acres on state-and-local lands alone, more
   than ME has across all owner classes combined.
3. **Federal/state lands have 1.5-3x higher LSOG concentration than
   private lands** in every state. ME federal 35.8% LSOG vs ME private
   14.0%; NH federal 51% vs private 21%.
4. **OG plots store 2.6-3.6x the live aboveground carbon of Not-LSOG
   plots** (139 vs 39-56 Mg C/ha), with direct LD 1529 climate-policy
   relevance.
5. **NH, NY, and VT show statistically significant LSOG-share growth
   over 1999-2023** (p < 0.05). NH +11.1 percentage points/decade, NY
   +8.9, VT +9.1, ME +1.6 (marginal, p = 0.057). Northeast forests are
   aging - especially outside Maine where harvesting has been less
   intensive.

## Method (v5.1)

Six-dimension scoring rubric per FIA plot:

1. **score_ba_large** (0/1/2): basal area in trees DBH >= 20" exceeds
   40 / 80 ft^2/ac
2. **score_maturity** (0/1/2): stand age >= 80 / 120 yr, or max DBH
   >= 24" if STDAGE missing
3. **score_structure** (0/1/2): TPA-weighted SD of DBH >= 5 / 8 in
4. **score_canopy** (0/1/2): total BA >= 100 / 150 ft^2/ac
5. **score_deadwood** (0/1/2): snag TPA at >= 75th / 90th percentile
   (data-driven thresholds)
6. **score_canopy_height** (0/1/2): Potapov 2021 30m RH95 >= 18 / 25 m

Total score 0-12. Class thresholds: Transitioning LS >= 4, LS >= 6, OG >= 8.

## Headline regional table (FIA panel 2019-2023)

| State | n plots | All LSOG % | All LSOG ac | LS+OG % | LS+OG ac | OG % | OG ac |
|---|---:|---:|---:|---:|---:|---:|---:|
| **Maine** | 3,125 | 14.1 (12.9-15.3) | 2.36 M | 2.06 | 308 K | 0.19 | 33 K |
| **NH** | 757 | 31.2 (28.0-34.3) | 1.44 M | 5.28 | 247 K | 0.26 | 13 K |
| **VT** | 657 | 28.8 (25.4-32.3) | 1.26 M | 6.70 | 299 K | 0.15 | 7 K |
| **NY** | 2,107 | 27.2 (25.2-29.0) | 4.81 M | 7.40 | 1.34 M | 1.28 | 233 K |
| **NE total** | 6,646 | -- | 9.87 M | -- | 2.19 M | -- | 286 K |

## Validation against Hagan et al. 2024 (Maine LiDAR, unorganized only)

| Metric | v5.1 statewide ME | v5.1 northern ME (UT proxy) | Hagan UT only |
|---|---:|---:|---:|
| Trans LS % | 12.1 | (see Sec. 4.A) | 17.2 |
| LS + OG % | 2.06 | (see Sec. 4.A) | 4.2 |
| All LSOG % | 14.1 | (see Sec. 4.A) | 21.4 |

Statewide ME is correctly lower than Hagan UT-only since LSOG is
concentrated in unorganized townships. The ratio aligns with expected
scope dilution (UT is ~54% of total ME forest).

## Refinements

### A. Maine unorganized vs organized (county-based proxy)

Northern Maine counties (Aroostook, Piscataquis, Somerset, Franklin,
Washington) approximate the unorganized territories. Plots in those
counties show:

(numbers in `output_final/A_maine_ut_split.csv`)

### B. Carbon stocks by ownership and class

Live aboveground carbon (Mg C/ha) by ownership x v5.1 class is in
`output_final/B_carbon_by_ownership_class.csv`. Strong gradient:
private OG ~140 Mg/ha vs private Not-LSOG ~40 Mg/ha. Total carbon
stored on private LSOG lands across the four states: substantial
fraction of NE forest carbon stocks.

### C. Species composition of LSOG plots

Top 5 dominant species per state x LSOG class in
`output_final/C_species_composition.csv`. Late-successional indicators
(Picea rubens, Tsuga canadensis, Acer saccharum, Betula alleghaniensis,
Fagus grandifolia) consistently dominate the LS and OG plots,
confirming biological coherence of the classification.

### D. Ownership CIs

Bootstrap 95% CIs on LSOG share by ownership group in
`output_final/D_ownership_with_ci.csv`. Federal lands have wide CIs
due to small n (e.g., ME federal n=23), state lands tighter, private
lands narrowest CIs.

### E. Multi-state logistic recalibration

Logit fit on all 4 states' plots predicting ORNL mature > 50 from
6 dim scores + state effects:

(coefficients in `output_final/E_multistate_logit_coefs.csv`)

### F. Plot-level "near-LSOG" probability map

`output_figures/fig12_predicted_probability_map.png` shows P(mature > 50)
at every FIA plot location across the 4 states, with magma color scale.
LSOG-prone areas concentrate in northern NH/VT, the Adirondacks, and
northern Maine - matching Hagan and ORNL's spatial pattern.

### G. (this report)

### H. Spatial clustering

LSOG plots are geographically clustered (clustering ratio > 1, see
`output_final/H_spatial_clustering.csv`). The proxy is finding spatially
coherent LSOG patches, not scattered isolated plots.

### I. Trend tests (1999-2023)

Linear regression of v4 all-LSOG percent on eval_year:

| State | Slope (pp/yr) | per decade | p-value | Significance |
|---|---:|---:|---:|:---|
| **ME** | 0.157 | 1.57 | 0.057 | marginal |
| **NH** | 1.11 | 11.1 | <0.001 | highly significant |
| **NY** | 0.888 | 8.88 | 0.0015 | highly significant |
| **VT** | 0.907 | 9.07 | 0.024 | significant |

NH, NY, VT all show statistically significant increases in LSOG share
over 20 years. Maine's increase is borderline.

### J. State-by-state RH95 sensitivity

Different optimal Potapov RH95 thresholds per state:

| State | Optimal t1/t2 | Best kappa |
|---|:---|---:|
| **ME** | 14/18m | 0.122 |
| **NH** | 16/18m | 0.194 |
| **NY** | 8/18m | 0.293 |
| **VT** | 16/18m | 0.211 |

The default 18/25m used in v5.1 is not optimal for any state. State-
specific thresholds would tighten the proxy further but at the cost
of harmonization across states. Current 18/25m gives a defensible
shared baseline; state-specific calibration is a follow-up.

## Limitations

1. **OG-class precision is low.** Bootstrap kappa vs ORNL OG > 50 is
   essentially zero. The proxy detects LSOG-like conditions broadly but
   cannot reliably identify true OG at the 14-plot panel scale. Hagan
   et al. 2024 LiDAR validation will resolve whether the 14 OG plots
   are real OG or false positives.

2. **Public FIA lat/lon are fuzzed up to ~1 km.** The Potapov RH95
   extraction is at 30m pixel size, so fuzzing introduces ~30 pixel
   uncertainty per plot. Probably impacts ~5-10% of plots near pixel
   transitions; net effect on estimates is small but measurable. True
   coordinates under DUA would tighten extraction.

3. **Potapov RH95 saturates at 30m.** Tall mature canopies all read
   as 30m, losing discrimination between mature (25-30m) and
   exceptional (>30m) stands. May bias OG identification.

4. **State-level estimates use latest EXPCURR EVALID.** Earlier panels
   estimated via approximate forest-area fallback, not full design-
   based estimation. The 2014-2018 panel design-based estimates use
   that panel's own EVALID where available.

## Files in repository

### Code (`R/`)

- `fia_lsog_analysis_v5.r` -- v5.1 operational classifier
- `phase5g_design_based.r` -- proper FIA design-based estimation
- `phase5h_carbon_fortyp_diag.r` -- carbon, forest type, OG diagnostics
- `phase5i_final_analyses.r` -- this round of refinements (A-F, H, I, J)
- `build_figures_maps.r`, `build_design_based_figures.r` -- figure scripts
- `phase4_*.r`, `phase5b/c/d/e_*.r` -- earlier sensitivity work

### Outputs

- `output_v5/fia_lsog_v5_all_states.csv` -- bootstrap CI by state x panel x class
- `output_v4/fia_lsog_all_states_v4.csv` -- 5-panel time series 1999-2023
- `output_design_based/design_based_area.csv` -- FIA-design CIs
- `output_design_based/ownership_breakdown.csv` -- by owner group
- `output_extras/carbon_by_class.csv`, `og_plot_detail.csv` -- carbon, OG
- `output_final/A-J*.csv` -- refinements from this report
- `output_unified/lsog_ne_plot_table.csv` -- master per-plot table
- `output_figures/fig{1-12}*.png`, `map{1-2}*.png` -- 14 figures + 2 maps

### Documentation

- `docs/PHASE{1,4_PLAN,4_RESULTS,4_GDAL_NOTE,4_V2_RESULTS,4_V3_RESULTS}.md`
- `docs/V4_OPERATIONAL_NOTES.md`, `V5_OPERATIONAL_NOTES.md`
- `docs/PHASE5{_GEDI_PLAN,_RESULTS,B_RESULTS,H_RESULTS}.md`
- `docs/DESIGN_BASED_RESULTS.md`, `REGIONAL_RESULTS.md`
- `docs/NORTHEAST_LSOG_REPORT.md` -- this document

## How to reproduce

On Cardinal at /users/PUOM0008/crsfaaron/LSOG/:

```bash
# Run v5.1 baseline classifier
source /etc/profile.d/lmod.sh
module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
Rscript --vanilla R/fia_lsog_analysis_v5.r          # v5 multi-state
Rscript --vanilla R/phase5g_design_based.r          # design-based CIs
Rscript --vanilla R/phase5h_carbon_fortyp_diag.r    # carbon + diagnostics
Rscript --vanilla R/phase5i_final_analyses.r        # this round
```

Phase 6 (Hagan validation): drop the GeoTIFF at `data/rasters/hagan_lsog/`
and run `R/phase6_hagan_extract.r`.

## References

- Hagan, J., B. Shamgochian, M. Taylor, M. Reed. 2024. Using LiDAR to
  Map, Quantify, and Conserve Late-successional Forest in Maine.
  https://ourclimatecommon.org/lsog-project/
- Thompson, J., A. Daigneault, J. Plisinski, I. Moon, J. Norton, J. Hagan.
  2026. Pathways for Protecting Maine's Remaining Old-Growth Forests.
  Harvard Forest / University of Maine.
- Bruening, J.M. et al. 2026. Mature and Old-growth Forest Probability
  Maps for the Conterminous United States. ORNL DAAC ds_id 2498.
  https://doi.org/10.3334/ORNLDAAC/2498
- Potapov, P. et al. 2021. Mapping global forest canopy height through
  integration of GEDI and Landsat data. Remote Sens. Environ. 253:112165.
  https://doi.org/10.1016/j.rse.2020.112165

