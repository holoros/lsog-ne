# Toward a defensible, standalone LSOG analysis: refinement plan

Prepared 13 June 2026. Purpose: a roadmap that resolves the Hagan dispute empirically rather than by argument, using data Aaron already holds (true FIA coordinates; MNAP/TNC CFI), with a sequenced predictor-upgrade pilot. The design goal is a study that stands without Hagan's cooperation.

## The problem, stated precisely

Hagan's reported 90% accuracy is the out-of-bag accuracy of his random forest against the field calls used to train it. It measures whether the LiDAR metrics reproduce his own labels, not whether the resulting wall-to-wall map matches the population of older forest. Both his accuracy and any FIA-proxy accuracy assessed against their own labels are therefore circular for the question that matters: how much LSOG exists, and where. The only way out of the circle is a third-party reference that neither map was trained on. That is the spine of this plan.

Two distinct quantities are being conflated in the dispute. Sensitivity (does the map flag a known old-growth site like Big Reed) is different from area accuracy (does the map's total LSOG area match an unbiased estimate). A wall-to-wall LiDAR map can be high on the first and biased on the second at the same time. Hagan is answering the first question to dismiss the second.

## Exhibit A: the Big Reed case (done with existing data)

Big Reed Forest Reserve (~5,000 ac, TNC, Piscataquis County) is the clearest old growth in Maine. Using current data:

- The 24 publicly located FIA plots within ~11 km of Big Reed top out at 127 years stand age and 33 ft^2/ac large-tree basal area; none classify as late-successional or old-growth. There is almost certainly no resolvable FIA plot inside the reserve: at roughly one plot per 6,000 ac, with coordinates fuzzed up to a mile, any plot is thrown into the surrounding working timberland.
- The LCMS continuity layer registers 72% of a 1.5 km window over the Big Reed core as undisturbed across 1985-2023 (it would pass the A4 continuity axis); the disturbed remainder is edge and surrounding managed forest plus coordinate imprecision.

Interpretation: the four-axis criteria would flag a true Big Reed plot trivially (large old trees pass A1, abundant dead wood A2, long-lived composition A3, no detected harvest A4). The apparent "miss" is FIA plot density and coordinate fuzzing, not a failure of the structural definition. This is precisely what true coordinates and reserve CFI plots will demonstrate. Big Reed is therefore not evidence against the design-based critique; it is the motivating case for fixing the sampling geometry.

Status: quantified above with public data. With the Big Reed boundary (Maine GeoLibrary) and the TNC CFI plots, this becomes a one-figure exhibit in the standalone paper.

## Exhibit B: scoring the reserve plots (done with the ERM data now in hand)

The MNAP/TNC Ecological Reserve Monitoring data (`~/Documents/MAINE/DATA/MNAP/`) provides 1,109 precisely located reserve plots across 36 reserves, including 25 in Big Reed, with live and dead tree lists and expansion factors. Scoring every plot with the four-axis structural criteria gives a result that reshapes the refinement:

- Only 13% of the 1,081 scorable reserve plots pass all three structural axes (live structure, dead wood, composition); Big Reed passes at 12%.
- The binding constraint is the large-tree basal-area axis, and it tracks forest type. Big Reed, which has big trees, passes it at 56%; the spruce-fir, cedar, and bog reserves (Moose River No. 5 Mountain, St. John Ponds, Number 5 Bog) pass it at 0%. The dead-wood and composition axes pass at ~57% across the reserves.
- The reserve network is 53% spruce-fir (forest type 120). A single large-tree threshold, borrowed from a generic structural definition, therefore systematically misses low-stature Acadian old growth: forest that is genuinely old and continuous but never reaches large diameters.

Interpretation: this is the central refinement, and it cuts against canopy mapping, not for it. A one-size-fits-all LSOG definition mismeasures humble old growth whether it keys on canopy height (Hagan) or large-tree basal area (our first pass). Low-stature old growth is short, so a higher-resolution canopy product (Meta CHMv2) cannot recover it either. The fix is forest-type-specific structural criteria, in the spirit of Pelz et al. 2023 (USFS Eastern Region, vegetation-type-specific age and density thresholds), calibrated against these 1,081 independent reserve plots. That is the standalone contribution.

## The refined classification: forest-type-specific criteria

Replace the single large-tree-basal-area threshold with vegetation-type-specific structural and maturity criteria, so that low-stature types (spruce-fir, northern white-cedar, bog/peatland) can qualify on age, structural complexity, dead wood, and continuity rather than on size alone, while big-tree types (northern hardwood, white pine) retain a size path. Calibrate the per-type thresholds against the reserve plots (treated as the late-successional reference) and against Pelz 2023 where a type maps to an Eastern Region vegetation class. Report omission error by forest type before and after, to show the recovery of the low-stature reserves.

## The algorithm itself: random-forest attenuation on a rare class

A separate flaw in the published approach is the classifier, not only the definition. A random forest trained on imbalanced data shrinks the rare class toward the majority (attenuation bias), so old growth is systematically under-predicted at the operating point even when overall accuracy is high. Hagan's own out-of-bag result is the signature: 94% overall accuracy but only 29.4% of true old-growth plots classified as old growth. The standard remedies are class weighting, balanced random forest (per-tree downsampling of the majority), up-sampling, or adjusting the probability threshold; a cost-sensitive or multi-objective learner is the more principled route.

Test (feasible now on his own data; we reproduced the random forest in `phase10_hagan_reproduction.r`): refit the classifier with balanced class weights and equal LSOG / non-LSOG representation, then compare the operating accuracy on the rare classes and the mapped LSOG/OG area against the unbalanced original. If balancing materially shifts the area, the published area is partly an artifact of the algorithm's handling of a rare class, on top of the definitional and geolocation issues. Report the area under both, framed as a sensitivity to the classifier, not an accusation.

By construction, the design-based estimate is immune to this failure mode: it applies transparent criteria and weights by the FIA sampling design rather than training a rare-class classifier and counting pixels. This is a further reason the honest area is the design-based estimate with its interval, and any wall-to-wall classification's area should be reported as sensitive to the algorithm as well as the definition.

## Track 1 (foundation): true FIA coordinates

Status of data: NOT yet on Cardinal. The `~/fia_data/ME_PLOTGEOM.csv` coordinates are byte-identical to the fuzzed `ME_PLOT.csv`. The DUA true-coordinate file (PLOT CN plus actual LAT/LON) needs to be uploaded to a restricted directory.

What it fixes: fuzzing (up to ~1 mile, with private-plot swapping) is the dominant source of plot-to-pixel error and is almost certainly why the Seven Islands plot-level kappa was near zero while the pixel-level kappa was 0.24, and why Big Reed looks missed. The design-based area estimates are unaffected (area uses EXPNS, not coordinates), but every remote-sensing extraction and every cross-map plot-level comparison is currently sampled at the wrong pixel.

What I will do on upload:
1. Re-extract Potapov RH95, LCMS, ORNL 2498, the reproduced Hagan raster, and any new predictors at the true plot locations.
2. Recompute the v5.1 and four-axis scores and every cross-map kappa.
3. Re-run the Big Reed and Seven Islands tests at true locations to quantify how much of the disagreement was geolocation.

Handling: a restricted Cardinal directory, added to `.gitignore`; no coordinate ever written to any committed output, figure, or repo. This is a hard rule for the DUA.

## Track 2 (keystone): independent validation against MNAP/TNC CFI

This is the analysis that stands alone. MNAP ecological-reserve monitoring and TNC CFI plots (including Big Reed) are expert-assessed, precisely located, and were not used to train either map. They are the third-party reference that breaks the circularity.

Data needed (fields): plot identifier and precise coordinates; remeasurement tree lists or stand-level structural attributes (live and dead BA, large-tree BA/count, QMD, snags, CWD where recorded, stand age or origin); and the expert old-growth / LSOG designation where one exists; Big Reed plots flagged. (See "Data to provide" below.)

What I will do on upload:
1. Score every CFI plot with v5.1 and the four-axis classifier using the same criteria, so the proxy is evaluated on independent ground.
2. Sample the reproduced Hagan map and the v5.1 wall-to-wall at each CFI plot.
3. Build confusion matrices for BOTH maps against the expert designation, reporting omission error (misses true LSOG such as Big Reed) AND commission error (flags non-LSOG), plus per-map sensitivity and specificity.
4. Place each map's total area against the FIA design-based estimate with intervals, separating the sensitivity question from the area-bias question.

Expected shape of the result (to be confirmed by the data): Hagan's map scores high sensitivity (it finds Big Reed) but high commission (its 21.9% area is ~5x the design-based older-forest estimate); the FIA proxy scores lower sensitivity at sparse reserve sites but matches the design-based area. The honest conclusion is complementary roles, not a winner: LiDAR is the better tool for locating candidate patches, design-based FIA the better tool for quantifying total area with uncertainty. That framing is defensible and needs nothing from Hagan.

Deliverable: this is the standalone companion paper. An independent accuracy assessment of LSOG maps against reserve CFI, with omission and commission error for each map, the design-based area with intervals, and the four-axis definition. The Comment stays as the focused critique; this resolves it with measurement.

## Track 3 (sequenced upgrade): predictor pilot

Goal: a stronger v2 classifier, tested for whether each new input actually improves agreement with the CFI reference rather than added for its own sake. Run only after Tracks 1-2, because without true coordinates and an independent reference you cannot tell whether a fancier predictor helps.

Candidates, with what each adds and its caveat:
- GEDI L2A (NASA, public): raw spaceborne-lidar waveform metrics (RH percentiles, foliage profiles, cover). Adds real vertical structure rather than Potapov's modeled RH95. Footprints are sparse (25 m, ~60 m along-track), so co-location needs true coordinates. The most defensible structural upgrade and the most independent of canopy-only signals.
- Meta / WRI Canopy Height Maps v2 (CHMv2, March 2026; DINOv3 backbone; validation R^2 0.86 vs 0.53 for v1; open model and global maps on Earth Engine and AWS Open Data): high-resolution canopy height, a clear upgrade over Potapov for the tall-canopy signal. Caveat: it is canopy height, so it makes the classifier MORE like Hagan's and inherits the same dead-wood and continuity blind spots, and it cannot recover low-stature old growth (which is short). Use as a covariate for the big-tree component, not a foundation.
- TESSERA embeddings (geotessera.org, open data/weights, 10 m per-pixel annual embeddings) and Google AlphaEarth Satellite Embeddings: rich learned feature spaces that compress a year of imagery per pixel. Worth a pilot as classifier inputs; verify license and the simplest access path (TESSERA is openly downloadable; AlphaEarth is in Earth Engine). These are a "build a better feature set" move, complementary to GEDI.
- 3D NAIP (structure-from-motion from NAIP stereo): high-resolution canopy structure where stereo coverage exists; useful as a fine-scale structural check near reserves.

Pilot design: at the CFI-plus-true-coordinate plots, test whether adding each predictor improves the cross-validated prediction of the expert LSOG designation over the current FIA-plus-Potapov set. Keep a predictor only if it improves the independent metric. Report the increment, not just the final model.

## The standalone deliverable

A methods-and-assessment paper, structured as: the four-axis definition; an independent accuracy assessment of competing LSOG maps against reserve CFI (omission and commission for each); the design-based area with intervals; and the predictor pilot as a methods advance. It is positioned to stand without Hagan's input and converts the dispute into a measurement that any reader can check.

## Sequencing

1. Now: Big Reed exhibit (done); build the CFI scoring-and-validation framework so it runs the moment the data lands; verify predictor access (TESSERA confirmed open).
2. On data upload: ingest true coordinates and CFI; re-extract at true locations; run the dual-map confusion matrices; quantify how much disagreement was geolocation.
3. After validation: run the predictor pilot; keep only inputs that improve the independent metric.

## Data status

In hand:
1. True FIA coordinates: `FIA.xy.csv` (PLT_CN, FUZZ.LAT/LON, TRUE.LAT/LON; ME). Hold in a restricted, git-ignored directory; never commit.
2. MNAP/TNC Ecological Reserve Monitoring: `~/Documents/MAINE/DATA/MNAP/` (1,109 plots, 36 reserves incl. 25 Big Reed; live and dead tree lists with expansion factors; reserve boundary shapefiles; full monitoring database). Scored in Exhibit B.

Pending (you have these; not yet on Cardinal or in the workspace):
3. Baxter SFMA CFI (Scientific Forest Management Area continuous forest inventory; additional true-LSOG reference). Please upload when convenient; it slots straight into the reserve-validation framework as a third independent reference.

## Independent validation sources for the standalone assessment

- MNAP/TNC ecological reserves (in hand): 1,109 plots, 36 reserves, the late-successional reference network.
- Baxter SFMA CFI (pending): managed and reference stands with long remeasurement.
- Pelz et al. 2023: external vegetation-type-specific old-growth criteria for calibration and cross-check.

## Immediate, in-hand analyses (no further data needed)

1. Forest-type-specific re-validation against the 1,081 reserve plots; report omission by type before and after.
2. Balanced-random-forest test on Hagan's reproduced classifier; report rare-class operating accuracy and area under balanced vs unbalanced.
3. Dual-map confusion at true coordinates: push the ERM plots and `FIA.xy.csv` to Cardinal, sample Hagan's map and the v5.1 wall-to-wall at the precise reserve and true FIA locations, build the independent confusion matrix (omission and commission) for both maps.

Predictor pilot (CHMv2, GEDI, TESSERA) follows, kept only where it improves the independent metric.
