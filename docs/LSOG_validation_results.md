# Independent validation results: answering the Big Reed challenge

Prepared 13 June 2026. Three analyses run against independent data Aaron holds (MNAP/TNC ecological reserve monitoring; Hagan's archived training data). All anti-bias safeguards applied: external published criteria (Pelz et al. 2023, co-authored by Woodall), no thresholds tuned to the reserves, a range of definitions reported rather than one.

## Headline numbers (quotable)

1. Our classifier DOES identify Big Reed. At Big Reed's 25 precise reserve plots, our four-axis criteria flag 72% as LSOG (Pelz type-specific), or 68% under the original threshold, against Hagan's 80%. The earlier wall-to-wall "miss" was the absence of any FIA plot inside the 5,000-acre reserve (plot density plus mile-scale coordinate fuzzing), not a failure of the criteria.

2. Neither map detects every reserve, and ours detects more. Across 819 ecological-reserve plots inside Hagan's mapped area, our criteria flag 67% (Pelz) versus Hagan's 57%. By Hagan's own standard ("it didn't identify the reserve, so it's bad"), his map misses 20% of Big Reed and 43% of the reserve plots, more than ours. Both detect most but not all reserve old growth, because old-growth structure is heterogeneous even within reserves. That is the thesis: it depends how you count.

3. Hagan's "90% accuracy" is preserved by sacrificing the rare class. Refitting his own random forest on his own training data, old-growth operating accuracy is 23.5% unbalanced (matching his reported ~29%) and 70.6% with standard class balancing, at a trivial cost to overall accuracy (0.868 to 0.836). A random forest on imbalanced data attenuates the rare class; balancing recovers old-growth detection threefold.

4. The published map area is an artifact of that imbalance. Re-running his wall-to-wall prediction, balancing raises mapped old growth from 109,000 to 192,000 acres (nearly double) and any-LSOG from 21.5% to 32.3%. A routine modeling fix swings his headline area by 50 to 75%, so the single number should not be taken at face value.

## The constructive refinement (anti-bias, externally anchored)

Scoring all 1,081 reserve plots, the large-structure axis recovers from 32% (our original type-agnostic large-tree basal-area threshold) to 67% under Pelz's published vegetation-type-specific large-tree-count criteria; spruce-fir, which is 53% of the reserve network, jumps from 29% to 68%. The binding bias was a single high diameter cutoff applied to all forest types; it misses low-stature Acadian old growth (spruce-fir, cedar) that is genuinely old and continuous but never reaches large diameters. The fix is Pelz-style type-specific criteria, calibrated against the reserves with hold-out validation, not a single tuned threshold. A high-resolution canopy product (Meta CHMv2) cannot recover this, because low-stature old growth is short; that is why canopy-only maps will always struggle with it and why a multi-axis, forest-type-aware FIA definition is the better backbone.

## How this resolves the dispute

- "It didn't identify Big Reed" reduces to a sampling-geometry artifact (no FIA plot in the reserve), disproven by scoring the actual Big Reed reserve plots, where our criteria agree with Hagan to within a few percent.
- "90% accurate" is a real number that measures agreement with his own training labels, and it is held up by under-detecting the rare class; balancing his model triples old-growth detection and doubles the mapped old-growth area.
- The honest unit remains the design-based estimate with its interval, which is immune to both the definitional and the algorithmic failure modes because it weights by the sampling design rather than training a rare-class classifier and counting pixels.

## Provenance

- Reserve dual-map: `output_phase37/Q1_reserve_dualmap.csv`, `Q2_per_reserve.csv` (Hagan raster `output_phase10/C_hagan_class_100m.tif` sampled at precise ERM coordinates; our call from ERM tree lists).
- Forest-type recovery: VM scoring of `ERM_ME_AllTrees.csv` under three externally grounded definitions.
- Balanced random forest: `output_phase36/P1_operating_accuracy.csv`, `P2_walltowall_area_by_model.csv` (refit of `phase10_hagan_reproduction.r` with balanced bootstrap and class weights).
- Pelz criteria: `docs/PELZ_2023_REVIEW.md`; Pelz et al. 2023 FEM 549:121437.

## Open follow-ups

1. True-coordinate cross-map kappa (FIA.xy vs Hagan, true vs fuzzed): blocked on a CN-vintage mismatch between `FIA.xy.csv` and the unified plot table; re-key on STATECD/COUNTYCD/PLOT/INVYR to complete. Quantifies how much plot-level disagreement is geolocation.
2. Baxter SFMA CFI: add as a third reference when uploaded.
3. Predictor pilot (CHMv2, GEDI, TESSERA) as covariates, kept only where they improve the independent reserve metric.
4. Build the type-specific classifier and report omission by forest type before and after, with hold-out validation, as the standalone paper's core.

## Update: refined RS + LCMS map (phase 38)

Fusing the LCMS Landsat-disturbance layer with Potapov canopy height in a balanced wall-to-wall model improves cross-validated discrimination of the structural LSOG label from AUC 0.614 (canopy only) to 0.668 (canopy + LCMS) on 6,214 Maine FIA plots. At a 0.5 threshold the RS-based map detects ~36% of Big Reed, well below direct structural scoring (72%), because canopy proxies are weak predictors of multi-axis structure. The honest reading: the Landsat disturbance layer measurably helps any RS map, but no canopy-driven wall-to-wall product (Hagan's or ours) is a strong substitute for design-based plot estimation of the structural definition. Provenance: output_phase38/R1_cv_auc.csv, R2/R3 reserve predictions; refined model output_phase38/refined_rf.rds.
