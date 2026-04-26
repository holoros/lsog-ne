# Phase 4: cross-validate v3 proxy against ORNL DAAC dataset 2498

## Idea

Bruening et al. (2026) recently published nationwide 1-ha probability maps of
mature and old-growth (MOG) forest in the conterminous US, derived from a
spatial Bayesian model that integrates FIA plot MOG labels with multi-sensor
remote sensing predictors. We use it as an independent cross-check on the v3
LSOG proxy: extract the 5 probability bands at every FIA plot location, then
cross-tabulate the ORNL old-growth probability bin against the v3
classification.

## Caveat: not fully independent

Bruening et al. trained their QDA models on FIA plot MOG labels (Pelz et al.
2023; Woodall et al. 2023). Both products use FIA, so this is a coherence
check, not blind validation. Disagreement modes are still informative:

- v3 LS or OG, ORNL low MOG probability: candidate proxy false positives
- v3 Not LSOG, ORNL high OG probability: plots with LiDAR-detectable canopy
  structure that the FIA proxy misses (likely sd_dia threshold floor)
- Both high: convergent evidence
- Both low: convergent evidence

## Inputs

- FIA tables (already on Cardinal at ~/fia_data/):
  - ME_PLOT.csv, ME_COND.csv, ME_TREE.csv (Apr 17, 2026 vintage)
  - extend to NH, NY, VT later by pulling from FIA DataMart
- ORNL DAAC 2498 raster:
  - CONUS_mature_old_growth_probabilities_0100m.tif (5 bands, 1-ha,
    EPSG:6933 EASE-Grid 2.0)
  - companion strata raster optional for stratum context

## Pipeline

```
   FIA PLOT.csv -- LAT, LON (fuzzed)
        |
        +--> sf_st_as_sf, st_transform to EPSG:6933
        |
   ORNL 2498 100m COG (5 bands)
        |
        +--> terra::extract -> 5 probability columns per plot
        |
   v3 process_state (from R/phase4_ornl2498_extract.r) -> per-plot LSOG class
        |
        +--> join on CN
        |
   per-state confusion CSV + heatmap, multi-state percent comparison
```

## Outputs (in output_phase4/)

- phase4_plot_classified_<ST>.csv: per-plot v3 score breakdown +
  ORNL probability bands
- phase4_confusion_<ST>.csv: count of plots in each (v3_class, ornl_OG_bin) cell
- phase4_confusion_<ST>.png: heatmap of the confusion matrix
- phase4_summary.csv: confusion matrix aggregated across states
- phase4_state_compare.csv: percent of plots in v3 LSOG classes alongside
  percent of plots with ORNL OG probability > 50

## Auth gotcha

ORNL DAAC requires NASA Earthdata Login. The current ~/.netrc on Cardinal has
machine + login but the password returns 401 from URS. Run

```
bash scripts/refresh_earthdata_netrc.sh
```

to re-enter your Earthdata password, then retry the download:

```
bash scripts/download_ornl2498.sh --test
```

The --test flag pulls only the small strata file (~50 MB) so you can confirm
auth without committing to the full 1.5 GB.

## Run

Once raster is in place (and FIA tables reachable as data/fia/):

Interactive:

```
source /etc/profile.d/lmod.sh && module purge && module load gcc/12.3.0 gdal/3.7.3 R/4.4.0
cd ~/LSOG
ln -sf ~/fia_data data/fia
Rscript --vanilla R/phase4_ornl2498_extract.r
```

Batch:

```
sbatch scripts/submit_phase4.sh
squeue -u crsfaaron
```

## Multi-state extension

Edit STATE_CODES at the top of R/phase4_ornl2498_extract.r:

```
STATE_CODES <- c("ME", "NH", "VT", "NY")
```

Make sure each state has <ST>_PLOT.csv, <ST>_COND.csv, <ST>_TREE.csv under
data/fia/. The ORNL raster covers the full CONUS, so no raster changes.

## True FIA coordinates (optional)

Public FIA lat/lon are fuzzed by up to ~1 km for forested plots, which is fine
for 1-ha pixels but introduces a small mismatch. If you have a DUA-released
true-coordinate CSV with columns CN, LAT, LON, set the OPTION_TRUE_LATLON_CSV
constant in the R script and the extraction will use those instead.
