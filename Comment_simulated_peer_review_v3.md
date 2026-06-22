# Simulated peer review (v3): the expanded Comment on Hagan et al. (2026)

Three reviewer perspectives (remote sensing; forest biometrics; ecologist, written in the voice the
original corresponding author would likely take as the invited respondent) plus an editor synthesis,
run against the 16-page manuscript (reproduction; training accuracy, confusion, threshold, AUC;
cross-map disagreement; multidimensionality of LSOG; design-based FIA estimate and trend; New England
regional context and current protection; ensemble-and-uncertainty prototype; a repeatable four-axis
classification; and a terrain/disturbance overlay). Indicative recommendation: **Minor Revision**.

---

## Reviewer 1 (remote sensing and LiDAR)

**General.** A strong, now constructive Comment. The reproduction, the cross-map comparison, the
multidimensionality result, and especially the four-axis classification and the ensemble move it well
past a critique. Five points.

1. **Independence of the disturbance overlay.** The disturbance-probability layer is itself a
   TreeMap-derived modeled product, and TreeMap is one of your cross-map methods. State explicitly
   that the LSOG layer used in the overlay is the airborne Hagan reproduction (independent of the
   TreeMap-derived disturbance layer), or the result risks looking circular. Also flag that the
   disturbance product carries its own error.

2. **Slope as a harvest-accessibility proxy is crude.** It omits roads, mill location, ownership, and
   operability. Keep it, but say plainly it is a first-order proxy; the forthcoming harvest-probability
   surface will be the proper test.

3. **Spatial cross-validation.** The AUC and plot-level intervals should acknowledge spatial blocking;
   you note plots are dispersed and treat intervals as lower bounds, which is adequate, but one
   sentence committing to blocked CV in any follow-up would help.

4. **Independent accuracy.** OOB and the authors' Method 2 field check are in hand; an accuracy
   assessment against an independent probability sample (not OOB) remains the gold standard and should
   be named as the priority next step (it already is in Sec. 10; good).

5. **Specific.** State the resolution at which each kappa is computed; confirm the ensemble's binary
   inputs are thresholded at the same operating point; give the hex counts for the New England map.

## Reviewer 2 (forest biometrics, FIA)

**General.** The design-based estimates, the regional analysis, and the four-axis classification are
the strongest contributions and are well executed. Four substantive points.

1. **Classification thresholds are illustrative and need a sensitivity pass.** The 30 ft^2/ac
   large-tree, 5 ft^2/ac snag, 50% late-successional, and TRTCD-based continuity cutoffs are
   defensible but arbitrary; the 6.5% true-LSOG figure will move with them. Say the thresholds are
   tunable (Table 7 does this) and commit to a formal threshold-sensitivity analysis.

2. **Dead wood is only standing dead.** Coarse woody debris, arguably the most diagnostic old-growth
   dead-wood attribute, is absent from the FIA pull (no DWM tables). Acknowledge that the dead-wood
   axis is therefore conservative and that adding CWD/DWM would strengthen it.

3. **Continuity via TRTCD is weak.** Treatment codes undercount legacy partial harvest and skid
   trails (your own point), so the continuity axis is permissive and the 6.5% is, if anything, an
   upper bound. The Landsat disturbance-history layer is the right fix; name it as planned.

4. **The dimensionality result is on a purposive sample.** The 463 training plots are not a
   probability sample, so the 59% PC1 / partial-independence finding is conditional on the training
   design. State this; the population anchor remains the design-based FIA estimate.

5. **Specific.** Justify the late-successional, long-lived species set with a citation; give plot
   counts for the rarer domains; report the FIA inventory-year span.

## Reviewer 3 (ecologist; the voice the original author would likely take)

**General.** I appreciate that the Comment reproduces our model faithfully, credits the transparency
and the Limitations section, and explicitly frames its aim as quantifying rather than dismissing our
caveats. I have three points where the framing should be adjusted, and I am inclined to see this
published with a Reply.

1. **The broad class is a deliberate, ecologically grounded choice, not an overstatement.** Our
   transitioning and late-successional classes are intended to capture the small patches and lifeboats
   that retention ecology shows have real biodiversity value; describing the broad class as
   "overstating the strict resource" reads the map against a target it was not solely built for. Please
   frame the breadth as objective-dependent (your Table 7 already supports this) rather than as error.

2. **Legacy skid trails do not negate ecological late-successional value.** A stand entered lightly
   decades ago can still carry late-successional structure and function. Treat continuity as one
   weighted axis, valued differently by objective, not as a disqualifier.

3. **Rate of loss conveys legitimate urgency.** I accept the flux-versus-stock distinction and that
   ingrowth offsets harvest in the aggregate; please retain the acknowledgment that the harvest flux is
   real and policy-relevant on the specific stands being cut, even as the net stock rises.

I would add that FIA, while unbiased for area, cannot resolve the specific small patches a land trust
acts on; the constructive synthesis is that the design-based estimate bounds the amount while a
verified, multi-axis map locates it.

## Editor synthesis

All three reviewers find the Comment publishable with minor revision and see the constructive turn
(multidimensionality, the repeatable classification, the ensemble, the driver overlay) as its main
value. Required revisions: (1) state the disturbance overlay's independence and the proxy nature of
slope; (2) flag the classification thresholds as tunable and commit to a sensitivity analysis; (3)
acknowledge CWD absence and the TRTCD/continuity weakness with Landsat as the planned fix; (4) note the
dimensionality result is from a purposive sample; (5) reframe the broad-class "overstatement" as
objective-dependent and treat continuity as a weighted axis, not a disqualifier; (6) justify the
species set; minor specifics on resolution, counts, and CV. None requires new data.

Recommendation: Minor Revision, with the original authors invited to submit a Reply.
