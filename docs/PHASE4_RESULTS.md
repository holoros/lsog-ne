# Phase 4 first run: Maine, all FIA plots through 2024

Date: 2026-04-25
Plots: 19,149 (all panels combined)
ORNL raster: Bruening et al. 2026 (ORNL DAAC ds_id 2498), circa 2022,
re-encoded from ZSTD to LZW so the Cardinal-bundled GDAL can read it.

## Headline numbers

| Metric | v3 proxy | ORNL 2498 |
|---|---:|---:|
| Old-growth (OG) percent of plots | 0.04 | 0.14 (OG prob > 50) |
| LS + OG percent of plots | 0.81 | n/a |
| Any LSOG / MOG percent of plots | 8.25 | 33.4 (MOG prob > 50) |

## Confusion table (v3 class x ORNL OG-probability bin)

| v3 class | <=5% | 6-25% | 26-50% | 51-75% | >75% | NA |
|---|---:|---:|---:|---:|---:|---:|
| Not LSOG          | 13,838 | 3,095 | 280 | 15 | 5 | 337 |
| Transitioning LS  |   982  |   363 |  44 |  6 | 0 |  29 |
| LS                |   108  |    25 |   9 |  0 | 0 |   5 |
| OG                |     6  |     0 |   2 |  0 | 0 |   0 |

## Two clear stories

**1. Disagreement on OG specifically.** v3 flags 8 plots as OG. ORNL gives
zero of them an OG probability above 50, only two above 25. The v3 OG
calls are not corroborated by the LiDAR/satellite-based Bayesian model.
Likely cause: the v3 score-8 OG threshold can be reached by a single
FIA plot with several large stems and high snag TPA without the canopy
structure signature that ORNL's QDA actually keys on.

**2. Systematic 4x gap on the broader "mature" pool.** ORNL flags 33.4%
of ME plots as MOG (mature-or-OG) probability above 50. v3 flags only
8.25% as any LSOG class (TLS + LS + OG combined). That is a four-fold
gap. The 337 NA entries in the Not-LSOG row are plots that fall outside
the ORNL valid extent (likely near coast or off the CONUS forest mask).

The ORNL "mature" definition (Pelz et al. 2023, Woodall et al. 2023) is
more inclusive than the v3 5-dimension threshold rubric. To make the
comparison fairer, Phase 4 v2 should add an ORNL mature-probability bin
to the confusion table and also re-bin v3 with looser thresholds for a
Mature-equivalent class.

## Caveats

- Public FIA lat/lon are fuzzed up to ~1 km; for 1-ha pixels this nudges
  some plots into adjacent cells. True coordinates under the DUA would
  improve precision but the fuzzing is unlikely to flip class assignment
  systematically.
- The 19,149 plots span 1999 to 2024; the ORNL raster represents 2022.
  A panel-aware comparison (run for the 2019 to 2023 panel only) would
  match the ORNL temporal scope better.
- Bruening et al. 2026 trained their QDA on FIA MOG labels (Pelz 2023,
  Woodall 2023). This is a coherence check, not blind validation.

## Next iteration ideas

1. Add ornl_mature_bin and ornl_mog_bin to the confusion table.
2. Filter to the 2019 to 2023 FIA panel and rerun for temporal alignment.
3. Recalibrate v3 thresholds against ORNL labels: pick threshold values
   that maximize agreement with ORNL "mature" call for the LS class and
   ORNL "old-growth" for the OG class. Check that this also lifts the
   bias the Hagan/Thompson comparison surfaced.
4. Add NH, VT, NY: just append codes to STATE_CODES and ensure the
   PLOT/COND/TREE CSVs are in data/fia/.
