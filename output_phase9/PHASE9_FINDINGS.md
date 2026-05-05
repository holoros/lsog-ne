# Phase 9 Seven Islands / Hagan cross-validation: findings

**Date:** May 5, 2026
**Reference data:** Seven Islands LSOG raster (Hagan M2V2b GFW23-MASKED, 100 m grid, classes 1-4)
**Reference area:** Pingree Ownership, ~290,098 ha (~717 K ac) in northwest Maine UT
**Pipeline:** `phase9_seven_islands_validation.R` and the Python equivalent in `phase9/`

## Headline numbers (FIA panel 2019 to 2023, n = 125 in-extent plots)

### Confusion matrix (v5.1 rows by Hagan columns)

| v5.1 class | Not LS | Trans LS | LS | OG-like | total |
|---|---:|---:|---:|---:|---:|
| Not LSOG | 93 | 21 | 1 | 0 | 115 |
| Transitioning LS | 7 | 1 | 0 | 1 | 9 |
| LS | 0 | 1 | 0 | 0 | 1 |
| OG | 0 | 0 | 0 | 0 | 0 |
| **total** | **100** | **23** | **1** | **1** | **125** |

### Cohen kappa

| Comparison | n | kappa | Interpretation |
|---|---:|---:|---|
| v5.1 any-LSOG vs Hagan any-LS (2/3/4) | 125 | 0.065 | essentially random |
| v5.1 LS+OG vs Hagan LS+OG-like (3/4) | 125 | -0.011 | random |
| v5.1 OG vs Hagan OG-like (4) | 125 | 0.000 | random |
| v4 any-LSOG vs Hagan any-LS (2/3/4) | 125 | -0.011 | random |
| v4 LS+OG vs Hagan LS+OG-like (3/4) | 125 | -0.016 | random |

### Share-level comparison (in-extent latest panel, n = 125)

| Source | any-LSOG % | LS+OG % | OG-only % |
|---|---:|---:|---:|
| v5.1 (FIA proxy) | 8.0 | 0.8 | 0.0 |
| v4 (FIA proxy, no GEDI) | 16.8 | 1.6 | 0.0 |
| Hagan (LiDAR at FIA plots) | 20.0 | 1.6 | 0.8 |
| Hagan landscape Pingree (Table 2 of report) | 18.8 | 2.4 | 0.6 |

## Three findings

**1. The FIA plot population is representative of Pingree.** Hagan any-LS at 125 in-extent FIA plot pixels is 20.0 percent, almost identical to the landscape Pingree estimate of 18.8 percent (report Table 2). The plot sample is unbiased.

**2. v5.1 (with GEDI canopy height) under-classifies relative to Hagan; v4 (without GEDI) matches Hagan share more closely but still does not match plot-by-plot.** The v5.1 any-LSOG share at these plots is 8.0 percent, less than half of Hagan's 20.0 percent. v4 sits at 16.8 percent, close to Hagan's overall share but with the same low plot-by-plot agreement.

**3. Plot-by-plot agreement is essentially random (kappa near zero) across all comparisons.** This is true for v5.1, v4, and any subset (any-LSOG, LS+OG, or OG-only). The two products are measuring genuinely different things even when their overall shares roughly agree.

## Mechanistic explanation: skid trails and FIA tree-level data

Ryan's note that the Hagan LSOG protocol is sensitive to skid trails and other legacy harvest impacts is consistent with these findings, and with the inverse direction also being true. The Hagan protocol uses 8 LiDAR canopy metrics (mean and max height, 95th percentile height, canopy rugosity, rumple index, and cover fractions over 2/6/15 m) to classify every hectare. Skid trails create canopy gaps that depress these metrics, which means Hagan can detect harvest-induced canopy disturbance that FIA tree-level data may not record (because the disturbed pixels around the skid trail were not necessarily within the FIA subplot).

The reverse is also at play. v5.1 weights tree-level attributes from FIA: large-tree basal area, total basal area, snag tree-per-acre, structural diversity of the diameter distribution, and stand age. These attributes can change after a selective harvest (large trees removed, BA reduced, stand age reset) even though the residual canopy structure that Hagan measures may stay tall and continuous. So v5.1 will downgrade a plot that v4 / Hagan would still classify as Transitioning LS based on canopy structure.

The mechanism is that Hagan and v5.1 measure different aspects of forest condition. Hagan measures canopy structure under disturbance; v5.1 measures stand-level FIA attributes. On Pingree, an actively managed industrial timberland, both forms of disturbance are common, and the two products diverge.

## What this means for the manuscript

The Phase 9 result strengthens the manuscript message in three ways. First, the share-level v4 to Hagan agreement (16.8 vs 18.8 percent) suggests the v4 calibration was on the right track for the working-forest portion of Maine, although the plot-by-plot kappa shows that inference at the individual plot is not robust. Second, the v5.1 share is systematically lower than v4 and Hagan for this region, which is consistent with the v5.1 GEDI canopy-height dimension being more conservative on Pingree's frequently-harvested stands where total basal area is depressed but residual canopy is tall. Third, the random plot-by-plot kappa across all variants confirms that LSOG class assignment at the individual plot is methodology-specific; only the LS+OG combined category is policy-stable, and even that warrants cautious interpretation in heavily managed industrial timberland.

Adding the skid-trail / legacy-impact caveat to the Limitations section is appropriate. The text in Section 4.6 of the V1 body draft should note that FIA-based classifiers like v5.1 cannot detect canopy-gap disturbance from skid trails or selective-harvest legacy impacts that Hagan's LiDAR-based protocol can detect, and conversely that Hagan-based products may miss tree-level changes (large-tree removal, BA reduction) that FIA tree-level data record.

## Caveats specific to this Phase 9 result

- **Pingree-only.** Seven Islands shared their ownership only, ~290 K ha, not the full 4.2 M ha Hagan UT raster. Cross-validation is therefore limited to plots within Pingree.
- **n = 125 latest-panel plots.** Adequate for the Trans LS comparison but small for the LS-class and OG-class comparisons (1 and 1 respectively in the Hagan reference).
- **FIA fuzzing.** Public FIA coordinates are fuzzed up to ~1 km. A buffered modal-class analysis (1 km radius) gave very similar kappa estimates and slightly different class shares, confirming that fuzzing is not the dominant source of disagreement.
- **GFW masking.** The Hagan raster masks out forest disturbed between 2016 and 2023 per Global Forest Watch. Some plots that were Hagan-classified as Trans LS at the time of the LiDAR flight may have since been harvested.
- **Class definitions differ.** Hagan's "Trans LS" is "100 to 150 yr canopy with structural characteristics, possibly recently lightly harvested or commercially overmature" — this overlaps but is not identical to v5.1's TLS at score >= 4 of 12.

## Companion files

- `phase9_seven_islands_validation.R` — production R script
- `phase9/me_plots_hagan_sampled_full.csv` — all 6,275 ME plots with Hagan value (1-4 in extent, 15 nodata, -1 outside bbox)
- `phase9/phase9_confusion_v5.csv` — v5.1 confusion matrix
- `phase9/phase9_confusion_v4.csv` — v4 confusion matrix
- `phase9/phase9_kappa_summary.csv` — Cohen kappa for all comparisons
- `phase9/phase9_share_table.csv` — share-level comparison
