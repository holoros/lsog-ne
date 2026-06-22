# Deep review of Woodall et al. 2023 (FIGSS) and cross-walk with our LSOG manuscripts

Prepared 17 June 2026. Reviews Woodall, C.W., A.G. Kamoske, G.D. Hayward, T.M. Schuler, C.A. Hiemstra, M. Palmer & A.N. Gray. 2023. Classifying mature federal forests in the United States: the forest inventory growth stage system. Forest Ecology and Management 546:121361 (doi 10.1016/j.foreco.2023.121361; SSRN preprint 10.2139/ssrn.4484906).

## Source access note

The journal version is paywalled and the SSRN full-text PDF redirected to a shell, so I could not read the paper's own results tables directly. This review is built from the SSRN abstract and, principally, the open USDA Forest Service and USDI BLM 2023 initial-inventory report (FS-1215a), which applies the FIGSS method and reproduces its definitions, structural-indicator table (its Table 3), and federal estimates. The one figure I could not verify against an accessible source is Chris's stated 27 to 81 percent threshold-sensitivity range; see the citation recommendation below.

## What FIGSS is and does

FIGSS is a national, FIA-anchored method for classifying the mature growth stage, motivated by Executive Order 14072 (2022), which directed the Forest Service and BLM to define and inventory mature and old-growth (MOG) forest. Rather than set fresh mature thresholds, FIGSS defines maturity by inverse modeling backward from old growth: it takes FIA condition records already classified as old growth under the Forest Service regional old-growth definitions, and "walks down" their structural thresholds to the onset of maturity.

Method, in five steps. (1) For roughly 80 regional vegetation types (grouped from more than 200, where types with fewer than 10 old-growth FIA records were pooled; this affected 2.9 percent of the 49,153 FIA records used), it identifies the structural indicators most correlated with stand age. (2) For each type it estimates the 25th percentile of each indicator among old-growth records. (3) It "walks down" that threshold to the onset of maturity using a walkdown factor derived from carbon-accumulation curves (Barnett et al. 2023) and maximum physiological ages (Loehle 1988), expressing the proportion of time from maturity to mortality. (4) Each indicator receives a correlation-weighted composite index. (5) A non-old-growth FIA record with a composite index above 0.5 is classified as mature. Estimation is design-based across the FIA probability sample.

Headline estimates (federal USFS/BLM forest): old growth about 18 percent, mature about 45 percent (the journal abstract gives 44.8 percent), so MOG combined is on the order of 63 percent. For contrast, DellaSala et al. (2022), using canopy height, canopy cover, and biomass, place MOG at about 36 percent of conterminous forest; the two national estimates differ both in population (federal versus all ownership) and, more to our point, in definition.

## FIGSS Table 3 structural indicators (selected from 36 FIA attributes for ecological relevance, scalability, low multicollinearity, field measurability)

| FIGSS variable | What it measures |
|---|---|
| tpadom | Density of dominant/codominant live trees >= 1 in DBH (large-tree abundance) |
| badom | Total basal area of dominant/codominant live trees (large-tree site occupancy) |
| QMDdom | Quadratic mean diameter of dominant/codominant trees |
| ddiscore | Diameter diversity index (DDI) over four DBH classes |
| HTquart | Mean height of the tallest 25 percent of trees |
| HTsd | Standard deviation of tree height (height diversity) |
| snagbatot | Total basal area of standing dead trees (dead wood) |

## Cross-walk: FIGSS versus our manuscripts

