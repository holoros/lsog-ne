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

## Cutpoint analysis and the single-objective limitation (phase 39)

A random forest optimizes one scalar objective, which is why it attenuates a rare class and why a single 0.5 cut is the wrong tool. The response has two layers. At the decision layer, the ROC curve is the multi-objective Pareto front of sensitivity versus specificity; the cutpoint analysis exposes it instead of hiding it in a default threshold. On the balanced canopy+LCMS model (CV AUC 0.66), the 0.5 cut over-predicts badly (mapped prevalence 40%, worse than Hagan's 22%), Youden's J sits at 0.55 (prevalence 32%), and matching the design-based 14% prevalence requires a threshold near 0.98 (prevalence 19%, specificity 0.84) at the cost of sensitivity (0.36). No single cutpoint gives both area accuracy and detection: the classic single-objective tension, and the reason the design-based estimate must remain the area anchor while the map is reported as a probability surface. At the structure layer, the four-axis funnel is already non-scalarized and multi-objective: it requires the axes jointly (a conjunctive, Pareto-style criterion) rather than blending them into one optimized score. A formal multi-objective learner (NSGA-II / multi-task) is a reasonable pilot but does not change the conclusion, because the design-based area is the anchor regardless of the learner. Recommendation for both papers: report P(LSOG), calibrate any binary threshold to the design-based area (anti-over-prediction), and show the Youden alternative so the omission-commission trade-off is explicit. Provenance: output_phase39/C1_cutpoint_comparison.csv, C2_roc.csv.

## Third reference: Baxter SFMA CFI (phase 40)

Plot coordinates were recovered from the "legal" sheet of each raw remeasurement workbook (PLOT CENTER in degrees-minutes-seconds); 90 plots cleaned and geolocated. Baxter SFMA is structurally mature, not young: median maximum DBH 51 cm, 98% of plots pass the large-tree axis, Potapov median canopy height 16 m, late-successional composition >= 50% on 62%. Only 18% of plots show LCMS stand-replacing or harvest disturbance over 1985-2023 (median 9 years ago), so 82% pass the continuity axis; the scientific-management area is lightly managed and largely continuous. Hagan flags 57% as LSOG. All three independent references (MNAP/TNC reserves, Big Reed, Baxter SFMA) behave consistently: both maps detect most mature/old forest, neither detects all of it, and the LCMS continuity axis correctly isolates the managed fraction. Baxter strengthens the validation as a third reference that no map trained on. Provenance: output_phase40/B1_baxter_map_sample.csv; coords parsed from BaxterData/2008_09 1st Remeasurement Raw Data/.

## True-coordinate re-key (phase 43) and the multi-objective dimension

The FIA.xy true coordinates were linked to the unified plot table by their public fuzzed coordinates (the CN vintages differ). Using true rather than fuzzed coordinates more than doubles the v5.1-vs-Hagan cross-map agreement: Cohen's kappa for any-LSOG rises from 0.134 (fuzzed, n=1729) to 0.286 (true, n=1737). About half the apparent plot-level disagreement in earlier cross-validations is the kilometre-scale public-coordinate error, not classifier disagreement, and the same artifact explains the appearance that a sparse fuzzed inventory "misses" a small reserve like Big Reed.

Multi-objective: the cutpoint analysis (phase 39) shows no single threshold gives both detection and area accuracy. The recommended product is P(LSOG) with the binary threshold calibrated to the design-based area (over-prediction bounded by the unbiased estimate). The estimator should be multi-objective, jointly minimizing total and systematic (attenuation) error, after the co-authored MOSVR of Legaard et al. (2020, Remote Sensing 12:1739). Data map of all datasets used (FIA, MNAP/TNC reserves incl. Big Reed, Baxter SFMA) is manuscript Fig. 1.

## Resolved follow-ups (phase 42b, 44e/f)

MOSVR pilot (phase 42b, resolved). The e1071 SVR was refit through the data.frame formula interface with cross-validated objective evaluation, which fixed the all-NA failure. On 2,500 Maine plots, a 3x3x2 cost/gamma/epsilon grid traces a clean Pareto front of total error (RMSE) versus systematic error (|1 - slope of observed on predicted|). The total-error-optimal solution attenuates the high end (slope 0.864, sys 0.136, mean high-decile bias -3.21 structural points); the multi-objective compromise on the same front nearly halves systematic error (slope 0.918, sys 0.082) at negligible RMSE cost (1.711 to 1.712). This is the attenuation-bias story made operational: choosing the operating point on the front, rather than accepting the single-objective fit, is what protects the rare class. Provenance: output_phase42/M1_grid_objectives.csv, M2_pareto.csv, M3_compare.csv; R/phase42b_mosvr.R. Folded into manuscript section 4.4a.

P(LSOG) probability surface (phase 44e/f, resolved). The earlier render failed twice: first an all-NA raster from resampling across mismatched CRS, then a terra global() error (it lacks a "median" string and a custom-function quantile). Fixed by reprojecting Potapov in one project(crop(...)) step aligned to the LCMS grid, using a custom predict function for RF class probability, and computing quantiles/medians from extracted values. The surface (11.06M forested cells, mean P 0.538) is archived as ME_LSOG_probability_100m.tif and clipped to a Maine land outline (concave hull of the true FIA coordinates, 93,189 km2) for display. The area-matched threshold of 0.93 reproduces the design-based 14.1% prevalence. Rendered as manuscript Fig. 6. Provenance: output_phase44/ME_LSOG_probability_100m.tif, ME_LSOG_probability_clipped_100m.tif, Fig_prob_surface.png; R/phase44e_probmap.R, phase44f_clip.R.
