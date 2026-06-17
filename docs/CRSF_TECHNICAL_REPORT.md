# Late-Successional and Old-Growth Forest Across Northern New England

## What the Inventory Shows, and the Limits of LiDAR-Based Mapping

### A General Technical Assessment of Late-Successional and Old-Growth Forest Inventory and Mapping in Maine and Northern New England

Aaron Weiskittel, Center for Research on Sustainable Forests, University of Maine.

June 2026.

This is a general technical assessment, prepared independently to inform the ongoing discussion of late-successional and old-growth forest in Maine and the surrounding region, including the LD 1529 process. It was not prepared for, or at the request of, any single organization.

---

## Executive summary

Recent LiDAR-based maps have drawn welcome attention to older forest in Maine's working landscape, and a downstream analysis has proposed protecting the highest-priority mapped acres at a cost on the order of $200 to $300 million. Before a single map anchors spending at that scale, its fitness for the purpose should be examined, and the question reframed from one state to the region it belongs to. This report does both.

Our central findings are four. First, how much late-successional and old-growth (LSOG) forest exists is not a single number but a range that depends on how the condition is defined and that carries a sampling interval; the honest unit is the design-based estimate from the Forest Inventory and Analysis (FIA) program, reported with its confidence bounds. Second, the same forest is anywhere from about 3 percent to over 90 percent LSOG depending on how many structural criteria a definition requires, so the headline percentage is a definitional choice as much as a measurement. Third, across northern New England and the adjacent Adirondacks, Maine carries the lowest integrated LSOG share, but this is the expected signature of its production role in a regional division of forest function, not a deficiency to be corrected state by state. Fourth, the older-forest stock is stable to rising across the region over the last two decades, even as individual mapped stands are harvested, because younger stands age into the older condition faster than the older stands are cut. The widely cited rate of loss measures a gross harvest flux, not a declining net stock.

On the mapping itself, we document specific, quantifiable limitations of the LiDAR analysis and the field protocol behind it. The reported 90 percent accuracy measures agreement with the project's own training labels, not correctness against an independent standard. Canopy LiDAR is sensitive to tall, big-tree forest but largely blind to the dead wood and disturbance history that distinguish genuine old-growth, and the field protocol used to train the map de-weights dead wood as well. Independent, equally credible remote-sensing maps of the same forest disagree by a factor of 1.6 to 2.6 in how much LSOG exists and agree on only a small fraction of the specific ground. The prioritization that proposes hundreds of millions in spending inherits the single map without carrying any of its uncertainty forward.

None of this argues against conserving older forest in Maine, which is a legitimate and shared goal. It argues that regional accounting should report a defensible range with intervals, that maps used for high-stakes allocation should be cross-checked and field-verified, and that a probabilistic product with explicit uncertainty, not one binary map, is the appropriate basis for parcel-level decisions.

As the constructive alternative, this report presents not a single replacement map but a multi-map comparison anchored to the inventory. Several independent, credible maps of the same forest, the published LiDAR classifier, a spaceborne canopy-height map, a continental old-growth product, and our own design-calibrated multi-model probability surface (Figure 6), are placed side by side and each held to the design-based FIA total. No single map is treated as truth: the map is the primary product a user acts on, and the design-based inventory is what keeps every map honest. Where a map's total agrees with the inventory it earns trust; where it departs, the burden is on the map. We are extending this comparison with a native-resolution, 10-meter product built from modern satellite embeddings (Section 3.6) that resolves the small remnants a coarse-grid map cannot, calibrated to the same FIA anchor.

---

## 1. Background

Late-successional and old-growth (LSOG) forest has become an active focus of mapping and policy across the conterminous United States, and the most productive posture is to learn from that collective body of work rather than to treat any single product as definitive. A 2022 federal executive order directed the Forest Service and the Bureau of Land Management to define and inventory mature and old-growth forest on federal lands, producing the first national accounting (U.S. Executive Order 14072 2022; USDA Forest Service and USDI Bureau of Land Management 2023). In parallel, the Forest Service has standardized field criteria for old-growth across its regions (Pelz et al. 2023), continental old-growth probability layers have been produced from spaceborne data (Bruening et al. 2026), and global canopy-height products now integrate spaceborne GEDI LiDAR with Landsat at moderate resolution (Potapov et al. 2021). These efforts share a common difficulty: older forest is rare, structurally heterogeneous, and operationalized differently by different programs, so independent and individually credible methods can disagree substantially on both how much exists and where it sits. That recurring disagreement, rather than any single map's error, is the central lesson this report builds on.

Within this national context, a recent study applied publicly available airborne LiDAR to classify LSOG forest across roughly 10 million acres of Maine's unorganized townships (Hagan et al. 2026), reporting that the combined late-successional and old-growth-like class covers 3.9 percent of the area, 161,881 hectares or about 400,000 acres. A companion field instrument, the Rapid Assessment Protocol version 2.0 (Shamgochian et al. 2025), provides the ground scoring used to train and validate the map. A subsequent report from the Property and Environment Research Center (Thompson et al. 2026) builds directly on the LiDAR map to delineate tens of thousands of forest patches and to estimate that protecting the highest-priority half would cost on the order of $200 to $300 million, with a full fee-acquisition figure near $422 million. This work is now informing Maine policy, including the LD 1529 mandate for a comprehensive LSOG conservation strategy.

The forest in question does not stop at Maine's borders. The Acadian and northern hardwood forests of Maine grade into the White and Green Mountains of New Hampshire and Vermont and the Adirondacks of New York, and the same definitional and measurement questions apply across all of them. A regional view is therefore not a digression; it is the correct frame for understanding what Maine's numbers mean.

---

## 2. Primary limitations of the LiDAR analysis and the RAP protocol

The published LiDAR map is a legitimate screening contribution that has drawn welcome attention to older forest. The limitations below matter not because the map exists, but because it has become the single substrate for a parcel-level acquisition program on the order of $200 to $300 million. The specific, documentable limitations below bear on that use; for each, the table pairs the limitation with a recommendation to address it and with what our own design-based analysis finds:

