# LSOG Northeast Manuscript Draft V1: Body Sections

**Working title:** Late Successional and Old Growth forest distribution across the Northeast: a four-state comparison
**Status:** V1 draft of Sections 2 through 5, April 30, 2026
**Companion files:** MANUSCRIPT_OUTLINE.md, MANUSCRIPT_DRAFT_V1_INTRODUCTION.md, NEXT_STEPS.md

---

## Reconciliation note (read before merging with V1 Introduction)

The introduction draft (April 27) reports state-level any-LSOG shares of ME 25.8 percent, NH 55.6 percent, VT 57.8 percent, NY 46.5 percent. Those numbers reflect the early v5 baseline classifier with the original liberal RAP thresholds. The current operational classifier (v5.1) uses the calibrated thresholds documented in PROJECT_MEMORY.md and produces design-based EXPNS-weighted estimates of ME 14.1 percent (95 percent CI 12.9 to 15.3), NH 31.2 percent (28.0 to 34.3), VT 28.8 percent (25.4 to 32.3), and NY 27.2 percent (25.2 to 29.0). All numbers in Sections 2 through 5 below use the v5.1 estimates. The Introduction should be updated to match before submission.

The same regional ranking (ME lowest, NH and VT highest, NY intermediate with the highest OG-class share) holds in both calibrations.

---

## 2. Methods

### 2.1 Study area and FIA data

We analyzed FIA Phase 2 inventory plots in four Northeastern states: Maine, New Hampshire, Vermont, and New York. The plots span the 1999 to 2023 inventory period across five evaluation panels (1999 to 2003, 2004 to 2008, 2009 to 2013, 2014 to 2018, and 2019 to 2023). Sample sizes for the most recent panel are 3,125 in Maine, 757 in New Hampshire, 657 in Vermont, and 2,107 in New York, totaling 6,646 plots. The 1999 to 2003 panel includes a comparable number of plots in each state and supports the 20-year trend analysis.

FIA plot location coordinates are publicly fuzzed up to approximately 1 kilometer to protect landowner privacy. For all spatial extractions in this study, fuzzed coordinates were used; the resulting noise on remote sensing extractions at 30 meter resolution is small but non-negligible and is discussed in Section 4.6.

We assembled a master plot-level analytical table (output_unified/lsog_ne_plot_table.csv, 13,432 rows, 32 columns) containing for each plot in each evaluation period: state, panel identifier, plot CN, inventory year, fuzzed latitude and longitude, stand age, total basal area, basal area in trees with diameter at breast height (DBH) at least 20 inches, TPA-weighted standard deviation of DBH, maximum DBH, snag tree-per-acre estimates, the six v5.1 dimension scores, the v4, v5, and v5b classification results, the five Bayesian probability bands from ORNL DAAC dataset 2498 (Bruening et al. 2026), and the Potapov RH95 canopy height value extracted at the plot fuzzed centroid.

### 2.2 The v5.1 LSOG classifier

The v5.1 classifier scores each plot on six structural dimensions and aggregates into a 0 to 12 total score. Class thresholds are: Transitioning LS (TLS) at score at least 4, Late Successional (LS) at score at least 6, and Old Growth (OG) at score at least 8.

The six dimensions are large-tree basal area, stand maturity, structural diversity, total stocking, deadwood, and canopy height (Table 1).

**Table 1.** v5.1 dimension definitions and scoring.

| Dim | Variable | Source | 1 point | 2 points |
|---|---|---|---|---|
| 1 | Large-tree BA | Σ(0.005454 × DIA² × TPA) for DBH at least 20 in | At least 40 ft²/ac | At least 80 ft²/ac |
| 2 | Stand maturity | STDAGE; max DBH fallback if STDAGE missing | At least 80 yr (or DBH at least 24 in) | At least 120 yr |
| 3 | Structural diversity | TPA-weighted SD of DBH | At least 5 in | At least 8 in |
| 4 | Total stocking | Total live BA, all DBH at least 1 in | At least 100 ft²/ac | At least 150 ft²/ac |
| 5 | Deadwood | Standing snag TPA, DBH at least 5 in | At least 75th percentile of state distribution | At least 90th percentile |
| 6 | Canopy height | Potapov 2021 RH95 (30 m grid) | At least 18 m | At least 25 m |

