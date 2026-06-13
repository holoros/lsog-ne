# Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA: Comment

Aaron R. Weiskittel{1}, [co-authors TBD]

{1} University of Maine, Center for Research on Sustainable Forests, 5755 Nutting Hall, Orono, ME 04469, USA. aaron.weiskittel@maine.edu

Comment on Hagan, J.M., B. Shamgochian, M.M.L. Taylor & J.M. Reed. 2026. Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA. Ecosphere 17(6):e70670. https://doi.org/10.1002/ecs2.70670. [VERIFY exact volume/article number/DOI and the published LS+OGL area figure against the final Ecosphere paper; an independent search confirmed the 2024 Our Climate Common report but could not confirm the 2026 Ecosphere citation details.]

Ecosphere Comment format: no abstract; <= 16 double-spaced manuscript pages; figures as separate files; tables after Literature Cited.

---

## 1. Introduction

Hagan et al. (2026) provide a valuable, transparent, and timely contribution: a field-trained, wall-to-wall classification of late-successional and old-growth (LSOG) forest across approximately 4.2 million hectares of Maine's unorganized townships, derived from publicly available airborne LiDAR. The authors archived their training data and code, the field effort is substantial, and the resulting map has focused overdue attention on older forest in a working landscape. We were able to reproduce their random forest classifier exactly from the archived data, obtaining an out-of-bag accuracy of 94.2% for the Not-LSOG versus LSOG distinction against their reported 94.1%, with the same most-important predictor (canopy cover above 15 m). Nothing in this Comment questions the competence or the openness of the original analysis, both of which we commend.

Our concern is narrower and methodological, and it follows from how the map is now being used. The classification has become the spatial basis for conservation prioritization at scale: Thompson et al. (2026) build directly on it and estimate that protecting the highest-priority half of the mapped LSOG patches would cost on the order of US $200-300 million, in support of Maine's LD 1529. When a single map becomes the substrate for parcel-level acquisition and emerging carbon and conservation markets, the properties that govern its fitness for that purpose are no longer only its training accuracy. They are (i) its accuracy and agreement relative to independent maps and to ground-based inventory of the same target; (ii) the uncertainty of every quantity derived from it; and (iii) the validity of the trend used to motivate action. A map can be both wrong, in the unavoidable sense that LSOG is a continuous and partly subjective condition forced into discrete classes, and useful for some decisions but not others (Box 1976). Our purpose is to show, using analyses built largely on the authors' own archived data and on independent public data over the same area, what a cross-map accuracy assessment and an explicit uncertainty statement add, and to suggest that they should accompany the map before it anchors large expenditures.

We make four points. First, training accuracy is high for every candidate approach and is therefore not the issue (Section 2). Second, independent operationalizations of LSOG, each with high training accuracy, disagree markedly at the landscape scale, which is the scale at which hectares are prioritized (Section 3). Third, the canopy-structure signal the method relies on is sensitive to large trees and tall canopy but largely insensitive to the dead-wood component that distinguishes old growth, so it maps tall, big-tree forest, which is roughly three times more extensive than ground-defined old forest (Section 4). Fourth, ground-based FIA inventory, the gold standard the LiDAR map approximates, places the amount of older forest with a sampling-error confidence interval the original analysis did not report, and shows the stock to be stable or increasing rather than rapidly declining (Section 5). Section 6 discusses implications.

We write as forest biometricians with a professional interest in how inventory data are used in policy; the analyses below use the authors' archived training data and independent public data over the same area, and all code and derived products are openly archived (Data and Code Availability).

## 2. Training accuracy is high for every approach, and is not the issue

The 463 known-class training hectares carry both the eight LiDAR canopy metrics and a parallel set of ground structural measurements (live and dead basal area, basal area and number of trees >= 40 cm dbh, quadratic mean diameter, coarse woody debris, and diameter variability). Using these, we estimated cross-validated AUC (repeated stratified five-fold cross-validation, 40 repeats; intervals from the repeat distribution) for three predictor sets against three binary targets (Table 1). Hagan's eight LiDAR metrics discriminate the field classes very well in-sample: AUC 0.990 for any-LSOG, 0.988 for LS+OG, and 0.966 for old growth. A canopy-height-only set and a ground-structure set also perform well for the broad classes. The training data are separable and the published classifier is internally sound; we emphasize this because it is the premise that makes the rest of the argument matter. Two features of Table 1 are nonetheless relevant. For old growth specifically, a canopy-height-only model, which approximates the information a spaceborne canopy-height product carries, is the weakest of the three (AUC 0.910 [0.868, 0.933]), while ground structure is the strongest. And the full LiDAR model's high ranking ability coexists with the operating-point performance the authors report: in their own out-of-bag confusion matrix, only 29.4% of true old-growth hectares were classified as old-growth-like. High AUC and low operating accuracy are reconcilable under class imbalance and overlap, but for a map used to select specific hectares, it is operating performance on the rare, high-value class that governs the decision. The point is sharpened by the paper's field validation, which contained no true old-growth sites at all (Hagan et al. 2026, Table 6): the rarest and highest-value class was evaluated only against the authors' own training labels and never field-verified.

