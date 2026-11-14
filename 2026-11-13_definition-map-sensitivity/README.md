# Definition-to-map sensitivity of LSOG in Maine and New Brunswick (November 13 and 14, 2026)

Scripts and aggregate outputs behind the section "Definition and the map", Figure 5 and Table 3 of the ME/NB
manuscript and Appendix S1 Section 21. Six LSOG definitions per jurisdiction are scored on the same plots, mapped at
10 m with cross-predicted random forests, and compared.

- `scripts/d1` to `d2`: Maine labels and the design-based reproduction gate (R). `d6`: New Brunswick labels and gate.
- `scripts/d3`, `d4`, `d5` (Maine) and `d7`, `d8`, `d9` (New Brunswick): cross-predicted fits, tile prediction, aggregation.
- `scripts/d10`: fixed 0.5 threshold and five seeds. `d11`: position-recovery test. `d12`, `d13`: block tables and figure (R).
- `scripts/d14`: training-point ring test for release. `d15` (R), `d16`: design-based agreement, label containment,
  permuted-label null fit, 40 km blocks.
- `out/`: aggregate JSON and CSV only, and the figure.

Not included, by rule: FIA true plot coordinates, the licensed New Brunswick plot records, per-plot tables
(`RESTRICTED/`), and the 10 m rasters. The Maine 10 m layers did not clear the release test and are reported at
20 km blocks. Scripts name restricted input paths for provenance; those files stay on the server.
