# Provenance and verification record, lsogscore 0.1.0, 6 September 2026

What this package was built from, what was checked against what, and what is
still open. Written so that the next person does not have to re-derive any of it.

## What it replaces

Seven implementations of the same axes, in two languages and two unit systems.

- `scripts/jobA_design_based_rfia.R` lines 109 to 160, the Maine published
  six-axis card
- `scripts/cardinal/nb_cli_lsog_fullscope.py` lines 179 to 187, the New
  Brunswick published five-axis card, with `scripts/cardinal_nb_magplot.py` and
  `10_JDI_Delivery_20260805/scripts/cli_lsog_score.py` as byte-identical
  siblings on the thresholds
- `scripts/jobB_four_axis_no_proxy.R` lines 142 to 197, the strict four-axis rule
- `data/mosvr_joint/step1_me_v51_score.R` lines 75 to 84, the Maine label card
- `nb_public_v51_pipeline_v2.py` lines 86 to 100, the New Brunswick label card
- `build/saeczi_v1/fit_saeczi_v6_core5_production.R` and
  `fit_saeczi_v7_core5_continuous_tolerance.R`, the two CORE5 forms

## CORE4 had no builder, and this is now its definition

An exhaustive content search of the workspace, of `/users/PUOM0008/crsfaaron`
and `/fs/scratch/PUOM0008/crsfaaron` on the Cardinal allocation, and of the
processing server found no script that writes the axis columns of
`samp_dat_core4_DATA_2026-09-02.csv`. Twenty-one hits, every one a consumer that
reads the file or a memo that discusses it. The nearest upstream scripts,
`build_samp_dat.R` and `build_samp_dat2.R`, both end with an explicit seven
column `keep` that excludes the axes, and their own input carries no axes
either. So the step that attached `s_ba`, `s_mat`, `s_str` and `s_can` and
summed them into `core4` was never committed to a file.

Two independent confirmations sit in the project's own record.
`verify_nb_positional_join_2026-09-03.R` opens by stating that the axis scores
were attached to that table **by position** rather than by key, and then builds
a within-tie-group permutation test to check the join after the fact, which is a
forensic reconstruction of an undocumented step. And the 5 September appendix
memo records that neither CORE4 fit rederives the axis.

`score_core4()` is therefore the first written definition of the instrument. Its
thresholds are those of the two label cards, which is the specification the
sweep and the fitted models used, and the oracle test confirms it reproduces the
precomputed column exactly.

## What was verified, and against what

Run on the processing server under R 4.5.1 on 6 September 2026. 98 assertions,
all passing, in three files.

Unit level, no data required. Every conversion round trips. Every conversion
reproduces the constants the source code itself asserts in its comments, which
is how `cardinal_nb_magplot.py` lines 36 and 37 document its own imperial
provenance. The axis maxima in the registry sum to the instrument maximum for
all four scored cards. The conjunctive rule fails a plot on any one failing axis.
The CORE5 penalty is subtractive, fires only on the interaction, never raises a
score, and never fires on a plot with no tolerance value.

Oracle level, against the project's own precomputed tables.

| Check | Result |
|---|---|
| Maine six-axis total equals the sum of its six axes | 3,071 of 3,071 |
| Maine canopy-height axis recomputed from `canopy_ht_m` | 3,071 of 3,071 exact |
| CORE4 equals the sum of its four axes | 13,708 of 13,708 |
| New Brunswick label card reproduced end to end from raw attributes, per axis | 10,681 of 10,681 on each of six axes |
| New Brunswick total score | 10,681 of 10,681 |
| New Brunswick any-LSOG rate, package against table | 36.5041% against 36.5041% |

The New Brunswick check is the strongest of the five, since it starts from
`ba_large`, `max_dia`, `sd_dia`, `ba_total` and `snag_ha` and rebuilds every axis
and the total, rather than checking an identity within a table.

## Two findings that came out of building it

**The FIA basal-area constant is rounded.** `0.005454` is a rounded
pi / (4 x 144) = 0.005454154, so the FIA convention reads about 28 parts per
million low against the metric convention on the same stand, always in the same
direction, so it does not cancel across a sample. Four orders of magnitude below
the spacing of any threshold here, so it changes no score. Recorded because a
reconciliation that chases a mismatch in the fifth decimal place will otherwise
find it the hard way. There is a test that states the limit.

**Two jurisdiction differences were not previously tabulated.** The structural
diversity axis is TPA-weighted in Maine and unweighted in New Brunswick, and the
appendix's threshold table carries a single row for it as though one convention
applied. And the snag definition itself differs, since Maine requires a dead stem
at or above 5.0 in while New Brunswick applies no diameter floor at all, which is
the mechanism behind the order-of-magnitude gap between the two jurisdictions'
snag quantiles rather than a separate fact about the forests.

## Restricted data

Nothing in this package reads, writes, or requires a plot coordinate. The
oracle tests read four tables, three of which carry no coordinate column of any
kind. The fourth, `nb_axes_v51_DATA_2026-09-02.csv`, carries `lon`, `lat`, and a
licensed holder field, so its test selects columns by name and asserts that no
coordinate came along before doing anything else.

One pre-existing exposure was found and is not this package's doing. That New
Brunswick table, and `lsog_ne_plot_table.csv` with its `LAT`, `LON` and `CN`
columns, have been resident on the processing server since the 2 and 3 September
runs. The processing server sits outside both the FIA agreement and the New
Brunswick CLI licence. That is worth a deliberate decision rather than being
inherited silently.

`me_train_true_v51_continuous.csv` was deliberately not used, even though it
carries the same six axes for the same Maine plots. It also carries 64
AlphaEarth embedding columns sampled at the true plot location, and a
64-dimensional embedding is close to spatially unique, so with the public
AlphaEarth product in hand a nearest-neighbour search reconstructs an approximate
true position. Treat it as coordinate-equivalent. `me_axes_v51_DATA_2026-09-02.csv`
carries what the validation needed without the embeddings.

## Open

Closed September 6, 2026. `man/` holds 24 Rd files compiled with roxygen2 8.1.0
under R 4.5.1, the regenerated NAMESPACE carries the same 33 exports as the
hand-written one, and `R CMD check --no-manual` returns Status OK. Three
constants remain without a source line in the registry, namely 0.229568,
2.54, and 2.4710538, which are unit definitions rather than project choices.

The New Brunswick label card's attribute construction is confirmed from sibling
scorers rather than from its own source, since `nb_public_v51_pipeline.py` v1
lives only on Cardinal at `/users/PUOM0008/crsfaaron/LSOG/` and was never
mirrored locally or into the deposit. The thresholds are confirmed from the v2
reference copy. The end-to-end oracle passing on all 10,681 rows is strong
evidence the construction matches, but it is evidence rather than a reading of
the line.

The A3 species set excludes balsam fir, *Abies balsamea* (L.) Mill. All ten
members of the set are long lived and balsam fir is not. Decided September 6,
2026, to keep it out and to state that rationale in the manuscript. A Cardinal
sensitivity run (SLURM 14267992, `scripts/jobB_four_axis_no_proxy_spcd12probe.R`)
found that adding SPCD 12 moves the Maine strict four-axis rate from 2.51%
[1.88, 3.13] to 2.87% [2.20, 3.55], 63 to 71 of 2,441 plots, inside the baseline
interval, while the A3 axis alone rises from 55.3% to 80.8% of forestland and
stops discriminating. `late_species()` encodes the set that produced the
reported figure and a test fails loudly if it changes.
