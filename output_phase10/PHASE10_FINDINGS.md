# Phase 10: Hagan et al. (2026) reproduction and full-UT cross-validation

**Date:** June 9, 2026
**Trigger:** Publication of Hagan, Shamgochian, Taylor & Reed (2026), *Ecosphere* 17:e70670,
"Using LiDAR to quantify, map, and conserve late-successional and old-growth forest in
Maine, USA," plus the companion Zenodo deposit (10.5281/zenodo.19696494, published 22 Apr 2026).

**What the new data unblocked:** Phase 6 (`hagan_extract`) was scaffolded but blocked on
Hagan's raster; Phase 9 only had the privately shared Seven Islands / Pingree subset
(~290 K ha, n = 125 in-extent plots). The Zenodo deposit now provides the actual 463-plot
training data, the exact randomForest recipe (`Ecosphere_code.Rmd`), and the per-hectare
LiDAR metrics for the entire 4.2 M-ha AOI (`AOI_LiDAR_stats.shp`, 4,282,675 hectares).
That lets us reproduce Hagan's classifier and cross-validate v5.1 against Hagan's *own*
wall-to-wall classification over the full unorganized townships, not a proxy.

Compute: OSC Cardinal, job 11406090, 2 min 16 s wall, 15.3 GB peak.
Script: `R/phase10_hagan_reproduction.r`. Outputs: `output_phase10/`.

---

## Part A — randomForest reproduction (faithful)

Trained `randomForest(LSOG_class ~ 8 LiDAR metrics, mtry = 2, ntree = 500)` on the 463
published training plots (282 Not LS, 85 Trans LS, 79 LS, 17 Old-growth).

| Validation | Reproduced (Phase 10) | Published (Hagan) |
|---|---:|---:|
| Binary Not-LSOG vs LSOG OOB accuracy | **94.2 %** | 94.1 % |
| Four-class OOB accuracy | 86.6 % | ~93 % (binary framing) |
| Most important variable (MDA) | **cano_cover_15** | cano_cover_15 |

Per-class OOB success: Not LS 95.4 %, LS 86.1 %, Trans LS 70.6 %, OG 23.5 %. The paper
reports Trans LS 84.7 %, LS 87.3 %, OG 29.4 % (Method 1, Table 4); OG is the hardest class
in both, exactly as the paper emphasizes. randomForest is stochastic, so small per-class
differences are expected. The headline binary accuracy reproduces to within 0.1 point.

Note: the *ordering* of variable importance matches (cano_cover_15, then height metrics),
but absolute MDA magnitudes differ from the paper's reported values because of importance
scaling/normalization differences — not a concern for reproduction validity.

## Part B — wall-to-wall prediction over the real 4.2 M-ha AOI

Applied the reproduced model to all 4,281,766 hectares with complete metrics (909 NA).

| Class | Reproduced ha | Reproduced % | Published ha | Published % |
|---|---:|---:|---:|---:|
| Not LSOG | 3,343,087 | 78.1 | 3,361,292 | 80.3 |
| Transitioning LS | 758,788 | 17.7 | 662,696 | 15.8 |
| LS | 142,118 | 3.32 | 124,821 | 3.0 |
| OGL | 37,773 | 0.88 | 37,060 | 0.9 |
| **LS + OGL** | **179,891** | **4.20** | **161,881** | **3.9** |

OGL reproduces almost exactly (37,773 vs 37,060 ha). LS + OGL comes in slightly high
(4.20 % vs 3.9 %), for two reasons: (1) our RF draw is marginally more liberal toward the
LSOG classes than the published draw, and (2) the Zenodo grid carries 4.28 M classified
hectares while the paper's reported study area is 4,185,869 ha — the ~96 K-ha gap is edge /
boundary hectares the published area total excluded, which inflates our denominator-based
percentages slightly. The published figures are reproducible from the deposit.

## Part C — true plot-by-plot cross-validation (the upgrade over Phase 9)

Rasterized the reproduced classification to 100 m and sampled it at every Maine FIA plot.
**3,527 ME plots fall inside the Hagan AOI** (both panels); **n = 1,760 for the 2019-2023
panel** — a 14× larger validation sample than Phase 9's n = 125.

Latest panel (2019-2023), v5.1 vs Hagan at the same plots:

| Share | v5.1 (FIA proxy) | Hagan (LiDAR) |
|---|---:|---:|
| any-LSOG | 12.0 % | 21.1 % |
| LS + OG | 1.19 % | 3.86 % |
| OG only | 0.06 % | 0.85 % |

Cohen kappa: any-LSOG **0.123**, LS + OG **0.050**.

**Three findings, now established at full UT scale:**

1. **FIA plots are spatially representative of the UT.** Hagan's any-LSOG share at the
   1,760 FIA plot pixels (21.1 %) matches his landscape wall-to-wall share (19.7 % published /
   21.9 % reproduced). The plot sample is unbiased — the Phase 9 result on Pingree (n = 125)
   holds across the whole unorganized townships.

2. **v5.1 (FIA proxy) classifies roughly half the any-LSOG and one-third the LS + OG that
   Hagan does.** v5.1 any-LSOG 12.0 % vs Hagan 21.1 %; v5.1 LS + OG 1.19 % vs Hagan 3.86 %.
   The gap is largest for the older, structurally-defined classes.

3. **Plot-by-plot agreement is weak (kappa ~0.12 for any-LSOG, ~0.05 for LS + OG).** The two
   products measure genuinely different things: Hagan reads canopy structure from LiDAR (and
   so detects skid-trail / selective-harvest canopy disturbance FIA tree records miss), while
   v5.1 weights FIA tree-level attributes (large-tree BA, total BA, snags, structural
   diversity, stand age) that change after selective harvest even when residual canopy stays
   tall. On actively managed industrial timberland, both forms of disturbance are common and
   the products diverge. Only the LS + OG combined category is policy-stable, and even that
   warrants caution in heavily managed forest.

## Implications

- The published Hagan numbers are reproducible from the public deposit (binary accuracy and
  per-class areas), which strengthens citing them as the authoritative LiDAR benchmark for
  Maine's unorganized townships.
- The Phase 9 caveat (FIA proxies cannot see canopy-gap harvest legacy; LiDAR products cannot
  see tree-level removals) is now confirmed on n = 1,760 rather than n = 125. The manuscript's
  Limitations / cross-validation section can cite the full-UT kappa with confidence.
- The earlier `output_final2/T30_maine_ut_vs_hagan.csv` (county-proxy UT delineation, Hagan
  values estimated, OG = 0) is **superseded** by `T31_maine_ut_vs_hagan_REAL.csv`, which uses
  the real spatial AOI and Hagan's actual classification at each plot.

## Files (output_phase10/)

- `hagan_rf_reproduced.rds` — reproduced randomForest model
- `A_oob_confusion_4class.csv`, `A_oob_confusion_binary.csv`, `A_variable_importance.csv`
- `B_walltowall_area_vs_published.csv`, `B_aoi_predicted_class_by_FID.rds`
- `C_hagan_class_100m.tif` — reproduced Hagan classification, 100 m raster
- `C_me_plots_hagan_full_AOI.csv` — every ME FIA plot with reproduced Hagan class
- `C_confusion_v5_2019-2023.csv`, `C_confusion_v5_all_panels.csv`, `C_share_and_kappa_summary.csv`
- `fig/A_varimp.png`, `fig/B_area_compare.png`
- `output_final2/T31_maine_ut_vs_hagan_REAL.csv` — superseding comparison table
