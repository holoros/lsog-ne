# Phase 8: TreeMap-based wall-to-wall LSOG estimation

Date: 2026-04-26
Status: Maine 2020 and 2022 done with caveat. NH/VT/NY pending.

## Approach

USFS TreeMap (Riley et al.) imputes an FIA plot ID (TM_ID -> PLT_CN)
to every 30m forested pixel in CONUS. Phase 8 leverages this to produce
wall-to-wall LSOG maps:

1. Read TreeMap raster (or state-clipped subset)
2. Read .vat.dbf for TM_ID -> PLT_CN mapping
3. Look up v5.1 class for each PLT_CN (via unified plot table)
4. Reclassify raster pixels by v5.1 class
5. Aggregate to state-level area shares

Pixel area: 30m x 30m = 0.222 acres each.

## Inputs on Cardinal

`/users/PUOM0008/crsfaaron/TREEMAP/`:
- TM2016/TreeMap2016.tif (3.99 GB CONUS)
- TM2020/TreeMap2020_CONUS.tif (4.84 GB CONUS) + vat.dbf (34 MB, 64,743 plots)
- TM2022/TreeMap2022_CONUS.tif (4.85 GB CONUS) + vat.dbf
- ME_TM_20.tif (745 MB, ME-clipped 2020)
- ME_TM_22.tif (745 MB, ME-clipped 2022)
- (no ME_TM_16; would need to crop CONUS)

## Maine 2020 and 2022 results

Pixel count by v5.1 class:

| Year | Class | n TM_IDs | Pixels (M) | Acres (M) | % of pixels |
|---|---|---:|---:|---:|---:|
| 2020 | Unknown | 2,170 | 37.7 | 8.39 | **50.2** |
| 2020 | TLS | 231 | 3.94 | 0.88 | 5.2 |
| 2020 | LS  | 25 | 0.25 | 0.055 | 0.33 |
| 2020 | OG  | 3 | 0.030 | 0.0067 | 0.040 |
| 2020 | Not LSOG | 1,083 | 33.2 | 7.39 | 44.2 |
| 2022 | Unknown | 2,196 | 37.6 | 8.36 | **50.1** |
| 2022 | TLS | 231 | 3.86 | 0.86 | 5.1 |
| 2022 | LS  | 26 | 0.24 | 0.054 | 0.32 |
| 2022 | OG  | 3 | 0.029 | 0.0065 | 0.039 |
| 2022 | Not LSOG | 1,114 | 33.3 | 7.41 | 44.4 |

Excluding "Unknown" pixels (PLT_CNs not in our 2014-2023 unified table):
- 2020: any-LSOG = 11.04 percent of classified pixels
- 2022: any-LSOG = 11.10 percent

For comparison: v5.1 plot-based ME 2019-2023 panel = 14.1% any-LSOG.
The plot-based estimate is ~3 points higher because it weights via
EXPNS over the Maine forested area; TreeMap is wall-to-wall over
all forested pixels including the older panels not in our table.

## The 50% Unknown gap

Half of TreeMap Maine pixels are imputed from PLT_CNs that are NOT in
our 2014-2023 unified table. Diagnostic ENTIRE_PLOT lookup shows these
Unknown PLT_CNs distribute by INVYR as:

| INVYR | N PLT_CNs |
|---:|---:|
| 2012 | 69 |
| 2010 | 62 |
| 2011 | 61 |
| 2013 | 52 |
| 2019 | 52 (from non-NE states, e.g., MA, CT) |
| 2017 | 42 |
| 2015 | 47 |
| (older panels back to 2000) | 200+ |

Most are Maine FIA plots from inventories before 2014 (the 2009-2013
panel and earlier). Some are non-NE state plots (MA, CT, RI, PA, NH, VT, NY)
imputed to Maine pixels because of similar forest type/structure.

## To close the gap

Two options for Phase 8 v2:

1. **Extend unified table back to 1999-2003 panels** by rerunning the
   v5.1 scoring with EVAL_BREAKS extended. v5.1 with Potapov RH95 doesn't
   work for 2010-2013 panels (Potapov is 2019), but v4 (no RH95) does.
   So could compute v4-class for older panels and treat as a fallback
   for Unknown pixels. Hybrid v5.1/v4 approach.

2. **Use ENTIRE_PLOT/COND/TREE for full-CONUS scoring**. ~/FIA/ENTIRE_*.csv
   files are 600+ MB each. For each unique PLT_CN in the TreeMap vat.dbf,
   compute v5.1 (or v5.1 minus Potapov for plots without RH95 extraction).
   More complete coverage but heavy I/O.

## Files

- `R/phase8_treemap_lsog.r`: producer
- `output_treemap/treemap_me_lsog.csv`: ME 2020 + 2022 class shares

## Next Phase 8 steps

- v2: close the Unknown gap via option 1 or 2 above
- Extend to NH/VT/NY (need to crop CONUS rasters or use ENTIRE coverage)
- TreeMap 2016 for ME (need CONUS crop)
- Compare TreeMap-derived state shares to v5.1 plot-based shares - the
  alignment quality is a proxy for how well TreeMap's imputation reflects
  the ground-truth plot characteristics