| Limitation of the published LiDAR analysis | Recommendation to address it | What our analysis finds | Confidence |
|---|---|---|---|
| 90 percent accuracy is internal label agreement, not correctness; old-growth is detected about 29 percent of the time and the class was not field-validated (no true old-growth sites were sampled in the field) | Validate against an independent standard and field-sample the old-growth class with a probability design | In-sample discrimination is high (AUC about 0.91 to 0.99 across methods), but old-growth operating accuracy is about 29 percent; the rare class is the binding constraint | High |
| Canopy LiDAR maps tall, big-tree forest, not old-growth, and is blind to dead wood | Measure the dead-wood and disturbance-history axes directly; treat canopy height as a proxy, not a definition | LiDAR predicts large-tree basal area at R-squared about 0.68 but dead wood at about 0.20; big-tree forest is roughly three times ground-defined old forest | High |
| A single, universal LSOG definition is assumed to exist and is applied across every forest type and ecoregion | Use ecoregion and forest-type-specific structural criteria, calibrated to reference stands within each type, rather than one threshold | A type-agnostic threshold flags 32 percent of reserve plots; forest-type-specific criteria flag 67 percent, recovering low-stature spruce-fir and cedar old-growth (29 to 68 percent). Maine's own documented old-growth inventory is organized by seven forest types, each with its own age and size signature | Medium |
| The field protocol that trained the map de-weights dead wood and was developed mainly on hardwood stands | Re-weight dead wood in the protocol, develop and validate criteria for softwood-dominated stands, and report protocol accuracy (about 74 percent) separately | Large snags rank last of 17 protocol metrics; forest-type-specific criteria recover spruce-fir flagging from 29 to 68 percent | Medium |
| Independent, equally credible maps disagree 1.6 to 2.6 fold | Cross-check any single map against at least one independent product and report spatial agreement | Airborne LiDAR 21.9 percent versus canopy height 14.0 percent (kappa 0.22); only 2.7 percent of flagged ground is agreed by all three | High |
| No classification uncertainty is carried into the parcel-level prioritization | Propagate classification uncertainty into the ranking; use a probabilistic surface, not one binary map | Under the map's own across-model uncertainty, the top 5 percent acquisition set overlaps the baseline by only 0.10 (Jaccard) | Medium |
| The map is a single hard class from a default majority-vote threshold, with no cutpoint chosen for the rare old-growth class | Carry the probability surface forward and set the operating threshold explicitly for the decision, since no single cutpoint is optimal for every objective | On our fused model the discrimination-optimal cutpoint (Youden's J) is 0.36, where precision is only about 0.51 at the training prevalence and falls under 1 percent at the 0.2 percent old-growth prevalence (Figure 9); a default majority vote is not optimal for a rare target | Medium |
| Extent is a single percentage with no interval and doubles under rebalancing | Report a design-based estimate with a confidence interval and make the rare-class sensitivity explicit | Design-based integrated any-LSOG is 14.1 percent [12.9 to 15.3] and older forest (age >= 120 yr) 3.9 percent [3.3 to 4.6]; rebalancing more than doubles mapped old-growth | High |
| Training data are a purposive, old-growth-enriched sample, not a probability sample | Train on a balanced, representative sample or anchor to a design-based sample (FIA), and validate on independent old-growth data | Training is about 20 percent LSOG against 3.9 percent of the landscape; we anchor to FIA plus 4,263 true-coordinate reserve and Baxter plots that include real old-growth | High |
| The 1-hectare mapping unit is too coarse to resolve the small remnants (often 1 to 5 hectares) where much true old-growth survives | Map at the native resolution of the sensor (high-resolution airborne LiDAR; 10 m embeddings) with true-coordinate validation | A 10 m embedding product resolves sub-hectare patches and discriminates the multi-axis any-LSOG class at AUC about 0.82 (TESSERA alone) and 0.87 (fused; Section 3.6), good but not perfect, so inventory remains the area backbone | Medium |
| The estimate was produced at a single 1-hectare grain (1-square-meter LiDAR metrics averaged to the hectare, then classified once) with no test of resolution sensitivity | Report the LSOG estimate across a range of grains and hold resolution fixed in any map-to-map or map-to-inventory comparison | The flagged LSOG share falls steadily from 22 percent at 10 m to 17.5 percent at the 1-hectare grid to 14.9 percent at 200 m, a one-third relative swing from grain alone; area-based LiDAR estimates are known to shift with cell size in these forests (Hayashi et al. 2016) | High |

Confidence is reported as High, Medium, or Low. **High** means the finding rests on a design-based estimate with a 95 percent confidence interval, on an independent reproduction of the original model, or on a result that holds across every stress test applied. **Medium** means it rests on a single method or a model-based result whose sensitivity is known and bounded. **Low** means it rests on a rare class or a small sample, so the direction is clear but the point estimate remains uncertain.

Each is detailed below.

### 2.1 The 90 percent figure measures label agreement, not map correctness

The reported accuracy of the LiDAR map is the rate at which the classifier reproduces the project's own field-assigned training labels. It is a measure of internal consistency, not of correctness against an independent reference. A model can reproduce its training labels 90 percent of the time and still place markedly different amounts of forest in markedly different places than an equally well-trained model built on a different but equally defensible definition. For decisions that select specific acres, the relevant question is not how well the model fits its own labels but how well independent operationalizations agree on the ground, and how the rare, high-value old-growth class is detected. On the project's own out-of-bag accounting, only about 29 percent of true old-growth hectares were classified as old-growth-like; the headline accuracy is carried by the common non-old-growth class. The point is sharper in the paper's field validation, which contained no true old-growth sites at all, so the rarest and highest-value class, the one a conservation program would most want to locate, was not field-verified.

### 2.2 Canopy LiDAR maps big-tree forest, not old-growth

Old growth is defined ecologically by large old trees, structural complexity, and abundant dead wood. Airborne canopy LiDAR predicts large-tree structure moderately well but is largely insensitive to the dead-wood component, standing snags and downed logs, that distinguishes genuine old-growth from merely tall forest. A classifier keyed on canopy height and cover therefore registers tall, continuous canopy whether it was produced by an old, complex stand or by a fast-growing 80- to 100-year-old stand. From ground inventory, big-tree forest is roughly three to four times more extensive than forest meeting an age or full-structural criterion, which bounds the magnitude of the over-inclusion a height-based map produces.

### 2.3 The field protocol de-weights dead wood and was developed mainly on hardwood stands

The Rapid Assessment Protocol is itself a 17-metric random forest classifier. In that classifier, large standing dead trees rank last of the seventeen metrics in importance and large downed logs rank thirteenth, even though the protocol's own text calls large logs one of the best indicators of old-growth. The signals that carry the classification are treefall gaps, large live trees, and harvest-history evidence such as sawn stumps and skid trails. The dead-wood component is therefore under-weighted not only by the LiDAR but by the field labels used to train it. The protocol was also developed on training plots that were mostly hardwood, with no purely softwood stands, and its authors caution against applying it to pure softwood; this matters because upland spruce-fir is a signature Acadian late-successional forest type. The protocol's own field accuracy is about 74 percent, distinct from the 90 percent figure attached to the LiDAR map.

### 2.4 Independent credible maps disagree substantially

When three independent remote-sensing operationalizations of LSOG, differing in sensor and definition, are compared over the same area on a common grid, they disagree both in amount and in location. The two structure-resolution maps, the airborne-LiDAR classifier and a spaceborne canopy-height model, place LSOG on 21.9 and 14.0 percent of the forested area respectively, a 1.6-fold difference, and agree spatially only modestly (the airborne-LiDAR figure is 19.7 percent when expressed over the full study area rather than the forested area alone). Adding a coarser continental old-growth product widens the range to 2.6-fold, and only a few percent of the acres flagged by any map are flagged by all three. No single map is ground truth. For a prioritization that selects specific parcels, the choice of map, not just the choice of parcels, drives most of the resulting selection. A fully like-for-like test makes this unambiguous. Regenerating the published classification from its own archived inputs, its random forest applied to the public hectare-level LiDAR statistics for all 4.28 million hectares of the study area, reproduces its reported extent to within about two percentage points (22.0 percent any-LSOG against 19.7 percent; the small residual reflects default classifier settings and grid alignment rather than the authors' exact configuration, while the model, predictors, and training labels are theirs). Setting our FIA-anchored 10-meter map to flag the identical amount, so the comparison is about location alone, the two then agree on only 7.7 percent of the landscape, each flagging about 14 percent the other does not, for a Cohen's kappa of 0.19. Neither map is ground truth and neither is being held up as correct; with the amount held fixed, two independent and comparably accurate methods (they perform similarly at known old-growth reserves) place that amount in largely different locations. That residual locational uncertainty is precisely the quantity a parcel-level acquisition program acts on.

On Seven Islands Land Company timberland, where an operational LSOG map already exists and was shared for this work, the same exercise can be run on common ground (Figure 2). Our independent FIA-anchored surface and the published classification are compared directly over the company's land: they agree on roughly how much LSOG is present yet place it in substantially different locations, the same locational disagreement seen across the full study area. That a working landowner's own map and an independent design-anchored map diverge on where, while agreeing on how much, is the clearest possible illustration of why location must be field-verified before parcel-level dollars are committed.

### 2.5 No uncertainty is carried into the prioritization

The downstream prioritization delineates its patches and ranks them for acquisition directly from the single binary map, with no propagation of the map's classification uncertainty. Its own authors note that each prioritization metric would need field validation before any investment is committed, and that most old-growth area sits in very small patches whose boundaries, and therefore whose size-based priority, are sensitive to exactly the classification uncertainty that is not carried forward. A probabilistic surface with explicit bounds is the appropriate substrate for parcel-level spending. Where the map's regional total does happen to agree with the design-based inventory total, that is agreement on how much, not on where; a parcel-level program acts on specific hectares, and it is the location of those hectares, not the regional total, that has not been independently validated.

### 2.6 A single number without an interval

The mapped area is reported as a single percentage without the sampling interval that any estimate of a rare condition should carry. A menu of standard fixes for rare events, class weighting, balanced sub-sampling, and lowering the voting threshold, raises old-growth detection from about a quarter to over 80 percent and more than doubles the mapped old-growth area, from 1.0 to 2.3 percent, which shows directly that the single headline number is a modeling choice rather than a fixed quantity, and is best reported with that sensitivity made explicit. This is not a claim that a rebalanced map is the more correct one: balancing trades omission of the rare class for commission, and which way the truth lies cannot be settled from the training labels alone. The point is only that the headline area is unstable to a routine modeling choice that no field validation has yet adjudicated.

### 2.7 The training data are not a representative sample of the landscape

The map was trained on 463 hectares selected by expert judgment and a search for older-forest features, anchored on known old-growth sites such as Big Reed Reserve, rather than on a representative or random sample of the working landscape. As a result the training set is heavily weighted toward older forest: roughly a fifth of the training hectares fall in the rare late-successional and old-growth classes, against 3.9 percent of the actual landscape, and the model was fit without correcting for that imbalance. A classifier trained on a class mix that does not match the landscape produces an extent estimate that is not anchored to the real frequency of older forest, which is one reason the mapped area moves so much under rebalancing. A defensible map needs a balanced, representative training dataset that includes both late-successional and ordinary working forest drawn from across the landscape, or a design-based probability sample such as the Forest Inventory and Analysis program, which is representative by construction. The map should then be field-verified against independent datasets that actually contain old-growth, such as the ecological reserve network including Big Reed, the Baxter State Park inventory used in this analysis, and the natural old-growth stands documented by the State's Critical Areas Program, which field-checked 104 stands and recommended 68 across seven forest types (hemlock, red and white spruce, white and red pine, cedar, oak, and hardwoods), including the old-growth class that the original field validation did not sample at all. A companion 1986 inventory of State lands confirmed fifteen of these as true old-growth on 1,553 acres, concentrated in Baxter State Park (889 acres) and the T.15 R.9 Deboullie unit (607 acres) in the northern study area, exactly where a map-based prioritization most needs an independent check. That the canonical Maine inventory is organized by forest type, each with its own age and size signature, is itself evidence that no single universal old-growth definition applies across the state.

---

### 2.8 The one-hectare mapping unit under-resolves small remnants

Genuine old-growth in Maine survives largely as small remnants, and the published map's own patches are most commonly one to five hectares. A one-hectare classification barely resolves a one-hectare patch and does not resolve sub-hectare remnants, so the same grid that over-includes big-tree forest under-resolves the smallest, highest-value true old-growth. Resolving those remnants is a task for high-resolution airborne LiDAR validated at true field coordinates, not for a coarser product.

## 3. Our primary findings: a regional, design-based account

Our account rests on a deliberately independent evidence base. The amount of older forest comes from the FIA probability sample, which is representative by construction and is the unbiased benchmark for how much older forest exists. Location and validation draw on 4,263 true-coordinate field plots that actually contain old-growth: the FIA grid, the MNAP and TNC ecological reserve network including Big Reed, and the Baxter State Park inventory, together with Maine's own documented old-growth stands (68 recommended across seven forest types in 1983 and fifteen confirmed in 1986) and the operational LSOG map that Seven Islands Land Company shared from its working timberland. Remote sensing adds open satellite embeddings (Sentinel-1 and Sentinel-2) and canopy-height and disturbance layers. No finding here depends on a single proprietary dataset, and all derived products are openly archived. The sections that follow report what this evidence base shows about how much LSOG exists, how the answer depends on definition, how it is distributed regionally, whether it is declining, and where it most likely sits on the ground. The datasets shown in Figure 4, and the amount of LSOG each carries, are summarized below.

**Table 1. The datasets behind Figure 4, with the LSOG content of each and a key citation.** Field datasets are design-based or systematically measured; remote-sensing products are wall-to-wall over the study area.

| Dataset | Size / extent | LSOG content | Key citation |
|---|---|---|---|
| FIA probability sample (Maine) | 3,125 plots, 2019-2023 | Design-based: integrated any-LSOG 14.1% [12.9-15.3], LS 1.9% [1.4-2.3], OG 0.2% [0.1-0.4] | Bechtold and Patterson 2005; Stanke et al. 2020 |
| MNAP / TNC ecological reserve network | ~819 plots, 36 reserves | Reference old-growth; 67% pass forest-type-specific LSOG criteria (32% under a universal threshold) | Pelz et al. 2023 (criteria) |
| Baxter State Park inventory (CFI) | 90 plots | Large-tree axis 98% [92-99]; continuity axis 82% [73-89] | Baxter SFMA CFI |
| Big Reed Forest Reserve | 25 plots | 72% [52-86] true LSOG by the four-axis criteria | Maine State Planning Office 1983 |
| Documented old-growth, 1983 recommended | 68 stands, 7 forest types | Recommended natural old-growth (104 field-checked) | Maine State Planning Office 1983 |
| Confirmed old-growth, 1986 | 15 stands, 1,553 ac | Confirmed true old-growth on State land | Maine State Planning Office 1986 |
| Published airborne-LiDAR map (reproduced) | 4.28 M ha AOI | any-LSOG 21.9% of forested area | Hagan et al. 2026 |
| Potapov / GEDI spaceborne canopy height | Wall-to-wall | any-LSOG 14.0% | Potapov et al. 2021 |
| ORNL national old-growth stratum | CONUS, 100 m | Old-growth stratum 36.1% over the study area | Bruening et al. 2026 |

### 3.1 How much LSOG: a range with intervals, not a point

Using design-based estimation from the FIA probability sample, the primary structural criterion, live large-tree basal area, puts older forest in Maine at 12.5 percent of forestland (95 percent confidence interval 11.4 to 13.7), and our integrated multi-axis structural proxy, the v5.1 classifier that scores each plot on six structural dimensions and aggregates them into a single class, puts it at 14.1 percent (12.9 to 15.3). Stand-age thresholds are reported only as a cross-check, and the conclusions that follow do not rest on them: older forest is 12.1 percent at stand age 100 years or more (10.9 to 13.2), 3.9 percent at 120 years or more (3.3 to 4.6), and 0.7 percent at 150 years or more (0.4 to 1.0). FIA stand age is a weak instrument in this region, because field crews typically assign it from the cored age of one or a few site trees, which represents an uneven-aged northern stand poorly; we therefore lean on the structural and multi-axis measures rather than on any stand's assigned age. These intervals, absent from map-only accounts, are the appropriate unit for high-stakes use. The federal mature-and-old-growth threat analysis reached the same methodological conclusion from the opposite direction: it could not resolve eastern old-growth at the national scale because FIA plots are too sparse there, which is precisely why a region-targeted design-based estimate with its interval is the right tool.

### 3.2 It depends how you count: the four-axis funnel

We define LSOG on four axes, live large-tree structure, dead wood, compositional maturity, and temporal continuity verified from the full Landsat disturbance record. Requiring more axes sharply reduces the qualifying share. Across the four-state region, 84 to 96 percent of forest passes at least one axis, but only a small fraction passes all four, which we treat as true LSOG: about 3.1 percent in Maine, 12.8 percent in New Hampshire, 15.2 percent in Vermont, and 12.2 percent in New York. The same forest is therefore anywhere from 3 percent to over 90 percent LSOG depending on the definition. This is the most consequential point for policy: the headline percentage is a choice about how many criteria to require, and that choice should be made explicitly and reported as a range.

### 3.3 Regional context: New England as a working-forest triad

Across northern New England and the adjacent Adirondacks, the late-successional condition is unevenly distributed in a way that reflects each state's forest history and function. Maine's heavily worked industrial timberland anchors the production tier; the aging old-field forests of New Hampshire and Vermont and the Adirondack reserves of New York carry a disproportionate share of the late-successional and reserve tiers. Maine's low share is thus the expected signature of its role in a regional division of forest function, not evidence that Maine should be made to match its neighbors acre for acre. The conservation-relevant question is not per-state parity but whether the late-successional condition is adequately represented across the region's forest types and ecoregions, which our analysis shows is broad but uneven: true LSOG is present in seven of the eight forest-type groups but concentrates in the northern hardwood and pine types and is thin in spruce-fir and the early-successional types. A regional late-successional strategy should focus on the under-represented types and ecoregions, not on Maine's aggregate share.

### 3.4 The stock is stable to rising, not collapsing

The premise of rapid loss rests on a gross harvest flux, the mapped acres that subsequently experienced canopy removal. That flux is real, on the order of 2 percent per year of mapped LSOG, but it is not the net trend. Over 2003 to 2024 the FIA design-based older-forest stock increased across the operational age and structure measures, with confidence intervals excluding zero, while total forestland area stayed flat. The increase holds on the large-tree basal-area measure alone, which uses no age assignment, so the stable-to-rising result does not rest on modeled stand age. Both statements are true at once: individual older stands are harvested, and the total older-forest stock is not declining, because younger stands age into the older condition faster than older stands are removed. Where a rate of loss is invoked to convey urgency, the flux and the net stock should be distinguished, because they point in opposite directions.

### 3.5 A probabilistic, multi-model map with quantified uncertainty

Rather than a single binary map, we produce a probability surface for LSOG and quantify the uncertainty that comes from the choice of statistical model. The design-based backbone of that surface is itself a map: Figure 6 shows every Maine FIA plot colored by its modeled four-axis LSOG probability, built entirely from public plot coordinates, with the documented old-growth and the reserves overlaid for reference. Five structurally different learners, trained on the same plots and predictors, produce markedly different wall-to-wall predictions: their average mapped probability ranges from 0.26 to 0.59 across methods, and the spread between the models, averaging 0.18 on a zero-to-one scale, is itself a measure of how much the answer depends on choices the modeler makes rather than on the forest. The ensemble average is the best single estimate, and any binary class drawn from it is calibrated so that its mapped area reproduces the design-based FIA estimate of late-successional-and-old-growth forest, 14.1 percent [12.9 to 15.3] of forestland under the integrated structural proxy and 3.1 percent [2.5 to 3.7] under the strict four-axis definition, rather than exceeding it. The inventory total is the anchor the map is held to, not the reverse: a wall-to-wall map of the same quantity is obliged to reproduce the probability sample's total, and when it does not, the discrepancy is a property of the map. A global sensitivity analysis makes plain why a canopy-based map is limited (Figure 7): canopy height alone accounts for essentially all of the explained variation in the modeled probability, with the Landsat disturbance signal a secondary modifier. A classifier keyed on canopy height is therefore resolving one dominant axis and is poorly suited to capture the dead-wood and continuity components that distinguish genuine old-growth. This is the product a high-stakes user should rely on: it shows not only where LSOG is likely but where the maps disagree, which is exactly the information a single accuracy number conceals.

### 3.6 Remote-sensing fusion and the 10-meter map: the central result

The most consequential result of this work is not a critique of any single map but a constructive one: when multiple modern remote-sensing sources are fused and trained on true-coordinate field plots, they discriminate late-successional and old-growth forest substantially better than any single canopy-height layer, and they do so at a 10-meter resolution that resolves the small remnants a 1-hectare grid cannot. This is the product that can actually improve conservation, economic, and policy decisions, because it answers where LSOG most likely sits at a grain fine enough to act on, while remaining anchored to the design-based inventory for how much exists.

We benchmarked a ladder of feature sets in five-fold cross-validation on 4,173 true-coordinate plots (those with complete satellite-embedding coverage, of 4,263 assembled; the FIA probability sample plus the MNAP and TNC ecological reserves), using a balanced random forest for the multi-axis any-LSOG class (prevalence 0.21). All embeddings were sampled locally on Cardinal so that true plot coordinates were not released.

| Feature set | Dimensions | Cross-validated AUC |
|---|---|---|
| Meta/WRI canopy-height statistics | 5 | 0.668 |
| Landsat (Potapov RH95 height) + LCMS time-since-disturbance | 2 | 0.704 |
| AlphaEarth (Google satellite embedding, includes GEDI inputs) | 64 | 0.806 |
| TESSERA (open Sentinel-1/2 embedding, no LiDAR) | 128 | 0.818 |
| AlphaEarth + Landsat | 66 | 0.823 |
| TESSERA + Landsat | 130 | 0.825 |
| TESSERA + Meta | 133 | 0.827 |
| TESSERA + AlphaEarth | 192 | 0.860 |
| TESSERA + AlphaEarth + Landsat | 194 | 0.862 |
| All four sources fused (best) | 199 | 0.872 |

Three points follow. First, fusion is clearly superior: stacking the two learned embeddings is the single largest gain, from about 0.81 alone to 0.860 together, and adding the canopy-height and disturbance layers lifts it to 0.872, with every layer helping and none hurting. A single canopy-height product, the basis of the published map, sits near the bottom of this ladder. Second, the open, LiDAR-free TESSERA embedding (0.818) is as strong as the GEDI-informed AlphaEarth (0.806), so a public, freely redistributable product loses no skill by staying GEDI-free. Third, even a fused AUC of 0.872 is good but not perfect discrimination, and for a rare class near 4 percent it still implies meaningful operating error, which is exactly why the design-based inventory must remain the area backbone while the map answers location.

From this fused model we produce a 10-meter wall-to-wall LSOG probability surface, demonstrated over a Big Reed and Baxter showcase region (about 13.7 million valid 10-meter pixels) and scalable to all of Maine tile by tile. At 10 meters a quarter-hectare remnant is twenty-five pixels rather than a fraction of one, so the product can both detect small old-growth patches and characterize structure within them, which the hectare-grid maps do not. A binary class drawn from the surface is design-calibrated so that its mapped area reproduces the FIA design-based estimate, so the fine-resolution map does not over-claim relative to the inventory. The classification threshold has no single optimum; it trades sensitivity against precision, and the trade-off sharpens as the target class becomes rarer (Figure 9). On the model's out-of-bag predictions the discrimination-optimal threshold is 0.36 by Youden's J (500-replicate bootstrap 95% confidence interval 0.29 to 0.37; the maximum-F1 threshold is 0.37, interval 0.36 to 0.44), yet even at that optimum precision is only about 0.51 on the training set. Because precision depends on the base rate, the same model that reaches an AUC of 0.87 yields a precision near 40 percent at the integrated any-LSOG prevalence of about 14 percent, about 11 percent at the strict four-axis prevalence of about 3 percent, and under 1 percent for the old-growth-only class near 0.2 percent. This base-rate collapse is the central difficulty of mapping a rare condition, and it is why we anchor the mapped amount to the design-based inventory, adopt the design-calibrated cutoff for area-matching rather than tuning to a single classification objective, and treat the old-growth class as something to be field-verified rather than read off any map. This fused, design-anchored, field-validated 10-meter product is what we recommend as the basis for parcel-level decisions, in place of any single-sensor map; the design-based estimate remains the standard it must reproduce. The wall-to-wall 10-meter probability surface over the full study area is complete: a single mosaic of 29,083 by 29,162 pixels, about 848 million 10-meter cells in the Maine TM projection (EPSG:32619), assembled from 958 native satellite-embedding tiles (Figure 8). It is archived in the project's open Zenodo record (concept DOI 10.5281/zenodo.20614496), so any user can inspect the probability of LSOG at 10 meters anywhere in the study area, the resolution at which parcel-level conservation, economic, and policy decisions are actually made.

---

## 4. Robustness: stress testing the conclusions

We stress tested the headline conclusions against the analytical choices most likely to be questioned. The finding that Maine carries the lowest integrated LSOG share in the region holds under every reasonable scoring threshold, holds when the canopy dimension is removed from the score entirely, and holds across independent FIA measurement panels, failing only at an extreme strictness where every state's share collapses to about one tenth of one percent and the ordering is statistical noise. The rarity of true LSOG holds across five different ways of drawing the temporal-continuity axis. The cross-map disagreement is not an artifact of any one comparison product. And the older-forest area estimate carries a bootstrap confidence interval rather than a single point. The primary structural measure is also robust to the choice of large-tree threshold, each with a design-based interval: live large-tree basal area at 20, 30, and 40 ft^2/ac per acre gives 19.5 percent [18.2 to 20.9], 12.5 percent [11.3 to 13.6], and 8.2 percent [7.2 to 9.1] of forestland respectively, so the headline 12.5 percent figure moves smoothly and predictably with the threshold rather than hinging on it. The conclusions are not knife-edge results that depend on a particular threshold; they are stable features of the data.

---

## 5. Implications for Maine policy and the regional forest economy

For the LD 1529 process and the broader discussion of older forest in Maine, several points follow directly. Maine does have comparatively little forest that meets a full late-successional definition, but this reflects an active, productive working forest operating within a regional system in which other states carry more of the late-successional and reserve functions, not a uniform deficit to be closed within Maine. The net older-forest stock is stable to rising, so the framing of imminent, rapid, statewide loss is not supported by the ground inventory, even though individual high-value stands are genuinely harvested and can be lost.

The policy implications are as consequential as the economic ones, and they concern how a strategy is designed rather than whether to conserve. A program that commits public funds at the scale contemplated should rest on a design-based amount reported as a range with its sampling interval, should adopt the combined late-successional-plus-old-growth class rather than the volatile old-growth-only class as its accounting unit, and should require independent cross-checking and parcel-scale field verification before any acquisition. It should also pursue representation of the late-successional condition across the region's forest types and ecoregions rather than per-state parity, since the conservation-relevant gap is compositional, not a matter of Maine's aggregate share. These are policy choices that determine whether public money protects genuine high-value forest or buys mislocated and over-valued ground; getting them right is the difference between a credible strategy and an expensive one.

On the economic side, the most acreage-relevant conservation levers, if the goal is regional representation, are the under-represented forest types and the private-timberland late-successional pool that holds most of the regional acreage, addressable through working-lands easements, payment-for-ecosystem-services arrangements, and targeted reserve placement, instruments compatible with a working forest.

Two points of context belong alongside this. First, conservation in Maine is expanding, not contracting. The ecological reserve system has grown substantially over the past two decades, to on the order of five percent of the state, and recent special-protection designations together with great-pond and forested-wetland regulations have added further area that is effectively off the table for timber management; conservation designation in the unorganized townships, the geography of the LiDAR study, is far higher than the statewide average, on the order of forty percent. Read against this trajectory, and against a net older-forest stock that is stable to rising, a narrative of imminent, accelerating, statewide LSOG loss is not supported by the evidence, even as individual high-value stands remain genuinely at risk and worth protecting. Statewide statistics should not be applied to the unorganized-territory study area, or the reverse, without noting the difference.

Second, the working-forest landowners and the third-party certification programs they participate in helped fund the airborne-LiDAR research on which this entire debate is built, and have worked with conservation organizations for years to identify and protect late-successional stands. A durable and effective LSOG strategy will treat these landowners as partners in conservation, and will weigh the consequences for loggers, mills, and the wider forest-products economy alongside the value of the stands conserved, rather than positioning the working forest as a risk to be managed against.

Overlaying the LSOG maps with ownership and harvest pressure adds useful, if two-sided, context. The canopy-defined LSOG rate rises with modeled harvest probability, from 13.1 percent on low-probability ground to 33.5 percent on high-probability ground. Part of that association is mechanical and should be read with care: the large trees and high stocking that make a stand read as LSOG are also what make it merchantable, so the harvest model and the canopy classifier key on overlapping structure. We therefore treat this as a descriptive overlay rather than as proof of targeting. The picture is also two-sided, because the same mapped LSOG sits disproportionately on steeper, more disturbance-prone terrain (median slope about 5.3 versus 3.0 degrees, with the LSOG share rising from 12 percent on the gentlest ground to 37 percent on the steepest), which raises harvest cost and logistics; risk to these stands is thus heterogeneous and parcel-specific rather than uniform. By owner class, the integrated LSOG share is highest on federal land (about 36 percent) and state and local land (about 31 percent) and lowest on private land (about 14 percent); but private ownership holds roughly 92 percent of Maine's forested acres and therefore the large majority of LSOG acres, on the order of 1.67 million of about 2.0 million statewide. The high-rate older forest is thus already largely public or protected, while any acreage-relevant strategy necessarily engages private working-forest owners, which is a further reason to favor easements, payments for ecosystem services, and targeted reserves over broad acquisition, and to treat landowners as partners. One overlay is genuinely diagnostic rather than mechanical: the LSOG rate also rises with disturbance intensity (16.9 to 35.0 percent), which it should not for truly intact old-growth, and which exposes the canopy blind spot directly, because canopy height persists through partial harvest, so a recently entered stand can still score as old-growth-like. That is exactly what the dead-wood and temporal-continuity axes are designed to catch.

---

## 6. Recommendations

The following are specific and actionable, grouped by category and ranked by priority (High, Medium, Low) so that a conservation program acting under LD 1529 can sequence them.

RECOMMENDATIONS_TABLE_INJECT

These priorities reflect both the strength of the underlying evidence and the consequences of getting a parcel-level decision wrong.

---

## 7. Conclusions

The amount of late-successional and old-growth forest in Maine is best expressed as a method range with a sampling interval, not a single percentage, and the location of that forest remains genuinely uncertain across credible maps. The published LiDAR map is a useful screening contribution, but its fitness for parcel-level spending depends on the uncertainty characterization and independent verification that should now accompany it. Three audiences can act on the findings directly.

**For research.** Field-validate the old-growth class against an independent probability sample, because neither the published map nor the field protocol behind it sampled true old-growth. Pursue a data-use agreement for true FIA coordinates to remove the kilometre-scale location fuzzing that drives much of the apparent disagreement between maps. Extend the fused 10-meter product to a per-axis, wall-to-wall classification, and develop and validate forest-type-specific structural criteria so that low-stature spruce-fir, cedar, and peatland old-growth are scored on their own terms rather than against a single canopy threshold. Report classification uncertainty as a layer, not as one accuracy number.

**For policy.** State LSOG extent as a design-based range with its confidence interval in any document that guides acquisition, and treat the combined late-successional-plus-old-growth class as the stable policy unit rather than the product-specific old-growth-only class. Require that any single map be cross-checked against at least one independent product and field-verified at the parcel scale before acquisition, and state the grain at which any percentage is produced. Where a rate of loss is cited, separate the gross harvest flux from the net older-forest stock, which is stable to rising over the last two decades.

**For conservation.** Pursue adequate representation of the late-successional condition across the forest types and ecoregions of northern New England and the Adirondacks rather than per-state parity, focusing on the under-represented types. Because private working-forest owners hold the large majority of the region's older-forest acres, favor working-lands easements, payments for ecosystem services, and targeted reserve placement over broad fee acquisition, and design the program with those owners as partners. Protect the documented high-value stands now, while the broader accounting matures.

---

## 8. Methods and data availability

Estimates use design-based, post-stratified estimation from the FIA probability sample, with stratified variance after Cochran (1977) (Bechtold and Patterson 2005; rFIA, Stanke et al. 2020) over all available inventory years for Maine, New Hampshire, Vermont, and New York. The four-axis classification combines FIA tree- and condition-level structure with a temporal-continuity axis derived from the USFS Landscape Change Monitoring System (LCMS) Landsat disturbance record, 1985 to 2023. The cross-map assessment compares a reproduced airborne-LiDAR classifier, a Potapov GEDI-calibrated spaceborne canopy-height model, and the ORNL national old-growth product on a common 100 meter grid. The multi-model probability surface ensembles five learners and reports across-model uncertainty, with global sensitivity quantified by variance-based Sobol indices. All code and derived products are openly archived (Zenodo concept DOI 10.5281/zenodo.20614496). No FIA plot coordinates are released; all products are derived rasters or aggregate summary tables.

---

## 9. References

Bechtold, W.A., and P.L. Patterson (eds.). 2005. The enhanced Forest Inventory and Analysis program: national sampling design and estimation procedures. USDA Forest Service General Technical Report SRS-80, Southern Research Station, Asheville, North Carolina, USA.

Bruening, J.M., P.B. May, R.O. Dubayah, L. Wertis, C. Quinn, N. Pederson, A.H. Armstrong, and B. Poulter. 2026. Mature and old-growth forest probability maps for the conterminous United States. ORNL DAAC, Oak Ridge, Tennessee, USA. Dataset 2498. https://doi.org/10.3334/ORNLDAAC/2498

Cochran, W.G. 1977. Sampling techniques, 3rd edition. Wiley, New York, USA.

Hagan, J.M., B. Shamgochian, M.M.L. Taylor, and J.M. Reed. 2026. Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA. Ecosphere 17(6):e70670. https://doi.org/10.1002/ecs2.70670

Hayashi, R., A. Weiskittel, and J.A. Kershaw, Jr. 2016. Influence of prediction cell size on LiDAR-derived area-based estimates of total volume in mixed-species and multicohort forests in northeastern North America. Canadian Journal of Remote Sensing 42(5):473-488. https://doi.org/10.1080/07038992.2016.1229597

Maine State Planning Office. 1983. Natural old-growth forest stands in Maine and its relevance to the Critical Areas Program. Planning Report Number 77, Maine Critical Areas Program, Augusta, Maine, USA.

Maine State Planning Office. 1986. Uncut timber stands and unique alpine areas on State lands. Critical Areas Program, Maine State Planning Office, Augusta, Maine, USA.

Pelz, K.A., G. Hayward, A.N. Gray, E.M. Berryman, C.W. Woodall, A. Nathanson, and N.A. Morgan. 2023. Quantifying old-growth forest of United States Forest Service public lands. Forest Ecology and Management 549:121437.

Potapov, P., X. Li, A. Hernandez-Serna, A. Tyukavina, M.C. Hansen, A. Kommareddy, A. Pickens, S. Turubanova, H. Tang, C.E. Silva, J. Armston, R. Dubayah, J.B. Blair, and M. Hofton. 2021. Mapping global forest canopy height through integration of GEDI and Landsat data. Remote Sensing of Environment 253:112165.

Shamgochian, B., J. Hagan, M. Taylor, and M. Reed. 2025. LSOG Rapid Assessment Protocol (RAP) for Maine (v2.0). Our Climate Common, Georgetown, Maine, USA. 36 pp.

Stanke, H., A.O. Finley, A.S. Weed, B.F. Walters, and G.M. Domke. 2020. rFIA: an R package for estimation of forest attributes with the FIA database. Environmental Modelling and Software 127:104664.

Thompson, J.R., A. Daigneault, J. Plisinski, I. Moon, and J. Norton. 2026. Pathways for protecting Maine's remaining late-successional and old-growth forests. Property and Environment Research Center, Bozeman, Montana, USA. 86 pp.

U.S. Executive Order 14072. 2022. Strengthening the Nation's Forests, Communities, and Local Economies. The White House, Washington, D.C., 22 April 2022.

USDA Forest Service and USDI Bureau of Land Management. 2023. Mature and old-growth forests: definition, identification, and initial inventory on lands managed by the Forest Service and Bureau of Land Management. U.S. Department of Agriculture and U.S. Department of the Interior, Washington, D.C.

Wilson, B.T., A.J. Lister, and R.I. Riemann. 2012. A nearest-neighbor imputation approach to mapping tree species over large areas using forest inventory plots and moderate resolution raster data. Forest Ecology and Management 271:182-198. https://doi.org/10.1016/j.foreco.2012.02.002

Remote-sensing embeddings used in the fusion analysis: TESSERA open Sentinel-1/2 embeddings (geotessera 0.9.0, 2024); AlphaEarth Google satellite-embedding annual product; Meta/WRI canopy-height statistics (Tolan et al. 2024, AWS Open Data). USFS Landscape Change Monitoring System (LCMS) time-since-disturbance, 1985-2023. All derived products and code are archived at Zenodo (concept DOI 10.5281/zenodo.20614496); no FIA plot coordinates are released.


## Appendix: detailed results with 95% confidence intervals

This appendix collects the full quantitative basis for the findings above. Every estimate carries a 95% confidence interval: design-based intervals for the inventory and representation estimates, Wilson intervals for the validation proportions.

**Table A1. Design-based older-forest and LSOG area for Maine, with 95% CI.** From the FIA probability sample (rFIA, post-stratified). The single-axis age and structure criteria are 2024; the multi-axis classes are the 2019-2023 panel. The stand-age rows are a cross-check only: FIA assigns stand age from the cored age of one or a few site trees, which is unreliable in these uneven-aged stands, so the large-tree basal-area row is the primary structural measure.

| Criterion | Maine forestland % [95% CI] |
|---|---|
| Large-tree basal area (trees >= 40 cm dbh, >= 30 ft^2/ac) | 12.5 [11.4, 13.7] |
| Late-successional class only, LS (v5.1 structural) | 1.9 [1.4, 2.3] |
| Old-growth class only, OG (v5.1 structural) | 0.2 [0.1, 0.4] |
| LS + OG combined (strict structural) | 2.0 [1.5, 2.7] |
| Integrated any-LSOG (LS + OG + transitioning, structural proxy) | 14.1 [12.9, 15.3] |
| True LSOG, all four axes (incl. Landsat continuity) | 3.1 [2.5, 3.7] |
| Stand age >= 100 yr (cross-check only) | 12.1 [10.9, 13.2] |
| Stand age >= 120 yr (cross-check only) | 3.9 [3.3, 4.6] |
| Stand age >= 150 yr (cross-check only) | 0.7 [0.4, 1.0] |

**Table A2. Design-based LS and OG classes separated, and the four-axis funnel, by state, with 95% CI.** LS and OG are the v5.1 structural classes (2019-2023 panel); True LSOG requires all four axes (live large-tree structure, dead wood, composition, Landsat-verified continuity); Integrated any-LSOG is LS plus OG plus transitioning.

| State | LS % [95% CI] | OG % [95% CI] | True LSOG (4-axis) % [95% CI] | Integrated any-LSOG % [95% CI] |
|---|---|---|---|---|
| Maine | 1.9 [1.4, 2.3] | 0.2 [0.1, 0.4] | 3.1 [2.5, 3.7] | 14.1 [12.9, 15.3] |
| New Hampshire | 5.0 [3.6, 6.7] | 0.3 [0.0, 0.7] | 12.8 [10.7, 15.0] | 31.2 [28.0, 34.3] |
| Vermont | 6.5 [4.7, 8.5] | 0.2 [0.0, 0.5] | 15.2 [12.7, 17.6] | 28.8 [25.4, 32.3] |
| New York | 6.1 [5.1, 7.2] | 1.3 [0.8, 1.8] | 12.2 [11.1, 13.4] | 27.2 [25.2, 29.0] |

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

| Map | Any-LSOG (% of area) | kappa vs LiDAR | kappa vs canopy | Confidence |
|---|---|---|---|---|
| Airborne LiDAR (Hagan et al. 2026) | 21.9 | -- | 0.22 | High |
| Potapov/GEDI spaceborne canopy height | 14.0 | 0.22 | -- | High |
| ORNL old-growth stratum (Bruening) | 36.1 | -0.02 | -0.07 | Medium |
| Agreed by all three (% of flagged area) | 2.7 | | | High |

**Table A6. Rare-class remedies for the reproduced airborne-LiDAR random forest (old-growth = rare event).** Old-growth detection and mapped area both move sharply, confirming the headline area is a modeling choice.

| Strategy | OG detection (recall) | Mapped OG area (%) |
|---|---|---|
| Default, unbalanced | 0.24 | 1.0 |
| Class weighting | 0.29 | 0.8 |
| Balanced sub-sampling | 0.71 | 1.9 |
| Voting-threshold adjustment | 0.82 | 2.3 |

**Table A7. Independent validation against field reserves, with Wilson 95% CI.** Our four-axis structural criteria versus the reproduced published LiDAR map at the same coordinates.

| Reference (n plots) | Our criteria % [95% CI] | LiDAR map % [95% CI] | Confidence |
|---|---|---|---|
| Big Reed Forest Reserve (25) | 72 [52, 86] | 80 [61, 91] | Low |
| Ecological reserve network (819) | 67 [64, 70] | 57 [54, 60] | High |
| Baxter SFMA, large-tree axis (90) | 98 [92, 99] | -- | High |
| Baxter SFMA, continuity axis (90) | 82 [73, 89] | -- | Medium |
| Baxter SFMA, LiDAR-map LSOG (90) | -- | 57 [46, 66] | Medium |

**Table A8. Final robustness summary: each headline conclusion and the stress it survives.**

| Conclusion | Stress applied | Result | Robust | Confidence |
|---|---|---|---|---|
| Maine carries the lowest LSOG share | thresholds, drop canopy dimension, FIA panels | lowest in 8 of 9 tests | yes | High |
| True LSOG is rare (3 to 5% in Maine) | five continuity definitions | 3.1 to 5.2% | yes | High |
| Credible maps disagree | three independent RS products | 1.6 to 2.6 fold | yes | High |
| Half the cross-map disagreement is geolocation | fuzzed vs true coordinates | kappa 0.13 to 0.29 | yes | Medium |
| Rare-class detection and area are choice-driven | four RF strategies | recall 0.24 to 0.82; area 1.0 to 2.3% | yes | Medium |
| Model structure dominates map uncertainty | five-learner ensemble | mean P 0.26 to 0.59, SD 0.18 | quantified | Medium |
| Canopy height drives the signal | Sobol indices | first-order ~1.0 | yes | High |
| Both maps detect most reserve old-growth | reserve/Big Reed/Baxter validation | see Table A7 | yes | Medium |

---
