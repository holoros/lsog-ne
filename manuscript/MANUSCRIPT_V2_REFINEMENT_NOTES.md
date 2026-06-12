# Northeast LSOG manuscript V2: refinement notes (12 June 2026)

This session refined the fuller manuscript beyond the first assembled draft, in response to three questions from Aaron: (1) does the analysis need refining; (2) was Landsat/time-since-disturbance integrated; (3) extend beyond Maine; plus the triad framing.

## What changed

### 1. A real Landsat time-since-disturbance continuity axis (A4)
The original four-axis funnel defined A4 continuity from FIA treatment/origin codes (TRTCD1, STDORGCD), which see only the most recent inventory cycle and undercount legacy and partial harvest. That proxy passed ~90% of conditions and was the weakest axis.

Replaced with a USFS LCMS (v2024-10) annual change layer, 1985-2023. For each FIA plot we take the year of most recent stand-replacing or harvest disturbance (LCMS causes: Tree Removal, Mechanical, Wildfire, Hurricane, Prescribed Fire, Other Loss). A4 passes only if no such disturbance is detected over the record. Built entirely on Cardinal by server-side cropping the remote LCMS COGs (vsicurl) to per-state AOIs at 100 m, no bulk download.

Effect (Maine): A4 pass 90% -> 29.5% at the plot level; true LSOG (all four axes) 6.5% -> ~3%. Continuity becomes co-limiting with live structure where it was previously negligible. Tree Removal (partial harvest) is the dominant LCMS cause in Maine, the exact signal binary Global Forest Watch and FIA codes both miss.

### 2. Extended to the full four-state region (NH, VT, NY)
The funnel and continuity axis are no longer Maine-only. Four-state true LSOG (all four axes, design-based): ME 3.1% [2.5, 3.7], NH 12.8% [10.7, 15.0], VT 15.2% [12.7, 17.6], NY 12.2% [11.1, 13.4]. The mechanism is explicit: forest disturbed since 1985 is ME 70.5%, NH 50.0%, VT 34.7%, NY 31.7%. Maine's low share is as much a continuity (active-management) result as a structural one.

### 3. Triad reframing + representation analysis
Reframed the discussion away from "Maine is deficient / the gap is widening" toward a regional triad (Seymour and Hunter 1999): Maine anchors the production tier; NH/VT and the Adirondacks carry more of the late-successional and reserve tiers. The conservation question is representation across forest types and ecoregions, not per-state parity.

Representation result (pooled four states, design-based): true LSOG is present in 8 of 9 forest-type groups but varies >30-fold. Largest absolute pools: northern hardwood (maple-beech-birch) 2.68 M ac at 11.6%, white-red-jack pine 0.72 M ac at 21.2%. Spruce-fir, the signature Acadian type, carries only 2.1%.

The ecoregion cut is now complete (phase34). FIA tables here carry no ecoregion field, so plots were spatially joined to EPA Level III ecoregions (downloaded to scratch; note Aaron's landis2/tools plot_to_ecoregion_*.csv crosswalks exist but only cover some states and use the LANDIS scheme, so the uniform EPA L3 join was used for all four states). True LSOG is present in all 9 ecoregion sections but concentrates in the Northeastern Highlands (2.99 M ac, 12.5%); the Acadian Plains and Hills, the core of Maine's industrial forest, has the lowest share of any major ecoregion (2.1%, 0.19 M ac over 8.9 M ac of forest). The triad is visible geographically: highlands = late-successional tier, Acadian lowlands = production tier. The phase34 ecoregion join is CPU-throttled on login nodes; run it via sbatch (R/sb34.sh) on a compute node.

## New analysis artifacts on Cardinal (output_phase31/)
- ME_LCMS_yod_heavy_100m.tif, ME_LCMS_tsd_heavy_100m.tif (Maine time-since-disturbance rasters)
- L1/L2/L3 (Maine funnel), R1-R4 (four-state funnel + continuity), R5/R6 (representation)
- Fig_funnel_4state.png; scripts R/phase31_tsd_funnel.R, R/phase31b_regional.R, R/phase33_representation.R, R/lcms_warp_all.sh, R/warp_states.sh

## LandTrendr follow-up (delivered, not yet run)
LSOG_LandTrendr_GEE.js is a ready-to-run Earth Engine LandTrendr script (annual Landsat NBR segmentation -> year-of-greatest-disturbance + magnitude + duration, export to Drive, EPSG:5070). It is the higher-fidelity replacement for the LCMS year-of-disturbance: run it in your GEE account, pull the export to Cardinal, and swap into phase31b A4 (pass where magnitude < threshold). Needs your Earth Engine auth, which cannot be done from here.

## Open items
- Co-authors still TBD.
- Citations flagged [VERIFY] as before; add RAP v2.0 protocol and Adirondack references.
- Section 3.8 still carries the older GFW continuity descriptive (since 2001); it is consistent but distinct from the A4 LCMS axis (since 1985). Consider harmonizing or cutting in a later pass.
- Figure 2 subtitle text slightly overflows the plot width; cosmetic, fix on final figure pass.
- Ecoregion representation cut pending a spatial overlay.
- The Maine-only quick run (phase31) reported true LSOG 2.0%; the authoritative value is the four-state run's 3.1% (cleaner out-of-AOI handling). The manuscript uses 3.1%.
