# Phase 11: Stress test + SILC update

**Date:** June 9, 2026. Jobs 11406341 (ensemble) + 11407549 (finish). Script:
`R/phase11_stresstest_silc.r` and `R/phase11b_finish.r`. Outputs: `output_phase11/`.

## Stress test of the Phase 10 reproduction and cross-validation

**(1) Random forest stochasticity (20 seeds).** Refitting and re-predicting under 20 seeds:

| Quantity | Mean | SD | Range |
|---|---:|---:|---:|
| OOB binary accuracy (%) | 94.05 | 0.32 | 93.7 – 95.0 |
| Wall-to-wall LS+OGL (%) | 4.23 | 0.06 | 4.12 – 4.34 |
| Wall-to-wall LS+OGL (ha) | 181,317 | 2,707 | 176,207 – 185,787 |
| Wall-to-wall OGL (%) | 0.94 | 0.03 | 0.88 – 1.01 |
| Cross-val kappa_any | 0.128 | 0.004 | 0.122 – 0.139 |
| Cross-val kappa_LS+OG | 0.064 | 0.011 | 0.049 – 0.079 |

The published binary accuracy (94.1%) sits squarely inside the seed range. The reproduced
LS+OGL share is tightly clustered at 4.2%, and the published 3.9% lies just **below** the
seed range, which confirms the small gap is not random forest noise but the study-area
denominator difference (the archived grid carries ~96 K more edge hectares than the
published 4,185,869-ha study-area total). The cross-validation kappa is highly stable.

**(2) FIA coordinate-fuzz sensitivity.** Point-sampling gave kappa_any = 0.123; sampling the
modal class within a 1 km radius gave kappa_any = 0.207. The buffer raises agreement modestly
but also drops the Hagan any-LSOG rate from 21.1% to 8.1%, because a 1 km modal filter washes
out the patchy, dispersed LSOG signal. Either way agreement remains fair-to-weak; fuzzing
explains part of the plot-by-plot disagreement but not the bulk of it.

**(3) Bootstrap CIs (B = 2000, latest panel).** v5.1 any-LSOG 12.0% [10.5, 13.5] versus Hagan
21.1% [19.2, 23.0]; v5.1 LS+OG 1.19% [0.68, 1.71] versus Hagan 3.86% [3.01, 4.77]. The share
differences are statistically robust (non-overlapping intervals). kappa_any 0.122 [0.071,
0.175] excludes zero but stays firmly in the weak-agreement band.

**Conclusion:** the Phase 10 reproduction and the weak FIA-vs-LiDAR plot agreement are both
robust to random forest stochasticity, coordinate fuzzing, and resampling.

## SILC update (Seven Islands M2V2b vs the published model)

Now that the published model is reproducible, we tested whether the privately shared Seven
Islands LSOG raster (SILC, M2V2b, GFW23-masked) agrees with it.

| Comparison | n | kappa |
|---|---:|---:|
| SILC vs Reproduced-Hagan, any-LSOG (plot) | 124 | 0.951 |
| SILC vs Reproduced-Hagan, LS+OG (plot) | 124 | 1.000 |
| **SILC vs Reproduced-Hagan, any-LSOG (pixel)** | **289,703** | **0.966** |
| SILC vs Reproduced-Hagan, LS+OG (pixel) | 289,703 | 0.952 |
| v5.1 vs SILC, any-LSOG (plot) | 125 | 0.065 |
| v5.1 vs Reproduced-Hagan, any-LSOG (plot) | 124 | 0.050 |

Plot-level Pingree shares: v5.1 8.0% / v4 16.8% / SILC 20.0% / Reproduced-Hagan 21.6% any-LSOG.

**Conclusion:** the privately shared SILC raster and Hagan's published model are essentially
the same product (pixel-level kappa 0.97 across ~290 K hectares; perfect agreement on the
LS+OG plot category). This validates the Phase 9 SILC-based cross-validation retroactively and
confirms that v5.1 disagrees with both Hagan-lineage products to the same degree (kappa ~0.05
to 0.07), i.e., the divergence is intrinsic to the FIA-proxy-versus-LiDAR contrast, not an
artifact of any one Hagan product.

## Files (output_phase11/)

S1_multiseed_ensemble.csv, S1_multiseed_summary.csv, S2_fuzz_sensitivity.csv,
S3_bootstrap_ci.csv, S5_silc_plot_shares.csv, S5_silc_kappa.csv,
S5_me_plots_silc_hagan.csv, S6_silc_vs_hagan_pixel_crosstab.csv,
S6_silc_vs_hagan_pixel_kappa.csv, fig/S1_lsogl_distribution.png.
