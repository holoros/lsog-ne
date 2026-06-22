# Simulated peer review: Weiskittel, "...Maine, USA: Comment" (Ecosphere)

Prepared as an internal hardening exercise (manuscript-review modules 1-6) before submission. Two
reviewer perspectives and an editor synthesis, written to anticipate the actual Ecosphere review
(in which Hagan, as corresponding author of the original paper, is invited to submit a signed
review and a Reply). Indicative recommendation: **Minor-to-Major Revision** of a strong, novel,
well-supported Comment.

---

## Reviewer 1 (remote sensing and LiDAR)

**General.** This is a careful, transparent, and largely convincing Comment. The author reproduces
the original random forest exactly, which is reassuring, and the central argument, that high
training accuracy does not translate into agreement among independent maps, is demonstrated cleanly
and is important for the policy use now being made of the original map. I have three substantive
concerns and several specific points.

First, the cross-map comparison must defend against the obvious rebuttal that the two comparison
products (canopy-height logistic model, TreeMap) are weaker than the airborne map, so their
disagreement reflects their limitations rather than genuine ambiguity. The author partly does this
by reporting high training AUC for all three predictor sets and by reproducing the Seven Islands
product at kappa 0.97, but the rebuttal will come, and the manuscript should meet it head-on:
state explicitly that the claim is about uncertainty among credible operationalizations, not about
any product being correct, and that the airborne map itself is one such operationalization. (The
revised draft now does this; good.)

Second, the AUC table (Table 1) can be read as showing the original method IS accurate, including
for old growth (0.966). The author concedes this, which is the right move, but the framing should
lean harder on the operating-point accuracy the original authors themselves report (29% for old
growth) and on the fact that AUC is a ranking statistic. This is handled but worth one more
sentence emphasizing that ranking ability on 463 labelled plots is not map accuracy at 4.2 million
hectares.

Third, the plot-level cross-validation for AUC and the FIA plot comparisons should acknowledge
spatial autocorrelation among nearby plots, which can make cross-validated intervals optimistic.
A sentence noting that FIA and the training plots are spatially dispersed, and that the intervals
should be read as lower bounds on uncertainty, would suffice.

**Specific.**
- Section 3 / Table 2: report the resolution at which kappa is computed and the resolution at which
  TreeMap area is computed, since they differ; the revised note helps but make it explicit in the
  table caption.
- Section 5: the spaceborne products (Potapov, Lang) have documented accuracy issues (Moudry 2024,
  now cited); good, but say plainly you are not proposing them as a better map.
- Fig. 1: panel (b) maps need a north arrow / scale bar and a one-line statement of the window
  location.

## Reviewer 2 (forest biometrics and FIA inventory)

**General.** The strongest and most novel contribution here is the FIA design-based estimate with
sampling-error intervals, which is exactly the uncertainty the original analysis omitted, and the
demonstration that the older-forest stock is stable to increasing rather than rapidly declining.
This is the right tool for the question and is well executed with rFIA. I have four concerns, all
addressable.

First, FIA stand age (STDAGE) is modeled and is unreliable in the uneven-aged Acadian stands that
dominate the study region; an age-threshold definition of old forest is therefore shaky on its own.
The author anticipates this by reporting a large-tree basal-area structural domain alongside age and
showing the two bracket a consistent range, and the revised draft adds a threshold-sensitivity
analysis (20/30/40 ft^2/ac). This is sufficient, but the manuscript should foreground the structural
domain at least as much as the age domain.

Second, the "increasing" trend is estimated over the FIA annual panel series, which is a system of
moving-window estimates; some of the apparent increase could reflect panel and methods updates
rather than ground change. The trend with confidence intervals is convincing for direction, but the
text should be explicit that the robust claim is direction (not declining), shared across age and
structural criteria, rather than a precise rate.

Third, and most important for the policy framing, the stock-versus-flux argument is asserted but not
quantified from the inventory itself. FIA tracks growth, removals, and mortality (the GRM tables).
A direct estimate of gross old-forest ingrowth versus harvest removals would make the mechanism
("aging more than replaces the hectares cut") concrete and much harder to dispute. I strongly
encourage adding this; it converts the central temporal claim from an inference into a measurement.

Fourth, the comparison crosses three different targets: the original "LSOG" (which includes a
transitioning class), FIA "old forest" by age, and "old growth." The manuscript should include a
short paragraph or table aligning these definitions so readers do not compare incommensurable
numbers. The 3.9% age-based figure happening to bracket the 3.9% LS+OGL figure is striking but is a
coincidence of two different definitions and should be labelled as such.

**Specific.**
- Section 5: report the estimate by ownership group (private commercial vs public), because the
  policy and certification implications are specific to commercial timberland; a statewide number
  can mask a commercial-land decline. (This is the single most useful addition.)
- Table 4: give sample sizes (number of plots) per estimate.
- Define "older forest" operationally at first use.

## Editor synthesis

Both reviewers find this a strong, timely, and well-supported Comment that meets the bar for the
journal, and neither identifies a flaw that would require new data collection; the concerns are
addressable by revision of the existing analysis and writing. The contribution is genuine: a
cross-map accuracy assessment and a design-based ground estimate with the intervals the original
analysis lacked, bearing directly on a $200-300 million policy use of the map.

Required revisions:
1. Meet the proxy-strawman rebuttal explicitly (done in revision; verify).
2. Strengthen the AUC framing toward operating accuracy and add the spatial-autocorrelation caveat.
3. Foreground the structural (large-tree) domain and state that the temporal claim is direction, not rate.
4. **Add an ownership-resolved estimate (private commercial vs public).** [Phase 19 supplies this.]
5. **Quantify flux vs stock from FIA growth-removals-mortality** to make the mechanism concrete. [Recommended follow-up analysis; can be a key addition or a noted next step.]
6. Add a short definition-alignment paragraph (LSOG vs old forest vs old growth).
7. Editorial: scale bars on maps, plot counts in Table 4, define terms at first use.

Recommendation: Minor-to-Major Revision. With items 1-4 and 6-7 the manuscript is acceptable; item 5
would elevate it from a strong critique to a definitive one.
