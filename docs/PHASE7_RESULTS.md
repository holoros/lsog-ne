# Phase 7 results: v5.1 vs Pelz 2023 OG criteria on NE NFS lands

Date: 2026-04-27
Reference: Pelz et al. 2023 (FEM 549:121437) Eastern Region (R9) OG criteria

## Method

Filtered NE FIA plots (ME/NH/VT/NY) to USFS National Forest System lands
(OWNCD == 11). Applied uniform Pelz Eastern Region OG thresholds:
- Stand age >= 100 yr
- Density >= 5 trees/ac of DBH >= 12 in (live)

These are minimum thresholds across Tyrrell 1998 vegetation types. Type-
specific calibration would refine but at the cost of complexity.

## NE NFS coverage

| State | NFS plots | NFS in unified | Pelz-OG | Pelz-OG % |
|---|---:|---:|---:|---:|
| ME | 99 | 54 | 14 | 14.1 |
| NH | 1,152 | 520 | 112 | 9.7 |
| VT | 786 | 337 | 81 | 10.3 |
| NY | 27 | 14 | 1 | 3.7 |
| **Total** | **2,064** | **925** | **208** | **10.1** |

NE NFS lands ≈ White Mountain NF (NH), Green Mountain NF (VT), Finger
Lakes NF (NY), small ME parcels. ~1.0 M ac total. Pelz-OG share of 10.1%
across NFS plots is consistent with Pelz's published Eastern Region
estimate (304 K ac OG of ~10 M ac NFS-Eastern total = 3% — but Eastern
Region includes much more than just NE NFS).

## Confusion matrix (925 NFS plots in unified table)

| v5.1 class | Not Pelz-OG | Pelz-OG | Total |
|---|---:|---:|---:|
| Not LSOG | 467 | 36 | 503 |
| Transitioning LS | 314 | 49 | 363 |
| LS | 31 | 24 | 55 |
| OG | 1 | 3 | 4 |
| **Total** | **813** | **112** | **925** |

## Cohen's kappa for OG agreement

| Binary comparison | Kappa | Interpretation |
|---|---:|---|
| v5.1 OG vs Pelz OG | 0.044 | essentially random |
| **v5.1 LS+OG vs Pelz OG** | **0.253** | **fair** |
| v5.1 any-LSOG vs Pelz OG | 0.115 | slight |

## Two key findings

### 1. v5.1 OG-class has very low independent validation

The v5.1 OG-specific kappa of 0.04 vs Pelz mirrors the kappa ~0 vs ORNL
mature-prob > 50 from Phase 4. The v5.1 OG class is too rare and too
sensitive to specific dimension combinations to align with independent
classifiers. **Don't over-interpret state-level v5.1 OG percentages
without further validation (Hagan raster pending).**

### 2. v5.1 LS+OG aligns "fairly" with Pelz OG (kappa 0.253)

Of 112 NFS plots Pelz flags as OG:
- 3 are v5.1 OG (3%)
- 24 are v5.1 LS (21%)
- 49 are v5.1 Transitioning LS (44%)
- 36 are v5.1 Not LSOG (32%)

So 76 of 112 Pelz-OG plots (68%) are at least flagged as some LSOG class
by v5.1. The proxy correctly identifies most Pelz-OG plots as having
LSOG-like characteristics, but classifies them lower in the four-class
hierarchy than Pelz (which only has binary OG vs not).

### 3. Pelz finds substantially more OG than v5.1

In NE NFS lands: 112 Pelz-OG (10.1% of plots) vs 4 v5.1-OG (0.4%). Pelz's
two-criterion classifier (STDAGE >= 100 + 5 trees/ac of >= 12in DBH) is
more permissive than v5.1's six-dimension >=8/12 score requirement.

The "right" OG percentage in NE NFS lands is uncertain - Pelz's official
USFS framework finds 10x more than v5.1 finds. Hagan's LiDAR estimate
for Maine UT lands (NOT NFS) was 1% OG. Three different products give
three different OG percentages:

| Source | Coverage | OG share |
|---|---|---:|
| **v5.1 (this work)** | NE NFS plots | 0.4% |
| **Pelz 2023 (R9 criteria)** | NE NFS plots | 10.1% |
| Hagan 2024 LiDAR | Maine UT (not NFS) | 1.0% |

This range (0.4% to 10.1%) is the headline takeaway: OG-class identification
is highly sensitive to the criteria used. For policy-relevant reporting,
LS+OG combined or any-LSOG categories are more stable across products
than OG-specific.

## Files

In `output_phase7/`:
- `phase7_NFS_plot_classifications.csv`: per-plot v5.1 + Pelz indicators
- `phase7_v51_pelz_confusion.csv`: 4x2 confusion matrix
- `phase7_kappas.csv`: three binary kappas
- `phase7_state_summary.csv`: per-state counts and shares