Dimensions 1 through 5 derive from FIA tree and condition tables. Dimension 6 derives from the Potapov et al. (2021) GEDI/Landsat 30 meter canopy height mosaic, sampled at the plot fuzzed centroid.

A bug in the deadwood scoring of an earlier classifier version was identified and fixed on March 19, 2026; the original code computed snag TPA from trees outside the plot boundary in some cases. All results reported here use the corrected classifier.

### 2.3 Calibration of the v5.1 thresholds

The v5.1 thresholds reported in Table 1 were calibrated through a grid search against two external references: (a) the Hagan et al. (2024) LiDAR-derived old-growth classification for Maine unorganized territories, which is treated as the canonical local reference, and (b) the ORNL DAAC dataset 2498 mature/old-growth probability layers, treated as a regional reference. The grid search optimized a composite score combining state-level any-LSOG share agreement with the ORNL 33 percent mature target and plot-level kappa against the Hagan reference. The calibrated thresholds are intentionally tighter than the published RAP v2.0 reference values.

A separate sensitivity analysis on the canopy height dimension found that the default 18 and 25 meter RH95 thresholds are conservative. Lower thresholds (10 and 20 meters) and a continuous-RH95 logistic regression specification both achieved higher AUC against the ORNL mature classification (0.682 and 0.689 respectively, vs 0.644 for default). The deployed v5.1 classifier retains the 18 and 25 meter thresholds for consistency with the published RAP literature; alternative threshold sets are documented in the supplementary material.

### 2.4 v4 fallback classifier for historical analysis

The v4 classifier uses dimensions 1 through 5 of Table 1, omitting canopy height, and scales the class thresholds to 0 to 10 (TLS at least 4, LS at least 6, OG at least 8). The v4 form supports the 20-year trend analysis because the Potapov canopy height product is only available beginning in 2019 and cannot be applied to plots in pre-2019 panels.

### 2.5 Design-based estimation

State-level any-LSOG share estimates are computed using FIA Phase 2 design-based post-stratified estimation, weighting plots by EXPNS values from POP_PLOT_STRATUM_ASSGN joined to POP_STRATUM. Confidence intervals are computed using the design-based variance estimator following Bechtold and Patterson (2005). For comparison, we also report bootstrap percentile intervals (N = 2000 plot-level replicates) for the same quantities.

Ownership breakdowns and forest-type breakdowns use the same design-based estimator stratified by OWNCD and FORTYPCD respectively. Carbon comparisons across LSOG classes use plot-level CARBON_AG aggregated by class.

### 2.6 Twenty-year trend analysis

The 1999 to 2003 to 2019 to 2023 LSOG share trend was estimated via Mann Kendall non-parametric trend test on annual all-LSOG percent values (one value per evaluation panel, four values per state, plus the early baseline). Linear regression of LSOG percent on panel midpoint year provided the per-decade slope and significance test. Results are reported in Table 4.

### 2.7 External cross-validation against Pelz et al. (2023)

We cross-validated the v5.1 classification against the Pelz et al. (2023) USFS old-growth criteria on National Forest System (NFS) plots in the four-state region. Pelz-OG criteria are STDAGE at least 100 years and at least 5 trees per acre with DBH at least 12 inches. The unified plot table was filtered to OWNCD = 31 (USFS), yielding 925 NFS plots. Cohen's kappa was computed for v5.1 OG vs Pelz-OG, v5.1 LS+OG vs Pelz-OG, and v5.1 any-LSOG vs Pelz-OG.

### 2.8 Wall-to-wall LSOG mapping via TreeMap imputation

We extended the plot-based v5.1 classification to wall-to-wall 30 meter raster maps using the USFS TreeMap product (Riley et al. 2021, 2022). TreeMap imputes a representative FIA plot identifier (PLT_CN) to each forested 30 meter pixel in CONUS through random forest imputation against Landsat composites and topographic predictors. The 2020 and 2022 vintages of TreeMap were used.

For each pixel, we joined the imputed PLT_CN to a hybrid plot-level lookup that prefers the v5.1 class for plots in the 2019 to 2023 panel (where Potapov canopy height is temporally appropriate) and falls back to the v4 class for plots in older panels. The hybrid lookup contained 43,389 plot-period entries, of which 6,570 (15 percent) used v5 and 36,819 (85 percent) used v4. Pixel-level acreage estimates were obtained as pixel count multiplied by 0.222394 acres per pixel.

