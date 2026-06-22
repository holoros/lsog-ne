# Simulated peer review: LSOG Comment and Northeast manuscript

Prepared 17 June 2026. This simulates the review each document would likely receive, using the structured review pipeline (preliminary screen, methods and statistical rigor, quantitative claims and scaling audit Q1 to Q13, citation integrity, scoring, recommendation). Two to three reviewers and an editor synthesis per document. Reviewer voices are simulated, not real. Actionable points marked **[implemented]** were folded into the documents in this round; the rest are noted for Aaron's judgment.

---

## Document 1: Comment on Hagan et al. (2026), Ecosphere

Manuscript type: Commentary. Central thesis: a single high-training-accuracy LiDAR classification is not a sufficient basis for parcel-level acquisition, and a cross-map accuracy assessment plus a design-based interval should accompany it before it anchors spending.

### Reviewer 1 (forest biometrics / FIA)

General. The design-based anchoring argument is the heart of the Comment and it is correct and well executed. The reproduction of the published classifier, the rare-class operating-accuracy point, and the cross-map disagreement are each fair and load-bearing. The revised national framing reads as objective rather than as a Maine-specific rebuttal. Three things would strengthen it.

Specific.
- L (Sec 5): the design-based estimates are given without their sample size; a reader cannot judge the interval width without n. Add the panel and plot count. **[implemented: "2019-2023 FIA panel, 3,125 plots"]**
- L (Sec 4): the contrast "12.5% large-tree basal area versus 3.9% on a stand-age criterion" uses age >= 120 yr while the Comment elsewhere de-emphasizes FIA stand age. The text already labels the contrast illustrative, which is adequate, but consider leading with the four-axis 3.1% to avoid the appearance of relying on the age measure. (Optional; left to Aaron.)
- Verify the three load-bearing characterizations of the original paper: 94.1% reported accuracy, no true old-growth field-validation sites, and Big Reed as the authors' primary old-growth training source. These were independently confirmed against the source in an earlier fidelity pass; the Comment is faithful.

Recommendation: Minor Revision.

### Reviewer 2 (remote sensing / mapping)

General. The "high training accuracy does not produce map agreement" point is the most valuable contribution and is well supported. The Comment is appropriately careful that the ORNL continental product is a cross-scale caution rather than evidence any one map is wrong, so the honest headline is the 1.6-fold disagreement between the two structure maps, with the 2.6-fold range a secondary figure. Two requests.

Specific.
- The Competing Interests statement cites discrimination figures (about 0.82 for an open Sentinel embedding, about 0.87 fused) with no pointer to where they are documented; a reader cannot locate the analysis. Add a pointer. **[implemented: "documented in the companion technical report (Weiskittel 2026)"]**
- "Two independent routes converge near 14%" overstated independence, since the canopy-height structural class is itself FIA-trained. **[implemented: softened to "two routes that differ in sensor and method"]**

Recommendation: Minor Revision.

### Editor synthesis (Comment)

Minor Revision. The science is sound and the tone is now objective. Required before acceptance: report sample sizes for the design-based estimates [done]; add a documentation pointer for the discrimination figures [done]; confirm the load-bearing characterizations of the original paper [confirmed in prior fidelity pass]. The national framing and the softened acquisition language address the most common reviewer concern, that a Comment reads as an attack rather than an assessment.

---

## Document 2: It depends how you count (Northeast LSOG manuscript), Ecological Applications / Ecosphere

Manuscript type: Research article. Central contributions: design-based older-forest estimates with intervals; a four-axis LSOG funnel; a full cross-map assessment over Maine.

### Reviewer 1 (FIA / biometrics)

General. A substantial, rigorous, and honest paper. The design-based framing, the four-axis funnel, and the cross-map assessment are each strong, and the limitations section is unusually candid. The work credibly reframes LSOG accounting from a number to a range. The methods are competent; my concerns are about two places where the claims reach slightly past what this manuscript documents (Q10, Q12).

Specific.
- Sec 2.2 (Q10 circular validation): the v5.1 thresholds are calibrated by grid search against the Hagan classification and the ORNL layers, and the manuscript later compares against the reproduced Hagan map and reports the v5.1 integrated share. A reader needs an explicit guard that the calibration does not circularly drive the reported disagreement. **[implemented: added a sentence stating the cross-map assessment uses the independently reproduced Hagan random forest, the load-bearing area estimates rest on the design-based ground criteria with no map calibration, and the v5.1 proxy is therefore not an independent cross-map member]**
- Sec 4.1 (Q12/Q13 scaling and reproducibility): the fused 10 m discrimination (about 0.87) is companion-report work whose methods are not in this manuscript. Frame it explicitly as companion so it is not read as validated here. **[implemented: attributed to "Section 4.1 and companion report" and framed as still short of a rare-class area estimate]**
- Sec 2.5 / 3.7: the per-year trend should state how the interpenetrating FIA panel structure is handled, so the slope is not read as repeated measurement of the same plots. **[implemented: "rFIA panel-based annual estimation ... rather than repeated measurement of the same plots"]**
- Sec 2.3 / Table S1: the four-axis A1 uses a 16 in large-tree cut while the v5.1 dimension uses 20 in; reconcile so it does not read as an inconsistency. **[implemented: clause added in A1]**

Recommendation: Minor Revision (was trending Major before the circularity and scaling framing were addressed).

### Reviewer 2 (remote sensing)

General. The cross-map assessment is the strongest section and the honesty about "independent" meaning independent in predictors and sensor rather than independent of FIA is exactly right. The probability-surface-with-uncertainty framing is the correct product recommendation. No major methodological objection.

Specific.
- Fig 6: a binary cut at 0.93 to match the design-based area is unusual and will draw a query; the caption already explains the balanced model over-predicts, which is adequate. (No change required.)
- The ORNL near-zero spatial correlation is correctly read as a cross-scale caution rather than as proof a structure map is wrong. Good.

Recommendation: Minor Revision.

### Reviewer 3 (forest policy / management)

General. The triad reframing (Maine's low share is the expected signature of its production role, not a deficit) is compelling and is argued from the representation analysis rather than asserted. The policy section is balanced and does not read as advocacy. The gross-flux versus net-stock distinction is the single most useful point for the LD 1529 audience and is handled carefully.

Specific.
- Sec 4.6: ensure the "stable to rising stock" conclusion is not read as dismissing genuine local loss of high-value stands; the text does distinguish the two, which is sufficient.

Recommendation: Minor Revision.

### Editor synthesis (manuscript)

Minor Revision. Three reviewers converge on a sound, well-validated study whose only substantive review items are interpretive rather than methodological: a circularity guard on the calibrated proxy [done], explicit companion-report framing for the fused 10 m discrimination [done], and a note on the trend estimator [done]. No new data collection is required and the paper's identity is intact, so this resolves to Minor Revision under the calibration anchors. The presentation is within the figure and table budget once the supplement is counted separately.

---

## Refinements implemented this round

Comment: added the FIA sample size (2019-2023 panel, 3,125 plots) to the design-based estimate; added a documentation pointer for the discrimination figures; softened the overstated "independent routes" claim (carried over from the prior red-team).

Manuscript: added a Q10 circularity guard in Section 2.2; attributed and bounded the fused 10 m discrimination as companion work (Section 4.1); noted the interpenetrating-panel trend estimator (Section 2.5); reconciled the 16 in versus 20 in large-tree cut (Section 2.3).

Both documents rebuilt and verified. Remaining optional items (lead Section 4 of the Comment with the four-axis figure; no change needed on Fig 6) are left to Aaron's judgment.
