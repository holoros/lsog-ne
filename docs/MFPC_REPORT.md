# Late-Successional and Old-Growth Forest Across Northern New England

## What the Inventory Shows, and the Limits of LiDAR-Based Mapping

### A Technical Report for the Maine Forest Products Council

Prepared by Aaron R. Weiskittel and colleagues, Center for Research on Sustainable Forests, University of Maine. June 2026.

---

## Executive summary

Recent LiDAR-based maps have drawn welcome attention to older forest in Maine's working landscape, and a downstream analysis has proposed protecting the highest-priority mapped acres at a cost on the order of $200 to $300 million. Before a single map anchors spending at that scale, its fitness for the purpose should be examined, and the question reframed from one state to the region it belongs to. This report does both.

Our central findings are four. First, how much late-successional and old-growth (LSOG) forest exists is not a single number but a range that depends on how the condition is defined and that carries a sampling interval; the honest unit is the design-based estimate from the Forest Inventory and Analysis (FIA) program, reported with its confidence bounds. Second, the same forest is anywhere from about 3 percent to over 90 percent LSOG depending on how many structural criteria a definition requires, so the headline percentage is a definitional choice as much as a measurement. Third, across northern New England and the adjacent Adirondacks, Maine carries the lowest integrated LSOG share, but this is the expected signature of its production role in a regional division of forest function, not a deficiency to be corrected state by state. Fourth, the older-forest stock is stable to rising across the region over the last two decades, even as individual mapped stands are harvested, because younger stands age into the older condition faster than the older stands are cut. The widely cited rate of loss measures a gross harvest flux, not a declining net stock.

On the mapping itself, we document specific, quantifiable limitations of the LiDAR analysis and the field protocol behind it. The reported 90 percent accuracy measures agreement with the project's own training labels, not correctness against an independent standard. Canopy LiDAR is sensitive to tall, big-tree forest but largely blind to the dead wood and disturbance history that distinguish genuine old growth, and the field protocol used to train the map de-weights dead wood as well. Independent, equally credible remote-sensing maps of the same forest disagree by a factor of 1.6 to 2.6 in how much LSOG exists and agree on only a small fraction of the specific ground. The prioritization that proposes hundreds of millions in spending inherits the single map without carrying any of its uncertainty forward.

None of this argues against conserving older forest in Maine, which is a legitimate and shared goal. It argues that regional accounting should report a defensible range with intervals, that maps used for high-stakes allocation should be cross-checked and field-verified, and that a probabilistic product with explicit uncertainty, not one binary map, is the appropriate basis for parcel-level decisions.

---

## 1. Background

In 2024, a team led by John Hagan (Our Climate Common) used publicly available airborne LiDAR to classify late-successional and old-growth forest across roughly 10 million acres of Maine's unorganized townships, reporting that about 4 percent of the area, on the order of 400,000 acres, is in a late-successional or old-growth-like condition. A companion field instrument, the Rapid Assessment Protocol version 2.0 (Shamgochian, Hagan, Taylor and Reed 2025), provides the ground scoring used to train and validate the map. A subsequent report from the Property and Environment Research Center (Thompson, Daigneault, Plisinski, Moon and Norton 2026) builds directly on the LiDAR map to delineate tens of thousands of forest patches and to estimate that protecting the highest-priority half would cost on the order of $200 to $300 million, with a full fee-acquisition figure near $422 million. This work is now informing Maine policy, including the LD 1529 mandate for a comprehensive LSOG conservation strategy.

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

The mapped area is reported as a single percentage without the sampling interval that any estimate of a rare condition should carry. A routine modeling choice, rebalancing the classifier to better detect the rare old-growth class, nearly doubles the mapped old-growth area, which shows directly that the single headline number should not be taken at face value.

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

## 7. Methods and data availability

Estimates use design-based, post-stratified FIA estimation (Bechtold and Patterson 2005; rFIA, Stanke et al. 2020) over all available inventory years for Maine, New Hampshire, Vermont, and New York. The four-axis classification combines FIA tree- and condition-level structure with a temporal-continuity axis derived from the USFS Landscape Change Monitoring System (LCMS) Landsat disturbance record, 1985 to 2023. The cross-map assessment compares a reproduced airborne-LiDAR classifier, a Potapov GEDI-calibrated spaceborne canopy-height model, and the ORNL national old-growth product on a common 100 meter grid. The multi-model probability surface ensembles five learners and reports across-model uncertainty, with global sensitivity quantified by variance-based Sobol indices. All code and derived products are openly archived (Zenodo concept DOI 10.5281/zenodo.20614496). No FIA plot coordinates are released; all products are derived rasters or aggregate summary tables.
