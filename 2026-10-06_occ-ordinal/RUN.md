# 2026-10-06 OCC ordinal LSOG rebuild (Maine v4, New Brunswick v4)

Scripts for the four-class ordinal LSOG model trained on pooled FIA plots and the Our Climate Common (OCC, J. Hagan) field points, the 10 m rebuild with Meta CHM v2 structure, the SILC comparison, the Fay-Herriot refinement, and the New Brunswick update. No data, coordinates, embeddings or licensed plot rows are in this folder. Inputs live on OSC Cardinal under the restricted project tree.

## Order of operations (Cardinal, python3 with gdal/3.7.3; R/4.5.2 for s11b)

1. `s1_extract_occ.py` extracts AlphaEarth 2024 embeddings at OCC points (tiles are south up; bounds are sorted) and samples the existing maps.
2. `s2_fit_compare.py`, `s2b_fia_only.py` fit the pooled and FIA only Frank-Hall ordinal forests (Not < Trans < LS < OG) with StratifiedGroupKFold (FIA spatial blocks, OCC 2 km sites) and score every map at OCC points with site bootstrap AUCs.
3. `s3_predict_ordinal*.py`, `s4*_mosaic*` produce the 6 October study and state surfaces (superseded by v4, kept for provenance).
4. `s5_structure_test_pltcn.py`, `s6_rebuild_hardneg.py` test whether structure separates OG from LS and whether aspen, balsam poplar, introduced larch and planted stands as hard negatives cut false positives. FIA joins are keyed on PLT_CN, never row position.
5. `s7a10_chm10.sh` (Maine) and `s7a10_chm10_nb.sh` (New Brunswick) summarize Meta CHM v2 (1.19 m) to 10 m mean, max and rms with `-srcnodata 255 -ovr NONE`; 0 m is a real height.
6. `s9_fit_v4.py` fits v3 (AE + CHM + time since disturbance), v4 (adds composition) and v5, plus the softwood share regressor; the simpler model is kept unless the richer one gains 0.01 OCC Type 2 AUC.
7. `s3_predict_v4.py` predicts statewide at 10 m; `s4d_mosaic_recal_v4.py` mosaics, runs the location, range and area gates and averages to 30 m and 100 m. Its prior shift used the unweighted training prevalence and is superseded by `s4e_areacal_me.py` (7 October), which solves a logit intercept per layer so the forest area mean equals the FIA rate. Agreement with the FIA rate is then true by construction and is not a validation.
8. `s9b_grouping_sensitivity.py` repeats the field point AUCs with OCC grouped at 10 km and by project and gives a cross-validated screening cut; `s15_memorisation_test.py` tests whether the 10, 30 and 100 m surfaces carry a spike at training points (aggregates only).
9. `s11c_fh_crossfit_v4c.py`, `s11d_fh_fit_v4c.R` refit the H3 block Fay-Herriot models with the area calibrated surface and the selected model form as the auxiliary, with a paired block bootstrap of the leave-one-block-out error (they supersede `s11a` and `s11b`, which used the wrong model form).
10. New Brunswick (`s7a10_chm10_nb.sh`, `s12` to `s14b`) and the Seven Islands comparison (`s10`, `s10b`) are held back from this repository until the data providers approve release of scripts that name their holdings.

## Figures (firebreather, R with terra)

`f1` to `f6` draw the multimap comparison, gates and maps, FIA only versus pooled, the v1 recalibration and the v4 state figures from surfaces and aggregates only.

## Rules

FIA true coordinates, per plot embeddings, OCC point locations and licensed MagPlot rows stay on Cardinal. Only gated surfaces and aggregate tables leave.
