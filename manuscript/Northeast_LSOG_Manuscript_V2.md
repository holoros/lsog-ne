# Late-successional and old-growth forest across the Northeast: a multi-axis, FIA-anchored classification and cross-map assessment

**Authors (working):** Aaron R. Weiskittel{1}, Adam Daigneault{1}, Daniel J. Hayes{1}, [additional co-authors TBD]

{1} University of Maine, Center for Research on Sustainable Forests, Orono, ME 04469, USA

**Target journal:** Ecological Applications

**Companion piece:** This manuscript develops the constructive, full-length analysis that the Comment on Hagan et al. (2026) points toward but does not attempt within a Comment's scope.

---

## Abstract

Late-successional and old-growth (LSOG) forests provide habitat, store carbon at high per-area densities, and carry particular conservation value in heavily managed landscapes. As wall-to-wall LSOG maps begin to anchor parcel-level conservation spending across the Northeastern United States, two questions become decision-relevant: how much LSOG exists, and how much do independent, equally defensible classifications agree on where it is. We address both with a probability-sample-anchored analysis across the Northeast. Using USDA Forest Inventory and Analysis (FIA) plots, we (i) estimate older-forest area with design-based confidence intervals by transparent ground criteria; (ii) develop a refined, four-axis LSOG classification (live structure, dead wood, composition, and temporal continuity) and quantify how the share of forest that qualifies depends on how many axes are required; and (iii) conduct a full cross-map assessment over Maine's unorganized townships, comparing a reproduced airborne-LiDAR classifier, a GEDI-calibrated canopy-height map, and a TreeMap structural imputation, with external checks against USFS old-growth criteria. LSOG attributes are genuinely multidimensional: live structure, dead wood, and temporal continuity load on separate axes, and once continuity is measured from the full Landsat disturbance record (USFS LCMS, 1985-2023) rather than from FIA treatment codes, true LSOG (all four axes) is far rarer than any single axis implies and varies sharply across the region: only 3.1% of Maine forestland qualifies, against 12-15% in New Hampshire, Vermont, and New York. Maine's low share tracks the working-forest signal the new axis exposes, with 70% of Maine forest carrying Landsat-detected stand-replacing or harvest disturbance since 1985 versus 32-50% in its neighbors, and recent disturbance second only to live structure as the limiting axis there. Across the Northeast, Maine carries the lowest combined LSOG share under the integrated proxy (14.1%, 95% CI 12.9-15.3) versus 27-31% in New Hampshire, New York, and Vermont, even though Maine is not lowest on the stand-age axis alone, a divergence that is itself the multidimensionality result. The three wall-to-wall maps disagree 2.8-fold in extent and agree spatially on only about a fifth of the flagged footprint (Cohen's kappa 0.21). Older-forest stock is stable to rising by every ground measure over 2003-2024, even as mapped LSOG is harvested at roughly 2% per year. We recommend that regional LSOG accounting report a method range with design-based intervals, that the LS+OG class be the stable unit for policy, and that maps be cross-checked and field-verified before they steer acquisition.

**Keywords:** late-successional and old-growth, FIA, design-based estimation, cross-map assessment, forest structure, canopy height, Northeast, working forest

---

## 1. Introduction

### 1.1 LSOG forests as a conservation and policy concern

Forests with mature, structurally complex stands provide ecosystem services that younger forests cannot. Cavity-nesting birds depend on standing dead trees that take decades to develop. Many lichen species require old, structurally complex canopies. Some terrestrial salamanders prefer the deep coarse woody debris that accumulates over generations. Beyond habitat, structurally complex older forests typically store more carbon per unit area than younger, simpler ones, and they store it more durably across the time horizons relevant to climate adaptation. Federal and state policy increasingly emphasizes the protection of late-successional and old-growth (LSOG) forest: the USDA Forest Service has issued direction to consider old growth in forest planning, state ecological-reserve programs maintain designated networks, and emerging carbon and conservation markets increasingly recognize the value of older forest. These developments raise the value of accurate, comparable, uncertainty-aware LSOG accounting.

### 1.2 Two questions: how much, and where

Recent work has put wall-to-wall LSOG maps directly into conservation practice. In Maine, an airborne-LiDAR classification of the unorganized townships (Hagan et al. 2026) has become the spatial basis for prioritization at scale, with downstream cost estimates on the order of US $200-300 million for protecting the highest-priority half of the mapped patches (Thompson et al. 2026, in support of Maine's LD 1529). When a single map becomes the substrate for parcel-level acquisition, two distinct questions become decision-relevant. The first is quantitative: how much LSOG exists, and with what sampling uncertainty. The second is spatial: how much do independent, equally defensible operationalizations of LSOG agree on which hectares qualify. The first question is answerable from the probability sample that underlies all of these products; the second requires placing several wall-to-wall classifications on a common grid and measuring their agreement. Neither has been addressed systematically for the region.

### 1.3 LSOG is multidimensional, and that matters for both questions

LSOG is not a single attribute but a bundle: large old live trees, structural complexity, abundant dead wood, characteristic composition, and continuity of forest cover over time. These attributes need not move together. A stand can carry large live trees yet little dead wood; it can have a tall continuous canopy yet a recent harvest signature. Any classification therefore embeds a choice about which axes to weight and how heavily, and that choice, more than any difference in fit to training data, drives how much forest qualifies and where. Making the axes explicit clarifies both the quantity question (the answer is a range that depends on how many axes are required) and the agreement question (maps disagree because they emphasize different axes).

### 1.4 The Northeast as a natural comparison

The four core Northeastern states share climate but diverge sharply in forest history. New Hampshire and Vermont saw peak agricultural clearing in the 1800s followed by widespread abandonment; the old-field forests that regrew now reach 100-150 years and are increasingly structurally complex. New York followed a similar arc, but the Adirondack landscape retained larger unmanaged forests and remains the regional old-growth concentration. Maine, by contrast, has supported continuous large-scale industrial forestry from the 1800s to today and produces more pulpwood than any state east of the Mississippi; its forests have been worked for generations on rotations long enough for merchantable trees but short of the structural conditions associated with old growth. These divergent histories make the region a natural setting for a consistent, structure-based LSOG comparison. They also make it a natural setting for a triad question (Seymour and Hunter 1999): across a landscape allocated among intensive production, extensive management, and reserves, the policy-relevant issue is whether the late-successional condition is adequately represented across forest types and ecoregions, not whether any single state carries a particular share.

### 1.5 Contribution

We make three contributions, each anchored in the FIA probability sample. First, we provide design-based older-forest estimates with confidence intervals for the Northeast under transparent ground criteria, distinguishing the gross harvest flux from the net stock trend. Second, we develop a refined four-axis LSOG classification and quantify, through a "funnel," how the qualifying share depends on how many axes are required and which axis is limiting. Third, we conduct a full cross-map assessment over Maine's unorganized townships, quantifying disagreement among a reproduced LiDAR classifier, a canopy-height map, and a TreeMap imputation, with external checks. Together these reframe LSOG accounting from a single number toward a method range with explicit uncertainty, and they give downstream users the agreement information that high-stakes allocation requires.

---

## 2. Methods

### 2.1 Study area and FIA data

We analyzed FIA Phase 2 inventory plots across the Northeastern United States, with the four-state core of Maine, New Hampshire, Vermont, and New York and supplementary estimates for Massachusetts, Connecticut, and Rhode Island. Plots span the 1999-2023 inventory period across five evaluation panels. Sample sizes for the most recent panel (2019-2023) are 3,125 in Maine, 757 in New Hampshire, 657 in Vermont, and 2,107 in New York. FIA plot coordinates are publicly fuzzed up to approximately 1 km to protect landowner privacy; fuzzed coordinates were used for all spatial extractions, and the resulting noise on 30 m raster sampling is discussed in Section 4.6. We assembled a master plot-level analytical table (`output_unified/lsog_ne_plot_table.csv`, 13,432 rows x 32 columns) containing, for each plot-period, state, panel, plot CN, inventory year, fuzzed coordinates, stand age, total and large-tree basal area, TPA-weighted SD of diameter, maximum diameter, snag density, the dimension scores, the v4 and v5.1 classifications, the ORNL DAAC 2498 probability bands (Bruening et al. 2026), and the Potapov (2021) RH95 canopy height at the plot centroid.

### 2.2 The six-dimension v5.1 structural proxy

The integrated v5.1 classifier scores each plot on six structural dimensions and aggregates into a 0-12 total (Table 1). Class thresholds are Transitioning LS (TLS) at score >= 4, Late Successional (LS) at >= 6, and Old Growth (OG) at >= 8. Dimensions 1-5 derive from FIA tree and condition tables; dimension 6 derives from the Potapov et al. (2021) GEDI/Landsat 30 m canopy-height mosaic sampled at the plot centroid. The thresholds were calibrated by grid search against two external references, the Hagan et al. (2026) LiDAR classification for Maine's unorganized townships and the ORNL DAAC 2498 mature/old-growth probability layers, and are intentionally tighter than the published RAP v2.0 reference values; an earlier relaxed configuration produced implausibly high regional shares (65-69% in New Hampshire and Vermont) and was rejected. A deadwood-scoring error in an earlier version (snag counts drawn from outside the plot boundary in some cases) was corrected on 19 March 2026; all results here use the corrected classifier.

### 2.3 A refined four-axis LSOG classification

The six-dimension score is convenient but collapses distinct ecological axes into one number. To make the axes explicit, we defined four LSOG axes and required a plot to pass each on its own transparent criterion: **A1 live structure** (large-tree basal area >= 30 ft^2/ac in trees >= 16 in dbh), **A2 dead wood** (standing snag basal area >= 5 ft^2/ac), **A3 composition** (>= 50% of live basal area in long-lived, late-successional species), and **A4 temporal continuity** (no stand-replacing or harvest disturbance detected in the USFS Landscape Change Monitoring System annual change record over the full Landsat era, 1985-2023). A1-A3 are deterministic functions of the FIA tree and condition tables. A4 replaces the earlier, permissive continuity proxy based on FIA treatment and stand-origin codes, which flags only the most recent inventory cycle and undercounts legacy and partial harvest; in Maine that proxy passed 90% of conditions, whereas the Landsat-era continuity test passes 29.5% (see Section 2.3a). We then computed, across all forested plots, the share passing each axis alone, the "funnel" share passing at least one, at least two, at least three, and all four axes (which we label *true LSOG*), and, among plots that fail, which single axis is most often limiting. This decomposition answers the quantity question as a range rather than a point and identifies the axis that most constrains LSOG status.

### 2.3a Landsat time-since-disturbance continuity layer

The temporal-continuity axis is the one a canopy sensor cannot see but the Landsat record can. We built it from the USFS Landscape Change Monitoring System (LCMS v2024-10) annual "change, cause of change" product, a Landsat-based classification giving, for every 30 m pixel and every year 1985-2023, the dominant change cause among sixteen classes. We cropped each annual layer to Maine, resampled to a common 100 m grid, and reduced the stack to the year of most recent stand-replacing or harvest disturbance, defined as any year flagged Tree Removal, Mechanical, Wildfire, Hurricane, Prescribed Fire, or Other Loss; time-since-disturbance is the current year minus that year. A condition passes A4 only if no such disturbance is detected at its plot over the full record (a 3 x 3 focal maximum absorbs FIA coordinate fuzzing). Tree Removal is by far the dominant LCMS cause in Maine, so this layer captures the partial and selective harvest that the binary Global Forest Watch loss layer (used by the original analysis) and the FIA treatment codes both miss.

### 2.4 Dimensionality of LSOG attributes

To test whether the axes are in fact distinct, we examined the correlation structure and principal components of seven plot-level structural attributes (live basal area, large-tree basal area, large-tree count, quadratic mean diameter, diameter diversity, standing dead basal area, and coarse woody debris volume) on the Maine plot population. We report the pairwise correlation matrix and the variance explained by successive principal components. The question is whether dead wood and continuity load separately from live structure; if they do, a one-axis classifier necessarily discards information that the four-axis definition retains.

### 2.5 Design-based estimation and trend

State-level shares are computed by FIA design-based post-stratified estimation, weighting plots by EXPNS from POP_PLOT_STRATUM_ASSGN joined to POP_STRATUM, with variance following Bechtold and Patterson (2005) as implemented in rFIA (Stanke et al. 2020). We report older-forest area by four transparent ground criteria (stand age >= 100, >= 120, >= 150 yr, and live basal area in trees >= 40 cm dbh above 30 ft^2/ac) statewide and for the northern timberland units, plus the integrated v5.1 share. Annual estimates over 2003-2024 give the trend; we fit per-year design-based estimates and report the slope with its confidence interval, distinguishing the net-stock trend from the gross harvest flux reported by canopy-change products.

### 2.6 Cross-map assessment

Over the Maine unorganized-townships study area, we placed three wall-to-wall LSOG classifications on a common 100 m grid: (i) the Hagan et al. (2026) airborne-LiDAR classifier, reproduced from the archived random forest (out-of-bag accuracy 94.2% against the published 94.1%, with the same top predictor) and verified against the privately held Seven Islands product (pixel-level kappa 0.97 over ~290,000 ha); (ii) an FIA structural class predicted from Potapov GEDI-calibrated canopy height; and (iii) the USFS TreeMap imputation of FIA structural class. We computed each map's any-LSOG area, pairwise Cohen's kappa and Jaccard agreement against the Hagan map, the three-way agreed footprint, and the overlap of the top-priority protected sets (top 5-20% of hectares) between the Hagan and canopy-height maps. We also built a 30 m ensemble agreement-and-uncertainty surface across the region: per pixel, the number of the three maps calling LSOG defines agreement, and the spread defines uncertainty. As external checks we cross-validated the FIA proxy against the Pelz et al. (2023) USFS Eastern Region old-growth criteria on National Forest System plots and against the ORNL DAAC 2498 probability bands, and we report the Seven Islands plot-level cross-validation.

### 2.7 Drivers and continuity

To characterize where LSOG sits in the working landscape, we related plot-level LSOG status to a CONUS harvest-probability model and to terrain slope, and we summarized the Landsat continuity layer by LSOG class. These analyses are descriptive and are reported briefly; they motivate the policy discussion rather than test a hypothesis.

### 2.8 Reproducibility

All code is at github.com/holoros/lsog-ne and the analyses ran on the OSC Cardinal cluster (`/users/PUOM0008/crsfaaron/LSOG/`). The master analytical artifact is `output_unified/lsog_ne_plot_table.csv`, and all derived products are archived at Zenodo (concept DOI 10.5281/zenodo.20614496).

---

## 3. Results

### 3.1 Regional context: older forest with intervals

Under the integrated v5.1 proxy, Maine carries the lowest combined LSOG share in the four-state core at 14.1% (95% CI 12.9-15.3), against 31.2% (28.0-34.3) in New Hampshire, 28.8% (25.4-32.3) in Vermont, and 27.2% (25.2-29.0) in New York; Maine's interval does not overlap any neighbor's (Table 2). New York carries the highest old-growth-class share (1.5%), consistent with the Adirondacks. By the design-based ground criteria, Maine older forest is 12.1% [10.9, 13.2] at stand age >= 100 yr, 3.9% [3.3, 4.6] at >= 120 yr, and 0.7% [0.4, 1.0] at >= 150 yr, with large-tree basal area at 12.5% [11.4, 13.7] (Table 3). These intervals, absent from map-only accounts, are the appropriate unit for high-stakes use.

### 3.2 The axes rank states differently

The integrated "Maine lowest" result does not hold on every axis, and that is the point. On the stand-age >= 120 yr criterion, Maine (3.9% [3.3, 4.6]) actually exceeds New Hampshire (1.8% [0.9, 2.6]) and Vermont (1.0% [0.4, 1.6]); on the live-structure (large-tree basal area) axis, however, Maine is the lowest in the region at 12.5%, far below New Hampshire (37.9%), Vermont (39.1%), and the southern New England states (47-58%) (Table 4). Maine thus has comparatively old forest that lacks large-tree structure, a signature of long-managed stands, while its neighbors have younger forest on more productive sites carrying more large-tree structure. Because the axes disagree on the ranking, no single-axis number is a sufficient summary, and the integrated proxy that combines them is what produces the "Maine lowest" headline.

### 3.3 LSOG attributes are genuinely multidimensional

The correlation structure confirms separable axes. Large-tree basal area, large-tree count, quadratic mean diameter, and diameter diversity are tightly intercorrelated (r = 0.74-0.98), forming a coherent live-structure axis, but standing dead basal area (r = 0.38-0.51 with the live-structure cluster) and coarse woody debris (r = 0.23-0.48) load only weakly on it (Table 5). The first principal component captures 58.8% of variance and the second 13.8%; four components are needed to reach 91% (Table 5). A one-axis (canopy or live-structure) classifier therefore discards the dead-wood and continuity information that the four-axis definition retains, which is the mechanistic reason canopy-based maps register big-tree forest rather than old growth.

### 3.4 The four-axis funnel: how much is "true" LSOG

Requiring more axes sharply reduces the qualifying share, and the reduction differs by state (Table 6, Fig. 2). Across all four states 84-96% of forest passes at least one axis, but only a small fraction passes all four, which we treat as *true LSOG*: 3.1% (95% CI 2.5-3.7) in Maine, 12.8% (10.7-15.0) in New Hampshire, 15.2% (12.7-17.6) in Vermont, and 12.2% (11.1-13.4) in New York. The headline is therefore not a single percentage but a curve, and the same forest is anywhere from 3% to over 90% LSOG depending on how many axes a definition requires.

The state ordering at the all-four threshold is driven by the two axes that vary most. Live structure is the scarcest axis everywhere (passing 12.5% of forest in Maine versus 38-39% in the other states), and the Landsat continuity axis is markedly tighter in Maine: it passes 40.1% of Maine forest against 54.7% in New Hampshire, 67.4% in Vermont, and 70.1% in New York. Maine is the only state where recent disturbance rivals live structure as the limiting axis (continuity missing in 22.7% of Maine near-misses, against 13-23% elsewhere). This is the working-forest signal the new axis exposes: 70.5% of Maine forest carries Landsat-detected stand-replacing or harvest disturbance since 1985, at a median 12 years ago, versus 50.0% in New Hampshire, 34.7% in Vermont, and 31.7% in New York (Fig. 2b). Maine's low true-LSOG share is thus as much a continuity result, reflecting active management, as a structural one.

### 3.5 Cross-map assessment: credible maps disagree

The three wall-to-wall classifications disagree substantially over the study area (Table 7, Fig. 3). Any-LSOG covers 21.9% under the Hagan LiDAR classifier, 14.0% under the canopy-height map, and 7.8% under TreeMap, a 2.8-fold range. The Hagan and canopy-height maps agree spatially on only about 21% of the hectares either flags (Cohen's kappa 0.21); across all three, only 21.0% of the flagged footprint is agreed by all three, and more than half is flagged by a single method. The 30 m ensemble surface shows mean agreement of 0.115, only 8.9% of forested pixels at high agreement (at least two of three concurring) and 0.7% with all three agreeing, while 24.3% carry high classification uncertainty. For prioritization the consequence is direct: the overlap of the top-priority protected sets selected by the Hagan versus the canopy-height map is only 0.16-0.30 (Jaccard) for the top 5-20% of hectares, so 70-84% of the prioritized ground differs depending on which equally defensible map is used.

### 3.6 External validation: the OG class is product-specific

Against the Pelz et al. (2023) USFS criteria on 925 Northeastern NFS plots, the integrated proxy achieves fair agreement on the combined LS+OG class (Cohen's kappa 0.25) but near-random agreement on the OG-only class (kappa 0.04), the latter driven by the small absolute number of OG plots. The Seven Islands plot-level cross-validation over Pingree (125 in-extent latest-panel plots) likewise shows reasonable share-level agreement but near-random plot-by-plot agreement at every class boundary (kappa near zero), because the LiDAR and FIA products measure genuinely different signals on heavily managed timberland: LiDAR canopy metrics register skid-trail and partial-harvest gaps that FIA tree-level data may miss, while the FIA proxy weights tree-level attributes that change after partial harvest even where the residual canopy stays tall. Across products, OG-share estimates differ several-fold; the LS+OG combined class is the stable unit for policy reporting.

### 3.7 Trend: stock stable to rising, flux notwithstanding

Older-forest stock increased by every ground measure over 2003-2024, with confidence intervals excluding zero: stand age >= 100 yr at +0.19%/yr [0.15, 0.23], >= 120 yr at +0.065%/yr [0.054, 0.075], and large-tree basal area at +0.17%/yr [0.15, 0.18], while total forestland area was flat (Table 3, Fig. 4). The northern units show the same increases; only the oldest class (age >= 150 yr) in the north declines slightly (-0.019%/yr [-0.031, -0.008]). This coexists with the reported gross loss of mapped LSOG (1.37%/yr overall, 2.19%/yr on commercial timberland): stands are harvested while aging more than replaces the hectares removed. The two statements describe a gross flux and a net stock and should not be conflated.

### 3.8 Where LSOG sits in the working landscape

LSOG occurrence rises with both modeled harvest probability and terrain slope. The LSOG rate is 13.1% on the lowest harvest-probability tercile, 24.1% on the middle, and 33.5% on the highest; and 11.8%, 21.7%, and 37.3% across low, medium, and high slope terciles (Table 8). The picture is two-sided: mapped LSOG sits disproportionately on the most merchantable ground yet also on steeper, more disturbance-prone terrain that raises harvest cost and logistics. Risk to these stands is therefore heterogeneous rather than uniform. Consistent with the continuity axis (Sections 2.3a, 3.4), LSOG plots are disturbed in the Landsat record at lower rates than non-LSOG forest, so most but not all mapped LSOG carries intact recent continuity; the share that fails the continuity test is highest in Maine, where active management is most extensive.

### 3.9 Representation of true LSOG across forest types

Pooling the four states, true LSOG (all four axes) is present in eight of the nine forest-type groups in the region, but its abundance varies more than thirtyfold among them (Table 9). The largest absolute pools are in the most extensive types: northern hardwood (maple-beech-birch) holds 2.68 million acres of true LSOG at an 11.6% rate, and the white-red-jack pine type holds 0.72 million acres at the highest rate of any group, 21.2%. The oak-pine and oak-hickory types contribute another 0.54 million acres combined. The spruce-fir type, often treated as the signature Acadian LSOG forest, carries a much smaller share (2.1%, 0.15 million acres), and the aspen-birch and elm-ash-cottonwood types carry almost none. Representation is therefore broad but highly uneven: the late-successional condition occurs across nearly all forest types in the region, but it is concentrated in the northern hardwood and pine types and is thin in the early-successional and some softwood types. This pattern, rather than any single state's aggregate share, is the appropriate target for a regional late-successional strategy.

---

## 4. Discussion

### 4.1 Reframing LSOG accounting from a number to a range

The central methodological result is that the honest answer to "how much LSOG" is a range with its definition and its sampling interval attached. The four-axis funnel makes the definitional component explicit: the same Northeastern forest is 6% true LSOG under a four-axis requirement and over 90% under a one-axis continuity requirement. The design-based intervals make the sampling component explicit: Maine older forest is 3.9% [3.3, 4.6] at age >= 120 yr, not a single point. Reporting a single percentage, whatever its source, conceals both. For policy use, the combined LS+OG class is the most stable category across both definitions and products; the OG-only class is genuinely product-specific and should always carry uncertainty bounds.

### 4.2 Why credible maps disagree, and what to do about it

The cross-map assessment shows that high training accuracy does not produce map agreement: three operationalizations that each fit their labels well place LSOG in 2.8-fold-different amounts and agree spatially on only about a fifth of the flagged footprint. This is not a defect of any one map; it follows from LSOG's multidimensionality (Section 3.3) and from each map emphasizing different axes. The practical implication for a $200-300 million prioritization is that the choice of map, not just the choice of parcels, drives most of the spending. We recommend that maps used for allocation be accompanied by an explicit cross-map agreement layer and field-verified at the parcel scale, as the original authors themselves advise for management decisions.

### 4.3 Maine's structural divergence reflects its working-forest history

The integrated proxy places Maine lowest in the region, and the axis decomposition shows this is jointly a structure and a continuity result rather than an age result. Maine has comparatively old forest that lacks large-tree structure, consistent with continuous management on rotations long enough to grow merchantable trees and short of the conditions that build large-tree, dead-wood-rich structure; and it carries the region's strongest recent-disturbance signal, with 70% of its forest showing Landsat-detected stand-replacing or harvest disturbance since 1985 against 32-50% in its neighbors. New Hampshire and Vermont, aging out of 19th-century abandonment, carry more large-tree structure and far less recent disturbance on younger stands; New York's Adirondacks preserve the regional old-growth concentration. The pattern is not a deficiency to be corrected state by state but a coherent regional division of forest function, which we develop next.

### 4.3a A regional triad, not a per-state deficit

The Northeast functions as a landscape-scale triad in the sense of Seymour and Hunter: a mosaic of intensively managed production forest, extensively managed forest, and reserves, with the three roles distributed unevenly among states. Maine's heavily worked timberland anchors the production tier; the aging old-field forests of New Hampshire and Vermont and the Adirondack reserves of New York carry a disproportionate share of the late-successional and reserve tiers. Under a triad framing, Maine's low true-LSOG share is the expected signature of its role, not evidence that Maine should be made to match its neighbors hectare for hectare. The conservation-relevant question is therefore not whether each state reaches parity but whether true LSOG is adequately represented across the region's forest types and ecoregions, so that the late-successional tier of the triad spans the full range of ecological conditions rather than concentrating in a few. Our representation analysis (Section 3.9) speaks to this directly: true LSOG is present in eight of the nine forest-type groups in the region, but its abundance varies more than thirtyfold among them. The largest absolute pools sit in the northern hardwood (maple-beech-birch) type, which carries 2.7 million acres of true LSOG at an 11.6% rate, and the white-red-jack pine type (0.7 million acres, 21.2%), while the iconic spruce-fir type carries a much smaller share (2.1%) and the aspen-birch and elm-ash-cottonwood types almost none. Representation is broad across types but highly uneven, and the under-represented types, rather than Maine's aggregate share, are where a regional late-successional strategy should focus. (A parallel cut by ecoregion requires a spatial ecoregion overlay not resolvable from the inventory fields in this snapshot and is a stated next step.)

### 4.4 The dead-wood blind spot and the limiting axis

That live structure is the limiting axis in 84% of failures, and that dead wood loads separately from live structure, together explain why canopy- and height-based classifications over-include relative to structural definitions. Such classifiers read tall continuous canopy whether it is produced by an old complex stand or a fast-growing young one, and they are largely blind to the dead-wood component that distinguishes old growth. A classification intended to identify true LSOG, rather than big-tree forest, must measure the dead-wood and continuity axes directly, which is the design rationale for the four-axis definition.

### 4.5 Limitations

First, the OG-class precision is low (near-random agreement against Pelz and Seven Islands at the plot level), and we do not over-interpret state-level OG percentages. Second, FIA coordinate fuzzing introduces ~30 m uncertainty at the canopy-height extraction; a Data Use Agreement for true coordinates would tighten dimension 6. Third, the ORNL 2498 product trains on FIA labels, making that comparison a coherence check rather than blind validation. Fourth, the wall-to-wall TreeMap layer is a representative-plot imputation that smooths rare classes, so its area is a lower bound. Fifth, the four-axis continuity criterion depends on the Landsat disturbance record's sensitivity and may under-detect light partial harvest.

### 4.6 Implications for policy

For Maine, the LD 1529 working group should know that the state has the lowest integrated LSOG share in the region, that the net older-forest stock is stable to rising rather than collapsing, that the qualifying share depends strongly on definition, and that any single map should be cross-checked before it steers acquisition. Read through a triad lens, Maine's low share reflects its production role in a regional division of forest function rather than a deficit to be closed within the state; the regional objective is adequate representation of the late-successional condition across forest types and ecoregions, which our results show is broad but uneven (Sections 3.9, 4.3a). The most acreage-relevant levers are therefore the under-represented forest types and the private-timberland LS+OG pool that holds most of the regional acreage; payment-for-ecosystem-services arrangements, working-lands easements, and targeted reserve placement in under-represented types all bear on them. The master plot table provides the analytical foundation to quantify each option.

### 4.7 Relationship to the Comment and future work

A short Comment on Hagan et al. (2026) presents the cross-map disagreement, dead-wood blindness, and design-based baseline as a focused critique; this manuscript is the constructive companion that builds the multi-axis classification and the full assessment that the Comment points toward. Immediate extensions include integrating the full Maine unorganized-townships LiDAR raster when accessible, extending the four-axis classification to wall-to-wall mapping of each axis, pursuing true plot coordinates, and linking LSOG class to wood-quality and harvest-economics outcomes for a direct working-forest-economy linkage.

---

## 5. Conclusion

Across the Northeast, the amount of LSOG forest is best expressed not as a single number but as a method range with design-based intervals, and the location of LSOG is genuinely uncertain across credible maps. The four-axis funnel shows that only about 6.5% of regional forest qualifies as LSOG on all axes while over 90% qualifies on at least one, with live structure the limiting axis. Maine carries the lowest integrated LSOG share in the region, a structure result rather than an age result, and the net older-forest stock is stable to rising even as mapped LSOG is harvested. Three independent wall-to-wall maps disagree 2.8-fold in extent and agree on only about a fifth of the flagged footprint, so the choice of map drives most of the spending it informs. We recommend reporting a method range with intervals, treating LS+OG as the stable policy unit, and cross-checking and field-verifying maps before they anchor acquisition.

---

## Literature Cited

Bechtold, W.A. & P.L. Patterson (eds.). 2005. The enhanced Forest Inventory and Analysis program: national sampling design and estimation procedures. USDA Forest Service General Technical Report SRS-80.

Bruening, J.M., et al. 2026. Mature and old-growth forest probability maps for the conterminous United States. ORNL DAAC dataset 2498. [VERIFY full author list, title, and citation.]

Hagan, J.M., B. Shamgochian, M.M.L. Taylor & J.M. Reed. 2026. Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA. Ecosphere 17:e70670. [VERIFY citation details against published paper.]

Pelz, K.A., et al. 2023. [Old-growth forest definition and identification on National Forest System lands.] Forest Ecology and Management 549:121437. [VERIFY full author list and title.]

Potapov, P., X. Li, A. Hernandez-Serna, A. Tyukavina, M.C. Hansen, A. Kommareddy, A. Pickens, S. Turubanova, H. Tang, C.E. Silva, J. Armston, R. Dubayah, J.B. Blair & M. Hofton. 2021. Mapping global forest canopy height through integration of GEDI and Landsat data. Remote Sensing of Environment 253:112165.

Riley, K.L., et al. 2021, 2022. TreeMap: a tree-level model of the forests of the conterminous United States. [VERIFY citation(s).]

Seymour, R.S. & M.L. Hunter Jr. 1999. Principles of ecological forestry. Pages 22-61 in M.L. Hunter Jr., editor. Maintaining Biodiversity in Forest Ecosystems. Cambridge University Press, Cambridge, UK.

Stanke, H., A.O. Finley, A.S. Weed, B.F. Walters & G.M. Domke. 2020. rFIA: An R package for estimation of forest attributes with the FIA database. Environmental Modelling & Software 127:104664.

Thompson, J.R., A. Daigneault, J. Plisinski, I. Moon & J. Norton. 2026. Pathways for Protecting Maine's Remaining Late-Successional and Old-Growth Forests. Property and Environment Research Center. [VERIFY venue and year.]

USDA Forest Service. 2024. Landscape Change Monitoring System (LCMS), CONUS version 2024-10. USDA Forest Service Geospatial Technology and Applications Center, Salt Lake City, UT. https://data.fs.usda.gov/geodata/LCMS/

[ADD: RAP v2.0 protocol reference; Lang et al. 2023 (canopy height); Birdsey regional-carbon synthesis if a verified reference is intended; Adirondack old-growth references for Section 1.4.]

---

## Tables

**Table 1.** v5.1 six-dimension structural proxy: dimension definitions and scoring.

| Dim | Variable | Source | 1 point | 2 points |
|---|---|---|---|---|
| 1 | Large-tree basal area | FIA trees, DBH >= 20 in | >= 40 ft^2/ac | >= 80 ft^2/ac |
| 2 | Stand maturity | STDAGE (max DBH fallback) | >= 80 yr (or DBH >= 24 in) | >= 120 yr |
| 3 | Structural diversity | TPA-weighted SD of DBH | >= 5 in | >= 8 in |
| 4 | Total stocking | Total live basal area | >= 100 ft^2/ac | >= 150 ft^2/ac |
| 5 | Deadwood | Standing snag TPA (DBH >= 5 in) | >= 75th pct | >= 90th pct |
| 6 | Canopy height | Potapov 2021 RH95, 30 m | >= 18 m | >= 25 m |

**Table 2.** Integrated v5.1 LSOG share by state, 2019-2023 panel (design-based, 95% CI).

| State | n plots | Any-LSOG % [95% CI] | OG-class % |
|---|---|---|---|
| Maine | 3,125 | 14.1 [12.9, 15.3] | 0.19 |
| New York | 2,107 | 27.2 [25.2, 29.0] | 1.5 |
| Vermont | 657 | 28.8 [25.4, 32.3] | 0.30 |
| New Hampshire | 757 | 31.2 [28.0, 34.3] | 0.66 |

**Table 3.** FIA design-based older-forest area, Maine, 2024 (95% CI) and 2003-2024 trend.

| Ground criterion | Statewide % [95% CI] | Northern units % [95% CI] | Trend (%/yr) [95% CI] |
|---|---|---|---|
| Stand age >= 100 yr | 12.1 [10.9, 13.2] | 12.2 [10.7, 13.7] | +0.19 [0.15, 0.23] |
| Stand age >= 120 yr | 3.9 [3.3, 4.6] | 4.2 [3.3, 5.1] | +0.065 [0.054, 0.075] |
| Stand age >= 150 yr | 0.7 [0.4, 1.0] | 0.6 [0.2, 1.0] | +0.000 [-0.005, 0.006] |
| Large-tree BA >= 30 ft^2/ac | 12.5 [11.4, 13.7] | 9.8 [8.4, 11.2] | +0.17 [0.15, 0.18] |

**Table 4.** Design-based older forest by axis across the Northeast (2024, % of forestland), showing axes rank states differently.

| State | Stand age >= 120 yr % [95% CI] | Large-tree BA >= 30 ft^2/ac % [95% CI] |
|---|---|---|
| Maine | 3.9 [3.3, 4.6] | 12.5 [11.3, 13.6] |
| New Hampshire | 1.8 [0.9, 2.6] | 37.9 [34.7, 41.0] |
| Vermont | 1.0 [0.4, 1.6] | 39.1 [35.8, 42.4] |
| Massachusetts | 1.5 [0.4, 2.5] | 56.1 [51.6, 60.7] |
| Connecticut | 6.8 [3.8, 9.8] | 57.7 [51.6, 63.8] |
| Rhode Island | 1.2 [0.0, 3.1] | 47.0 [37.9, 56.1] |

**Table 5.** Dimensionality of LSOG attributes (Maine plots): selected pairwise correlations and PCA variance.

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

**Table 6.** Four-axis LSOG funnel by state (design-based % of forestland), with the LCMS continuity axis. "% disturbed since 1985" is the share of forest with Landsat-detected stand-replacing or harvest disturbance in the LCMS record.

| State | >= 1 axis | >= 2 axes | >= 3 axes | true LSOG (all 4) [95% CI] | A4 continuity alone | % disturbed since 1985 |
|---|---|---|---|---|---|---|
| Maine | 83.8 | 48.8 | 18.4 | 3.1 [2.5, 3.7] | 40.1 | 70.5 |
| New Hampshire | 94.0 | 72.6 | 40.1 | 12.8 [10.7, 15.0] | 54.7 | 50.0 |
| Vermont | 95.6 | 77.5 | 44.6 | 15.2 [12.7, 17.6] | 67.4 | 34.7 |
| New York | 94.4 | 69.8 | 37.9 | 12.2 [11.1, 13.4] | 70.1 | 31.7 |

**Table 7.** Cross-map any-LSOG area and agreement over the study area.

| Method | Any-LSOG (% area) | vs Hagan: kappa | vs Hagan: Jaccard |
|---|---|---|---|
| Hagan (airborne LiDAR) | 21.9 | -- | -- |
| Canopy-height (FIA on Potapov) | 14.0 | 0.21 | 0.21 |
| TreeMap (FIA imputation) | 7.8 | 0.01 | 0.03 |
| 3-way agreed footprint | 21.0 | | |
| Ensemble: high-uncertainty pixels | 24.3 | | |

**Table 8.** LSOG occurrence rate by harvest-probability and slope tercile.

| Tercile | LSOG rate by harvest probability % | LSOG rate by slope % |
|---|---|---|
| Low | 13.1 | 11.8 |
| Medium | 24.1 | 21.7 |
| High | 33.5 | 37.3 |

**Table 9.** Representation of true LSOG (all four axes, LCMS continuity) across forest-type groups, pooled across the four states (design-based).

| Forest-type group | Total forest (K ac) | True LSOG (%) | True LSOG (K ac) |
|---|---|---|---|
| Maple/beech/birch (northern hardwood) | 22,995 | 11.6 | 2,676 |
| Spruce/fir | 7,428 | 2.1 | 153 |
| Oak/hickory | 4,432 | 6.6 | 294 |
| White/red/jack pine | 3,387 | 21.2 | 720 |
| Aspen/birch | 2,527 | 0.6 | 15 |
| Elm/ash/cottonwood | 1,772 | 0.0 | 0 |
| Oak/pine | 1,475 | 16.4 | 242 |
| Other softwood | 258 | 1.8 | 5 |

---

## Figure Legends

**Fig. 1.** Conceptual four-axis LSOG definition (live structure, dead wood, composition, continuity) and how requiring more axes narrows the qualifying share.

**Fig. 2.** (a) The four-axis true-LSOG funnel by state: design-based share of forestland passing at least one through all four axes, with the LCMS Landsat continuity axis; true LSOG (all four axes) ranges from 3.1% in Maine to 12-15% in New Hampshire, Vermont, and New York. (b) Share of forest with Landsat-detected stand-replacing or harvest disturbance since 1985, the working-forest signal that makes the continuity axis most limiting in Maine.

**Fig. 3.** Cross-map disagreement over the study area: any-LSOG area by method (2.8-fold range), the same window classified by each method, the three-way agreed footprint (21%), and the ensemble agreement/uncertainty surface.

**Fig. 4.** FIA design-based older-forest area for Maine, 2003-2024, with 95% CI, showing rising stock against flat total forestland and the gross harvest flux for contrast.

**Fig. 5.** Regional context: integrated v5.1 LSOG share by state with confidence intervals, and the axis decomposition showing that stand age and live structure rank the states differently.
