# Late-Successional and Old-Growth Forest Across Northern New England

## What the Inventory Shows, and the Limits of LiDAR-Based Mapping

### A Technical Report for the Maine Forest Products Council

Prepared by Aaron R. Weiskittel, Center for Research on Sustainable Forests, University of Maine. June 2026.

---

## Executive summary

Recent LiDAR-based maps have drawn welcome attention to older forest in Maine's working landscape, and a downstream analysis has proposed protecting the highest-priority mapped acres at a cost on the order of $200 to $300 million. Before a single map anchors spending at that scale, its fitness for the purpose should be examined, and the question reframed from one state to the region it belongs to. This report does both.

Our central findings are four. First, how much late-successional and old-growth (LSOG) forest exists is not a single number but a range that depends on how the condition is defined and that carries a sampling interval; the honest unit is the design-based estimate from the Forest Inventory and Analysis (FIA) program, reported with its confidence bounds. Second, the same forest is anywhere from about 3 percent to over 90 percent LSOG depending on how many structural criteria a definition requires, so the headline percentage is a definitional choice as much as a measurement. Third, across northern New England and the adjacent Adirondacks, Maine carries the lowest integrated LSOG share, but this is the expected signature of its production role in a regional division of forest function, not a deficiency to be corrected state by state. Fourth, the older-forest stock is stable to rising across the region over the last two decades, even as individual mapped stands are harvested, because younger stands age into the older condition faster than the older stands are cut. The widely cited rate of loss measures a gross harvest flux, not a declining net stock.

On the mapping itself, we document specific, quantifiable limitations of the LiDAR analysis and the field protocol behind it. The reported 90 percent accuracy measures agreement with the project's own training labels, not correctness against an independent standard. Canopy LiDAR is sensitive to tall, big-tree forest but largely blind to the dead wood and disturbance history that distinguish genuine old growth, and the field protocol used to train the map de-weights dead wood as well. Independent, equally credible remote-sensing maps of the same forest disagree by a factor of 1.6 to 2.6 in how much LSOG exists and agree on only a small fraction of the specific ground. The prioritization that proposes hundreds of millions in spending inherits the single map without carrying any of its uncertainty forward.

None of this argues against conserving older forest in Maine, which is a legitimate and shared goal. It argues that regional accounting should report a defensible range with intervals, that maps used for high-stakes allocation should be cross-checked and field-verified, and that a probabilistic product with explicit uncertainty, not one binary map, is the appropriate basis for parcel-level decisions.

---

## 1. Background

In 2024, a team led by John Hagan (Our Climate Common) used publicly available airborne LiDAR to classify late-successional and old-growth forest across roughly 10 million acres of Maine's unorganized townships, reporting that the combined late-successional and old-growth-like class covers 3.9 percent of the area, 161,881 hectares or about 400,000 acres. A companion field instrument, the Rapid Assessment Protocol version 2.0 (Shamgochian, Hagan, Taylor and Reed 2025), provides the ground scoring used to train and validate the map. A subsequent report from the Property and Environment Research Center (Thompson, Daigneault, Plisinski, Moon and Norton 2026) builds directly on the LiDAR map to delineate tens of thousands of forest patches and to estimate that protecting the highest-priority half would cost on the order of $200 to $300 million, with a full fee-acquisition figure near $422 million. This work is now informing Maine policy, including the LD 1529 mandate for a comprehensive LSOG conservation strategy.

The forest in question does not stop at Maine's borders. The Acadian and northern hardwood forests of Maine grade into the White and Green Mountains of New Hampshire and Vermont and the Adirondacks of New York, and the same definitional and measurement questions apply across all of them. A regional view is therefore not a digression; it is the correct frame for understanding what Maine's numbers mean.

---

## 2. Primary limitations of the LiDAR analysis and the RAP protocol

### 2.1 The 90 percent figure measures label agreement, not map correctness

The reported accuracy of the LiDAR map is the rate at which the classifier reproduces the project's own field-assigned training labels. It is a measure of internal consistency, not of correctness against an independent reference. A model can reproduce its training labels 90 percent of the time and still place markedly different amounts of forest in markedly different places than an equally well-trained model built on a different but equally defensible definition. For decisions that select specific acres, the relevant question is not how well the model fits its own labels but how well independent operationalizations agree on the ground, and how the rare, high-value old-growth class is detected. On the project's own out-of-bag accounting, only about 29 percent of true old-growth hectares were classified as old-growth-like; the headline accuracy is carried by the common non-old-growth class. The point is sharper in the paper's field validation, which contained no true old-growth sites at all, so the rarest and highest-value class, the one a conservation program would most want to locate, was never field-verified.

