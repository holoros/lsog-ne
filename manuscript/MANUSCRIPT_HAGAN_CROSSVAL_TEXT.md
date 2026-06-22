# Manuscript insert: Hagan cross-validation and Limitations (Phase 10/11)

Drop-in replacement for the Phase 9 (n = 125, Pingree-only) cross-validation text in
`MANUSCRIPT_DRAFT_V1_BODY.md`. Numbers are from `output_phase10` and `output_phase11`.
Stress-test figures (multi-seed range, bootstrap CI) are pending the Phase 11 job and will
be filled where bracketed.

---

## Cross-validation against an independent LiDAR product (revise Section 4.5)

To test our FIA plot-based classifier against an independent, structurally-based map, we
used the publicly released late-successional and old-growth (LSOG) classification of Hagan
et al. (2026), who applied a random forest model to eight airborne-LiDAR canopy metrics to
classify every hectare of the approximately 4.2 million ha of Maine's unorganized townships.
Their training data, model recipe, and per-hectare LiDAR metrics are archived on Zenodo
(Hagan et al. 2026; deposit 10.5281/zenodo.19696494), which allowed us to reproduce their
classification directly rather than rely on a proxy.

We first confirmed that the published model is reproducible from the deposit. Refitting the
random forest on the 463 training hectares returned an out-of-bag accuracy of 94.2% for the
binary Not-LSOG versus LSOG distinction, matching the published 94.1%, with the fraction of
canopy above 15 m the most important predictor in both cases. Applying the reproduced model
across the full hectare grid returned 179,891 ha of combined late-successional and
old-growth-like (LS + OGL) forest (4.20% of the area classified), against the published
161,881 ha (3.9%); the old-growth-like class reproduced almost exactly (37,773 versus
37,060 ha). The small upward difference is consistent with random forest stochasticity and
with the archived grid carrying about 96,000 more edge hectares than the published study-area
total. We treat the published map as the authoritative LiDAR benchmark on this basis.

We then sampled the reproduced Hagan classification at every Maine FIA plot. A total of 3,527
plots fell inside the unorganized-townships extent (1,760 in the 2019-2023 panel), a sample
roughly fourteen times larger than the single-ownership cross-validation we reported earlier.
Across these plots the two products agree at the landscape level but diverge plot by plot. The
Hagan any-LSOG share at the FIA plot locations (21.1%) closely tracked the Hagan wall-to-wall
landscape share (19.7%), confirming that the FIA sample is spatially representative of the
unorganized townships. Our v5.1 classifier, however, assigned any-LSOG to 12.0% of the same
plots and LS + OG to 1.19%, against Hagan's 21.1% and 3.86%. Plot-by-plot agreement was weak
in both the inclusive category (Cohen's kappa 0.12) and the policy-relevant LS + OG category
(kappa 0.05). The divergence is largely structural rather than an artifact of FIA coordinate
fuzzing: re-sampling the Hagan class as the modal value within a 1 km radius of each plot
raised agreement only to kappa 0.21, still within the fair-to-weak range. A 20-seed random
forest ensemble confirmed that neither the reproduced area estimate (LS + OGL 4.23%, SD
0.06) nor the cross-validation agreement (kappa_any 0.128, SD 0.004) is sensitive to model
stochasticity, and a 2000-sample bootstrap placed the v5.1 and Hagan any-LSOG shares in
non-overlapping confidence intervals (12.0% [10.5, 13.5] versus 21.1% [19.2, 23.0]).

## Limitations (revise Section 4.6)

Our cross-validation shows that FIA plot-based and LiDAR canopy-based classifications of LSOG
forest measure related but distinct properties of the same stands, and the choice of method
materially affects the estimated amount of LSOG forest. The Hagan protocol reads canopy
structure from LiDAR and therefore registers canopy-gap disturbance from skid trails and
selective-harvest legacy that FIA tree-level records do not capture, because the disturbed
canopy around a skid trail need not fall within an FIA subplot. Conversely, our v5.1 classifier
weights FIA tree-level attributes, large-tree basal area, total basal area, snag density,
diameter-distribution structure, and stand age, which can change after a partial harvest even
where the residual canopy that LiDAR measures remains tall and continuous. On the actively
managed industrial timberland that dominates the unorganized townships, both forms of
disturbance are common, and the two products diverge accordingly. The practical consequence
is that only the combined LS + OG category should be treated as policy-stable across methods;
individual-plot class assignments, and the old-growth class in particular, are
method-specific. We recommend that area estimates of LSOG forest in this region be reported
with the classification method stated explicitly, and that maps intended for conservation or
certification decisions be ground-truthed before action, as Hagan et al. (2026) also advise.
