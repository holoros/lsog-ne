# It depends how you count: definition, disturbance history, and the distribution of late-successional and old-growth forest across the northeastern United States

Aaron R. Weiskittel

University of Maine, Center for Research on Sustainable Forests and School of Forest Resources, 5755 Nutting Hall, Orono, ME 04469, USA. aaron.weiskittel@maine.edu

---

## Abstract

Late-successional and old-growth (LSOG) forests provide habitat, store carbon at high densities, and carry particular conservation value in heavily managed landscapes. A 2022 federal executive order set off a wave of national and regional mapping of mature and old-growth forest, and these maps are increasingly read as guides to where conservation money should go. As wall-to-wall LSOG maps begin to anchor parcel-level conservation spending across the Northeastern United States, two questions become decision-relevant: how much LSOG exists, and how much do independent, equally defensible classifications agree on where it is. Using USDA Forest Inventory and Analysis (FIA) plots across the Northeast, we (i) estimate older-forest area with design-based confidence intervals under transparent ground criteria; (ii) develop a refined four-axis LSOG classification (live structure, dead wood, composition, and temporal continuity) and quantify how the qualifying share depends on how many axes are required; and (iii) conduct a full cross-map assessment over Maine's unorganized townships, comparing three remote-sensing classifications that differ in sensor, training data, and target definition. LSOG attributes are genuinely multidimensional: once temporal continuity is measured from the Landsat disturbance record (USFS LCMS, 1985-2023), true LSOG (all four axes) is far rarer than any single axis implies, with only 3.1% of Maine forestland qualifying against 12-15% in New Hampshire, Vermont, and New York. Maine's low share tracks a working-forest signal, with about three-quarters of its forest carrying Landsat-detected disturbance since 1985 (74.4%, 95% CI 71.9-76.9) versus 30-50% in its neighbors. Under the integrated structural proxy, Maine carries the lowest combined LSOG share in the region (14.1%, 95% CI 12.9-15.3) even though it is not lowest on stand age alone. The two structure-resolution maps disagree 1.6-fold in extent (21.9% versus 14.0%) and overlap only modestly (Cohen's kappa 0.22); adding a continental old-growth product widens the range to 2.6-fold, and only 2.7% of the hectares flagged by any map are flagged by all three. Older-forest stock is stable to rising over 2003-2024 even as mapped LSOG is lost at roughly 2% per year, and the published LiDAR map's old-growth area nearly doubles under routine class balancing. We recommend that regional LSOG accounting report a method range with design-based intervals, that the LS+OG class be the stable policy unit, and that maps be cross-checked and field-verified before they steer acquisition.

**Keywords:** late-successional and old-growth, FIA, design-based estimation, cross-map assessment, forest structure, canopy height, Northeast, working forest

---

## 1. Introduction

### 1.1 LSOG forests as a conservation and policy concern

Forests with mature, structurally complex stands provide ecosystem services that younger forests cannot. Cavity-nesting birds depend on standing dead trees that take decades to develop. Many lichen species require old, structurally complex canopies. Some terrestrial salamanders prefer the deep coarse woody debris that accumulates over generations. Beyond habitat, structurally complex older forests typically store more carbon per unit area than younger, simpler ones, and they store it more durably across the time horizons relevant to climate adaptation. Federal and state policy increasingly emphasizes the protection of late-successional and old-growth (LSOG) forest. A 2022 federal executive order directed the first government-wide inventory of mature and old-growth forest (U.S. Executive Order 14072 2022; USDA Forest Service and USDI Bureau of Land Management 2023), and the same period produced continental old-growth probability layers (Bruening et al. 2026), structure-based national maps (DellaSala et al. 2022), region-standardized field criteria (Pelz et al. 2023), and a wider recognition that defining and inventorying older forest is itself a hard problem on which credible efforts disagree (Barnett et al. 2023; Gray et al. 2023). State ecological-reserve programs maintain designated networks, and emerging carbon and conservation markets increasingly recognize the value of older forest. These developments raise the value of accurate, comparable, uncertainty-aware LSOG accounting, and they make the methodological questions below national in scope even where we work them out in one region.

### 1.2 Two questions: how much, and where

Recent work has put wall-to-wall LSOG maps directly into conservation practice. In Maine, an airborne-LiDAR classification of the unorganized townships (Hagan et al. 2026) has become the spatial basis for prioritization at scale, with downstream cost estimates on the order of US $200-300 million for protecting the highest-priority half of the mapped patches (Thompson et al. 2026, in support of Maine's LD 1529). When a single map becomes the substrate for parcel-level acquisition, two distinct questions become decision-relevant. The first is quantitative: how much LSOG exists, and with what sampling uncertainty. The second is spatial: how much do independent, equally defensible operationalizations of LSOG agree on which hectares qualify. The first question is answerable from the probability sample that underlies all of these products; the second requires placing several wall-to-wall classifications on a common grid and measuring their agreement. Neither has been addressed systematically for the region.

### 1.3 LSOG is multidimensional, and that matters for both questions

LSOG is not a single attribute but a bundle: large old live trees, structural complexity, abundant dead wood, characteristic composition, and continuity of forest cover over time. These attributes need not move together. A stand can carry large live trees yet little dead wood; it can have a tall continuous canopy yet a recent harvest signature. Any classification therefore embeds a choice about which axes to weight and how heavily, and that choice, more than any difference in fit to training data, drives how much forest qualifies and where. Making the axes explicit clarifies both the quantity question (the answer is a range that depends on how many axes are required) and the agreement question (maps disagree because they emphasize different axes). This multidimensional framing, and the strong dependence of the estimate on the criteria chosen, has national precedent: the Forest Inventory Growth Stage System treats maturity as a multidimensional structural condition built from a suite of FIA structural indicators, and places about 45% of federal forest in the mature class and 18% in old growth (Woodall et al. 2023; USDA Forest Service and USDI Bureau of Land Management 2023), an estimate sensitive to the structural thresholds chosen. The axis-count funnel we develop below is the design-based, regional expression of the same phenomenon.

### 1.4 The Northeast as a natural comparison

The four core Northeastern states share climate but diverge sharply in forest history. New Hampshire and Vermont saw peak agricultural clearing in the 1800s followed by widespread abandonment; the old-field forests that regrew now reach 100-150 years and are increasingly structurally complex. New York followed a similar arc, but the Adirondack landscape retained larger unmanaged forests and remains the regional old-growth concentration. Maine, by contrast, has supported continuous large-scale industrial forestry from the 1800s to today and produces more pulpwood than any state east of the Mississippi; its forests have been worked for generations on rotations long enough for merchantable trees but short of the structural conditions associated with old-growth. These divergent histories make the region a natural setting for a consistent, structure-based LSOG comparison. They also make it a natural setting for a triad question (Seymour and Hunter 1999): across a landscape allocated among intensive production, extensive management, and reserves, the policy-relevant issue is whether the late-successional condition is adequately represented across forest types and ecoregions, not whether any single state carries a particular share.

### 1.5 Contribution

We make three contributions, each anchored in the FIA probability sample. First, we provide design-based older-forest estimates with confidence intervals for the Northeast under transparent ground criteria, distinguishing the gross harvest flux from the net stock trend. Second, we develop a refined four-axis LSOG classification and quantify, through a "funnel," how the qualifying share depends on how many axes are required and which axis is limiting. Third, we conduct a full cross-map assessment over Maine's unorganized townships, quantifying disagreement among three remote-sensing classifications (a reproduced LiDAR classifier, a canopy-height map, and the ORNL national old-growth product), with external checks and with the TreeMap FIA imputation read on the design-based side. Together these reframe LSOG accounting from a single number toward a method range with explicit uncertainty, and they give downstream users the agreement information that high-stakes allocation requires.

---

## 2. Methods

### 2.1 Study area and FIA data

We analyzed FIA Phase 2 inventory plots across the Northeastern United States, with the four-state core of Maine, New Hampshire, Vermont, and New York and supplementary estimates for Massachusetts, Connecticut, and Rhode Island. Plots span the 1999-2023 inventory period across five evaluation panels. Sample sizes for the most recent panel (2019-2023) are 3,125 in Maine, 757 in New Hampshire, 657 in Vermont, and 2,107 in New York. FIA plot coordinates are publicly fuzzed up to approximately 1 km to protect landowner privacy; fuzzed coordinates were used for all spatial extractions, and the resulting noise on 30 m raster sampling is discussed in Section 4.6. We assembled a master plot-level analytical table (`output_unified/lsog_ne_plot_table.csv`, 13,432 rows x 32 columns) containing, for each plot-period, state, panel, plot CN, inventory year, fuzzed coordinates, stand age, total and large-tree basal area, TPA-weighted SD of diameter, maximum diameter, snag density, the dimension scores, the v4 and v5.1 classifications, the ORNL DAAC 2498 probability bands (Bruening et al. 2026), and the Potapov (2021) RH95 canopy height at the plot centroid. The FIA plots and the independent validation datasets used here, the MNAP/TNC ecological reserve network including Big Reed Forest Reserve and the Baxter SFMA continuous forest inventory, are shown in Fig. 1.

### 2.2 The six-dimension v5.1 structural proxy

The integrated v5.1 classifier scores each plot on six structural dimensions and aggregates into a 0-12 total (Table S1). Class thresholds are Transitioning LS (TLS) at score >= 4, Late Successional (LS) at >= 6, and Old Growth (OG) at >= 8. Dimensions 1-5 derive from FIA tree and condition tables; dimension 6 derives from the Potapov et al. (2021) Global Ecosystem Dynamics Investigation (GEDI)/Landsat 30 m canopy-height mosaic sampled at the plot centroid. The thresholds were calibrated by grid search against two external references, the Hagan et al. (2026) LiDAR classification for Maine's unorganized townships and the Oak Ridge National Laboratory (ORNL) Distributed Active Archive Center (DAAC) 2498 mature/old-growth probability layers, and are intentionally tighter than the RAP v2.0 reference structural values (Shamgochian et al. 2025, Appendix A: a late-successional class averaging roughly 90 large trees >= 40 cm dbh per hectare, coarse woody material near 80 m^3/ha, and 56% of basal area in trees >= 40 cm); an earlier relaxed configuration produced implausibly high regional shares (65-69% in New Hampshire and Vermont) and was rejected. Because these thresholds were tuned in part against the Hagan and ORNL products, we do not treat the v5.1 proxy as an independent member of the cross-map assessment (Section 2.6), which instead uses the independently reproduced Hagan random forest; and the load-bearing area estimates rest on the design-based ground criteria (large-tree basal area and stand age, Section 2.5), which involve no map calibration, so neither the cross-map disagreement nor the design-based totals are artifacts of the proxy's calibration. A deadwood-scoring error in an earlier version (snag counts drawn from outside the plot boundary in some cases) was corrected on 19 March 2026; all results here use the corrected classifier.

### 2.3 A refined four-axis LSOG classification

The six-dimension score is convenient but collapses distinct ecological axes into one number. To make the axes explicit, we defined four LSOG axes and required a plot to pass each on its own transparent criterion: **A1 live structure** (large-tree basal area >= 30 ft^2/ac in trees >= 16 in, about 40 cm, dbh; the v5.1 six-dimension proxy of Section 2.2 uses a stricter 20 in cut for its large-tree dimension), **A2 dead wood** (standing snag basal area >= 5 ft^2/ac), **A3 composition** (>= 50% of live basal area in long-lived, late-successional species), and **A4 temporal continuity** (no stand-replacing or harvest disturbance detected in the USFS Landscape Change Monitoring System annual change record over the full Landsat era, 1985-2023). Each structural threshold is a conservative lower benchmark calibrated to regional reference stands rather than a maximum, so the qualifying shares reported below are floors on what a stricter definition would return. A1-A3 are deterministic functions of the FIA tree and condition tables. A4 replaces the earlier, permissive continuity proxy based on FIA treatment and stand-origin codes, which flags only the most recent inventory cycle and undercounts legacy and partial harvest; in Maine that proxy passed 90% of conditions, whereas the Landsat-era continuity test passes 29.5% (see Section 2.3a). We then computed, across all forested plots, the share passing each axis alone, the "funnel" share passing at least one, at least two, at least three, and all four axes (which we label *true LSOG*), and, among plots that fail, which single axis is most often limiting. This decomposition answers the quantity question as a range rather than a point and identifies the axis that most constrains LSOG status.

### 2.3a Landsat time-since-disturbance continuity layer

The temporal-continuity axis is the one a canopy sensor cannot see but the Landsat record can. We built it from the USFS Landscape Change Monitoring System (LCMS v2024-10) annual "change, cause of change" product, a Landsat-based classification giving, for every 30 m pixel and every year 1985-2023, the dominant change cause among sixteen classes. We cropped each annual layer to Maine, resampled to a common 100 m grid, and reduced the stack to the year of most recent stand-replacing or harvest disturbance, defined as any year flagged Tree Removal, Mechanical, Wildfire, Hurricane, Prescribed Fire, or Other Loss; time-since-disturbance is the current year minus that year. A condition passes A4 only if no such disturbance is detected at its plot over the full record (a 3 x 3 focal maximum absorbs FIA coordinate fuzzing). Tree Removal is by far the dominant LCMS cause in Maine, so this layer captures the partial and selective harvest that the binary Global Forest Watch loss layer (used by the original analysis) and the FIA treatment codes both miss. Because the choice of disturbance-class set, time window, and spatial buffer is itself a modeling decision, we tested the sensitivity of the resulting true-LSOG share to five continuity definitions (Section 3.4, Table 5).

### 2.4 Dimensionality of LSOG attributes

To test whether the axes are in fact distinct, we examined the correlation structure and principal components of seven plot-level structural attributes (live basal area, large-tree basal area, large-tree count, quadratic mean diameter, diameter diversity, standing dead basal area, and coarse woody debris volume) on the Maine plot population. We report the pairwise correlation matrix and the variance explained by successive principal components. The question is whether dead wood and continuity load separately from live structure; if they do, a one-axis classifier necessarily discards information that the four-axis definition retains.

### 2.5 Design-based estimation and trend

State-level shares are computed by FIA design-based post-stratified estimation, weighting plots by EXPNS from POP_PLOT_STRATUM_ASSGN joined to POP_STRATUM, with variance following Bechtold and Patterson (2005) as implemented in rFIA (Stanke et al. 2020). We report older-forest area by four transparent ground criteria (stand age >= 100, >= 120, >= 150 yr, and live basal area in trees >= 40 cm dbh above 30 ft^2/ac) statewide and for the northern timberland units, plus the integrated v5.1 share. Because FIA stand age is a modeled field attribute that is poorly defined in the uneven-aged stands that dominate this region, we treat the large-tree basal-area criterion as the primary structural measure and the age thresholds as corroborating; the substantive conclusions are reported on the structural and multi-axis measures and do not depend on a stand's assigned age. Annual estimates over 2003-2024 give the trend; we fit per-year design-based estimates using rFIA panel-based annual estimation, so the slope reflects the interpenetrating-panel inventory design rather than repeated measurement of the same plots, and report it with its confidence interval, distinguishing the net-stock trend from the gross harvest flux reported by canopy-change products.

### 2.6 Cross-map assessment

Over the Maine unorganized-townships study area, we placed three independent remote-sensing LSOG classifications on a common 100 m grid: (i) the Hagan et al. (2026) airborne-LiDAR classifier, reproduced from the archived random forest (out-of-bag accuracy 94.2% against the published 94.1%, with the same top predictor) and verified against the privately held Seven Islands product (pixel-level kappa 0.97 over ~290,000 ha); (ii) an FIA structural class predicted from Potapov GEDI-calibrated spaceborne canopy height (an alternative global canopy-height product, Lang et al. 2023, gives a comparable structural surface); and (iii) the ORNL national mature-and-old-growth product (Bruening et al. 2026, old-growth stratum). We deliberately restricted the cross-map comparison to independent remote-sensing products: the USFS TreeMap imputation (Riley et al. 2021), although wall-to-wall, is a k-nearest-neighbor imputation of the same FIA plots and so is a second FIA-anchored accounting, reported alongside the design-based estimate rather than as an independent map. We computed each map's any-LSOG area, pairwise Cohen's kappa and Jaccard agreement, the number of maps agreeing per cell (0-3) as an agreement surface, and the overlap of the top-priority protected sets (top 5-20% of hectares) between the Hagan and canopy-height maps. As external checks we cross-validated the FIA proxy against the Pelz et al. (2023) USFS Eastern Region old-growth criteria on National Forest System plots, and we report the Seven Islands plot-level cross-validation.

### 2.7 Drivers and continuity

To characterize where LSOG sits in the working landscape, we related plot-level LSOG status to a CONUS harvest-probability model and to terrain slope, and we summarized the Landsat continuity layer by LSOG class. These analyses are descriptive and are reported briefly; they motivate the policy discussion rather than test a hypothesis.

### 2.8 Reproducibility

All code is at github.com/holoros/lsog-ne and the analyses ran on the OSC Cardinal cluster (`/users/PUOM0008/crsfaaron/LSOG/`). The master analytical artifact is `output_unified/lsog_ne_plot_table.csv`, and all derived products are archived at Zenodo (concept DOI 10.5281/zenodo.20614496).

---

## 3. Results

### 3.1 Regional context: older forest with intervals

Under the integrated v5.1 proxy, Maine carries the lowest combined LSOG share in the four-state core at 14.1% (95% CI 12.9-15.3), against 31.2% (28.0-34.3) in New Hampshire, 28.8% (25.4-32.3) in Vermont, and 27.2% (25.2-29.0) in New York; Maine's interval does not overlap any neighbor's (Table S2). New York carries the highest old-growth-class share (1.5%), consistent with the Adirondacks. By the design-based ground criteria, Maine older forest is 12.1% [10.9, 13.2] at stand age >= 100 yr, 3.9% [3.3, 4.6] at >= 120 yr, and 0.7% [0.4, 1.0] at >= 150 yr, with large-tree basal area at 12.5% [11.4, 13.7] (Table 1). These intervals, absent from map-only accounts, are the appropriate unit for high-stakes use.

### 3.2 The axes rank states differently

The integrated "Maine lowest" result does not hold on every axis, and that is the point. On the stand-age >= 120 yr criterion, Maine (3.9% [3.3, 4.6]) actually exceeds New Hampshire (1.8% [0.9, 2.6]) and Vermont (1.0% [0.4, 1.6]); on the live-structure (large-tree basal area) axis, however, Maine is the lowest in the region at 12.5%, far below New Hampshire (37.9%), Vermont (39.1%), and the southern New England states (47-58%) (Table S3). Maine thus has comparatively old forest that lacks large-tree structure, a signature of long-managed stands, while its neighbors have younger forest on more productive sites carrying more large-tree structure. Because the axes disagree on the ranking, no single-axis number is a sufficient summary, and the integrated proxy that combines them is what produces the "Maine lowest" headline (Fig. 5).

### 3.3 LSOG attributes are genuinely multidimensional

The correlation structure confirms separable axes. Large-tree basal area, large-tree count, quadratic mean diameter, and diameter diversity are tightly intercorrelated (r = 0.74-0.98), forming a coherent live-structure axis, but standing dead basal area (r = 0.38-0.51 with the live-structure cluster) and coarse woody debris (r = 0.23-0.48) load only weakly on it (Table S4). The first principal component captures 58.8% of variance and the second 13.8%; four components are needed to reach 91% (Table S4). A one-axis (canopy or live-structure) classifier therefore discards the dead-wood and continuity information that the four-axis definition retains, which is the mechanistic reason canopy-based maps register big-tree forest rather than old-growth.

### 3.4 The four-axis funnel: how much is "true" LSOG

Requiring more axes sharply reduces the qualifying share, and the reduction differs by state (Table 2, Fig. 2). Across all four states 84-96% of forest passes at least one axis, but only a small fraction passes all four, which we treat as *true LSOG*: 3.1% (95% CI 2.5-3.7) in Maine, 12.8% (10.7-15.0) in New Hampshire, 15.2% (12.7-17.6) in Vermont, and 12.2% (11.1-13.4) in New York. The headline is therefore not a single percentage but a curve, and the same forest is anywhere from 3% to over 90% LSOG depending on how many axes a definition requires.

The state ordering at the all-four threshold is driven by the two axes that vary most. Live structure is the scarcest axis everywhere (passing 12.5% of forest in Maine versus 38-39% in the other states), and the Landsat continuity axis is markedly tighter in Maine: it passes 40.1% of Maine forest against 54.7% in New Hampshire, 67.4% in Vermont, and 70.1% in New York. Maine is the only state where recent disturbance rivals live structure as the limiting axis (continuity missing in 22.7% of Maine near-misses, against 13-23% elsewhere). This is the working-forest signal the new axis exposes: by design-based estimation 74.4% of Maine forest carries Landsat-detected stand-replacing or harvest disturbance since 1985 (95% CI 71.9 to 76.9), at a median 12 years ago, versus 50.0% in New Hampshire (45.7 to 54.2), 36.8% in Vermont (32.7 to 40.9), and 30.4% in New York (28.6 to 32.1) (Fig. 2b). Maine's low true-LSOG share is thus as much a continuity result, reflecting active management, as a structural one.

The true-LSOG estimates are robust to how the continuity axis is drawn (Table 5). Across five definitions, varying the disturbance-class set (all heavy classes, stand-replacing only, or any detected loss), the time window (the full 1985-2023 record or only the last 20 years), and the spatial buffer (a 3 x 3 focal maximum or the plot pixel alone), Maine true LSOG ranges from 3.1% to 5.2%, New Hampshire from 12.6% to 18.8%, Vermont from 15.0% to 18.8%, and New York from 12.1% to 15.0%. The base definition (full record, heavy classes, focal buffer) is the most conservative; relaxing any one choice raises the share modestly, and broadening the class set to any detected loss barely changes it because canopy-removing causes already dominate detection. Most important, the regional ordering is invariant: Maine is the lowest state under every definition, at roughly a third to a quarter of its neighbors. The conclusion that true LSOG is rare and lowest in Maine does not depend on the particular continuity threshold.

### 3.5 Cross-map assessment: credible maps disagree

The three remote-sensing classifications disagree substantially over the study area (Table 3, Fig. 3). The two structure-resolution maps differ 1.6-fold in extent: any-LSOG covers 14.0% under the canopy-height map and 21.9% under the Hagan LiDAR classifier, and they overlap only modestly (Cohen's kappa 0.22). These map percentages are fractions of forested hectares on the common comparison grid; the published LiDAR map reports its three LSOG classes as 15.8% Transitioning LS, 3.0% LS, and 0.9% old-growth-like, totaling 19.7% of the full study area (Hagan et al. 2026, Table 7). Adding the ORNL old-growth stratum, a coarser continental product that flags 36.1% (its mature-plus-old-growth stratum reaches 65%), widens the range to 2.6-fold and collapses the agreement: only 2.7% of the hectares flagged by any map are flagged by all three, and 73% by a single map. The ORNL stratum shares little spatial information with either structure map (kappa near zero); rather than evidence that one structure map is wrong, this is a cross-scale caution that a continental old-growth product and a state airborne-LiDAR product, each credible in its own domain, identify largely different ground. Read against the ground, every FIA-anchored accounting sits at or below the airborne-LiDAR map: the design-based integrated any-LSOG is 14.1% [12.9, 15.3] and the strict four-axis true-LSOG estimate is 3.1% [2.5, 3.7] (Section 3.1), and the TreeMap FIA imputation gives 7.8%. For prioritization the consequence is direct: the overlap of the top-priority protected sets selected by the Hagan versus the canopy-height map is only 0.16-0.30 (Jaccard) for the top 5-20% of hectares, so 70-84% of the prioritized ground differs depending on which equally defensible map is used.

### 3.6 External validation: the OG class is product-specific

Against the Pelz et al. (2023) USFS criteria on 925 Northeastern NFS plots, the integrated proxy achieves fair agreement on the combined LS+OG class (Cohen's kappa 0.25) but near-random agreement on the OG-only class (kappa 0.04), the latter driven by the small absolute number of OG plots. The Seven Islands plot-level cross-validation over Pingree (125 in-extent latest-panel plots) likewise shows reasonable share-level agreement but near-random plot-by-plot agreement at every class boundary (kappa near zero), because the LiDAR and FIA products measure genuinely different signals on heavily managed timberland: LiDAR canopy metrics register skid-trail and partial-harvest gaps that FIA tree-level data may miss, while the FIA proxy weights tree-level attributes that change after partial harvest even where the residual canopy stays tall. Across products, OG-share estimates differ several-fold; the LS+OG combined class is the stable unit for policy reporting.

### 3.7 Trend: stock stable to rising, flux notwithstanding

Older-forest stock increased across the operational age and structure measures over 2003-2024, with confidence intervals excluding zero: stand age >= 100 yr at +0.19%/yr [0.15, 0.23], >= 120 yr at +0.065%/yr [0.054, 0.075], and large-tree basal area at +0.17%/yr [0.15, 0.18], while total forestland area was flat (Table 1, Fig. 4). The oldest class is the exception: the statewide age >= 150 yr trend is indistinguishable from zero. The northern units show the same increases; only the oldest class (age >= 150 yr) in the north declines slightly (-0.019%/yr [-0.031, -0.008]). This coexists with the reported gross loss of mapped LSOG (1.37%/yr overall, 2.19%/yr on commercial timberland): stands are harvested while aging more than replaces the hectares removed. The two statements describe a gross flux and a net stock and should not be conflated. The net-stock increase is present on the large-tree basal-area measure alone (+0.17%/yr [0.15, 0.18]), which uses no age assignment, so the stable-to-rising stock result does not rest on FIA stand age.

### 3.8 Where LSOG sits in the working landscape

LSOG occurrence rises with both modeled harvest probability and terrain slope. The LSOG rate is 13.1% on the lowest harvest-probability tercile, 24.1% on the middle, and 33.5% on the highest; and 11.8%, 21.7%, and 37.3% across low, medium, and high slope terciles (Table S5). The picture is two-sided: mapped LSOG sits disproportionately on the most merchantable ground yet also on steeper terrain that raises harvest cost and logistics. We read the terrain association cautiously and do not treat disturbance-proneness as a basis for discounting these stands, because in the predominantly partial-disturbance regime of this region a stand can experience harvest or windthrow and still retain much of its late-successional structure, unlike the stand-replacing fire regimes of western or boreal systems. The continuity axis is therefore better understood as a record of management history than as a forecast that disturbed stands will fail to persist. Consistent with that axis (Sections 2.3a, 3.4), LSOG plots are disturbed in the Landsat record at lower rates than non-LSOG forest, so most but not all mapped LSOG carries intact recent continuity; the share that fails the continuity test is highest in Maine, where active management is most extensive.

### 3.9 Representation of true LSOG across forest types and ecoregions

Pooling the four states, true LSOG (all four axes) is present in seven of the eight forest-type groups in the region, but its abundance varies more than thirtyfold among them (Table S6). The largest absolute pools are in the most extensive types: northern hardwood (maple-beech-birch) holds 2.68 million acres of true LSOG at an 11.6% rate, and the white-red-jack pine type holds 0.72 million acres at the highest rate of any group, 21.2%. The oak-pine and oak-hickory types contribute another 0.54 million acres combined. The spruce-fir type, often treated as the signature Acadian LSOG forest, carries a much smaller share (2.1%, 0.15 million acres), and the aspen-birch and elm-ash-cottonwood types carry almost none. Representation is therefore broad but highly uneven: the late-successional condition occurs across nearly all forest types in the region, but it is concentrated in the northern hardwood and pine types and is thin in the early-successional and some softwood types.

Spatially joining the FIA plots to EPA Level III ecoregions gives the same picture geographically (Table 4). True LSOG is present in all nine ecoregion sections that hold at least 50,000 acres of forest in the four-state region, but it concentrates strongly: the Northeastern Highlands, the mountainous northern-hardwood region spanning western Maine, New Hampshire, Vermont, and the Adirondacks, hold 2.99 million acres of true LSOG at a 12.5% rate, more than the rest of the region combined. The Northern Allegheny Plateau (0.50 million acres, 9.2%) and the Northeastern Coastal Zone (0.17 million acres, 9.4%) carry intermediate shares. The Acadian Plains and Hills, the glaciated lowland that is the core of Maine's industrial timberland, carries the lowest share of any major ecoregion at 2.1% (0.19 million acres) despite covering 8.9 million acres of forest. The representation pattern, rather than any single state's aggregate share, is the appropriate target for a regional late-successional strategy.

### 3.10 Independent validation against ecological reserves

We validated the classification against the Maine ecological reserve network (Maine Natural Areas Program and The Nature Conservancy): 1,109 precisely located monitoring plots across 36 protected reserves that include Big Reed Forest Reserve, the largest old-growth in New England, and that no map in this comparison used for training. Three findings follow.

First, the structural criteria do identify the reserves. At Big Reed's 25 plots, our four-axis call flags 72% as LSOG under forest-type-specific criteria (Wilson 95% CI 52 to 86), against the reproduced Hagan map's 80% (61 to 91) at the same coordinates; the intervals overlap heavily at this sample size, so the two are statistically indistinguishable at Big Reed. Across 819 reserve plots within the Hagan study area, our criteria flag 67% (64 to 70) and the Hagan map 57% (54 to 60), a difference whose intervals do not overlap. Neither map flags every reserve plot, because old-growth structure is heterogeneous even within reserves. The impression that a plot-based map "misses" Big Reed is an artifact of FIA plot density and coordinate fuzzing rather than the criteria: no FIA plot falls within the 5,000-acre reserve, and the 24 nearest public plots reach only 127 years of stand age.

Second, a single structural threshold misclassifies low-stature old-growth. Under our original type-agnostic large-tree basal-area threshold, 32% of reserve plots pass the live-structure axis; under the externally published, vegetation-type-specific large-tree-count criteria of Pelz et al. (2023), 67% pass, and spruce-fir, which is 53% of the reserve network, rises from 29% to 68%. The binding bias is a single high diameter cutoff applied across forest types, which misses the spruce-fir and cedar old-growth that is old and continuous but never large-statured; type-specific criteria, calibrated against the reserves with hold-out validation, resolve it. A higher-resolution canopy-height product cannot recover this, because low-stature old-growth is short.

Third, the wall-to-wall area is sensitive to the classifier, and the sensitivity has a root cause in the training design. The published map's training hectares were selected purposively, anchored on known older stands (Big Reed was the authors' primary old-growth source), so the rare late-successional and old-growth classes make up roughly a fifth of the training hectares against 3.9% of the mapped area, and the random forest was fit without class weighting; its operating point and implied prevalence are therefore not anchored to the landscape's true class frequencies. A menu of standard rare-class remedies all points the same way (Table S9): class weighting through randomForest's classwt is weak (old-growth recall 0.24 to 0.29), but balanced subsampling (the equivalent of imblearn's BalancedRandomForestClassifier) raises old-growth operating accuracy from 23.5% to 70.6% and a lowered voting threshold raises it to 82%, in both cases roughly doubling the mapped old-growth area (109,000 to 192,000 acres) at negligible cost to overall accuracy (0.87 to 0.84). A representative or design-based probability sample, balanced across LSOG and non-LSOG, is the appropriate basis for an unbiased areal estimate, and independent field references that contain true old-growth (the ecological reserves and the Baxter inventory) are the appropriate basis for verification, including the old-growth class the published field validation did not sample. The headline conclusions of this study survive a full battery of analytical perturbations, summarized in Table S10. Fusing our LCMS Landsat-disturbance layer with canopy height improves a two-predictor balanced wall-to-wall model's discrimination of the structural definition (cross-validated AUC 0.61 to 0.67); adding modern multi-source satellite embeddings raises discrimination substantially further, to about 0.87 (Section 4.1 and companion report), yet even that fused model remains short of what a rare-class area estimate requires, which reinforces design-based plot estimation, rather than any single map, as the appropriate backbone for area accounting.

Fourth, coordinate fuzzing accounts for much of the apparent plot-level disagreement. Using true FIA plot coordinates rather than the public fuzzed coordinates more than doubles the cross-map agreement between the FIA proxy and the Hagan map (Cohen's kappa 0.13 to 0.29 for any-LSOG on 1,737 plots). Roughly half the plot-level disagreement reported in earlier single-ownership cross-validations therefore reflects the kilometre-scale location error in public FIA data, not genuine classifier disagreement, and the same artifact explains why a sparse, fuzzed inventory appears to "miss" a small reserve like Big Reed.

---

## 4. Discussion

### 4.1 Reframing LSOG accounting from a number to a range

The central methodological result is that the honest answer to "how much LSOG" is a range with its definition and its sampling interval attached. The four-axis funnel makes the definitional component explicit: the same Northeastern forest is 6% true LSOG under a four-axis requirement and over 90% under a one-axis continuity requirement, a regional, design-based counterpart to the national definitional sensitivity that the Forest Inventory Growth Stage System reports for federal land (Woodall et al. 2023). The design-based intervals make the sampling component explicit: Maine older forest is 3.9% [3.3, 4.6] at age >= 120 yr, not a single point. Reporting a single percentage, whatever its source, conceals both. The need for a state-targeted design-based estimate is underscored by the federal mature-and-old-growth threat analysis (USDA and USDI 2024), which could not statistically resolve eastern old-growth at the national scale "because there were few or no FIA plots"; a probability sample concentrated on the region of interest, reported with its interval, is the appropriate unit precisely where the resource is rare. The objection that FIA lacks the resolution to identify LSOG conflates two different resolutions. FIA does lack the spatial resolution to locate an individual old stand, with roughly one plot per 2,400 ha and coordinates fuzzed for landowner privacy; but locating stands is a mapping task, not an estimation task. For the population quantity in question, the area of LSOG within a defined region, the design-based estimator is unbiased by construction, and rarity widens its confidence interval without biasing the point estimate. The continental analysis ran short of plots because a national stratification spreads them thin; a region-targeted sample does not, supplying several thousand Maine plots and resolving even the age >= 150 yr class to 0.7% [0.4, 1.0]. A wall-to-wall map does not escape this rarity, it conceals it: fit to a non-representative training sample without class balancing, its rare-class area is both biased and reported without an interval, so its finer grain buys spatial detail rather than a better-resolved total. Two clarifications guard against over-reading the refined classification: the four-axis definition is offered as a sensitivity device that brackets how the qualifying share depends on how many axes are required, not as a replacement truth, and the stable unit we recommend for policy is the combined LS+OG class rather than the strict four-axis number. Consistent with the inventory-first conclusion, even improved remote sensing does not displace the design-based estimate for this target: in cross-validation on the true-coordinate plots (companion technical report, Weiskittel 2026), an open Sentinel-based satellite-embedding model (TESSERA) discriminates the multi-axis class at an area-under-curve near 0.82 and a fusion of multiple modern sources reaches about 0.87, both well above a single coarse canopy-height layer (near 0.67 to 0.70) but still short of the precision a rare-class area estimate requires, so the limitation is general to remote sensing rather than specific to any one map. For policy use, the combined LS+OG class is the most stable category across both definitions and products; the OG-only class is genuinely product-specific and should always carry uncertainty bounds. This reframing also fixes the direction of inference between maps and inventory. For the amount of LSOG, the design-based estimate from the FIA probability sample is the reference quantity, carrying a known and quantifiable sampling error, that a wall-to-wall map of the same attribute is obliged to reproduce; a map is not corrected by its own internal accuracy, and when it departs from the design-based total the discrepancy is a property of the map, with the burden on the map to reconcile with the inventory rather than the reverse. The map's irreplaceable role is spatial allocation, indicating where the inventory total most likely sits, not the total itself.

### 4.2 Why credible maps disagree, and what to do about it

The cross-map assessment shows that high training accuracy does not produce map agreement: three operationalizations that each fit their labels well place LSOG in amounts spanning a 1.6-fold range between the two structure maps and 2.6-fold once the coarser continental product is included, and they agree on only 2.7% of the flagged footprint. This is not a defect of any one map; it follows from LSOG's multidimensionality (Section 3.3) and from each map emphasizing different axes. A fully like-for-like test sharpens the point. We regenerated the published LiDAR classification from its own archived inputs, training the random forest on the 463 known-class training hectares and applying it to the public hectare-level LiDAR canopy statistics for all 4.28 million hectares of the study area; this reproduces the published extent to within about two percentage points (any-LSOG 22.0% against the reported 19.7%, LS+OG 4.3% against 3.9%); the small residual reflects our use of default random-forest settings and grid alignment rather than the authors' exact configuration, while the random forest, the eight canopy predictors, and the training labels are theirs. We then thresholded the FIA-anchored 10 m embedding surface to flag the identical landscape fraction, so that the residual difference in amount is removed and any disagreement is about location alone. At matched prevalence (about 21.5% any-LSOG), the reproduced classifier and the embedding map agree on only 7.7% of the landscape, with 13.7% flagged by the reproduced classifier alone and 13.7% by the embedding map alone, for a Cohen's kappa of 0.19; the same comparison on the Seven Islands ownership against the authors' own map gives kappa 0.24. Neither map is ground truth, and this is not a claim that either locates LSOG correctly; it isolates the locational uncertainty that persists when two independent methods are forced to agree on the amount, and it is a lower bound, since a third credible method would only add disagreement. That the two maps perform comparably at independently located old-growth (Big Reed 72% versus 80%, the reserve network 67% versus 57%; Section 3.10) indicates the low kappa reflects genuine ambiguity in the working-forest matrix rather than one map being broadly wrong. Holding the amount fixed, two equally defensible maps place their late-successional and old-growth forest in substantially different locations. The practical implication for a $200-300 million prioritization is that the choice of map, not just the choice of parcels, drives most of the spending. We recommend that maps used for allocation be accompanied by an explicit cross-map agreement layer and field-verified at the parcel scale, as the original authors themselves advise for management decisions.

### 4.3 Maine's structural divergence reflects its working-forest history

The integrated proxy places Maine lowest in the region, and the axis decomposition shows this is jointly a structure and a continuity result rather than an age result. Maine has comparatively old forest that lacks large-tree structure, consistent with continuous management on rotations long enough to grow merchantable trees and short of the conditions that build large-tree, dead-wood-rich structure; and it carries the region's strongest recent-disturbance signal, with 74% of its forest showing Landsat-detected stand-replacing or harvest disturbance since 1985 (95% CI 72 to 77) against 30 to 50% in its neighbors. New Hampshire and Vermont, aging out of 19th-century abandonment, carry more large-tree structure and far less recent disturbance on younger stands; New York's Adirondacks preserve the regional old-growth concentration. The pattern is not a deficiency to be corrected state by state but a coherent regional division of forest function, which we develop next.

### 4.3a A regional triad, not a per-state deficit

The Northeast functions as a landscape-scale triad in the sense of Seymour and Hunter: a mosaic of intensively managed production forest, extensively managed forest, and reserves, with the three roles distributed unevenly among states. Maine's heavily worked timberland anchors the production tier; the aging old-field forests of New Hampshire and Vermont and the Adirondack reserves of New York carry a disproportionate share of the late-successional and reserve tiers. Under a triad framing, Maine's low true-LSOG share is the expected signature of its role, not evidence that Maine should be made to match its neighbors hectare for hectare. The conservation-relevant question is therefore not whether each state reaches parity but whether true LSOG is adequately represented across the region's forest types and ecoregions, so that the late-successional tier of the triad spans the full range of ecological conditions rather than concentrating in a few. Our representation analysis (Section 3.9) speaks to this directly: true LSOG is present in seven of the eight forest-type groups in the region, but its abundance varies more than thirtyfold among them. The largest absolute pools sit in the northern hardwood (maple-beech-birch) type, which carries 2.7 million acres of true LSOG at an 11.6% rate, and the white-red-jack pine type (0.7 million acres, 21.2%), while the iconic spruce-fir type carries a much smaller share (2.1%) and the aspen-birch and elm-ash-cottonwood types almost none. Representation is broad across types but highly uneven, and the under-represented types, rather than Maine's aggregate share, are where a regional late-successional strategy should focus. The same holds across ecoregions: spatially joining the plots to EPA Level III ecoregions, true LSOG is present in all nine ecoregion sections of the four-state region but concentrates in the Northeastern Highlands, which hold 3.0 million acres at a 12.5% rate, while the Acadian Plains and Hills, the heart of Maine's industrial forest, carry the lowest share at 2.1%. The triad is thus visible on the ground: the highlands anchor the late-successional tier and the Acadian lowlands the production tier.

### 4.4 The dead-wood blind spot and the limiting axis

That live structure is the limiting axis in 84% of failures, and that dead wood loads separately from live structure, together explain why canopy- and height-based classifications over-include relative to structural definitions. Such classifiers read tall continuous canopy whether it is produced by an old complex stand or a fast-growing young one, and they are largely blind to the dead-wood component that distinguishes old-growth. A classification intended to identify true LSOG, rather than big-tree forest, must measure the dead-wood and continuity axes directly, which is the design rationale for the four-axis definition. The same blind spot reaches into the field protocol behind the LiDAR map: in the random-forest classifier of the RAP v2.0 rapid-assessment protocol (Shamgochian et al. 2025), large standing dead trees rank last of seventeen metrics in importance and large downed logs thirteenth, while harvest-history evidence (sawn stumps, skid trails) ranks among the strongest predictors. Dead wood is thus under-weighted not only by canopy LiDAR but by the field instrument used to train it, whereas the harvest-history signal it relies on is precisely what an explicit temporal-continuity axis captures from the disturbance record. A second, related limitation of any one-size-fits-all classification is definitional rather than instrumental: because old-growth structure differs by forest type, a universal threshold tuned to tall, large-diameter hardwood and pine systematically misses the low-stature spruce-fir, northern white-cedar, and peatland old-growth that never attains that signature (Section 3.10). The criteria should therefore be ecoregion- and forest-type-specific, calibrated to reference stands within each type, rather than assumed to follow a single universal definition; Maine's own documented old-growth inventory, organized across seven forest types each with a distinct age and size signature (Maine State Planning Office 1983), is direct evidence that no such universal signature exists.

### 4.4a From a single threshold to a multi-objective product

The mapping problem is multi-objective, and treating it as single-objective is the root of the rare-class failure. A classifier that minimizes one scalar loss attenuates the rare, high-value old-growth class (Section 3.10), and any single probability threshold then trades detection against area: on our balanced canopy-plus-disturbance model, a default 0.5 cut over-predicts (mapped prevalence 40%, exceeding even the original LiDAR map), while calibrating the threshold to the design-based area controls over-prediction only at the cost of sensitivity. No single cutpoint achieves both. Two responses follow. First, the appropriate product is a probability surface, P(LSOG), which we render for Maine from the balanced canopy-plus-disturbance model and archive as a 100 m raster (Fig. 6), with any binary class calibrated to the design-based area rather than to an arbitrary threshold, so the omission-commission trade-off is explicit and over-prediction is bounded by the unbiased estimate; the surface is deliberately shown as a probability rather than a hard class, and its mean (0.54) reflects the balanced model's known tendency to over-predict, which is exactly why the binary cut is tied to the design-based area. Second, the estimator itself should be multi-objective: methods that jointly minimize total error and systematic (attenuation) error, such as the multi-objective support vector regression of Legaard et al. (2020), are designed for the rare, high-value tail that single-objective learners suppress, and are a natural direction for mapping LSOG. A pilot on the Maine plots makes the trade-off concrete. Fitting a support vector regression of the four-axis LSOG score on canopy height and disturbance time, and tracing the Pareto front of total error (root mean squared error) against systematic error (departure of the predicted-on-observed slope from unity), recovers the familiar pattern: the total-error-optimal solution attenuates the high end (regression slope 0.86, mean high-decile bias of more than three structural points) while a compromise solution on the same front cuts the systematic error by roughly 40% (slope 0.92, with negligible change in total error). Choosing the operating point on the front, rather than accepting whatever single-objective fitting returns, is what protects the rare class. The four-axis definition is already multi-objective at the structural layer, requiring the axes jointly rather than collapsing them to one optimized score.

Realized as a product, we ensemble five structurally different learners, a balanced random forest, a probability forest, a weighted logistic model, a support vector machine, and the multi-objective support vector regression, into a single LSOG probability surface for Maine and map the across-model standard deviation as an explicit uncertainty layer (Fig. 7). The five learners' mean mapped probabilities range from 0.26 to 0.59 (Table S8) and the mean across-model standard deviation is 0.18 on a 0-1 scale, so the choice of algorithm moves the answer nearly as much as the data do, and a single binary map conceals exactly that spread. A variance-based global sensitivity analysis attributes almost all of the explained variation in the ensemble probability to canopy height (first-order Sobol index near unity) with the Landsat disturbance axis a secondary contributor (Table S7), the quantitative statement of why a canopy-driven map resolves one axis and not the four. The honest product for allocation is therefore the probability surface with its uncertainty layer, calibrated to the design-based area, not a single binary class.

### 4.5 Limitations

First, the OG-class precision is low (near-random agreement against Pelz and Seven Islands at the plot level), and we do not over-interpret state-level OG percentages. Second, FIA coordinate fuzzing introduces ~30 m uncertainty at the canopy-height extraction; a Data Use Agreement for true coordinates would tighten dimension 6. Third, the three cross-map products are independent in sensor and method but not free of ground labels: Hagan trains on field plots, and the canopy-height model and the ORNL product train on FIA, so "independent" refers to predictors, training data, and target definition rather than to independence from FIA. The ORNL old-growth stratum is additionally a coarse continental product that flags a much broader area, and its near-zero spatial correlation with the structure maps should be read as a cross-scale caution rather than as proof that any structure map is wrong; the like-for-like disagreement between the two structure-resolution maps (1.6-fold, kappa 0.22) is the more directly comparable figure. Fourth, the wall-to-wall TreeMap layer, which we report on the design-based side rather than as a cross-map member, is a representative-plot FIA imputation that smooths rare classes, so its area is a lower bound. Fifth, the four-axis continuity criterion depends on the Landsat disturbance record's sensitivity and may under-detect light partial harvest; because it flags any canopy-removing disturbance of any intensity over the satellite era, it is conservative for stands subject to light single-tree selection, and the sensitivity analysis (Section 3.4, Table 5) brackets the resulting range. Sixth, the continuity axis is evaluated at the plot's single coordinate and applied to all conditions on that plot, whereas the structural axes are scored per condition, so a multi-condition plot inherits one continuity call; and the design-based estimator addresses sampling variance but not residual spatial autocorrelation among plots, which a spatially explicit model could incorporate in future work. Seventh, the analysis operates on the 1 ha grid of the published map, which is the decision unit but also a floor on spatial resolution: genuine old-growth in Maine persists largely as small remnants, the published map's own patches most commonly 1 to 5 ha, so a 1 ha classification under-resolves sub-hectare remnants by construction and cannot separate a small old patch from its matrix. This limit is shared by any 100 m product and is not relieved by the FIA-anchored approach, whose effective location is bounded not by the raster but by the up-to-1 km coordinate fuzzing of the plots; predicting our structural surface at 20 to 30 m would manufacture a precision the training labels do not carry. The instrument suited to sub-hectare remnants is high-resolution airborne LiDAR, which exists near 1 m and was aggregated to 1 ha here and in the published map by choice, paired with field plots at true coordinates, the design we propose for validation rather than for another wall-to-wall classification. Eighth, the mapped LSOG fraction itself depends on the prediction grain. Aggregating a 10 m v6 probability surface over a Big Reed and Baxter showcase to progressively coarser cells lowers the flagged LSOG share monotonically, from 22.0% at 10 m to 17.5% at the 1 ha grid the published map uses and 14.9% at 200 m. This decline reflects the interaction of grain with a fixed probability threshold, since averaging a probability surface to coarser cells pulls values toward the mean so that fewer cells clear a fixed cutoff; its direction and magnitude therefore depend on the aggregation-then-threshold rule, not on older forest alone, and we report it not as an intrinsic property of LSOG but to make the operational point that a mapped percentage is uninterpretable without its grain and thresholding rule attached. The published map fixed the hectare as its modeling scale, averaging the 1-m^2 LiDAR canopy metrics to the hectare before a single hectare-scale classification (Hagan et al. 2026), and did not test how the mapped LSOG fraction responds to grain; finer within-hectare old patches are therefore averaged into their matrix before any class is assigned. This modifiable-areal-unit behaviour is well documented for LiDAR area-based estimation in these same northeastern mixed-species, multicohort forests (Hayashi et al. 2016): area-based estimates shift systematically with prediction cell size. A single LSOG percentage at one grain is therefore not directly comparable to another, and any cross-map or map-versus-inventory comparison must hold resolution fixed, which is a further reason to anchor the amount on the design-based inventory rather than on a map reported at a single chosen cell size.

### 4.6 Implications for policy

For Maine, the LD 1529 working group should know that the state has the lowest integrated LSOG share in the region, that the net older-forest stock is stable to rising rather than collapsing, that the qualifying share depends strongly on definition, and that any single map should be cross-checked before it steers acquisition. Read through a triad lens, Maine's low share reflects its production role in a regional division of forest function rather than a deficit to be closed within the state; the regional objective is adequate representation of the late-successional condition across forest types and ecoregions, which our results show is broad but uneven (Sections 3.9, 4.3a). The most acreage-relevant levers are therefore the under-represented forest types and the private-land LS+OG pool that holds most of the regional acreage; payment-for-ecosystem-services arrangements, working-lands easements, and targeted reserve placement in under-represented types all bear on them. Because private owners hold the large majority of the region's older-forest acres, accurate, uncertainty-aware maps matter for conservation planning on those lands as much as for any fee acquisition, and the dominance of that ownership is itself why creative regional planning, rather than per-state acquisition, is the appropriate frame. The master plot table provides the analytical foundation to quantify each option.

### 4.7 Relationship to the Comment and future work

A short Comment on Hagan et al. (2026) presents the cross-map disagreement, dead-wood blindness, and design-based baseline as a focused critique; this manuscript is the constructive companion that builds the multi-axis classification and the full assessment that the Comment points toward. Immediate extensions include integrating the full Maine unorganized-townships LiDAR raster when accessible, extending the four-axis classification to wall-to-wall mapping of each axis, pursuing true plot coordinates, and linking LSOG class to wood-quality and harvest-economics outcomes for a direct working-forest-economy linkage. A further priority is to widen the true-old-growth reference base beyond Big Reed: the State's Critical Areas Program field-checked 104 stands and documented 68 recommended natural old-growth stands across seven forest types (hemlock, red and white spruce, white and red pine, cedar, oak, and hardwoods), with the strict confirmed old-growth documented as fifteen stands on 1,553 acres of State land, concentrated in Baxter State Park (7 stands, 889 acres) and the T.15 R.9 Deboullie unit (5 stands, 607 acres) within the northern study area, plus extensive subalpine old forest in Baxter and on public land (Maine State Planning Office 1986). Georeferencing these independently documented stands gives the validation a set of true old-growth anchors that does not trace to a single reserve, and the inventory's organization by forest type underscores that old-growth structure, and therefore any defensible LSOG definition, is forest-type-specific rather than universal.

---

## 5. Conclusion

Across the Northeast, the amount of LSOG forest is best expressed not as a single number but as a method range with design-based intervals, and the location of LSOG is genuinely uncertain across credible maps. The four-axis funnel shows that only about 6% of regional forest qualifies as LSOG on all axes while over 90% qualifies on at least one, with live structure the limiting axis; the qualifying share ranges from 3.1% in Maine to 12-15% in the other three states. Maine carries the lowest integrated LSOG share in the region, a structure result rather than an age result, and the net older-forest stock is stable to rising even as mapped LSOG is lost to harvest and disturbance. Three remote-sensing maps disagree 1.6-fold in extent between the two structure maps and 2.6-fold once a coarser continental product is added, and agree on only 2.7% of the flagged footprint, so the choice of map drives most of the spending it informs. Underlying these recommendations is a simple ordering: for the amount of LSOG, the design-based estimate from the probability sample is the benchmark a wall-to-wall map must reproduce, and a map that disagrees with it carries the burden of reconciliation, not the inventory. We recommend reporting a method range with design-based intervals, treating LS+OG as the stable policy unit, and reconciling and field-verifying maps against independent inventory before they anchor acquisition.

---

## Literature Cited

Barnett, K., G.H. Aplet & R.T. Belote. 2023. Classifying, inventorying, and mapping mature and old-growth forests in the United States. Frontiers in Forests and Global Change 5:1070372. https://doi.org/10.3389/ffgc.2022.1070372

Bechtold, W.A. & P.L. Patterson (eds.). 2005. The enhanced Forest Inventory and Analysis program: national sampling design and estimation procedures. USDA Forest Service General Technical Report SRS-80.

Bruening, J.M., P.B. May, R.O. Dubayah, L. Wertis, C. Quinn, N. Pederson, A.H. Armstrong & B. Poulter. 2026. Mature and old-growth forest probability maps for the conterminous United States. ORNL DAAC, Oak Ridge, Tennessee, USA. Dataset 2498. https://doi.org/10.3334/ORNLDAAC/2498

DellaSala, D.A., B. Mackey, P. Norman, C. Campbell, P.J. Comer, C.F. Kormos, H. Keith & B. Rogers. 2022. Mature and old-growth forests contribute to large-scale conservation targets in the conterminous United States. Frontiers in Forests and Global Change 5:979528. https://doi.org/10.3389/ffgc.2022.979528

Gray, A.N., K. Pelz, G.D. Hayward, T. Schuler, W. Salverson, M. Palmer, C. Schumacher & C.W. Woodall. 2023. Perspectives: the wicked problem of defining and inventorying mature and old-growth forests. Forest Ecology and Management 546:121350. https://doi.org/10.1016/j.foreco.2023.121350

Hagan, J.M., B. Shamgochian, M.M.L. Taylor & J.M. Reed. 2026. Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA. Ecosphere 17(6):e70670. https://doi.org/10.1002/ecs2.70670

Hayashi, R., A. Weiskittel & J.A. Kershaw, Jr. 2016. Influence of prediction cell size on LiDAR-derived area-based estimates of total volume in mixed-species and multicohort forests in northeastern North America. Canadian Journal of Remote Sensing 42(5):473-488. https://doi.org/10.1080/07038992.2016.1229597

Lang, N., W. Jetz, K. Schindler & J.D. Wegner. 2023. A high-resolution canopy height model of the Earth. Nature Ecology & Evolution 7:1778-1789. https://doi.org/10.1038/s41559-023-02206-6

Legaard, K., E. Simons-Legaard & A. Weiskittel. 2020. Multi-objective support vector regression reduces systematic error in moderate resolution maps of tree species abundance. Remote Sensing 12:1739.

Maine Natural Areas Program and The Nature Conservancy. 2024. Ecological Reserve Monitoring Program plot data, Maine. Maine Natural Areas Program, Augusta, Maine, USA (provided under data-use agreement).

Maine State Planning Office. 1983. Natural old-growth forest stands in Maine and its relevance to the Critical Areas Program. Planning Report Number 77, Maine Critical Areas Program, Augusta, Maine, USA.

Maine State Planning Office. 1986. Uncut timber stands and unique alpine areas on State lands. Critical Areas Program, Maine State Planning Office, Augusta, Maine, USA.

Pelz, K.A., G. Hayward, A.N. Gray, E.M. Berryman, C.W. Woodall, A. Nathanson & N.A. Morgan. 2023. Quantifying old-growth forest of United States Forest Service public lands. Forest Ecology and Management 549:121437.

Potapov, P., X. Li, A. Hernandez-Serna, A. Tyukavina, M.C. Hansen, A. Kommareddy, A. Pickens, S. Turubanova, H. Tang, C.E. Silva, J. Armston, R. Dubayah, J.B. Blair & M. Hofton. 2021. Mapping global forest canopy height through integration of GEDI and Landsat data. Remote Sensing of Environment 253:112165.

Riley, K.L., I.C. Grenfell, M.A. Finney & J.M. Wiener. 2021. TreeMap, a tree-level model of conterminous US forests circa 2014 produced by imputation of FIA plot data. Scientific Data 8:11. https://doi.org/10.1038/s41597-020-00782-x

Seymour, R.S. & M.L. Hunter Jr. 1999. Principles of ecological forestry. Pages 22-61 in M.L. Hunter Jr., editor. Maintaining Biodiversity in Forest Ecosystems. Cambridge University Press, Cambridge, UK.

Shamgochian, B., J. Hagan, M. Taylor & M. Reed. 2025. LSOG Rapid Assessment Protocol (RAP) for Maine (v2.0). Our Climate Common, Georgetown, Maine, USA. 36 pp.

Stanke, H., A.O. Finley, A.S. Weed, B.F. Walters & G.M. Domke. 2020. rFIA: An R package for estimation of forest attributes with the FIA database. Environmental Modelling & Software 127:104664.

Thompson, J.R., A. Daigneault, J. Plisinski, I. Moon & J. Norton. 2026. Pathways for protecting Maine's remaining late-successional and old-growth forests. Property and Environment Research Center, Bozeman, Montana, USA. 86 pp.


U.S. Executive Order 14072. 2022. Strengthening the Nation's Forests, Communities, and Local Economies. The White House, Washington, D.C., 22 April 2022.

USDA Forest Service and USDI Bureau of Land Management. 2023. Mature and old-growth forests: definition, identification, and initial inventory on lands managed by the Forest Service and Bureau of Land Management. U.S. Department of Agriculture and U.S. Department of the Interior, Washington, D.C.

USDA Forest Service and U.S. Department of the Interior, Bureau of Land Management. 2024. Mature and old-growth forests: analysis of threats on lands managed by the Forest Service and Bureau of Land Management in fulfillment of Section 2(c) of Executive Order No. 14072. FS-1215c. Washington, DC, USA.

USDA Forest Service. 2024. Landscape Change Monitoring System (LCMS), CONUS version 2024-10. USDA Forest Service Geospatial Technology and Applications Center, Salt Lake City, UT. https://data.fs.usda.gov/geodata/LCMS/

Weiskittel, A.R. 2026. Late-successional and old-growth forest across northern New England: what the inventory shows, and the limits of LiDAR-based mapping. Technical report to the Maine Forest Products Council, Center for Research on Sustainable Forests, University of Maine.

Woodall, C.W., A.G. Kamoske, G.D. Hayward, T.M. Schuler, C.A. Hiemstra, M. Palmer & A.N. Gray. 2023. Classifying mature federal forests in the United States: the forest inventory growth stage system. Forest Ecology and Management 546:121361. https://doi.org/10.1016/j.foreco.2023.121361

---

## Tables

**Table 1.** FIA design-based older-forest area, Maine, 2024 (95% CI) and 2003-2024 trend.

| Ground criterion | Statewide % [95% CI] | Northern units % [95% CI] | Trend (%/yr) [95% CI] |
|---|---|---|---|
| Stand age >= 100 yr | 12.1 [10.9, 13.2] | 12.2 [10.7, 13.7] | +0.19 [0.15, 0.23] |
| Stand age >= 120 yr | 3.9 [3.3, 4.6] | 4.2 [3.3, 5.1] | +0.065 [0.054, 0.075] |
| Stand age >= 150 yr | 0.7 [0.4, 1.0] | 0.6 [0.2, 1.0] | +0.000 [-0.005, 0.006] |
| Large-tree BA >= 30 ft^2/ac | 12.5 [11.4, 13.7] | 9.8 [8.4, 11.2] | +0.17 [0.15, 0.18] |

**Table 2.** Four-axis LSOG funnel by state (design-based % of forestland), with the LCMS continuity axis. "% disturbed since 1985" is the share of forest with Landsat-detected stand-replacing or harvest disturbance in the LCMS record.

| State | >= 1 axis | >= 2 axes | >= 3 axes | true LSOG (all 4) [95% CI] | A4 continuity alone | % disturbed since 1985 |
|---|---|---|---|---|---|---|
| Maine | 83.8 | 48.8 | 18.4 | 3.1 [2.5, 3.7] | 40.1 | 74.4 [71.9, 76.9] |
| New Hampshire | 94.0 | 72.6 | 40.1 | 12.8 [10.7, 15.0] | 54.7 | 50.0 [45.7, 54.2] |
| Vermont | 95.6 | 77.5 | 44.6 | 15.2 [12.7, 17.6] | 67.4 | 36.8 [32.7, 40.9] |
| New York | 94.4 | 69.8 | 37.9 | 12.2 [11.1, 13.4] | 70.1 | 30.4 [28.6, 32.1] |

**Table 3.** Cross-map any-LSOG area and pairwise spatial agreement across three independent remote-sensing maps over the study area. TreeMap is an FIA imputation (any-LSOG 7.8%) and is reported with the design-based estimates (Section 3.5), not as a cross-map member.

| Method | Any-LSOG (% area) | kappa vs Hagan | kappa vs canopy |
|---|---|---|---|
| Hagan (airborne LiDAR) | 21.9 | -- | 0.22 |
| Canopy-height (Potapov/GEDI) | 14.0 | 0.22 | -- |
| ORNL old-growth stratum (Bruening) | 36.1 | -0.02 | -0.07 |
| 3-way: % of flagged area agreed by all three | 2.7 | | |

**Table 4.** Representation of true LSOG across EPA Level III ecoregions, pooled across the four states (design-based; sections with >= 50 K ac of forest).

| Ecoregion (EPA Level III) | Total forest (K ac) | True LSOG % [95% CI] | True LSOG (K ac) |
|---|---|---|---|
| Northeastern Highlands | 23,883 | 12.5 [11.5, 13.5] | 2,990 |
| Acadian Plains and Hills | 8,887 | 2.1 [1.4, 2.9] | 188 |
| Northern Allegheny Plateau | 5,421 | 9.2 [7.1, 11.2] | 497 |
| Eastern Great Lakes Lowlands | 3,709 | 4.0 [2.3, 5.6] | 147 |
| Northeastern Coastal Zone | 1,851 | 9.4 [5.9, 12.8] | 173 |
| North Central Appalachians | 614 | 8.5 [2.2, 14.8] | 52 |
| Erie Drift Plain | 372 | 8.0 [0.1, 15.8] | 30 |
| Ridge and Valley | 239 | 6.6 [0.0, 15.5] | 16 |
| Atlantic Coastal Pine Barrens | 188 | 2.1 | 4 |

**Table 5.** Sensitivity of design-based true LSOG (% of forestland, all four axes) to the A4 continuity definition. base = heavy disturbance classes, full 1985-2023 record, 3 x 3 focal buffer; strict_SR = stand-replacing classes only; recent20 = heavy classes but only the last 20 years; local = heavy classes, full record, plot pixel only (no focal); anyloss = any detected loss or stress class. The Maine-lowest ordering holds under every definition.

| State | base | strict_SR | recent20 | local | anyloss | range |
|---|---|---|---|---|---|---|
| Maine | 3.1 | 3.7 | 4.1 | 5.2 | 3.1 | 3.1-5.2 |
| New Hampshire | 12.8 | 14.2 | 15.9 | 18.8 | 12.6 | 12.6-18.8 |
| Vermont | 15.2 | 16.6 | 18.0 | 18.8 | 15.0 | 15.0-18.8 |
| New York | 12.2 | 14.0 | 13.6 | 15.0 | 12.1 | 12.1-15.0 |

---

## Figure Legends

**Fig. 1.** Datasets used in the analysis over Maine: USDA FIA inventory plots (grey) on their systematic probability grid, the MNAP/TNC ecological reserve monitoring network (teal) including Big Reed Forest Reserve (red), and the Baxter SFMA continuous forest inventory (orange). FIA provides the design-based estimation backbone; the ecological reserves and Baxter SFMA are independent validation references that no map in the comparison used for training.

**Fig. 2.** (a) The four-axis true-LSOG funnel by state: design-based share of forestland passing at least one through all four axes, with the LCMS Landsat continuity axis; true LSOG (all four axes) ranges from 3.1% in Maine to 12-15% in New Hampshire, Vermont, and New York. (b) Share of forest with Landsat-detected stand-replacing or harvest disturbance since 1985, the working-forest signal that makes the continuity axis most limiting in Maine.

**Fig. 3.** Three independent remote-sensing operationalizations of LSOG over Maine on a common 100 m grid, clipped to the state: (a) Hagan airborne LiDAR, any-LSOG 21.9%; (b) Potapov/GEDI spaceborne canopy height, 14.0%; (c) ORNL old-growth stratum (Bruening et al. 2026), 36.1%; (d) number of maps agreeing on LSOG per cell (0-3). Only 2.7% of flagged hectares are agreed by all three; the two structure-based maps agree modestly (kappa 0.22) and the ORNL stratum is uncorrelated with either (kappa near zero).

**Fig. 4.** FIA design-based older-forest area for Maine, 2003-2024, with 95% CI, showing rising stock against flat total forestland and the gross harvest flux for contrast.

**Fig. 5.** Regional context: integrated v5.1 LSOG share by state with confidence intervals, and the axis decomposition showing that stand age and live structure rank the states differently.

**Fig. 6.** LSOG probability surface for Maine from the refined balanced model (Potapov canopy height plus the LCMS Landsat disturbance and continuity layer), rendered at 100 m and clipped to the state. The probability product, not a hard class, is the honest primary map: it preserves the omission-commission trade-off rather than hiding it in a threshold. Any binary class is calibrated to the design-based area (matching the 14.1% prevalence at a probability cut of 0.93) rather than to an arbitrary 0.5, which bounds over-prediction by the unbiased estimate. The surface is archived as a 100 m GeoTIFF.

**Fig. 7.** The definitive multi-model LSOG product for Maine. (a) Ensemble mean probability across five learners (balanced random forest, probability forest, weighted logistic, support vector machine, multi-objective support vector regression), with the MNAP/TNC ecological reserve network, the Baxter State Park inventory, and Big Reed Forest Reserve overlaid; the named reserves fall within the higher-probability fabric, so the map does identify the locations experts target. (b) Across-model uncertainty, the per-pixel standard deviation among the five models (mean 0.18 on a 0-1 scale); darker areas are where credible models disagree most. The five learners' mean mapped probabilities span 0.26 to 0.59, a variance-based global sensitivity analysis attributes nearly all explained variation to canopy height with the Landsat disturbance axis secondary (Table S7), and any binary class is calibrated to the design-based area. The probability surface with its uncertainty layer, not a binary class, is the product intended for high-stakes use.

---

## Supplemental Materials

**Table S1.** v5.1 six-dimension structural proxy: dimension definitions and scoring.

| Dim | Variable | Source | 1 point | 2 points |
|---|---|---|---|---|
| 1 | Large-tree basal area | FIA trees, DBH >= 20 in | >= 40 ft^2/ac | >= 80 ft^2/ac |
| 2 | Stand maturity | STDAGE (max DBH fallback) | >= 80 yr (or DBH >= 24 in) | >= 120 yr |
| 3 | Structural diversity | TPA-weighted SD of DBH | >= 5 in | >= 8 in |
| 4 | Total stocking | Total live basal area | >= 100 ft^2/ac | >= 150 ft^2/ac |
| 5 | Deadwood | Standing snag TPA (DBH >= 5 in) | >= 75th pct | >= 90th pct |
| 6 | Canopy height | Potapov 2021 RH95, 30 m | >= 18 m | >= 25 m |

**Table S2.** Integrated v5.1 LSOG share by state, 2019-2023 panel (design-based, 95% CI).

| State | n plots | Any-LSOG % [95% CI] | OG-class % |
|---|---|---|---|
| Maine | 3,125 | 14.1 [12.9, 15.3] | 0.19 |
| New York | 2,107 | 27.2 [25.2, 29.0] | 1.5 |
| Vermont | 657 | 28.8 [25.4, 32.3] | 0.30 |
| New Hampshire | 757 | 31.2 [28.0, 34.3] | 0.66 |

**Table S3.** Design-based older forest by axis across the Northeast (2024, % of forestland), showing axes rank states differently.

| State | Stand age >= 120 yr % [95% CI] | Large-tree BA >= 30 ft^2/ac % [95% CI] |
|---|---|---|
| Maine | 3.9 [3.3, 4.6] | 12.5 [11.4, 13.7] |
| New Hampshire | 1.8 [0.9, 2.6] | 37.9 [34.7, 41.0] |
| Vermont | 1.0 [0.4, 1.6] | 39.1 [35.8, 42.4] |
| Massachusetts | 1.5 [0.4, 2.5] | 56.1 [51.6, 60.7] |
| Connecticut | 6.8 [3.8, 9.8] | 57.7 [51.6, 63.8] |
| Rhode Island | 1.2 [0.0, 3.1] | 47.0 [37.9, 56.1] |

**Table S4.** Dimensionality of LSOG attributes (Maine plots): selected pairwise correlations and PCA variance.

| Attribute pair / component | Value |
|---|---|
| Large-tree BA vs large-tree count | r = 0.98 |
| Large-tree BA vs diameter diversity | r = 0.77 |
| Large-tree BA vs standing dead BA | r = 0.51 |
| Large-tree BA vs coarse woody debris | r = 0.48 |
| Standing dead BA vs coarse woody debris | r = 0.47 |
| PC1 variance explained | 58.8% |
| PC1-PC2 cumulative | 72.6% |
| PC1-PC4 cumulative | 90.8% |

**Table S5.** LSOG occurrence rate by harvest-probability and slope tercile.

| Tercile | LSOG rate by harvest probability % | LSOG rate by slope % |
|---|---|---|
| Low | 13.1 | 11.8 |
| Medium | 24.1 | 21.7 |
| High | 33.5 | 37.3 |

**Table S6.** Representation of true LSOG (all four axes, LCMS continuity) across forest-type groups, pooled across the four states (design-based).

| Forest-type group | Total forest (K ac) | True LSOG % [95% CI] | True LSOG (K ac) |
|---|---|---|---|
| Maple/beech/birch (northern hardwood) | 22,995 | 11.6 [10.6, 12.7] | 2,676 |
| Spruce/fir | 7,428 | 2.1 [1.3, 2.8] | 153 |
| Oak/hickory | 4,432 | 6.6 [4.7, 8.6] | 294 |
| White/red/jack pine | 3,387 | 21.2 [17.2, 25.3] | 720 |
| Aspen/birch | 2,527 | 0.6 [0.0, 1.3] | 15 |
| Elm/ash/cottonwood | 1,772 | 0.0 [0.0, 0.0] | 0 |
| Oak/pine | 1,475 | 16.4 [10.8, 22.0] | 242 |
| Other softwood | 258 | 1.8 [0.0, 5.0] | 5 |

**Table S7.** Global (variance-based Sobol) sensitivity of the multi-model ensemble LSOG probability to the two predictors, over their empirical ranges. S1 is the first-order index (main effect); ST is the total-order index (main plus interactions). Canopy height dominates; the disturbance axis contributes mainly through interaction. (S1 for canopy height slightly exceeds 1 owing to Monte Carlo estimator noise and is interpreted as approximately unity.)

| Predictor | First-order S1 | Total-order ST |
|---|---|---|
| Canopy height (Potapov/GEDI) | ~1.0 | 0.97 |
| Time since disturbance (LCMS) | 0.08 | 0.12 |

**Table S8.** Mean mapped LSOG probability by learner in the multi-model ensemble (Maine, forested cells). The wide spread is the model-structural uncertainty mapped in Fig. 7b.

| Learner | Mean mapped P(LSOG) |
|---|---|
| Balanced random forest | 0.50 |
| Probability forest (ranger) | 0.26 |
| Weighted logistic | 0.59 |
| Support vector machine | 0.27 |
| Multi-objective SVR | 0.26 |
| Ensemble mean | 0.37 |

**Table S9.** Rare-class remedies for the reproduced Hagan random forest, with old-growth (OG) as the rare event. Three standard corrections and a voting-threshold adjustment are compared against the default. OG operating accuracy (recall) and the wall-to-wall mapped OG area both move substantially, confirming that the headline area is a modeling choice rather than a fixed quantity. (The OG class rests on only 17 training hectares, so OG-specific accuracies are themselves highly uncertain; plot-level bootstrap intervals are too wide to be informative.)

| Strategy (scikit-learn / imblearn analog) | OG recall | Overall acc. | Mapped OG area (%) |
|---|---|---|---|
| Default, unbalanced | 0.24 | 0.87 | 1.0 |
| Class weighting (classwt; class_weight='balanced') | 0.29 | 0.86 | 0.8 |
| Balanced subsample (sampsize/strata; BalancedRandomForestClassifier) | 0.71 | 0.84 | 1.9 |
| Voting-threshold adjustment (OG vote >= 0.2) | 0.82 | 0.87 | 2.3 |

**Table S10.** Final robustness summary: each headline conclusion and the analytical perturbation it survives.

| Conclusion | Stress applied | Result | Robust |
|---|---|---|---|
| Maine carries the lowest LSOG share | scoring threshold, drop canopy dimension, FIA panel | lowest in 8 of 9 tests | yes |
| True LSOG is rare (3 to 5% in Maine) | five LCMS continuity definitions | 3.1 to 5.2% | yes |
| Credible maps disagree | three independent remote-sensing products | 1.6 to 2.6 fold, agree on 2.7% | yes |
| Half the plot-level cross-map disagreement is geolocation | fuzzed vs true FIA coordinates | kappa 0.13 to 0.29 | yes |
| Rare-class detection and area are choice-driven | default vs weighted vs balanced vs threshold RF | OG recall 0.24 to 0.82; area 1.0 to 2.3% | yes |
| Model structure dominates map uncertainty | five-learner ensemble | mean P 0.26 to 0.59, SD 0.18 | quantified |
| Canopy height drives the signal | variance-based Sobol indices | first-order ~1.0, disturbance secondary | yes |
| Both maps detect most reserve old-growth, neither all | reserve, Big Reed, Baxter validation (Wilson CIs) | Big Reed 72 [52,86] vs 80 [61,91]; reserves 67 [64,70] vs 57 [54,60] | yes |