| FIGSS element | Our analogue (manuscript / comment) | Alignment and difference |
|---|---|---|
| Maturity as a multidimensional structural condition, not one threshold | Four-axis LSOG definition (manuscript Sec 2.3); six-dimension v5.1 proxy (Table S1) | Same core premise. Chris's point is correct: our multi-axis framing has explicit national precedent. |
| Indicator selection from 36 FIA attributes, minimizing multicollinearity | Dimensionality / PCA of structural attributes (manuscript Sec 3.3, Table S4) | Both reduce a correlated structural set to a few axes; our PCA quantifies the redundancy FIGSS handles by selection. |
| tpadom, badom (large-tree density and basal area) | A1 live structure (large-tree BA >= 30 ft^2/ac, trees >= 40 cm / 16 in); v5.1 dim 1 | Direct match. We threshold on large-tree BA; FIGSS uses dominant-tree density and BA. |
| QMDdom, ddiscore (size and diameter diversity) | v5.1 structural diversity (TPA-weighted SD of DBH); QMD inputs | Conceptual match; FIGSS uses a 4-class DDI, we use SD of DBH. |
| HTquart, HTsd (height and height diversity) | v5.1 dim 6 canopy height (Potapov/GEDI) | We use remote-sensed canopy height; FIGSS uses field height and, additionally, height diversity (HTsd), which our structural set does not carry. |
| snagbatot (standing dead basal area) | A2 dead wood (standing snag BA >= 5 ft^2/ac); v5.1 dim 5 | Direct match. Note FIGSS Table 3 has no downed wood; our dimensionality analysis adds coarse woody debris. |
| (no composition axis) | A3 composition (>= 50% BA in long-lived late-successional species) | Our addition; FIGSS is structure-only. |
| (no temporal-continuity axis) | A4 temporal continuity (Landsat/LCMS disturbance, 1985-2023) | Our key extension. FIGSS classifies on present structure only and cannot see harvest or disturbance history, the same blind spot we document for canopy maps. |
| 80 regional vegetation types, region-specific thresholds | Forest-type and ecoregion representation (manuscript Sec 3.9, Tables 4, S6); forest-type-specific criteria (Pelz et al. 2023) | Strong alignment, and direct support for our recommendation that LSOG criteria be forest-type and ecoregion specific rather than universal. |
| Design-based FIA estimation of mature extent (about 45% federal) | Design-based FIA estimates with intervals (manuscript Sec 3.1, Tables 1, S2, S3) | Same estimation backbone; we add confidence intervals and a regional (all-ownership) frame. |
| Estimate depends on the 25th-percentile, walkdown factor, and 0.5 composite-index cut | Axis-count funnel: 6% to over 90% by number of axes required (manuscript Sec 3.4, Fig 2) | The same definitional sensitivity. FIGSS expresses it through threshold and walkdown choices; we express it through how many axes a definition requires. |

## What to cite, and how (recommendation)

Verifiable now, and worth citing: FIGSS treats maturity as a multidimensional structural condition built from about seven structural indicators across roughly 80 regional vegetation types, applied to FIA by design-based estimation, placing about 45 percent of federal forest in the mature class and 18 percent in old growth (Woodall et al. 2023; USDA Forest Service and USDI BLM 2023), an estimate that shifts with the structural thresholds chosen. This is the national-scale precedent and the definitional-sensitivity parallel to our axis-count funnel, and it is fully sourced.

Pending: Chris's specific 27 to 81 percent sensitivity range. It is consistent with the FIGSS design (varying the percentile, walkdown factor, and composite-index cut would swing the mature estimate widely), but it is not in the open federal report, which uses a single configuration. Recommendation: cite the verifiable approximately 45 percent / 18 percent figures now, and add Chris's exact sensitivity range once he sends the table he offered. I revised both documents accordingly so no unverifiable number is in the submission draft.

## Bottom line

Chris is right that the multi-axis treatment is national precedent, and FIGSS is the correct anchor: it shares our live-structure, dead-wood, and size/diversity indicators and the design-based FIA backbone, and its estimate is just as definition-sensitive as our funnel. Our framework's distinct contribution against FIGSS is the explicit composition axis and, especially, the satellite-derived temporal-continuity axis, which addresses the structure-only blind spot that FIGSS, like the canopy maps, cannot.
