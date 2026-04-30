# LSOG Northeast Manuscript Outline

**Working title:** Late Successional and Old Growth forest distribution across the Northeast: a four-state comparison
**Target journal candidates:** Ecological Applications, Forest Ecology and Management, or Conservation Biology
**Status:** Outline V1 (April 27, 2026)
**Lead author:** Aaron Weiskittel
**Likely coauthors:** Adam Daigneault, Dan Hayes, possibly Thompson team and the Phase 4/5 analytical team
**Source:** `~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/` (NEXT_STEPS.md, output_unified, regional, phase5_results)

---

## Why this manuscript

The LSOG Northeast regional analysis has produced a striking, publishable headline finding: Maine has the lowest LSOG share in the Northeast at 25.8%, compared to NH (55.6%), VT (57.8%), and NY (46.5%). This counterintuitive result (Maine being the most heavily forested state and yet having the smallest mature/old-growth share) has direct implications for forest policy, biodiversity conservation, climate adaptation, and the working forest economy across the region.

The analysis is complete (v4, v5, v5b, v5c variants). The unified plot table at `output_unified/lsog_ne_plot_table.csv` (13,432 rows × 32 columns) is the master analytical artifact. The Conversation article V2 has been drafted using this finding. The peer-reviewed manuscript is the natural next step.

---

## Working title alternatives

1. **Late Successional and Old Growth forest distribution across the Northeast: a four-state comparison** (current preferred)
2. **Maine has the smallest mature forest share in the Northeast: a regional FIA analysis**
3. **Working forest history shapes the late successional landscape: evidence from four Northeastern states**
4. **Northeast forest aging reveals a structural divergence: Maine vs its neighbors**

---

## Abstract (target 250 words)

**Background**: Late successional and old growth (LSOG) forests provide habitat, store carbon, and represent a particular conservation value. Across the Northeast, forest history differs substantially among states, but the resulting LSOG share has not been systematically compared at the regional scale.

**Methods**: We apply the RAP v2.0 LSOG classification protocol to FIA remeasurement plots across Maine (n=3,125), New Hampshire (n=757), New York (n=2,107), and Vermont (n=657) for the 2019-2023 panel. We compare two classifier variants: v4 (without remote sensing) and v5 (with Potapov RH95 canopy height integration). We also examine a 20-year time trend (1999-2003 vs 2019-2023) and test sensitivity to RH95 thresholds.

**Results**: Maine has the lowest LSOG share at 25.8% (combined transitional, late successional, and old growth classes). NH and VT have nearly double Maine's share at 55.6% and 57.8%. NY is intermediate at 46.5% with the highest old-growth class share (2.5%) reflecting the Adirondacks. Twenty year change reveals NH and VT essentially doubling their LSOG share (+21.4 and +14.5 pp), while Maine added only +3.6 pp. The pattern is consistent with Maine's continuous industrial forestry history relative to land abandonment in the other three states. RH95 threshold sensitivity reveals that the standard 18/25 m breakpoints may be too conservative; 10/20 m optimization or continuous RH95 in logistic regression yields higher AUC against ORNL mature classification.

**Implications**: The structural age divergence has consequences for biodiversity, carbon storage, and forest policy. Maine's choice of how to manage its working forest landscape into the next decades will shape this regional pattern.

---

## 1. Introduction (target 1,200 words)

### 1.1 LSOG forests as a conservation and policy concern

- Habitat for species requiring structurally complex forest (cavity nesters, lichens, salamanders, fungi)
- Carbon storage advantages of structurally complex forest
- Aesthetic, cultural, and recreational value
- Federal and state policy emphasis (USFS old growth amendment, state ecological reserve programs)

### 1.2 LSOG classification methodology

- RAP v2.0 protocol overview
- Multiple dimensions: tree size, basal area, dead wood, complexity
- Class structure: transitional, late successional, old growth
- Strengths and limitations of plot-based classification

### 1.3 Northeast forest history

- 19th century agricultural clearing and subsequent abandonment
- Maine's continuous industrial forestry vs other states' land abandonment
- Implications for current forest age structure
- Related work on regional forest aging trends

### 1.4 Research questions

1. What is the share of LSOG forest in each Northeast state at the most recent FIA panel?
2. How does the share differ among states, and what historical processes account for the differences?
3. What has been the 20-year trajectory of LSOG share in each state?
4. How sensitive are the classification results to threshold choices, particularly remote sensing canopy height integration?
5. What are the implications for forest policy across the four states?

### 1.5 Contribution

- First systematic four-state LSOG comparison using consistent FIA methodology
- v4 vs v5 classifier variant comparison
- 20-year regional trend analysis
- RH95 threshold sensitivity analysis
- Integration of plot-based FIA with remote sensing canopy height (Potapov)

---

## 2. Methods (target 2,000 words)

### 2.1 FIA data

- Plot population: NE region states for 2019-2023 panel and 1999-2003 panel
- Sample sizes by state and panel
- Remeasurement and panel structure
- Plot location handling (fuzzing, ecoregion membership)