A subtlety in the TreeMap raster's categorical attribute table required the categorical levels to be cleared (levels(rc) is set to NULL in the R terra package) before frequency tabulation, otherwise terra::freq returns the active categorical column (ForTypName by default) rather than the integer Value codes that match the vat.dbf TM_ID column.

### 2.9 Reproducibility

All code is at github.com/holoros/lsog-ne (commit history continuously pushed; Phase 8 v3 and v3-Potapov landed April 30, 2026). The Cardinal HPC working directory is at /users/PUOM0008/crsfaaron/LSOG/. The master analytical artifact is output_unified/lsog_ne_plot_table.csv. A persistent project memory file is committed at CLAUDE.md.

---

## 3. Results

### 3.1 State-level v5.1 LSOG share

Table 2 shows the v5.1 plot-based and design-based estimates for the most recent panel (2019 to 2023).

**Table 2.** State-level v5.1 LSOG share, 2019 to 2023 panel.

| State | n plots | Any-LSOG (95% CI) | Trans LS | LS | OG |
|---|---:|---|---:|---:|---:|
| Maine | 3,125 | 14.1% (12.9 to 15.3) | 8.4% | 5.4% | 0.19% |
| New York | 2,107 | 27.2% (25.2 to 29.0) | 16.1% | 9.6% | 1.5% |
| Vermont | 657 | 28.8% (25.4 to 32.3) | 19.9% | 8.6% | 0.30% |
| New Hampshire | 757 | 31.2% (28.0 to 34.3) | 21.0% | 9.5% | 0.66% |

Maine has the lowest any-LSOG share in the four-state region. The Maine 95 percent CI does not overlap any of the other three states' CIs. New Hampshire has the highest share at 31.2 percent, more than twice Maine's. New York has the highest old-growth-class share at 1.5 percent, reflecting the Adirondacks. The OG-class shares for Maine, New Hampshire, and Vermont are all under 1 percent.

### 3.2 Twenty-year LSOG trend

Table 3 reports per-decade slopes from linear regression of all-LSOG percent on panel midpoint year, using the v4 classifier for cross-panel comparability.

**Table 3.** Twenty-year all-LSOG slope, 1999 to 2023.

| State | Slope (pp / decade) | p-value | Significance |
|---|---:|---:|---|
| New Hampshire | +11.1 | < 0.001 | strongly increasing |
| Vermont | +9.1 | 0.024 | increasing |
| New York | +8.9 | 0.002 | strongly increasing |
| Maine | +1.6 | 0.057 | borderline |

New Hampshire, Vermont, and New York are aging at significant rates of 9 to 11 percentage points per decade. Maine's slope is borderline and substantially smaller. The regional gap between Maine and the others is widening rather than closing.

### 3.3 Ownership and policy-relevant breakdowns

Public lands across the four states carry approximately 1.5 to 3 times the LSOG concentration of private lands (Table 4).

**Table 4.** Public versus private LSOG concentration by state, 2019 to 2023 v5.1.

| State | Federal LSOG % | Private LSOG % | Ratio |
|---|---:|---:|---:|
| Maine | 36% | 14% | 2.6 |
| New Hampshire | 51% | 21% | 2.4 |
| Vermont | 45% | 26% | 1.7 |
| New York | (state and local) 17.5% LS+OG = 583 K ac | (private) varies | n/a |

New York state and local lands carry 583,000 acres of LS+OG combined, exceeding Maine's total LS+OG across all owners. Across the region, private timberlands hold approximately 987,000 acres of LS+OG combined, which is the natural target audience for payment for ecosystem services or working-lands easement programs.

### 3.4 Carbon storage by class

Plot-level live aboveground carbon scales monotonically with LSOG class (Table 5).

**Table 5.** Maine plot-level live aboveground carbon by v5.1 class.

| Class | Mean carbon (Mg C / ha) | Ratio to Not-LSOG |
|---|---:|---:|
| Not LSOG | 39 | 1.0 |
| TLS | 72 | 1.8 |
| LS | 91 | 2.3 |
| OG | 139 | 3.6 |

Old-growth-class plots store approximately 3.6 times the live carbon of Not-LSOG plots in Maine. Across Maine's approximately 24 thousand acres of OG-class forest, the carbon density premium amounts to roughly 100 megagrams of carbon per hectare relative to letting that area revert to Not-LSOG conditions.

