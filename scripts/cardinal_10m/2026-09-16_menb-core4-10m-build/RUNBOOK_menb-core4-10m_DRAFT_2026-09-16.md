# ME/NB pooled CORE4 10 m build, runbook

September 16, 2026. This bundle carries out steps 6 and 7 of the September 4 plan and gets the 10 m map ready for Zenodo. It follows the decisions already made: one pooled cross-border surface, CORE4 at cut 3, RF and MOSVR compared under the house rule, and the M3 hybrid forest frame. The Hansen refresh is dropped for this build, so the v1.11 tile set used by the September 4 surface stays in place. The bundle was written in the Cowork cloud sandbox, which cannot reach Cardinal. Steps 2 and 3a/3 were smoke-tested on synthetic data there (the magnitude gate fired as designed on a deliberately wrong rate). Steps 1 and 4 have syntax checks only, since the sandbox has no R and no GDAL command-line tools. Every step stops with an error if a check fails, and nothing is renamed to its final name until every gate passes.

The CORE4 label definition was checked against the Drive copy of `samp_dat_core4_DATA_2026-09-02.csv`. The point-sum rule (`core4 >= 3`) reproduces the published sampling-table rates exactly: Maine 4.44% (published 4.44% [3.76, 5.23]) and New Brunswick 4.62% (published 4.61% [3.86, 5.37]). The axes-fired count with maximum-diameter maturity gives New Brunswick 5.43%, which falls outside the published interval. Step 1 repeats this test and stops unless exactly one definition matches.

## Step 0, stage inputs (about 20 minutes, yours)

Copy the bundle to Cardinal and create the input folder.

```bash
scp -r 2026-09-16_menb-core4-10m-build cardinal:~/LSOG/
ssh cardinal 'source ~/LSOG/2026-09-16_menb-core4-10m-build/config.sh && mkdir -p $BUILD/inputs && echo $BUILD'
```

Then stage the five inputs into `$BUILD/inputs/`.

1. `CLI_Grid.gdb.zip`, the one blocking item. Upload it with `scp`, then run `unzip` in `inputs/`. Step 1 checks the frame count of 18,334, the 58.26% coverage, and the 1.855 design effect.
2. `samp_dat_core4_DATA_2026-09-02.csv`, from `active-projects/ne-lsog-analysis/build/saeczi_v1/` on your laptop.
3. `frame_M3_hybrid_forest_landuse_30102x25127.tif`, downloaded on Cardinal with `wget -O inputs/frame_M3_hybrid_forest_landuse_30102x25127.tif "https://zenodo.org/records/22650397/files/frame_M3_hybrid_forest_landuse_30102x25127.tif?download=1"`.
4. `me_boundary_3979.geojson`, built from the Census cartographic boundary. Run `wget https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_state_500k.zip && unzip cb_2023_us_state_500k.zip && ogr2ogr -f GeoJSON -where "STUSPS='ME'" -t_srs EPSG:3979 inputs/me_boundary_3979.geojson cb_2023_us_state_500k.shp`.
5. `nb_public_plot_xy.csv`, with columns `plot_id_export, lon, lat` for New Brunswick public CLI plots only. Export it from the plot table the September 3 pooled AlphaEarth extraction used. The file name was not recoverable from Drive, so this is the one lookup for you. Step 0 refuses the file if any Maine row is present.

Confirm two settings in `config.sh`: `PY_ACTIVATE` (set to the `gdalz` conda env by default) and `MOSVR_SCRIPT`. Then run the preflight check.

```bash
bash ~/LSOG/2026-09-16_menb-core4-10m-build/s0_preflight.sh
```

## Stage A, labels, weights, fit (hours)

```bash
bash ~/LSOG/2026-09-16_menb-core4-10m-build/submit_chain.sh A
```

