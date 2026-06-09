# Multi-method LSOG mapping uncertainty for Maine's unorganized townships

## Authors
Aaron R. Weiskittel, University of Maine, Center for Research on Sustainable Forests.
ORCID 0000-0003-2534-4478. Contact: aaron.weiskittel@maine.edu

## Description
This dataset quantifies the uncertainty in mapping late-successional and old-growth (LSOG)
forest across the approximately 4.2 million hectares of Maine's unorganized townships. It
compares three to four independent, credible mapping methods on a common 100 m grid, tests
the "rapid loss" premise with an independent time series, and provides the derived raster
products and summary tables that support those conclusions. The central finding is that
credible methods disagree by roughly 2.8 times on how much LSOG exists and on the location of
about four of every five LSOG hectares, and that two independent stock measurements show LSOG
stable to increasing rather than rapidly disappearing.

## Associated analysis
Northeast LSOG Project, CRSF, University of Maine (https://github.com/holoros/lsog-ne).
Companion report "How Hard Is It to Map Late-Successional and Old-Growth Forest in Maine?"
included as a PDF in this deposit.

## Methods compared
- **M1 Hagan**: reproduction of Hagan et al. (2026) random forest on eight airborne-LiDAR
  canopy metrics, rebuilt from their public Zenodo deposit (10.5281/zenodo.19696494).
- **M2 v5.1-GEDI**: logistic model of the FIA field-structure LSOG class on Potapov (GEDI-
  calibrated) canopy height, fit on Northeast FIA plots.
- **M3 Potapov-direct**: canopy height >= 18 m.
- **M4 TreeMap**: FIA v5.1 structural class imputed to every pixel via USFS TreeMap 2016/2020/2022.

## File inventory
| File | Description | Format |
|------|-------------|--------|
| M1_hagan_class_100m.tif | Reproduced Hagan 4-class LSOG classification | GeoTIFF (INT1U) |
| M2_v51gedi_pLSOG_100m.tif | v5.1-GEDI probability of any-LSOG | GeoTIFF (Float) |
| M4_treemap_class_100m.tif | TreeMap-imputed v5.1 class (2022) | GeoTIFF (INT1U) |
| CONSENSUS_nmethods_100m.tif | Number of methods flagging LSOG per cell | GeoTIFF (INT1U) |
| T*_*.csv | Area, agreement, concordance, fragility, temporal, and validation tables | CSV |
| phase1x_*.r | Analysis scripts (reproduction, stress test, comparison, temporal) | R |
| LSOG_Mapping_Uncertainty_Report.pdf | Full methods and findings report | PDF |
| KEY_FINDINGS_graphical_abstract.png | One-page visual summary of all key findings | PNG |
| figures/*.png | Quick-look summary figures | PNG |

## Spatial information
Coordinate reference system: custom NAD83 UTM Zone 19N (matches Hagan et al. AOI grid;
embedded in each GeoTIFF). Spatial extent: Maine unorganized townships, approximately
4.19 million ha. Cell size: 100 m. NoData: outside the area of interest.

## Temporal coverage
LiDAR base 2015-2019 (Hagan); Potapov canopy height 2019; FIA panels 2014-2023; TreeMap
2016, 2020, 2022.

## Provenance and attribution
Derived from: Hagan et al. (2026), Ecosphere 17:e70670 and Zenodo 10.5281/zenodo.19696494;
Potapov et al. (2021) global forest canopy height; USFS TreeMap (Riley et al.); USDA Forest
Inventory and Analysis (FIA); Sass et al. (2020) forest ownership. Cite those sources when
reusing the corresponding inputs.

## Privacy note
No FIA plot coordinates are included. All products are derived rasters or aggregate summary
tables. FIA public coordinates are privacy-fuzzed at the source; per-plot files were excluded
from this deposit by design.

## License
CC-BY-4.0.

## Citation
Weiskittel, A.R. (2026). Multi-method LSOG mapping uncertainty for Maine's unorganized
townships. Zenodo. https://doi.org/10.5281/zenodo.20614497