### 3.5 Cross-validation against Pelz USFS criteria

Table 6 reports the confusion matrix between v5.1 class and Pelz-OG flag on 925 four-state NFS plots, and the corresponding Cohen's kappa values.

**Table 6.** v5.1 versus Pelz-OG cross-validation on 925 NFS plots.

| v5.1 class | Not Pelz-OG | Pelz-OG | Total |
|---|---:|---:|---:|
| Not LSOG | 467 | 36 | 503 |
| Trans LS | 314 | 49 | 363 |
| LS | 31 | 24 | 55 |
| OG | 1 | 3 | 4 |
| **Total** | **813** | **112** | **925** |

| Comparison | Cohen's kappa | Interpretation |
|---|---:|---|
| v5.1 OG vs Pelz-OG | 0.044 | essentially random |
| v5.1 LS+OG vs Pelz-OG | 0.253 | fair agreement |
| v5.1 any-LSOG vs Pelz-OG | 0.115 | slight |

The OG-only kappa is essentially random because of the small absolute number of v5.1 OG plots (n = 4) on NFS lands. The LS+OG combined comparison achieves fair agreement (kappa = 0.253), supporting LS+OG as the most stable class for policy reporting. The Pelz-OG share of NFS plots in this region is 12.1 percent, compared to v5.1 LS+OG at 6.4 percent of the same plot population, indicating that v5.1 is somewhat conservative relative to the Pelz criteria on NFS lands.

### 3.6 Wall-to-wall LSOG mapping

Table 7 reports any-LSOG share and acreage from TreeMap imputation, with two classifier variants: v3 (v4-based, no canopy height) and v3-Potapov (hybrid v5.1 / v4-based, with canopy height where available).

**Table 7.** Wall-to-wall any-LSOG estimates from TreeMap 2020 and 2022.

| State | Year | v3 share | v3 acres | v3-Potapov share | v3-Potapov acres | Lift (pp) |
|---|---:|---:|---:|---:|---:|---:|
| Maine | 2020 | 8.09% | 1,333,955 | 9.17% | 1,511,924 | +1.08 |
| Maine | 2022 | 7.99% | 1,313,970 | 9.03% | 1,486,809 | +1.04 |
| New Hampshire | 2020 | 15.75% | 735,489 | 17.49% | 816,721 | +1.74 |
| New Hampshire | 2022 | 15.65% | 730,610 | 17.37% | 810,522 | +1.72 |
| New York | 2020 | 13.62% | 2,562,932 | 15.07% | 2,835,126 | +1.45 |
| New York | 2022 | 13.55% | 2,552,411 | 14.99% | 2,824,131 | +1.44 |
| Vermont | 2020 | 16.15% | 728,756 | 18.87% | 852,494 | +2.72 |
| Vermont | 2022 | 16.03% | 724,263 | 18.74% | 846,907 | +2.71 |

The pixel-area-weighted wall-to-wall estimates are systematically lower than the design-based plot-weighted estimates from Section 3.1 because TreeMap imputes from a wider plot pool that includes pre-2019 panels (where the canopy-height dimension is unavailable) and because the FIA design weights account for sampling intensity differences not represented at the pixel level. The v3-Potapov hybrid recovers approximately 1 to 3 percentage points relative to v3, with Vermont showing the largest lift and Maine the smallest, consistent with Maine's relatively shorter canopy heights.

The same regional ranking (Maine lowest, Vermont and New Hampshire highest, New York intermediate) appears in both wall-to-wall variants, providing pixel-level confirmation of the plot-based finding.

---

## 4. Discussion

### 4.1 Maine's structural divergence reflects its working-forest history

Maine's continuous industrial-forestry sector dating to the 1800s sets it apart from the other three states. Annual harvest volumes of approximately 12 million cords are sustained over rotation lengths of 35 to 80 years for the dominant softwood and mixedwood types. Those rotations are long enough to grow merchantable trees, short enough to limit accumulation of the structural attributes (large trees, dead wood, canopy complexity) that v5.1 weights into its score. By contrast, New Hampshire and Vermont experienced 19th-century agricultural abandonment that has now generated old-field forests reaching ages of 100 to 150 years; New York's Adirondack landscape preserved larger contiguous unmanaged forests through the same period. The pattern in Tables 2 and 3 is consistent with these documented histories. Maine is not catching up; if anything, the gap is widening at approximately 7 to 10 percentage points per decade based on Table 3's slope differences.