### 2.2 Canopy LiDAR maps big-tree forest, not old growth

Old growth is defined ecologically by large old trees, structural complexity, and abundant dead wood. Airborne canopy LiDAR predicts large-tree structure moderately well but is largely insensitive to the dead-wood component, standing snags and downed logs, that distinguishes genuine old growth from merely tall forest. A classifier keyed on canopy height and cover therefore registers tall, continuous canopy whether it was produced by an old, complex stand or by a fast-growing 80- to 100-year-old stand. From ground inventory, big-tree forest is roughly three to four times more extensive than forest meeting an age or full-structural criterion, which bounds the magnitude of the over-inclusion a height-based map produces.

### 2.3 The field protocol itself de-weights dead wood, and was not trained on softwood

The Rapid Assessment Protocol is itself a 17-metric random forest classifier. In that classifier, large standing dead trees rank last of the seventeen metrics in importance and large downed logs rank thirteenth, even though the protocol's own text calls large logs one of the best indicators of old growth. The signals that carry the classification are treefall gaps, large live trees, and harvest-history evidence such as sawn stumps and skid trails. The dead-wood component is therefore under-weighted not only by the LiDAR but by the field labels used to train it. The protocol was also developed on training plots that were mostly hardwood, with no purely softwood stands, and its authors caution against applying it to pure softwood; this matters because upland spruce-fir is a signature Acadian late-successional forest type. The protocol's own field accuracy is about 74 percent, distinct from the 90 percent figure attached to the LiDAR map.

### 2.4 Independent credible maps disagree substantially

When three independent remote-sensing operationalizations of LSOG, differing in sensor and definition, are compared over the same area on a common grid, they disagree both in amount and in location. The two structure-resolution maps, the airborne-LiDAR classifier and a spaceborne canopy-height model, place LSOG on 21.9 and 14.0 percent of the forest respectively, a 1.6-fold difference, and agree spatially only modestly. Adding a coarser continental old-growth product widens the range to 2.6-fold, and only a few percent of the acres flagged by any map are flagged by all three. No single map is ground truth. For a prioritization that selects specific parcels, the choice of map, not just the choice of parcels, drives most of the resulting selection.

### 2.5 No uncertainty is carried into the prioritization

The downstream prioritization delineates its patches and ranks them for acquisition directly from the single binary map, with no propagation of the map's classification uncertainty. Its own authors note that each prioritization metric would need field validation before any investment is committed, and that most old-growth area sits in very small patches whose boundaries, and therefore whose size-based priority, are sensitive to exactly the classification uncertainty that is not carried forward. A probabilistic surface with explicit bounds is the appropriate substrate for parcel-level spending.

### 2.6 A single number without an interval

The mapped area is reported as a single percentage without the sampling interval that any estimate of a rare condition should carry. A menu of standard fixes for rare events, class weighting, balanced sub-sampling, and lowering the voting threshold, raises old-growth detection from about a quarter to over 80 percent and more than doubles the mapped old-growth area, from 1.0 to 2.3 percent, which shows directly that the single headline number is a modeling choice rather than a fixed quantity, and is best reported with that sensitivity made explicit.

### 2.7 The training data are not a representative sample of the landscape

The map was trained on 463 hectares selected by expert judgment and a search for older-forest features, anchored on known old-growth sites such as Big Reed Reserve, rather than on a representative or random sample of the working landscape. As a result the training set is heavily weighted toward older forest: roughly a fifth of the training hectares fall in the rare late-successional and old-growth classes, against 3.9 percent of the actual landscape, and the model was fit without correcting for that imbalance. A classifier trained on a class mix that does not match the landscape produces an extent estimate that is not anchored to the real frequency of older forest, which is one reason the mapped area moves so much under rebalancing. A defensible map needs a balanced, representative training dataset that includes both late-successional and ordinary working forest drawn from across the landscape, or a design-based probability sample such as the Forest Inventory and Analysis program, which is representative by construction. The map should then be field-verified against independent datasets that actually contain old growth, such as the ecological reserve network including Big Reed and the Baxter State Park inventory used in this analysis, including the old-growth class that the original field validation did not sample at all.

---

## 3. Our primary findings: a regional, design-based account

### 3.1 How much LSOG: a range with intervals, not a point