### 2.2 RAP v2.0 LSOG classification protocol

- Six dimensions used in classification
- Score thresholds for each class
- Adaptations for Northeast forest type groups
- Bug fix history (March 19 fix on dead wood scoring; pulls snag counts from inside vs outside plot)

### 2.3 Classifier variants

- v4 (baseline): no remote sensing integration
- v5: integrates Potapov RH95 canopy height with default 18/25 m thresholds
- v5b: alternative classifier variant for sensitivity
- v5c: continuous RH95 in logistic regression for highest AUC

### 2.4 Sensitivity analysis

- RH95 threshold grid: 10-25 m breakpoints tested
- AUC against ORNL mature classification (>50 years) as ground truth proxy
- Continuous RH95 logit specification

### 2.5 20-year trend analysis

- 1999-2003 panel as baseline
- 2019-2023 panel as comparison
- State-level LSOG share differences
- Net change in percentage points

### 2.6 Spatial structure

- Plot density by ecoregion
- Sub-state geographic patterns
- Regional facet visualization

### 2.7 Statistical analysis

- Logistic regression for classification probability
- Threshold grid search
- AUC and kappa for classifier comparison
- Plot-level effects vs aggregate effects

### 2.8 Reproducibility

- Pipeline scripts: `R/build_unified_plot_table.r`, `R/phase5c_potapov_sensitivity.r`, etc.
- Master analytical artifact: `output_unified/lsog_ne_plot_table.csv`
- Cardinal cluster execution
- Open code for downstream users (Thompson team, DACF, MFS, NEFF)

---

## 3. Results (target 1,500 words)

### 3.1 v5 classification: state-level summary

Table 1: State-level LSOG share, 2019-2023 panel:

| State | n | Trans LS | LS | OG | All LSOG |
|-------|---|---|---|---|---|
| ME | 3,125 | 19.9% | 5.5% | 0.38% | **25.8%** |
| NY | 2,107 | 31.1% | 12.9% | 2.52% | **46.5%** |
| NH | 757 | 42.5% | 12.0% | 1.06% | **55.6%** |
| VT | 657 | 42.9% | 13.9% | 1.07% | **57.8%** |

### 3.2 20-year trend (v4)

Table 2: All-LSOG percent change 1999-2003 to 2019-2023:

| State | 1999-2003 | 2019-2023 | Net change |
|-------|---|---|---|
| ME | 16.8% | 20.4% | +3.6 pp |
| NH | 22.9% | 44.3% | **+21.4 pp** |
| NY | 16.5% | 33.2% | **+16.7 pp** |
| VT | 25.4% | 39.9% | +14.5 pp |

### 3.3 Geographic distribution within states

- Regional facet visualization (Figure 1)
- State-level bar charts (Figure 2)
- Heatmap of LSOG share by ecoregion (Figure 3)

### 3.4 RH95 threshold sensitivity

Table 3: Classifier AUC vs ORNL mature classification:

| Configuration | AUC |
|---|---|
| Default v5 (18/25 m) | 0.644 |
| Optimal grid (10/20 m) | 0.682 |
| Continuous RH95 in logit | **0.689** |

### 3.5 v4 vs v5 comparison

- Where the addition of canopy height changes classification
- State-level differences in v5 vs v4
- Implications for threshold tuning

### 3.6 v5b classifier variant comparison

- Phase 5b kappa and share table
- Logit coefficients (mature and og25)

### 3.7 Plot-level analytical table

- 13,432 rows × 32 columns master table
- Column descriptions
- Suitable as analytical artifact for downstream users

---

## 4. Discussion (target 1,500 words)

### 4.1 Maine's structural divergence

- Continuous industrial forestry vs land abandonment
- 19th century agricultural decline in NH/VT but not Maine
- Industrial forestry rotations: long enough for merchantable, short enough to suppress old growth structure
- Pattern is consistent across multiple metrics

### 4.2 NH and VT aging trajectory

- Old field forest legacy now reaching old growth conditions
- Smaller absolute forest base but higher proportion mature
- Implications for regional carbon storage and habitat

### 4.3 NY old growth concentration

- Adirondacks as the regional old growth hotspot
- Highest OG class share (2.5%)
- Implications for federal forest amendment context

### 4.4 What the trend reveals

- All four states are aging
- The gap is not closing; if anything, Maine's slow pace makes it more divergent
- Active management vs passive aging as the primary driver

### 4.5 RH95 threshold methodology

- Default 18/25 m thresholds may be too conservative
- 10/20 m optimization or continuous RH95 yields higher AUC
- Recommendation for downstream users: continuous RH95 in logit

### 4.6 Limitations

- FIA plot fuzzing limits cell-level analysis
- Two panels for trend analysis is sufficient but not robust
- ORNL mature classification as ground truth is itself a model
- Forest type groups vary across states; comparisons require care
- Wood quality is not directly measured