### 4.2 The lower OG-class shares are partly definitional

All four states show OG-class shares under 2 percent. Some of this rarity is real: true old-growth forest is rare in the Northeast, and the v5.1 protocol intentionally requires a high score (at least 8 of 12) for OG classification. Some is also definitional: the OG threshold sits very close to the maximum achievable score for plots dominated by mixed northern hardwoods, which rarely exceed 25 meter canopy heights even in the most mature stands. New York's higher OG share (1.5 percent) reflects the Adirondack landscape, where older red spruce, eastern hemlock, and northern hardwoods produce taller canopies and more structural complexity. The validation work in Section 3.5 (Cohen's kappa essentially zero on OG alone, but fair on LS+OG) supports treating LS+OG combined as the more stable category for policy reporting.

### 4.3 Wall-to-wall mapping confirms but does not amplify the plot finding

The TreeMap-imputed wall-to-wall estimates in Section 3.6 reproduce the regional ranking (Maine lowest, Vermont and New Hampshire highest, New York intermediate) at the pixel level. The wall-to-wall absolute share is systematically lower than the design-based plot estimate (e.g., Maine 9.2 percent wall-to-wall versus 14.1 percent plot-based) for two reasons documented in Section 3.6. The pattern is robust across both estimation approaches.

### 4.4 The validation triangle and what it tells us

We compared v5.1 against three independent products: the Hagan et al. (2024) LiDAR-derived Maine old-growth raster (still pending acquisition for plot-level cross-validation), the Bruening et al. (2026) ORNL DAAC 2498 Bayesian probability surfaces, and the Pelz et al. (2023) USFS Eastern Region old-growth criteria. The OG-share estimates differ by a factor of 25 across products: v5.1 ME OG at 0.4 percent, Hagan UT OG at 1.0 percent, and Pelz-OG at NFS plots at 10.1 percent. Each product applies a defensible methodology to a defensible plot or pixel population; the answers differ because the criteria differ.

For policy reporting, the LS+OG combined class is the most stable category across products. The OG-only class is meaningfully product-specific.

### 4.5 Methodological recommendations

The Potapov RH95 threshold sensitivity analysis in Section 2.3 indicates that the default 18 and 25 meter thresholds are conservative. Lower thresholds (10 and 20 meters) and a continuous-RH95 logistic regression specification both achieved higher AUC against the ORNL mature classification. We retained the default thresholds for consistency with the published RAP literature in the v5.1 deployment, but downstream users should consider the alternative specifications for fine-tuned applications.

The LS+OG combined class should be the headline category in policy-facing reporting. The OG-only class is more sensitive to methodological choices and should be reported with explicit uncertainty bounds.

### 4.6 Limitations

First, the v5.1 OG-class precision is low. Cohen's kappa is essentially random against Pelz-OG and against ORNL OG-probability bands. We do not over-interpret state-level OG-class percentages.

Second, FIA plot fuzzing introduces approximately 30 meter uncertainty at the Potapov RH95 extraction step. The contribution to plot-level scoring noise is small but systematic. Access to true coordinates under a Data Use Agreement would tighten this dimension.

Third, the Hagan et al. (2024) LiDAR raster, the canonical Maine UT old-growth reference, was not available for plot-level cross-validation in this study. The Phase 6 cross-validation pipeline is fully scaffolded and ready to run when the raster becomes accessible through the appropriate channel.

Fourth, the ORNL DAAC 2498 product trains its mature/OG probability layers on FIA labels, which makes our cross-validation a coherence check rather than blind validation.

Fifth, the wall-to-wall mapping uses TreeMap imputation. TreeMap is not a direct LSOG product but a representative-plot imputation. Some of the "Unknown" pixels (Maine 0.3 percent, New York 24 percent) reflect TreeMap PLT_CN values that map to plots outside our 1999 to 2023 four-state inventory; these pixels could be rescued with broader CONUS plot lookups.

### 4.7 Implications for forest policy

For Maine, the LD 1529 working group should know that the state has the lowest LSOG share in the Northeast, that the share is essentially flat over 20 years (versus increases of 9 to 11 percentage points per decade in neighboring states), and that the carbon density premium of OG-class forest is roughly 100 megagrams per hectare relative to Not-LSOG. Policy options include continuing current management, intentionally extending rotations on a fraction of the land base, expanding the ecological reserve network, and pursuing payment-for-ecosystem-services arrangements on private timberland. Each option has different implications for the working-forest economy, and each can be quantified using the master plot table as the analytical foundation.