Using design-based estimation from the FIA probability sample, older forest in Maine by transparent ground criteria is 12.1 percent of forestland at stand age 100 years or more (95 percent confidence interval 10.9 to 13.2), 3.9 percent at 120 years or more (3.3 to 4.6), and 0.7 percent at 150 years or more (0.4 to 1.0), with live large-tree basal area at 12.5 percent (11.4 to 13.7). Under our integrated multi-axis structural proxy, Maine carries 14.1 percent (12.9 to 15.3). These intervals, absent from map-only accounts, are the appropriate unit for high-stakes use. The federal mature-and-old-growth threat analysis reached the same methodological conclusion from the opposite direction: it could not resolve eastern old growth at the national scale because FIA plots are too sparse there, which is precisely why a region-targeted design-based estimate with its interval is the right tool.

### 3.2 It depends how you count: the four-axis funnel

We define LSOG on four axes, live large-tree structure, dead wood, compositional maturity, and temporal continuity verified from the full Landsat disturbance record. Requiring more axes sharply reduces the qualifying share. Across the four-state region, 84 to 96 percent of forest passes at least one axis, but only a small fraction passes all four, which we treat as true LSOG: about 3.1 percent in Maine, 12.8 percent in New Hampshire, 15.2 percent in Vermont, and 12.2 percent in New York. The same forest is therefore anywhere from 3 percent to over 90 percent LSOG depending on the definition. This is the single most important point for policy: the headline percentage is a choice about how many criteria to require, and that choice should be made explicitly and reported as a range.

### 3.3 Regional context: New England as a working-forest triad

Across northern New England and the adjacent Adirondacks, the late-successional condition is unevenly distributed in a way that reflects each state's forest history and function. Maine's heavily worked industrial timberland anchors the production tier; the aging old-field forests of New Hampshire and Vermont and the Adirondack reserves of New York carry a disproportionate share of the late-successional and reserve tiers. Maine's low share is thus the expected signature of its role in a regional division of forest function, not evidence that Maine should be made to match its neighbors acre for acre. The conservation-relevant question is not per-state parity but whether the late-successional condition is adequately represented across the region's forest types and ecoregions, which our analysis shows is broad but uneven: true LSOG is present in seven of the eight forest-type groups but concentrates in the northern hardwood and pine types and is thin in spruce-fir and the early-successional types. A regional late-successional strategy should focus on the under-represented types and ecoregions, not on Maine's aggregate share.

### 3.4 The stock is stable to rising, not collapsing

The premise of rapid loss rests on a gross harvest flux, the mapped acres that subsequently experienced canopy removal. That flux is real, on the order of 2 percent per year of mapped LSOG, but it is not the net trend. Over 2003 to 2024 the FIA design-based older-forest stock increased across the operational age and structure measures, with confidence intervals excluding zero, while total forestland area stayed flat. Both statements are true at once: individual older stands are harvested, and the total older-forest stock is not declining, because younger stands age into the older condition faster than older stands are removed. Where a rate of loss is invoked to convey urgency, the flux and the net stock should be distinguished, because they point in opposite directions.

### 3.5 A probabilistic, multi-model map with quantified uncertainty

Rather than a single binary map, we produce a probability surface for LSOG and quantify the uncertainty that comes from the choice of statistical model (Figure 2). Five structurally different learners, trained on the same plots and predictors, produce markedly different wall-to-wall predictions: their average mapped probability ranges from 0.26 to 0.59 across methods, and the spread between the models, averaging 0.18 on a zero-to-one scale, is itself a mappable measure of how much the answer depends on choices the modeler makes rather than on the forest (Figure 2b). The ensemble average is the best single estimate, and any binary class drawn from it is calibrated to the design-based area so that over-prediction is bounded by the unbiased estimate. A global sensitivity analysis makes plain why a canopy-based map is limited: canopy height alone accounts for essentially all of the explained variation in the modeled probability, with the Landsat disturbance signal a secondary modifier. A classifier keyed on canopy height is therefore resolving one dominant axis and is structurally unable to capture the dead-wood and continuity components that distinguish genuine old growth. This is the product a high-stakes user should rely on: it shows not only where LSOG is likely but where the maps disagree, which is exactly the information a single accuracy number conceals.

---

## 4. Robustness: stress testing the conclusions

We stress tested the headline conclusions against the analytical choices most likely to be questioned. The finding that Maine carries the lowest integrated LSOG share in the region holds under every reasonable scoring threshold, holds when the canopy dimension is removed from the score entirely, and holds across independent FIA measurement panels, failing only at an extreme strictness where every state's share collapses to about one tenth of one percent and the ordering is statistical noise. The rarity of true LSOG holds across five different ways of drawing the temporal-continuity axis. The cross-map disagreement is not an artifact of any one comparison product. And the older-forest area estimate carries a bootstrap confidence interval rather than a single point. The conclusions are not knife-edge results that depend on a particular threshold; they are stable features of the data.

