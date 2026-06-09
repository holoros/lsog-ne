# Phase 12: How hard is it to map LSOG? Three methods, one honest answer

**Date:** June 9, 2026. Job 11408596. Script `R/phase12_uncertainty_3method.r`.
Outputs: `output_phase12/`.

## The question

Reports now drive real money and policy off a single LSOG map. Thompson et al. (2026,
PERC / Harvard Forest / UMaine) build directly on Hagan et al.'s map, treat the ~165,000 ha
as established, and price protecting the "top 50%" of those patches at **$200-300 million** to
inform LD 1529. That makes the mapping uncertainty a first-order question, not a footnote.

We compared three credible, mappable ways to find LSOG across the same 4.2 M-ha unorganized
townships, all on the same 100 m grid:

- **M1 Hagan** — airborne-LiDAR canopy random forest (reproduced, Phase 10).
- **M2 v5.1-GEDI** — a logistic model of the FIA field-structure LSOG class on Potapov
  (GEDI-calibrated) canopy height, fit on 13,318 NE FIA plots (AUC 0.70). The defensible,
  mappable product: its target is field structure, not canopy shape.
- **M3 Potapov-direct** — canopy height >= 18 m, a naive "tall canopy" rule.

## They disagree on HOW MUCH

| Method | any-LSOG % of AOI | any-LSOG ha |
|---|---:|---:|
| M1 Hagan (LiDAR canopy) | 21.9 | 938,679 |
| M2 v5.1-GEDI (FIA + Potapov) | 14.0 | 597,528 |
| M3 Potapov-direct (RH95 >= 18 m) | 14.1 | 603,991 |

Hagan flags **1.6x more** any-LSOG than the GEDI-based products, a gap of ~340,000 ha. And
within the single defensible product, the estimate swings from 424,000 to 1,059,000 ha
(a factor of 2.5) just by moving the probability threshold across a defensible range. "How
much LSOG is there" has no single answer.

## They disagree on WHERE, much more

| Pair | Cohen kappa | Jaccard |
|---|---:|---:|
| Hagan vs v5.1-GEDI | 0.21 | 0.21 |
| Hagan vs Potapov-direct | 0.21 | 0.21 |
| v5.1-GEDI vs Potapov-direct | 0.99 | 0.99 |

Hagan and the GEDI-based maps overlap on only ~21% of the hectares either one flags; about
**four out of five LSOG hectares are flagged by one method but not the other.** (The two
GEDI-based maps agree with each other because both derive from Potapov height; they represent
one "canopy-height view" against Hagan's "airborne-LiDAR-structure view.")

Three-way concordance over every hectare flagged by any method:

| Methods agreeing | hectares | share of flagged |
|---|---:|---:|
| 1 method only | 672,764 | 52.9% |
| 2 methods | 333,013 | 26.2% |
| all 3 methods | 267,136 | 21.0% |

**Only 21% of the flagged LSOG footprint is agreed by all three methods; the majority is
flagged by a single method.**

## What Hagan's canopy-only model includes

Of the 938,679 ha Hagan classifies as LSOG, **71% have Potapov (GEDI) canopy height below
18 m** and 71% fall below the v5.1-GEDI probability cutoff. Hagan's any-LSOG class folds in a
large transitional component that independent canopy-height data do not register as tall,
mature forest. Some of this is expected (his "Transitioning LS" is by definition not yet
mature), but policy framings that treat the whole any-LSOG figure as "old forest" inherit that
ambiguity.

## No method matches the field plots well

At the 1,760 FIA plots in the unorganized townships, agreement with the FIA field-structure
class is weak for **every** method, Cohen kappa 0.06 to 0.07. Even the FIA-calibrated
GEDI product reaches only 0.063 plot-by-plot, because canopy height alone (AUC 0.70) cannot
resolve the tree-level structure that defines LSOG on the ground. There is no clean ground
truth here; the field class is itself a proxy for an inherently continuous, fuzzy property.

## Why this matters for conservation spending (policy fragility)

If a program protects the highest-priority hectares, do different maps point to the same
ground? Jaccard overlap of the top-ranked protected sets, Hagan versus the GEDI product:

| Protect the top... | overlap (Jaccard) |
|---|---:|
| 5% of hectares | 0.16 |
| 10% | 0.30 |
| 20% | 0.27 |

**70 to 84% of the prioritized hectares differ depending on which map you trust.** A
$200-300 M acquisition program steered by one map would buy largely different forest than the
same program steered by another equally defensible map.

## The honest takeaway

Mapping LSOG in Maine's working forest is genuinely hard, and the uncertainty is large and
irreducible with current data:

- credible methods disagree by ~1.6x on **how much** (and 2.5x within one method by threshold),
- they disagree on **where** for ~4 of every 5 hectares,
- no remote method reproduces the field class plot-by-plot (kappa <= 0.21),
- and that spatial uncertainty would redirect most of a conservation budget.

This does not mean the maps are useless. It means LSOG extent should be reported as a
**range across methods with explicit uncertainty**, single-map patch-level prioritization for
large expenditures should be treated with caution and paired with field verification, and
reports informing LD 1529 (e.g., Thompson et al. 2026) should carry that uncertainty in the
headline, not the appendix. The most defensible mappable product anchors its target in FIA
field structure (v5.1) and uses GEDI canopy height as the wall-to-wall predictor, but even
that is one uncertain estimate among several, not a definitive map.

## Files (output_phase12/)

T0_M2_logit_fit, T1_area_by_method, T2_M2_threshold_sensitivity, T3_pairwise_agreement,
T4_concordance_counts, T5_hagan_overcall, T6_prioritization_jaccard, T7_fia_validation,
M2_v51gedi_pLSOG_100m.tif, fig/M_three_maps.png.
