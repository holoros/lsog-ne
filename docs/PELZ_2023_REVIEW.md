# Pelz et al. 2023 review: implications for v5.1

**Reference**: Pelz, K.A., G. Hayward, A.N. Gray, E.M. Berryman, C.W. Woodall,
A. Nathanson, N.A. Morgan. 2023. Quantifying old-growth forest of United
States Forest Service public lands. Forest Ecology and Management 549:121437.
https://doi.org/10.1016/j.foreco.2023.121437

## Summary of Pelz et al. 2023

Pelz et al. produced the first nationally-consistent old-growth (OG) forest
inventory for USDA Forest Service National Forest System (NFS) lands. They
worked with regional NFS experts to translate regionally approved OG
definitions into FIA-applicable criteria, then applied those criteria to
the FIA inventory using design-based estimation.

**Headline estimate**: 10 million ha of OG on NFS lands nationally = 17% of
total NFS forested land. Mostly concentrated in western regions; Eastern
Region only 123,000 ha = 3% of NFS lands in the East.

## Most relevant section: Eastern Region (R9)

For the Northeast, the relevant NFS region is the Eastern Region (R9),
which uses Tyrrell et al. (1998) vegetation types translated to FIA forest
types. To classify a FIA condition as OG, it must meet:

- **Stand age**: 100 to 160 yr (varies by vegetation type)
- **Density of large trees**: 12.3 to 49.4 trees/ha (= 5 to 20 trees/ac) of
  trees with DBH >= 30.5 to 50.8 cm (= 12 to 20 inches)

These thresholds are applied differently per vegetation type. For instance,
spruce-fir has different (lower) DBH thresholds than maple-beech-birch.

**Their Eastern Region OG estimate**: 123,000 ha = 304,000 acres on NFS
lands only (~3% of NFS-East forested area).

## Key common elements across all 9 regions (Table 2)

Pelz documents which criteria appear in which NFS region's OG definition:

| Element | # of regions using |
|---|:---:|
| Old + large tree density | 8 of 9 |
| Tree or stand age | 7 of 9 |
| Large tree density (separate from above) | 8 of 9 |
| Dead tree density of certain size | 4 of 9 |
| Stand basal area | 1 of 9 (Northern only) |
| Down wood cover | 1 of 9 (Pacific Northwest under NWFP) |
| Diameter diversity | 1 of 9 (Pacific Northwest under NWFP) |