### 4.7 Implications for biodiversity, carbon, and policy

**Biodiversity**: Cavity nesting birds, lichens, certain salamanders, fungi require structural complexity. Maine has plenty of forest but proportionally less old growth structure. Biodiversity implications are real, even if precise consequences are still being measured.

**Carbon**: Structurally complex older forests typically store more carbon per acre and store it more durably. Maine forests will continue to be a sink under all eight scenarios in the cbm_maine analysis, but the difference between scenarios is partly a function of the old growth fraction.

**Policy**: Each state faces different choices. Maine could continue current management, intentionally extend rotations, set aside reserves, or pursue mixed approaches. NH and VT are aging passively into old growth conditions; the question is whether to encourage or discourage this. NY's Adirondacks are a regional treasure that requires continued protection.

### 4.8 Future work

- Climate scenario projection (which states gain or lose old growth as climate warms)
- Integration with cbm_maine carbon model for state comparison
- Wood quality and harvest economics linkage
- Younger panel updates (2024-present) to confirm trends
- Inclusion of MA, CT, RI for full New England comparison

---

## 5. Conclusion (target 250 words)

A four-state Northeast LSOG analysis reveals a striking divergence: Maine, the most heavily forested state in the United States, has the smallest share of late successional and old growth forest in the region (25.8%), roughly half the share in NH and VT. Twenty year trend analysis shows the gap widening rather than closing, consistent with Maine's continuous industrial forestry history vs the land abandonment trajectory in NH, VT, and NY. The methodology generalizes to other regions and the unified plot table provides an analytical foundation for downstream policy, biodiversity, and carbon analyses. The implications for forest policy are real, and the choices each state makes will shape this regional pattern for the next quarter century.

---

## Key figures

1. **Figure 1**: Regional facet of LSOG share by state and panel (`output_v4/lsog_pct_regional_facet_v4.png`)
2. **Figure 2**: State-level bar chart of LSOG share (`output_v4/lsog_pct_state_bar_v4.png`)
3. **Figure 3**: Heatmap of LSOG share by ecoregion (`output_v4/lsog_heatmap_regional_v4.png`)
4. **Figure 4**: Phase 5 three-way bar comparison (`phase5_results/phase5_three_way_bar.png`)
5. **Figure 5**: Phase 5b any-LSOG bar (`phase5_results/v5b/phase5b_anylsog_bar.png`)
6. **Figure 6**: Maine v5 baseline LSOG percent (`v5_baseline/lsog_pct_combined_ME_v5.png`)
7. **Figure 7**: NH, VT, NY per-state v5 LSOG percent (in `output_v5/`)

---

## Key tables

1. **Table 1**: State-level LSOG share, 2019-2023 panel (from `regional/fia_lsog_v5_all_states.csv`)
2. **Table 2**: 20-year trend (from `regional/fia_lsog_all_states_v4.csv`)
3. **Table 3**: RH95 threshold sensitivity AUC table
4. **Table 4**: Logit coefficients for v5b (mature and og25)
5. **Table 5**: Phase 5b share table by classifier variant

---

## Open items for next session

1. **Confirm target journal**: Ecological Applications, Forest Ecology and Management, or Conservation Biology
2. **Confirm coauthor list**: Adam Daigneault, Dan Hayes, possibly Thompson team
3. **Phase 6 Hagan raster integration**: complete before submission per NEXT_STEPS.md
4. **Drop v5 RH95 thresholds 18/25 m → 10/20 m**: rerun and regenerate figures (one-line code change in `R/fia_lsog_analysis_v5.r`)
5. **State-level acres by class for reporting**: produce summary table (e.g., NH 414K acres LS+OG vs ME 855K acres) for DACF-style reporting
6. **Aaron drafts Introduction** (1,200 words) in a travel-free week
7. **Convert Methods sections from outline to full prose**
8. **Coordinate Conversation article release with manuscript submission timeline** (Conversation V2 already drafted)
9. **Add to manuscript-pipeline.md** with target submission date

---

## Connections to other CRSF work

- **Conversation article V2**: leads with the LSOG Maine finding (~/Documents/Claude/CRSF-Cowork/active-projects/crsf-strategic-plan/conversation_article_draft_v2.md)
- **cbm_maine carbon budget**: provides the carbon implications context
- **bgi_cspi_conus**: related forest productivity context
- **Maine Climate Council STS**: Forest Health Indicators reporting
- **Irving Chair 25th positioning**: lead Conversation article angle uses this finding
- **Working forest economy framing**: connects to broader CRSF policy work

---

*Outline path: `~/Documents/MAINE/DATA/FIA/ME/LSOG_cardinal_setup/MANUSCRIPT_OUTLINE.md`*
*Source data: `output_unified/lsog_ne_plot_table.csv` and `regional/`*
*Manuscript pipeline entry: `~/Documents/Claude/CRSF-Cowork/_context/manuscript-pipeline.md` (item 5)*