This rare-class shortfall reflects the algorithm's handling of class imbalance more than the data. Refitting the published random forest on the archived training data with standard class balancing raises old-growth operating accuracy from 23.5% to 70.6%, at a negligible cost to overall accuracy (0.87 to 0.84), and nearly doubles the mapped old-growth area, from about 109,000 to 192,000 acres, with any-LSOG rising from 21.5% to 32.3% of the study area (Supporting Information). The wall-to-wall area a single classifier reports is therefore sensitive to a routine modeling choice, a further reason it should not by itself anchor parcel-level expenditure.

## 3. High training accuracy does not produce map agreement

The decisive test for policy use is not how well a model separates its own training plots but whether independent, equally defensible operationalizations of LSOG agree on the landscape. We compared three remote-sensing classifications that differ in sensor, training data, and target definition, over the study area on a common 100 m grid: the reproduced Hagan airborne-LiDAR classifier; an FIA-field-structure class predicted from Potapov (GEDI-calibrated) spaceborne canopy height; and the ORNL national mature-and-old-growth product (Bruening et al. 2026; old-growth stratum). The two structure-resolution maps differ 1.6-fold in extent (Hagan any-LSOG 21.9% versus canopy height 14.0%) and overlap only modestly (Cohen's kappa 0.22). The ORNL old-growth stratum is a coarser, continental product that flags a much larger area (36.1%, and 65% for its mature-plus-old-growth stratum); including it widens the range to 2.6-fold (Fig. 1a-c). Spatially the three overlap poorly: only 2.7% of the hectares flagged by any map are flagged by all three, and 73% are flagged by a single map (Fig. 1d). The ORNL stratum shares little spatial information with either structure map (kappa near zero); rather than evidence that any one map is wrong, this is a cross-scale caution that a continental old-growth product and a state airborne-LiDAR product, each credible in its own domain, identify largely different ground. We separately reproduced the privately held Seven Islands classification and found it effectively identical to the published model (pixel-level kappa 0.97 across approximately 290,000 ha), which confirms that the disagreement among methods is genuine rather than an artifact of our reproduction.

None of the three products is ground truth, including ours; all are remote-sensing proxies for the ground-measured structure that defines LSOG, and each embeds different definitional and sensor choices. The point of the comparison is not that the Hagan map is wrong and another is right. It is that several credible, high-training-accuracy operationalizations of the same concept place markedly different amounts of forest in markedly different places, and that spread is itself the quantity a high-stakes user needs to see. Accuracy issues of this kind are well documented even among global canopy-height products built from the same sensors (Moudry et al. 2024).

The consequence for prioritization is direct. If a program protects the highest-priority hectares, the overlap of the protected sets selected by the Hagan map versus the canopy-height map is only 0.16 to 0.30 (Jaccard) for the top 5% to 20% of hectares; that is, 70% to 84% of the prioritized ground differs depending on which equally defensible map is used (Fig. 1). A US $200-300 million acquisition program steered by one map would purchase substantially different forest than the same program steered by another. Each map can have excellent training accuracy and the maps can still disagree on most of the ground, because the disagreement lives in the definitional and methodological choices rather than in the fit to any one training set.

## 4. The canopy signal maps big-tree forest, not old growth

Old growth is defined ecologically by large old trees, structural complexity, and abundant dead wood. Using the archived plots, we asked how well the eight LiDAR canopy metrics predict these defining attributes (cross-validated R^2). They predict large-tree basal area moderately (R^2 = 0.68) but are largely blind to dead wood: coarse woody debris volume R^2 = 0.20 and standing dead basal area R^2 = 0.24 (Table 3). The blind spot is not confined to the canopy metrics; it reaches into the field protocol that trained the map. In the random-forest classifier of the authors' own RAP v2.0 rapid-assessment protocol (Shamgochian et al. 2025), large standing dead trees rank last of seventeen metrics in importance and large downed logs thirteenth, even though that document calls large logs one of the best indicators of old growth, while harvest-history evidence (sawn stumps, skid trails) is among the strongest predictors. The dead-wood component that distinguishes old growth is therefore under-weighted by the training labels as well as by the LiDAR. A classification keyed on canopy height and cover therefore registers tall, continuous canopy whether it is produced by an old, structurally complex stand or by an 80- to 100-year-old fast-growing stand, a failure mode the authors note for Populus. The scale of the resulting ambiguity is quantifiable from ground inventory (Section 5): roughly 12.5% of Maine forest carries substantial large-tree basal area, but only about 3.9% meets a stand-age criterion for old forest, so big-tree forest is about three times more extensive than ground-defined old forest. The large-tree threshold is illustrative rather than definitional, and the two criteria measure different things; we use the contrast only to bracket the magnitude of the over-inclusion a height- or canopy-based classifier produces relative to a structural or age-based definition, which is consistent with the among-method spread in Section 3.

## 5. Ground-based inventory: the estimate, with the interval the map omits

Airborne LiDAR and spaceborne canopy height are proxies for the ground-based structural measurements that define LSOG; TreeMap imputes those same measurements from the FIA plots themselves, so it is a second FIA-anchored accounting rather than an independent map. The USDA Forest Inventory and Analysis (FIA) program provides the measurements under a probability sample, which permits design-based estimates with sampling-error variance. Using rFIA design-based estimation (post-stratified, with FIA estimation-unit areas; Stanke et al. 2020) over all Maine inventory years, the area of older forest by transparent ground criteria is (2024, 95% CI): stand age >= 100 yr, 12.1% [10.9, 13.2] of forestland; stand age >= 120 yr, 3.9% [3.3, 4.6]; stand age >= 150 yr, 0.7% [0.4, 1.0]; and live basal area in trees >= 40 cm dbh exceeding 30 ft^2/ac, 12.5% [11.4, 13.7] (Table 4). In the northern timberland units that approximate the study area, the stand-age >= 120 yr estimate is 4.2% [3.3, 5.1]. The point estimate for older forest brackets the published LS+OGL figure of 3.9%, which is reassuring, but the original analysis reported that figure without an interval; the ground-based gold standard places it in a range of roughly 3.3 to 4.6%, and that uncertainty is exactly what a $200-300 million prioritization should carry. FIA stand age is itself modeled and uncertain in uneven-aged stands, which is why we pair the age criteria with the large-tree basal-area structural criterion; the two bracket a consistent range.

Applying the same multi-axis LSOG definition to the FIA probability sample with design-based estimation gives the disputed quantity directly: under the integrated structural proxy, late-successional-and-old-growth forest covers 14.1% [12.9, 15.3] of Maine forestland, and requiring all four structural axes (live large-tree structure, dead wood, composition, and Landsat-verified temporal continuity) reduces true LSOG to 3.1% [2.5, 3.7] (Table 4). The reproduced LiDAR map's 21.9% any-LSOG is the highest of the operational maps and exceeds the design-based any-LSOG estimate of 14.1%. The spaceborne canopy-height map (14.0%) coincides almost exactly with that design-based estimate, so two independent routes to the inclusive quantity converge near 14% while the airborne map sits well above them; the TreeMap imputation (7.8%) sits below, and the strict four-axis estimate (3.1%) far below. The honest unit remains the design-based estimate with its interval, against which the airborne map is the high outlier.

The design-based series also addresses the loss premise directly. The map is motivated in part by rapid LSOG loss, reported at 1.37% per year overall and 2.19% per year on commercial timberland. That figure is a gross harvest flux: it counts mapped LSOG hectares that subsequently experienced canopy removal in the Global Forest Watch record, and it does not net out ingrowth, the younger stands that mature into older condition each year. The FIA design-based stock moves the other way. Over 2003-2024, older forest increased by every ground measure, with confidence intervals excluding zero: stand age >= 100 yr at +0.19% of forestland per year [0.15, 0.23], stand age >= 120 yr at +0.065% per year [0.054, 0.075], and large-tree basal area at +0.17% per year [0.15, 0.18], while total forestland area was essentially flat (Fig. 2). The northern units show the same increases; only the oldest class (age >= 150 yr) in the north declines slightly (-0.019% per year [-0.031, -0.008]). Both statements can be true at once: LSOG stands are harvested at roughly 2% per year, and the total older-forest stock is not declining, because aging more than replaces the hectares removed. Where a rate of loss is invoked to convey urgency, the flux and the stock should be distinguished.

We note finally that the publicly available spaceborne canopy-height products covering the study area (Potapov et al. 2021; Lang et al. 2023), although cited in passing in the original introduction, are not used as an independent benchmark. They are coarser than airborne LiDAR but global, repeatable, and free, and they provide the kind of independent cross-check, illustrated in Section 3, that a single airborne map otherwise lacks.

## 6. Implications

None of the above argues against mapping LSOG with LiDAR, nor against conserving older forest in Maine, which we support. It argues that a single classification, however well trained, is not a sufficient basis for parcel-level expenditures of the magnitude now contemplated, and that three practices should accompany its policy use. First, LSOG extent should be reported as a range across methods and with the design-based sampling interval, rather than as a single number; the ground-based estimate of older forest, 3.9% [3.3, 4.6], is an example. Second, before hectares are prioritized for acquisition or enrolled in markets, the map should be checked against at least one independent product and field-verified at the parcel scale, as the authors themselves recommend for management decisions. This matters because the downstream prioritization already delineates tens of thousands of patches from the single classification and ranks them for acquisition without propagating the map's uncertainty (Thompson et al. 2026), so a probabilistic surface with explicit bounds, rather than one binary map, is the appropriate substrate for parcel-level spending. Third, where a rate of loss is invoked, the harvest flux and the net stock should be distinguished, because they point in opposite directions here. The constructive next step, which we develop in a companion analysis, is a repeatable, FIA-anchored, multi-axis classification of LSOG with an explicit cross-map accuracy assessment; that work is beyond the scope of a Comment but follows directly from it. The Hagan et al. map is a useful and reproducible product; our point is that its usefulness for high-stakes allocation depends on the cross-map accuracy assessment and uncertainty characterization that should now accompany it.

## Data and Code Availability

All analyses, code, and derived products supporting this Comment are archived at Zenodo (concept DOI 10.5281/zenodo.20614496, resolving to the latest version). Hagan et al.'s training data and code are at Zenodo (10.5281/zenodo.19696494). FIA data are from the USDA FIA DataMart (apps.fs.usda.gov/fia/datamart), accessed June 2026.

## Literature Cited

Box, G.E.P. 1976. Science and statistics. Journal of the American Statistical Association 71:791-799.

Hagan, J.M., B. Shamgochian, M.M.L. Taylor & J.M. Reed. 2026. Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in Maine, USA. Ecosphere 17(6):e70670. https://doi.org/10.1002/ecs2.70670. [VERIFY citation details against published paper.]

Lang, N., W. Jetz, K. Schindler & J.D. Wegner. 2023. A high-resolution canopy height model of the Earth. Nature Ecology & Evolution 7:1778-1789.

Moudry, V., et al. 2024. [Accuracy assessment of global canopy height products.] Ecosphere. [VERIFY full author list, title, volume, and article number; added per self-review as a same-journal supporting reference.]

Potapov, P., X. Li, A. Hernandez-Serna, A. Tyukavina, M.C. Hansen, A. Kommareddy, A. Pickens, S. Turubanova, H. Tang, C.E. Silva, J. Armston, R. Dubayah, J.B. Blair & M. Hofton. 2021. Mapping global forest canopy height through integration of GEDI and Landsat data. Remote Sensing of Environment 253:112165.

Stanke, H., A.O. Finley, A.S. Weed, B.F. Walters & G.M. Domke. 2020. rFIA: An R package for estimation of forest attributes with the FIA database. Environmental Modelling & Software 127:104664.

Thompson, J.R., A. Daigneault, J. Plisinski, I. Moon & J. Norton. 2026. Pathways for Protecting Maine's Remaining Late-Successional and Old-Growth Forests. Property and Environment Research Center. [VERIFY publication venue and year.]

[ADD from Hagan et al. reference list, both cited in this Comment's argument: Barnett, K., et al. 2023 (FIA-based old growth); Shamgochian, B., et al. 2025 (field protocol). A "Birdsey et al. 2025" regional-synthesis citation appeared in an earlier draft but could not be independently verified; the sentence on regional consistency in Section 5 has been written to stand without it. If a specific synthesis is intended, supply the verified reference.]

---

## Tables

**Table 1.** Cross-validated AUC (mean [95% interval]) recovering the field-assigned class from three predictor sets, on the 463 known-class training hectares.

| Target (prevalence) | Hagan 8 LiDAR | Canopy height only | Ground structure |
|---|---|---|---|
| any-LSOG (0.39) | 0.990 [0.988, 0.992] | 0.984 [0.981, 0.987] | 0.966 [0.962, 0.969] |
| LS + OG (0.21) | 0.988 [0.984, 0.990] | 0.977 [0.973, 0.982] | 0.970 [0.967, 0.973] |
| old growth (0.04) | 0.966 [0.954, 0.977] | 0.910 [0.868, 0.933] | 0.974 [0.966, 0.981] |

**Table 2.** Wall-to-wall any-LSOG area and pairwise spatial agreement across three independent remote-sensing maps over the study area. TreeMap is an FIA imputation and is reported with the design-based estimates (Table 4), not here.

| Method | any-LSOG (% of area) | kappa vs Hagan | kappa vs canopy |
|---|---|---|---|
| Hagan (airborne LiDAR canopy) | 21.9 | -- | 0.22 |
| Canopy height (Potapov/GEDI) | 14.0 | 0.22 | -- |
| ORNL old-growth stratum (Bruening) | 36.1 | -0.02 | -0.07 |
| 3-way: % of flagged area agreed by all three | 2.7 | | |

**Table 3.** Cross-validated R^2 for predicting ground structural attributes from the eight LiDAR canopy metrics.

| Structural attribute | CV R^2 from LiDAR |
|---|---|
| Live basal area in trees >= 40 cm dbh | 0.68 |
| Number of trees >= 40 cm dbh | 0.59 |
| Diameter variability (CV of dbh) | 0.51 |
| Standing dead basal area (snags) | 0.24 |
| Coarse woody debris volume | 0.20 |

**Table 4.** FIA design-based LSOG and older-forest area with 95% CI. Single-axis age and structure criteria are 2024 with statewide, northern-unit, and 2003-2024 trend estimates; the multi-axis LSOG classes are the 2019-2023 panel (statewide). TreeMap, an independent FIA imputation, gives any-LSOG 7.8%.

| Domain (ground criterion) | Statewide % [95% CI] | Northern units % [95% CI] | Trend (%/yr, statewide) [95% CI] |
|---|---|---|---|
| Integrated any-LSOG (structural proxy) | 14.1 [12.9, 15.3] | -- | -- |
| True LSOG, all four axes (incl. continuity) | 3.1 [2.5, 3.7] | -- | -- |
| Stand age >= 100 yr | 12.1 [10.9, 13.2] | 12.2 [10.7, 13.7] | +0.19 [0.15, 0.23] |
| Stand age >= 120 yr | 3.9 [3.3, 4.6] | 4.2 [3.3, 5.1] | +0.065 [0.054, 0.075] |
| Stand age >= 150 yr | 0.7 [0.4, 1.0] | 0.6 [0.2, 1.0] | +0.000 [-0.005, 0.006] |
| Large-tree BA >= 30 ft^2/ac (>=16 in) | 12.5 [11.4, 13.7] | 9.8 [8.4, 11.2] | +0.17 [0.15, 0.18] |

---

## Figure Legends

**Fig. 1.** Three independent remote-sensing operationalizations of LSOG over Maine on a common 100 m grid disagree in amount and location: (a) Hagan airborne LiDAR, any-LSOG 21.9%; (b) Potapov/GEDI spaceborne canopy height, 14.0%; (c) ORNL old-growth stratum (Bruening et al. 2026), 36.1%; (d) number of maps agreeing on LSOG per cell (0-3). Only 2.7% of the hectares flagged by any map are flagged by all three, and 73% are flagged by a single map. The two structure-based maps agree only modestly (Cohen's kappa 0.22) and the ORNL old-growth stratum is uncorrelated with either (kappa near zero). Each panel is clipped to the Maine land area.

**Fig. 2.** FIA design-based older-forest area (stand age >= 120 yr) for Maine, 2003-2024, with 95% confidence intervals; the stock rises while total forestland area is flat.