The dominant signals are **(a) old/large tree density** and **(b) stand age**.
Total stand basal area (one of v5.1's six dimensions) is used in only ONE
region's official OG definition (Northern, R1).

## Comparison to v5.1

| Criterion | v5.1 (current) | Pelz Eastern Region (official) |
|---|---|---|
| Stand age | >= 80 yr (1pt), >= 120 (2pt) | **100-160 yr by veg type** |
| Large tree DBH threshold | >= 20 in | **12-20 in by veg type** |
| Large tree metric | BA in trees DBH>=20" | **count of trees per acre** |
| Total BA | >= 100/150 ft^2/ac | not used (R1 only nationally) |
| Sd_dia | >= 5/8 in | not used (PNW under NWFP only) |
| Snag TPA | data-driven percentile | not used (4 of 9 regions only) |
| Canopy height (Potapov) | >= 18/25 m | not used directly |
| Forest type specificity | type-agnostic | **type-specific** |

## Five recommendations for v5.1

### 1. Refine the OG-class specifically

The v5.1 OG class is the weakest part of the classifier (kappa ~0 vs ORNL
OG; sensitivity to thresholds high). Pelz's Eastern Region OG criteria are
the official USFS definition. Apply them as a parallel "v5.1-Pelz" check:

```r
# v5.1-Pelz Eastern OG flag (per FIA condition)
v51_pelz_og <- with(plot_data, 
  STDAGE >= 100 &                                  # min age
  STDAGE <= 200 &                                  # exclude impossibly old
  trees_per_acre_DBH_ge_12in >= 5 &                # min large-tree density
  trees_per_acre_DBH_ge_12in <= 20                 # not over-stocked old grass
)
```

Compare v51_class == "OG" to v51_pelz_og — agreement = stronger evidence
of OG; disagreement = a candidate "near-OG" or "false-positive" plot.

### 2. Add tree-count metric to score_ba_large

Currently `score_ba_large` uses basal area in trees DBH >= 20". Pelz's
official OG definitions use **count of trees per acre** with DBH >= 12-20".
Add a parallel score:

```r
score_large_tree_count <- case_when(
  trees_per_acre_DBH_ge_12in >= 10 ~ 2L,    # well-stocked with large trees
  trees_per_acre_DBH_ge_12in >= 5  ~ 1L,    # some large trees
  TRUE ~ 0L
)
```

This matches Pelz Eastern Region thresholds (5-20 trees/ac of DBH >= 12in).

### 3. Forest-type-specific thresholds

The current v5.1 is type-agnostic — same thresholds for spruce-fir as for
maple-beech-birch. Pelz applies different thresholds per Tyrrell vegetation
type. Refinement: lookup table mapping FORTYPCD to type-specific OG
thresholds. For Northeast forests (using Tyrrell 1998 types):

| FIA forest type group | Min stand age | Min large tree density (per ac) |
|---|:---:|:---:|
| Spruce-fir (FORTYPCD 121-129) | 100 | 5 |
| Maple-beech-birch (801-809) | 130 | 8 |
| Aspen-birch (901-909) | 80 | 5 |
| Oak-pine (401-409) | 120 | 7 |
| White-red-jack pine (101-140) | 120 | 7 |

These come from Tyrrell et al. 1998 Table 1 (referenced in Pelz). Type-
specific thresholds likely tighten the OG identification but require the
type-mapping look-up table.

### 4. Condition-level scoring

The current v5.1 uses dominant-condition per plot (slice_max on
CONDPROP_UNADJ). Pelz applies criteria at the FIA condition level
directly. For plots with multiple substantively different conditions
(e.g., a clearcut + adjacent mature stand), this matters. Refinement:
score each FIA condition separately, then aggregate to plot-level via
condition-area weighting.

### 5. Cross-validate against Pelz on USFS lands specifically

For Northeast FIA plots on USFS National Forest System lands (White
Mountain NF in NH, Green Mountain NF in VT, plus parts of Maine state
forests under USFS easement), we can:

1. Filter to OWNCD codes for USFS NFS (OWNCD 11)
2. Apply Pelz's Eastern Region OG criteria as documented
3. Compare to v5.1 OG / LS calls on the same plots
4. Get a kappa or AUC against this independent ground-truth-like reference

This does NOT need the Hagan raster. It uses Pelz's already-published
criteria.

## Phase 7 plan: Pelz cross-validation

Define `R/phase7_pelz_validation.r` that:

1. Reads PLOT, COND, TREE for ME/NH/VT/NY
2. Filters to NFS lands (OWNCD == 11)
3. Computes Pelz Eastern Region OG indicator per FIA condition using
   Tyrrell 1998 type-specific thresholds (Table 1 of Pelz)
4. Computes v5.1 class on the same conditions
5. Outputs:
   - 4x4 confusion matrix (v5.1 class x Pelz OG flag)
   - Cohen's kappa for OG agreement
   - Per-state Pelz-OG share for cross-check vs Pelz's R9 estimate
6. Reports ME/NH/VT/NY USFS-only OG area for direct comparison to Pelz's
   E-Region 123,000 ha

This gives us an INDEPENDENT validation pathway that doesn't depend on
Hagan's raster. The Eastern Region NFS lands in NE are limited (White
Mtn NF + Green Mtn NF, ~ 1.0 million acres total), but provide a clean
test bed for the OG criteria specifically.

## Methodological notes from Pelz worth carrying

1. **FIA plot footprint may be too small for OG**: Pelz acknowledges
   the 1/8 ha sample is small; OG patches may not be reliably detected.
   This is the same caveat we noted in v5.1's Limitations section.

2. **Estimate uncertainty is high for OG**: Pelz's national estimate
   (10M ha) is ~2x DellaSala 2022 and Barnett 2023 (4-5M ha). Different
   definitions lead to different estimates by factor of 2. Our v5.1
   uncertainty on OG specifically is in this same range.

3. **Stand age in FIA is approximate**: FIA STDAGE is derived from
   site-index trees + local interpretation. Not a direct measurement.
   Pelz acknowledges this is imperfect but useful.

4. **Different definitions are NOT directly comparable**: Comparing
   our v5.1 to Hagan, Bruening, and Pelz means comparing three different
   conceptual classifiers. None is "the truth"; each has different
   assumptions. The integrated NE LSOG report should explicitly note
   this when reporting cross-product comparisons.

## Summary

Pelz 2023 is the official USFS old-growth methodology paper. Three
specific refinements to v5.1:

1. Add a Pelz-Eastern-Region OG check as a parallel classifier (Phase 7)
2. Add tree-count metric (`score_large_tree_count`) alongside the
   existing BA-based score
3. Forest-type-specific thresholds for OG class (matters for spruce-fir
   vs hardwood differentiation)

Phase 7 (Pelz cross-validation) is independent of the Hagan raster and
should be the next refinement to undertake.