---

## 5. Implications for Maine and the regional forest economy

For the Maine Forest Products Council and the LD 1529 process, several points follow directly. Maine does have comparatively little forest that meets a full late-successional definition, but this reflects an active, productive working forest operating within a regional system in which other states carry more of the late-successional and reserve functions, not a uniform deficit to be closed within Maine. The net older-forest stock is stable to rising, so the framing of imminent, rapid, statewide loss is not supported by the ground inventory, even though individual high-value stands are genuinely harvested and can be lost. Any conservation prioritization that proposes hundreds of millions in spending should rest on a map whose uncertainty is characterized and carried forward, should be field-verified at the parcel scale before acquisition, and should report area as a range with its sampling interval rather than as a single number. The most acreage-relevant conservation levers, if the goal is regional representation, are the under-represented forest types and the private-timberland late-successional pool that holds most of the regional acreage, addressable through working-lands easements, payment-for-ecosystem-services arrangements, and targeted reserve placement, instruments compatible with a working forest.

---

## 6. Recommendations

Report LSOG extent as a method range with design-based sampling intervals, not as a single percentage. Treat the combined late-successional-plus-old-growth class as the stable unit for policy, since the old-growth-only class is genuinely product-specific and uncertain. Before acres are prioritized for acquisition or enrolled in markets, cross-check any single map against at least one independent product and field-verify at the parcel scale. Distinguish the gross harvest flux from the net stock trend wherever a rate of loss is cited. And frame the conservation objective regionally, around adequate representation of the late-successional condition across the forest types and ecoregions of northern New England and the Adirondacks, rather than around per-state parity.

---

## Appendix: detailed results with 95% confidence intervals

This appendix collects the full quantitative basis for the findings above. Every estimate carries a 95% confidence interval: design-based intervals for the inventory and representation estimates, Wilson intervals for the validation proportions.

**Table A1. Design-based older-forest and LSOG area for Maine, with 95% CI.** From the FIA probability sample (rFIA, post-stratified). The single-axis age and structure criteria are 2024; the multi-axis classes are the 2019-2023 panel.

| Criterion | Maine forestland % [95% CI] |
|---|---|
| Stand age >= 100 yr | 12.1 [10.9, 13.2] |
| Stand age >= 120 yr | 3.9 [3.3, 4.6] |
| Stand age >= 150 yr | 0.7 [0.4, 1.0] |
| Large-tree basal area (trees >= 40 cm dbh, >= 30 ft^2/ac) | 12.5 [11.4, 13.7] |
| Integrated any-LSOG (structural proxy) | 14.1 [12.9, 15.3] |
| True LSOG, all four axes (incl. Landsat continuity) | 3.1 [2.5, 3.7] |

**Table A2. The four-axis funnel: true LSOG by state, with 95% CI.** Requiring all four axes (live large-tree structure, dead wood, composition, Landsat-verified continuity).

| State | True LSOG % [95% CI] | Integrated any-LSOG % [95% CI] |
|---|---|---|
| Maine | 3.1 [2.5, 3.7] | 14.1 [12.9, 15.3] |
| New Hampshire | 12.8 [10.7, 15.0] | 31.2 [28.0, 34.3] |
| Vermont | 15.2 [12.7, 17.6] | 28.8 [25.4, 32.3] |
| New York | 12.2 [11.1, 13.4] | 27.2 [25.2, 29.0] |

**Table A3. Representation of true LSOG by forest-type group (design-based, four states pooled), with 95% CI.**

| Forest-type group | Total forest (K ac) | True LSOG % [95% CI] |
|---|---|---|
| Maple/beech/birch (northern hardwood) | 22,995 | 11.6 [10.6, 12.7] |
| Spruce/fir | 7,428 | 2.1 [1.3, 2.8] |
| Oak/hickory | 4,432 | 6.6 [4.7, 8.6] |
| White/red/jack pine | 3,387 | 21.2 [17.2, 25.3] |
| Aspen/birch | 2,527 | 0.6 [0.0, 1.3] |
| Elm/ash/cottonwood | 1,772 | 0.0 [0.0, 0.0] |
| Oak/pine | 1,475 | 16.4 [10.8, 22.0] |
| Other softwood | 258 | 1.8 [0.0, 5.0] |

