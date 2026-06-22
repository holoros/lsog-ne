# Simulated peer review (v2): expanded Comment on Hagan et al. (2026)

Prepared as an internal hardening pass on the 14-page expanded manuscript (adds Sections 6 regional
context and protection, 7 ensemble prototype, and Figs 1-2 confusion/threshold and Fig 4 temporal
panel). Two reviewer perspectives and an editor synthesis. Indicative recommendation: **Minor
Revision** of a now substantially stronger Comment.

---

## Reviewer 1 (remote sensing, classification, spatial analysis)

**General.** The expansion materially strengthens the paper. The confusion matrix (Fig. 1) and the
cross-map work make the central claim concrete, and the ensemble-and-uncertainty prototype (Sec. 7)
turns a recommendation into a demonstration, which is exactly what a methods-and-tools venue should
want. Four points, all addressable in revision.

1. **Define the ensemble quantity precisely.** Fig. 6 calls the layer "ensemble LSOG probability,"
   but it is the mean of three heterogeneous memberships: two binary class indicators (Hagan,
   TreeMap) and one continuous score (v5.1-GEDI). That is an agreement or membership score, not a
   calibrated probability, and a careful reader will object to the word "probability." Either
   calibrate it or rename it (e.g., "ensemble membership / agreement score") and say plainly how it
   is formed and that it is unweighted.

2. **The threshold-sensitivity figure (Fig. 2) is on the labelled plots, not the landscape.** The
   "fraction called LSOG" there reflects the enriched training prevalence, so a reader could mistake
   it for mapped area. State that it is computed on the labelled plots to show the leverage of the
   cutoff on classification, not the wall-to-wall extent.

3. **Bivariate map legibility.** Fig. 7 is effective but the 3x3 legend is small; ensure it is
   readable at column width, and state the quantile breaks used for the classes.

4. **Confusion-matrix reproduction.** Old growth at 24% here versus the authors' 29.4% is fine, but
   note explicitly that the small difference is random forest stochasticity and the rare-class
   sample (n = 17 OG plots), not a discrepancy in the data.

## Reviewer 2 (forest inventory, FIA, biometrics)

**General.** The regional context (Sec. 6) and the protection analysis are valuable and well within
what FIA design-based estimation supports. The New England panel is a strong addition: showing the
age-versus-structure divergence across six states is a clean, general demonstration of the
definitional problem. Four points.

1. **RESERVCD is a conservative protection proxy.** It captures land legally withheld from harvest
   and will miss working conservation easements that permit some cutting, so the "% protected" is a
   lower bound on conserved area. Say so, and frame the headline as "formally reserved" rather than
   "protected" in the strict sense. The dominant finding (older forest is overwhelmingly private and
   largely unreserved) is robust to this.

2. **"private AND reserved ~0" needs a softer statement.** Report it as below the sampling detection
   limit (no sampled plots; effectively 0 with a wide interval), not a hard zero.

3. **Structural threshold interpretation varies by forest type.** Large-tree basal area >= 30
   ft^2/ac reaches 56 to 58% in southern New England because those are mature second-growth hardwood
   stands, which are structurally large-treed but not old growth. Add a sentence so the high southern
   values are not read as old-growth abundance; this actually reinforces the big-trees-are-not-
   old-growth argument.

4. **RI age-trend.** The Rhode Island age >= 120 slope is unestimable (sparse plots); note it rather
   than leave it blank, and lean on the structural measure there.

**Specific.** Give plot counts for the rarer domains; confirm the New England estimates use each
state's own post-stratification; state the FIA inventory-year span per state in the caption.

## Editor synthesis

A clearly improved Comment that now both diagnoses and constructively addresses the problem, with
regional generality and a working prototype. No new data required; all points are revision of
framing and precision.

Required (minor) revisions:
1. Rename/define the ensemble layer as an unweighted membership/agreement score, not a probability.
2. Clarify Fig. 2 is on labelled plots (cutoff leverage), not landscape area.
3. Frame RESERVCD as "formally reserved" (a conservative lower bound on conserved area).
4. Soften "private AND reserved ~0" to below detection.
5. Note the structural threshold's type-dependent meaning (southern NE = mature second growth, not OG).
6. Editorial: bivariate legend legibility/breaks; confusion stochasticity note; RI trend note.

Recommendation: Minor Revision. Items 1-5 are quick text/caption fixes that remove the few handholds
a hostile reviewer (or the original authors) could grab.
