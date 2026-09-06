# lsogscore

One tested implementation of every late-successional and old-growth (LSOG)
scoring instrument used in the Maine and New Brunswick analysis.

Before this package the same axes were implemented seven times across four R
scripts and three Python scripts, in two unit systems, with the thresholds
written as literals at the point of use. Two of those implementations differed
from each other in ways nobody had written down, and one instrument, CORE4, had
no builder at all: its axis columns were carried precomputed in a CSV and the
step that produced them was never committed to a file. This package replaces all
of that with one source of truth, and it is the first written definition of
CORE4.

Nothing here reads, writes, or requires a plot coordinate.

## Why this exists, in one paragraph

The question that keeps coming up when two groups map LSOG and disagree is
whether the disagreement is about the forest or about the definition. That
question is unanswerable while each definition lives inside its own script in
its own units. Here every threshold sits in one registry in the units its
source used, carries the file and line it came from, and is converted at exactly
one boundary. Run two instruments over the same plots and the difference you see
is the definition, because nothing else was allowed to vary.

## The seven instruments

| Instrument | Axes | Max | Cut | Canopy height | Behind which number |
|---|---|---|---|---|---|
| `score_me_v51` | 6 | 12 | 4 | one axis of six | Maine any-LSOG 14.66% |
| `score_nb_v51` | 5 | 10 | 4 | **none at all** | New Brunswick any-LSOG 31.47% |
| `score_me_sae_card` | 6 | 11 | 4 | one axis of six | Maine small-area labels |
| `score_nb_sae_card` | 6 | 11 | 4 | one axis of six | New Brunswick small-area labels |
| `score_core4` | 4 | 7 | 3 | **none** | Maine 4.56%, New Brunswick 9.37% |
| `score_core5` | 4 plus a penalty | 7 | 3 | **gate only, no points** | Maine 4.79%, New Brunswick 4.69% |
| `score_strict_four_axis` | 4, conjunctive | pass or fail | all four | **none** | Maine true LSOG 2.5% |

Of the seven, three carry no canopy height anywhere, one carries it only as the
gate on a subtractive penalty, and three carry it as one axis worth at most 2 of
11 or 12 points. Canopy height does one piece of real work in this analysis, as
the single fixed-effect predictor in the small-area model, and that is
prediction rather than definition. Worth saying plainly, since a comparison
against a canopy-height classifier tends to assume height is doing more.

## The four real jurisdiction differences

Most Maine and New Brunswick thresholds look different and are the same number
in different units. Four are genuinely different, and `lsog_thresholds()` flags
each of them in its `note` column.

1. **Maturity is a different construct.** Maine's published card scores FIA
   stand age at 80 and 120 yr. New Brunswick has no stand age at all and scores
   quadratic mean diameter at 20.3 and 30.5 cm. The two published cards do not
   measure the same thing. This is the axis CORE4 harmonizes, by moving both
   sides onto maximum live-tree diameter.
2. **Structural diversity is weighted on one side only.** Maine takes the
   TPA-weighted standard deviation of live diameter, New Brunswick takes the
   unweighted one. Real, and not previously tabulated in the appendix.
3. **A snag is a different object.** Maine requires a dead stem at or above 5.0
   in (12.7 cm). New Brunswick applies no diameter floor whatsoever. This is the
   mechanism behind the order-of-magnitude gap in the deadwood quantiles, and it
   alone moves New Brunswick from 31.47% to 9.75% and Maine from 14.66% to
   20.93% when the conventions are swapped.
4. **The large-tree floor differs by 0.8 cm.** Maine uses 20 in, which is 50.8
   cm. New Brunswick uses 50 cm. Small, real, and preserved rather than
   harmonized, since silently rounding it away is how a difference stops being
   inspectable.

A fifth difference is worth naming even though it is not a threshold. The
canopy-height column is called `canopy_ht_m` on both sides and holds Potapov
GLAD in Maine and ETH GlobalCanopyHeight in New Brunswick. One column name, two
products, which is exactly the kind of thing this package exists to surface.

## Quantile-set thresholds

Exactly one axis in any instrument is set from data rather than written as a
literal: the Maine published card's deadwood axis, at the 75th and 90th
percentiles of nonzero snag density within each state. Call
`me_v51_snag_quantiles()` with your data to recompute them. Called with no
arguments it returns the values from the run record and says so in an attribute,
because those two numbers appear in no code line anywhere in the project and
pretending otherwise would be the sort of thing this package is meant to stop.

## Use

```r
# From a tree list, either jurisdiction, into one comparable schema.
me <- plot_attributes_fia(dia_in = tr$DIA, tpa = tr$TPA_UNADJ,
                          statuscd = tr$STATUSCD, spcd = tr$SPCD)
nb <- plot_attributes_cli(dbh_cm = tr$dbh, stems_ha = tr$stem_ha,
                          status = tr$tree_status)

# Score one instrument.
score_core4(x, jurisdiction = rep("ME", nrow(x)))

# Or run them all and look at where they part company.
s <- score_all_instruments(x, jurisdiction, yodh = yodh, tolerance = tol_score_ba)
instrument_deltas(s)

# Where did this threshold come from?
threshold_provenance("nb_v51", "sc_dead")
```

## Tests

```r
Sys.setenv(LSOGSCORE_ORACLE_DIR = "/path/to/DATA/csvs")
testthat::test_local()
```

The suite has two halves. The unit tests run anywhere and check the conversions
against the constants the source code itself asserts, the axis arithmetic, the
NA convention, and the conjunctive logic. The oracle tests run against the
project's own precomputed tables and check that the package reproduces numbers
already in the manuscript: that the Maine six-axis totals reconcile as the sum
of their axes over 3,071 plots, that the canopy-height axis recomputes exactly
from the height column on those same plots, that CORE4 is exactly its four axes
summed over 13,708 rows, and that the New Brunswick label card reproduces end to
end from raw attributes. They skip when the tables are absent, so the package
tests clean on a machine that has only the package.

The New Brunswick oracle table carries coordinate columns and a licensed holder
field. The test selects columns by name and asserts that no coordinate came
along before it does anything else.

## Conventions reproduced deliberately

A missing measurement scores zero rather than propagating NA, matching the `ge()`
helper in `jobA_design_based_rfia.R`. That is a real modelling choice with a real
consequence, since a plot with no snag record scores zero on deadwood rather
than dropping out of the sample, and it is reproduced here rather than quietly
improved. Improving it is a decision for the analysis, not for the package.
