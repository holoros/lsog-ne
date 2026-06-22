# Deep review: Hagan et al. (2026) vs our Comment — fact and fairness audit

Read the full 24-page Ecosphere article (DOI 10.1002/ecs2.70670) line by line and checked every claim our Comment makes about it. Summary: the Comment's numbers are accurate; three items were corrected or strengthened to remove any misrepresentation and to pre-empt pushback.

## Claims verified as accurate (no change needed)

- Reproduced OOB accuracy 94.1% for Not-LSOG vs LSOG. Confirmed: paper p.8, "the random forest classification model had a 94.1% accuracy rate." (The abstract rounds this to 93%.)
- Old-growth operating accuracy 29.4%. Confirmed: "did not perform well at correctly classifying the true OG hectares as OGL (29.4% success)."
- Most important predictor = fraction of canopy above 15 m (MDA 21.4%). Confirmed verbatim.
- Eight LiDAR canopy metrics, 463 training hectares. Confirmed.
- Loss rates 1.37%/yr study area and 2.19%/yr commercial timberland (period 2015-2023, from Global Forest Watch). Confirmed.
- LS+OGL = 3.9% of the study area. Confirmed (paper Table 7), and it matches our FIA design-based older-forest estimate of 3.9% [3.3, 4.6] almost exactly. This is a strong point of agreement, not a contradiction.
- ~4.2 million ha study area (exact 4,185,869 ha). Confirmed.
- Populus failure mode. Confirmed: the paper itself flags "tall, fast-growing Populus spp." in "80-100-year-old" stands as a confusion source. Our Section 4 mechanism is the authors' own observation.
- The authors recommend field verification before decisions. Confirmed: "we encourage forest managers and conservation practitioners to ground-truth our map before making management or conservation decisions." Our Section 6 cites this correctly.
- No confidence intervals anywhere in the paper. Confirmed by full-text search. Our "reported that figure without an interval" is accurate.
- They are aware of FIA-based estimates (cite Barnett 2023 at 6.3% US old growth; Pelz 2023 at 17% of National Forest land) but produce no FIA design-based estimate for Maine. Our framing (they did not report the unbiased ground estimate with intervals) is accurate.

## Corrected (was a misrepresentation)

1. Spaceborne products. Our Section 5 said Potapov (2021) and Lang (2023) were "cited in passing in the original introduction." They are not cited at all. The paper does cite GEDI-based structural work (de Conto et al. 2024). Fixed: the sentence now states the analysis references GEDI structural work but neither cites nor uses the Potapov/Lang canopy-height products as a cross-check, and de Conto et al. (2024) was added to the references.

## Reconciled (avoids an easy rebuttal)

2. Any-LSOG amount. The paper's Table 7 gives any-LSOG = 19.7% (15.8% transitioning + 3.0% LS + 0.9% OGL). Our reproduction over the 100 m grid gives 21.9%. Both are now reported, the small difference attributed to grid resolution and extent, and the cross-method spread restated as a 2.5- to 2.8-fold range so it holds under either figure. Table 2 caption updated.

## Strengthened (the author conceded our central point)

3. Gross flux vs net stock. Hagan et al. state plainly: "We had no way in this study to estimate the amount and rate of forest growing into an LSOG condition," and cite the federal Pacific Northwest case where older forest increased over 1993-2017 because ingrowth exceeded harvest. Our flux-vs-stock argument is therefore not a gotcha against an unaware author; it is the side the authors said their data could not measure. The Comment now quotes this directly, which both credits their transparency and makes the point much harder to dispute.

## Does Hagan acknowledge limitations, future work, and uncertainty? (Yes, qualitatively)

This is the key fairness check. The paper is genuinely transparent, so the Comment's language was tightened to credit it and to make the narrower, defensible claim.

What the authors DO acknowledge:
- A dedicated Limitations section (did not map stunted high-elevation/wetland old forest; did not evaluate indigenous land; mixed leaf-on/leaf-off LiDAR).
- The model classifies true old growth correctly only 29.4% of the time, and they propose future metrics, canopy-gap density and large downed-log density, to better separate LS from true OG. This directly anticipates our Section 4 dead-wood result.
- They could not estimate ingrowth ("We had no way in this study to estimate the amount and rate of forest growing into an LSOG condition") and cite the PNW case where ingrowth exceeded harvest. This is our flux point, conceded.
- Definitions matter: they cite a landscape where relaxing the old-growth definition moved the estimate from 2.7% to 15%. This is our cross-method-spread point, in their own words.
- They recommend ground-truthing before any management or conservation decision.

What the authors do NOT do (the gap the Comment fills):
- No confidence intervals or sampling error on any quantity (area, loss rate). Accuracy is reported as OOB/field point estimates only.
- No spatiotemporal trend with error estimates; the 1.37%/yr and 2.19%/yr loss rates are bare point estimates, and the half-lives are deterministic zero-order projections.
- No comparison against an independent map.
- No design-based ground (FIA) estimate for Maine.

Language consequence: the Comment now states plainly that the authors flag these limits qualitatively and that our contribution is to quantify them, since the map is being used quantitatively at a scale its stated uncertainties were never propagated to. Three sentences were added to the Comment (intro credit of the Limitations section; Section 4 noting they propose downed-log/gap metrics; Section 3 noting they stress definitions matter). The email was tightened the same way: it credits his Limitations section explicitly and frames our work as putting numbers and intervals on his own caveats. We avoid any phrasing that implies he ignored uncertainty, because he did not; he discussed it without quantifying it.