**Table A4. Representation of true LSOG by EPA Level III ecoregion (design-based), with 95% CI.**

| Ecoregion | Total forest (K ac) | True LSOG % [95% CI] |
|---|---|---|
| Northeastern Highlands | 23,883 | 12.5 [11.5, 13.5] |
| Acadian Plains and Hills | 8,887 | 2.1 [1.4, 2.9] |
| Northern Allegheny Plateau | 5,421 | 9.2 [7.1, 11.2] |
| Eastern Great Lakes Lowlands | 3,709 | 4.0 [2.3, 5.6] |
| Northeastern Coastal Zone | 1,851 | 9.4 [5.9, 12.8] |

**Table A5. Cross-map comparison: three independent remote-sensing operationalizations over the Maine study area.**

| Map | Any-LSOG (% of area) | kappa vs LiDAR | kappa vs canopy |
|---|---|---|---|
| Airborne LiDAR (Hagan et al. 2024) | 21.9 | -- | 0.22 |
| Potapov/GEDI spaceborne canopy height | 14.0 | 0.22 | -- |
| ORNL old-growth stratum (Bruening) | 36.1 | -0.02 | -0.07 |
| Agreed by all three (% of flagged area) | 2.7 | | |

**Table A6. Rare-class remedies for the reproduced airborne-LiDAR random forest (old growth = rare event).** Old-growth detection and mapped area both move sharply, confirming the headline area is a modeling choice.

| Strategy | OG detection (recall) | Mapped OG area (%) |
|---|---|---|
| Default, unbalanced | 0.24 | 1.0 |
| Class weighting | 0.29 | 0.8 |
| Balanced sub-sampling | 0.71 | 1.9 |
| Voting-threshold adjustment | 0.82 | 2.3 |

**Table A7. Independent validation against field reserves, with Wilson 95% CI.** Our four-axis structural criteria versus the reproduced Hagan map at the same coordinates.

| Reference (n plots) | Our criteria % [95% CI] | LiDAR map % [95% CI] |
|---|---|---|
| Big Reed Forest Reserve (25) | 72 [52, 86] | 80 [61, 91] |
| Ecological reserve network (819) | 67 [64, 70] | 57 [54, 60] |
| Baxter SFMA, large-tree axis (90) | 98 [92, 99] | -- |
| Baxter SFMA, continuity axis (90) | 82 [73, 89] | -- |
| Baxter SFMA, LiDAR-map LSOG (90) | -- | 57 [46, 66] |

**Table A8. Final robustness summary: each headline conclusion and the stress it survives.**

| Conclusion | Stress applied | Result | Robust |
|---|---|---|---|
| Maine carries the lowest LSOG share | thresholds, drop canopy dimension, FIA panels | lowest in 8 of 9 tests | yes |
| True LSOG is rare (3 to 5% in Maine) | five continuity definitions | 3.1 to 5.2% | yes |
| Credible maps disagree | three independent RS products | 1.6 to 2.6 fold | yes |
| Half the cross-map disagreement is geolocation | fuzzed vs true coordinates | kappa 0.13 to 0.29 | yes |
| Rare-class detection and area are choice-driven | four RF strategies | recall 0.24 to 0.82; area 1.0 to 2.3% | yes |
| Model structure dominates map uncertainty | five-learner ensemble | mean P 0.26 to 0.59, SD 0.18 | quantified |
| Canopy height drives the signal | Sobol indices | first-order ~1.0 | yes |
| Both maps detect most reserve old growth | reserve/Big Reed/Baxter validation | see Table A7 | yes |

---

## 7. Methods and data availability

Estimates use design-based, post-stratified FIA estimation (Bechtold and Patterson 2005; rFIA, Stanke et al. 2020) over all available inventory years for Maine, New Hampshire, Vermont, and New York. The four-axis classification combines FIA tree- and condition-level structure with a temporal-continuity axis derived from the USFS Landscape Change Monitoring System (LCMS) Landsat disturbance record, 1985 to 2023. The cross-map assessment compares a reproduced airborne-LiDAR classifier, a Potapov GEDI-calibrated spaceborne canopy-height model, and the ORNL national old-growth product on a common 100 meter grid. The multi-model probability surface ensembles five learners and reports across-model uncertainty, with global sensitivity quantified by variance-based Sobol indices. All code and derived products are openly archived (Zenodo concept DOI 10.5281/zenodo.20614496). No FIA plot coordinates are released; all products are derived rasters or aggregate summary tables.
