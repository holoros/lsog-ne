# lsog-maine

FIA-based late-successional / old-growth (LSOG) classification for Maine and New England.

Built on the proxy scoring framework in `R/fia_lsog_analysis_v3.r`, with a planned
v4 line that will:

1. Add a 2020 to 2024 evaluation panel using the FIA refresh of Feb 2026.
2. Add an unorganized-territories subset so estimates can be compared like-for-like
   to Hagan et al. (2024) and Thompson et al. (2026).
3. Cross-validate against ORNL DAAC dataset 2498 ("Mature and Old-growth Forest
   Probability Maps for the Conterminous US") at the FIA plot level.
4. Recalibrate the 5-dimension score thresholds against the 348 FIA plots that
   fall inside Hagan's three LSOG classes in the unorganized townships.

## Layout

- `R/`            Analysis scripts. v3 is the current baseline.
- `data/fia/`     FIA tables (gitignored; pull from USDA FIA DataMart).
- `data/rasters/` Hagan LSOG raster, ORNL DAAC 2498 layers (gitignored).
- `output_v3/`    Phase 1 baseline figures and CSVs from the v3 March 2026 run.
- `output_legacy/`  Earlier Mar-2026 figures from the pre-v3 script.
- `docs/`         Methodology notes, comparison tables, source PDFs.
- `logs/`         Slurm logs (gitignored).

## v3 baseline result (Maine, 2014-2018 evaluation period)

- Transitioning LS: ~1,328,000 ac (7.9 percent of plots, statewide)
- Late-Successional: ~171,000 ac (1.0 percent)
- Old-Growth: ~22,000 ac (0.13 percent)
- All LSOG: ~1,521,000 ac (9.0 percent)

Compare with Hagan/Thompson (unorganized townships only, 9.5M ac):
- Transitioning LS: 17.2 percent
- LS + OG: 4.2 percent
- All LSOG: 21.4 percent

The scope difference (statewide vs. unorganized only) explains part of the gap;
the rest is sensitivity floor of the proxy and STDAGE NA frequency. Phase 2 and
Phase 3 of this project address both.

## References

- Hagan, J., B. Shamgochian, M. Taylor, and M. Reed. 2024. Using LiDAR to Map,
  Quantify, and Conserve Late-successional Forest in Maine. Our Climate Common.
  https://ourclimatecommon.org/lsog-project/
- Thompson, J., A. Daigneault, J. Plisinski, I. Moon, J. Norton, and J. Hagan.
  2026. Pathways for Protecting Maine's Remaining Old-Growth Forests.
  Harvard Forest / University of Maine.
- Burrill, E. et al. ORNL DAAC. Mature and Old-growth Forest Probability Maps
  for the Conterminous United States. doi:10.3334/ORNLDAAC/2498

## Running v3 on Cardinal

```bash
module load gdal/3.7.3 gcc/12.3.0 geos/3.12.0 proj/9.2.1 R/4.4.0
cd ~/LSOG
# Place ME_PLOT.csv, ME_COND.csv, ME_TREE.csv in data/fia/
# Edit data_root in R/fia_lsog_analysis_v3.r if needed
Rscript R/fia_lsog_analysis_v3.r
```