- **Step 1** writes the training table, with NB design weights and no coordinates.
- **Step 2** fits the random forest. It reports:
  - within-jurisdiction blocked CV AUC and leave-one-jurisdiction-out AUC
  - block-level calibration slope (predicted on observed) with a block bootstrap interval
  - the top-decile slope
  - a permutation null floor

  It stops if the AUC interval does not clear the null. It also stops if the mean out-of-fold probability sits outside half the lower or twice the upper published sample rate.
- **Step 2b** runs `mosvr_pareto.R` on the same table, then stops on purpose until you record the learner decision. Write one line to `$BUILD/logs/s2b_learner_decision.txt` starting with `RF` or `MOSVR`, giving both slopes and the RMSE cost. Step 3 predicts with the random forest only. If MOSVR wins, a 10 m SVR prediction is a separate compute decision.

## Stage B, 10 m prediction, mosaic, gates (days)

```bash
bash ~/LSOG/2026-09-16_menb-core4-10m-build/submit_chain.sh B
```

- **Step 3a** checks the frame coding and the forest area inside each boundary. The references are 7.41 Mha for Maine and 6.55 Mha for NB, times the EPSG:3979 overstatement, with a 3% tolerance.
- **Step 3** is a SLURM array, one AlphaEarth tile per task, with at most 12 running at once. It predicts only inside the forest frame, window by window, and writes three layers per tile:
  - probability x 10000
  - block-bootstrap SD x 10000
  - an extrapolation flag

  Resampled tiles are written as `.part` files and renamed only when complete, so a rerun resumes where it stopped.

  The runtime estimate is rough. With 500 final trees plus 20 × 100 bootstrap trees at 10 m, expect on the order of an hour per tile on 48 cores. Tile count and forest share set the total, and the chain was sized for about two days of wall time.
- **Step 4** builds per-jurisdiction EPSG:3979 mosaics and clips them to each boundary. It masks them to the forest frame, then runs six gates:
  - **G1 coverage:** 98% or more of frame forest predicted.
  - **G2 frame area:** within 3% of the published frame area.
  - **G3 value range.**
  - **G4 magnitude:** the model-based share against the published sample rate. It also reports whether the share sits inside the design-based CORE4 interval (Maine 4.56% [3.83, 5.30], NB 9.37% [7.71, 11.03]).
  - **G5 border seam:** on the forest frame, along the shared ME-NB border only, with the 0 to 500 m jump required to stay within the mean bootstrap SD.
  - **G6 file size.**

  Products stay as `.part` until every gate passes. After that they are renamed in `$FINAL` and a `SHA256SUMS.txt` file is written.

## Products

Six rasters, two for each jurisdiction and layer type. The names state the grid, the jurisdiction, and the conservative structural core label, which satisfies F10.

- `core4-structural-core-probability_10m_{ME,NB}_DATA_2026-09-16.tif`
- `core4-structural-core-bootstrap-sd_10m_{ME,NB}_DATA_2026-09-16.tif`
- `core4-structural-core-extrapolation-flag_10m_{ME,NB}_DATA_2026-09-16.tif`

Two further files sit beside them: `core4-border-seam-forest-frame_10m_DATA_2026-09-16.csv` and `core4-10m-build-summary_DATA_2026-09-16.json`.

## Deposit and sharing

The staged v1.4.0 deposit carries text fixes only, and its publication date is still set to September 9. Update that date and publish v1.4.0 as it stands. Then publish the 10 m layers as v1.5.0 through zenodo-deposit, using the reverse manifest gate. Folding them into v1.4.0 would invalidate that version's 100-file gate.

John gets the Maine layers first, with a README stating two points. The layers are a conservative structural core at CORE4 cut 3, not old growth under any other definition. They must not be summed to an area without the forest frame, or used to call an individual stand.

## Known limits carried into the product

- The New Brunswick half is trained on public CLI labels, which read 4.72 points below the licensed delivery on the same plots.
- The CORE5 tolerance penalty is not in this surface. Only the CORE4 labels are mapped.
- Hardwood omission, the question John raised, is not addressed by this build. It is what the Hagan hectare crosswalk tests.