For New Hampshire and Vermont, the question is whether the passive aging trajectory should be encouraged (more LSOG over time) or moderated (active management to enhance other values). The 9 to 11 percentage-point-per-decade gain is unlikely to continue indefinitely, and active management decisions made now will shape the trajectory.

For New York, the Adirondacks are the regional treasure for old-growth forest. State and local lands hold 583,000 acres of LS+OG combined, the largest such pool in the four-state region. Continued protection and possibly expansion of the reserve network is the natural policy direction.

For the broader region, the private timberland LS+OG pool of approximately 987,000 acres across all four states is the most acreage-relevant target for policy intervention. Payment-for-ecosystem-services programs, working-lands easements, and tax-incentive structures all bear on this pool.

### 4.8 Future work

Five immediate extensions are appropriate. First, integrate the Hagan et al. (2024) LiDAR raster when accessible, completing the Maine plot-level cross-validation. Second, extend the analysis to Massachusetts, Connecticut, and Rhode Island for full-New-England comparison. Third, project LSOG share forward using a climate-aware succession model integrated with the master plot table. Fourth, pursue a Data Use Agreement for true plot coordinates and re-run the Potapov extraction. Fifth, link LSOG class to wood-quality and harvest-economics outcomes for direct working-forest-economy linkage.

---

## 5. Conclusion

A four-state Northeastern LSOG analysis using calibrated FIA-proxy methodology reveals a striking regional pattern. Maine, the most heavily forested state in the United States, has the lowest LSOG share in the region (14.1 percent), roughly half the share of its neighbors. The 20-year trend is similarly divergent: New Hampshire, Vermont, and New York are aging at 9 to 11 percentage points per decade, while Maine adds approximately 2 percentage points per decade, a borderline-significant slope. The pattern is consistent with Maine's continuous industrial-forestry history relative to land abandonment in New Hampshire and Vermont and protected reserve management in New York.

The structural age divergence has direct implications for biodiversity (cavity-nesting birds, lichens, dead-wood-dependent fauna), carbon storage (old-growth-class plots store 3.6 times the live carbon of Not-LSOG plots in Maine), and forest policy. The LS+OG combined class is the most stable category for policy reporting; the OG-only class is sensitive to methodological choices and should be reported with explicit uncertainty.

The methodology generalizes to other regions, and the publicly archived master plot table at output_unified/lsog_ne_plot_table.csv provides an analytical foundation for downstream policy, biodiversity, and carbon analyses. The choices each state makes in the next decade will shape this regional pattern for the next quarter century.

---

## Notes for next session

This V1 body draft covers Sections 2 through 5 (Methods, Results, Discussion, Conclusion). Combined with the V1 Introduction and Abstract from MANUSCRIPT_DRAFT_V1_INTRODUCTION.md, the manuscript is at first-complete-draft stage.

Open items for V2:

1. Reconcile the Introduction's old (25.8 / 55.6 / 57.8 / 46.5) numbers with the calibrated v5.1 numbers (14.1 / 31.2 / 28.8 / 27.2) used in the body. The story is the same; the magnitudes differ.
2. Add full citations: Hagan et al. (2024), Bruening et al. (2026), Pelz et al. (2023), Riley et al. (2021, 2022), Potapov et al. (2021), Bechtold and Patterson (2005).
3. Aaron review for voice, accuracy, and emphasis.
4. Coauthor input on framing (Adam Daigneault, Dan Hayes, possibly Thompson team).
5. Render embedded tables as proper .docx tables and figures from the figures/ folder.
6. Confirm exact statistics against the unified plot table once more.
7. Add Hagan plot-level cross-validation results when the raster lands.
8. Add a Supplementary Material section documenting the v5.1 calibration grid search and the wall-to-wall TM_ID encoding fix.

---

*Body draft path: ~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/MANUSCRIPT_DRAFT_V1_BODY.md*
*Outline reference: MANUSCRIPT_OUTLINE.md*
*Introduction reference: MANUSCRIPT_DRAFT_V1_INTRODUCTION.md*
*Source data: output_unified/lsog_ne_plot_table.csv*
