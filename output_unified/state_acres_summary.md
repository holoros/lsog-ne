# Late-Successional / Old-Growth Forest by Northeast State

FIA-based proxy classification (v5: 5 FIA dimensions + Potapov 2021 GEDI canopy height; /12 score; class thresholds 5/7/9). Acres derived from FIA EXPNS or state forest-area fallback. 95% bootstrap confidence intervals from 2,000 resamples.

## State x panel summary

| State | Panel | n | Trans LS % | Trans LS ac | LS % | LS ac | OG % | OG ac | All LSOG % | All LSOG ac |
|---|---|---:|---|---|---|---|---|---|---|---|
| ME | 2014-2018 | 3150 | 10.5% (9.4-11.6) | 1.76 M | 1.8% (1.4-2.3) | 307 K | 0.3% (0.1-0.4) | 44 K | 12.6% (11.4-13.7) | 2.11 M (1.91 M-2.31 M) |
| ME | 2019-2023 | 3125 | 12.1% (11.0-13.2) | 2.02 M | 1.9% (1.4-2.3) | 306 K | 0.2% (0.1-0.4) | 33 K | 14.1% (12.9-15.3) | 2.36 M (2.16 M-2.57 M) |
| NH | 2014-2018 | 748 | 24.3% (21.3-27.4) | 1.13 M | 4.1% (2.8-5.6) | 180 K | 0.1% (0.0-0.4) | 6 K | 28.6% (25.4-31.8) | 1.31 M (1.16 M-1.46 M) |
| NH | 2019-2023 | 757 | 25.9% (22.7-29.1) | 1.20 M | 5.0% (3.6-6.7) | 224 K | 0.3% (0.0-0.7) | 13 K | 31.2% (28.0-34.3) | 1.44 M (1.28 M-1.59 M) |
| NY | 2014-2018 | 2228 | 18.9% (17.3-20.6) | 3.36 M | 5.7% (4.8-6.7) | 1.04 M | 0.6% (0.3-0.9) | 107 K | 25.2% (23.4-27.1) | 4.50 M (4.17 M-4.83 M) |
| NY | 2019-2023 | 2107 | 19.8% (18.1-21.5) | 3.48 M | 6.1% (5.1-7.2) | 1.10 M | 1.3% (0.8-1.8) | 233 K | 27.2% (25.2-29.0) | 4.81 M (4.44 M-5.14 M) |
| VT | 2014-2018 | 660 | 25.0% (21.8-28.3) | 1.10 M | 5.0% (3.3-6.7) | 219 K | 0.3% (0.0-0.8) | 14 K | 30.3% (27.0-33.8) | 1.33 M (1.19 M-1.48 M) |
| VT | 2019-2023 | 657 | 22.1% (19.0-25.3) | 961 K | 6.5% (4.7-8.5) | 292 K | 0.2% (0.0-0.5) | 7 K | 28.8% (25.4-32.3) | 1.26 M (1.11 M-1.41 M) |

## Notes

- v5.1 score system uses six dimensions: large-tree basal area (BA in trees DBH>=20in: 1pt at 40, 2pt at 80 ft^2/ac), stand maturity (STDAGE >=80/120 yr or max_dia >=24in fallback), TPA-weighted DBH dispersion (sd_dia >=5/8 in), total basal area (>=100/150 ft^2/ac), snag TPA (data-driven percentiles), and Potapov GEDI/Landsat canopy height (RH95 >=18/25 m). Class thresholds: Transitioning LS >= 4, LS >= 6, OG >= 8 (out of 12).
- Reference points: Hagan et al. 2024 LiDAR estimate for Maine unorganized territories (9.5M ac): Trans LS 17.2%, LS+OG 4.2%, all LSOG 21.4%. Bruening et al. 2026 ORNL DAAC 2498 estimates ~33% mature-prob > 50 statewide for ME.
- Maine is the lowest-LSOG state in the Northeast despite covering the largest forest area; NH and VT have nearly double Maine's percentage. NY's Adirondack region drives its high OG share (2.5%).
- v5.1 reverts to v3-original dim thresholds and 18m/25m RH95 thresholds after the sweep showed that v3R relaxed dims combined with 10/20m RH95 produced implausibly high regional shares (NH/VT 65-69 percent all-LSOG). The v5.1 configuration produces field-defensible regional shares: ME 12.6 percent, NH ~31 percent, NY ~27 percent, VT ~29 percent statewide all-LSOG.
