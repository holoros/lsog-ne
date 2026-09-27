# 10 m LSOG probability surfaces, build code (Cardinal)

Code only. No training tables, coordinates, rasters or models are committed; those stay on the
compute cluster and the public rasters are on Zenodo.

| Folder | Surface | Zenodo concept DOI |
|---|---|---|
| `2026-09-16_menb-core4-10m-build/` | pooled ME+NB CORE4 structural core, 16 September 2026, plus the Maine transitioning chain (`*_trans*`) | 10.5281/zenodo.22410163 (companion record v1.1.0) |
| `me-transitioning-10m_2026-09-23/` | Maine transitioning and above, v5.1 score >= 4, as archived with the product | 10.5281/zenodo.22967249 |
| `2026-09-25_nb-core4-licensed-10m-build/` | New Brunswick CORE4 on licensed MagPlot labels | 10.5281/zenodo.22967451 |
| `2026-09-27_nb-trans-licensed-10m-build/` | New Brunswick transitioning and above on licensed labels | pending deposit |
| `2026-09-27_sae-block-prep/` | block aggregates for the Fay-Herriot small area estimation fitted on firebreather (`../firebreather_sae/`) | n/a |

Chain per build: s1 labels and weights, s2 blocked random forest with gates, s3 tile prediction
(array), s4 mosaic, mask and eleven acceptance gates, s5 share bootstrap interval, stress test.
Run on OSC Cardinal with system python3 and scikit-learn 1.6.1 (gate G0).