## Did Hagan cite Woodall and the GEDI LSOG literature? (Yes, do not run a "Maine vacuum" line)

He cites both, so any claim that he ignored the national or global literature is factually wrong and easily rebutted from his reference list.
- Woodall appears as a co-author on three cited works: Gray et al. 2023 (the wicked-problem synthesis), Pelz et al. 2023, and Ducey et al. 2013.
- GEDI LSOG work is cited directly: Spracklen and Spracklen 2021 (GEDI old growth), de Conto et al. 2024 (GEDI structural complexity), and Bauer et al. 2021 (GEDI fusion). He calls spaceborne lidar "one of the best ways to identify LSOG forest."
- Comparative LiDAR mapping is engaged too: de Assis Barros and Elkin 2021 (BC), Trouvé et al. 2024 (Australia), and the federal MOG inventory (Barndt et al. 2023; Barnett 2023; Pelz 2023).

Consequence for language: do not imply he worked in isolation. The defensible critique is the opposite and stronger: despite citing this literature, the analysis never uses any independent product as a benchmark, never places a sampling interval on its quantities, and never grounds the Maine estimate in the design-based FIA sample. The Comment intro now states exactly this, so the critique survives because he cites the literature, not in spite of it.

## GEDI / remote-sensing noise and geolocation error (handled, not relied upon)

The Comment does not treat GEDI or any remote-sensing product as a reference. GEDI is sparse-footprint and noisier than airborne LiDAR or a NAIP-derived canopy height model, and it carries a systematic geolocation error on the order of 10 m (Shannon, Finley, Hayes, Noralez, Weiskittel, Cook, and Babcock 2024, Environmetrics 35:e2840). Section 5 now states this plainly, and Section 3 notes that geolocation and co-registration error (which affects ALS and NAIP products too, not only GEDI) inflates pixel-level disagreement. This is why the Comment leans on (1) disagreement in total amount, which is position-insensitive; (2) 8-km hex aggregation, where positional error averages out; and (3) the design-based FIA estimate, which has no map geolocation error at all, as the sole reference. Net effect: the argument is robust to, and partly corroborated by, the GEDI-noise concern rather than dependent on GEDI being accurate.

## Residual risks to keep in mind (not errors)

- Definitional non-equivalence. Their commercial-timberland LS+OGL is 1.8% (a canopy class); our private-commercial older forest is 3.3% (stand age >= 120 yr, FIA). These are different targets over different denominators; the Comment already flags the definition-alignment issue and does not equate them. Worth a sentence in person if John raises it.
- Different time windows. Their loss is 2015-2023 (GFW canopy removal); our trend is 2003-2024 (FIA panels). We claim direction, not rate, which is the defensible claim across both windows.
- Our AOI grid (4,282,675 ha) is slightly larger than their analyzed area (4,185,869 ha); immaterial to the conclusions.

## Stress test (data verification, June 2026)

Every quantity in the Comment was re-checked against the source CSV outputs on Cardinal:
- Table 1 AUC (all nine cells and the three prevalences): matches T1_cv_auc_by_approach.csv exactly.
- Table 4 FIA design-based area and trend (age 100/120/150 and large-tree BA, statewide and northern, plus all four slopes): matches T1_designbased_oldforest_trend.csv and T3_trend_slopes.csv exactly.
- Table 3 structure R-squared (five attributes): matches T2_lidar_predicts_structure_R2.csv.
- Cross-map kappa/Jaccard (0.21, 0.01, 0.03) and prioritization Jaccard (0.16 to 0.30 over top 5-20%): match T2_pairwise_kappa_4method.csv and T6_prioritization_jaccard.csv.
- Ownership (private age>=120 3.3% slope +0.031; public 10.8%; private large-tree 11.5%): matches S1_oldforest_by_ownership.csv.
- 20-seed ensemble LS+OGL 4.23% (SD 0.06): matches S1_multiseed_summary.csv.
- TreeMap any-LSOG 7.8%: matches T1_treemap_lsog_timeseries.csv (2022, native 30 m), the basis the Table 2 caption states. A separate 100 m/full-AOI figure (2.88%) exists in T1_area_4method.csv but is not used in the Comment; either basis preserves the "2.5 to 2.8-fold" range.
- Numbers attributed to Hagan et al. (94.1%, 29.4%, canopy above 15 m, 1.37%/2.19% loss, LS+OGL 3.9%, any-LSOG 19.7%): verified against the article.

Reference integrity: every reference is cited in-text and every in-text citation has a reference. One orphan was found and fixed: Shamgochian et al. 2025 (the RAP field protocol) is now cited at the field-verification recommendation in Section 6. Clean rebuild of both documents validates. A build-crash from an unescaped quote (line 72) was found and fixed; it had frozen the deposited PDF at an earlier draft through Zenodo v1.2.2, corrected in v1.2.3.

## Bottom line

Nothing in the Comment overturns or misstates the original science. After these edits it credits the authors' transparency at every relevant point, uses their own admissions where they help, corrects the one citation error, and reconciles the one number a careful reader (or John) would have flagged. It is now harder to push back on, not softer.
