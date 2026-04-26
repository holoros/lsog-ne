# Phase 5b: classifier variant comparison

Date: 2026-04-26
Inputs: ME FIA panel 2019-2023 (n=3,125), v5 plot scores from Phase 5,
ORNL DAAC 2498 mature/OG probability bins.

## Five variants tested

| Variant | Definition |
|---|---|
| v4        | /10 score, thresholds 4/6/8 (current operational baseline) |
| v5        | /12 score, thresholds 5/7/9 (Phase 5 default) |
| v5b       | /12 score, thresholds 4/6/8 (loosened) |
| v5logit   | logistic P(ORNL mature > 50) > 0.50 |
| v5logit_y | logistic P(ORNL mature > 50) > Youden-optimal (= 0.352) |
| v5logit_og | logistic P(ORNL OG > 25) > Youden-optimal (= 0.023) |

## Share comparison

| Variant | any-LSOG | LS+OG | OG |
|---|---:|---:|---:|
| v4 default (4/6/8 /10) | 20.4 | 4.0 | 0.22 |
| v5 (5/7/9 /12) | 12.8 | 1.79 | 0.13 |
| **v5b (4/6/8 /12)** | **24.6** | **5.6** | 0.35 |
| v5logit P(mature)>0.5 | 12.7 | n/a | n/a |
| **v5logit_y P(mature)>0.35** | **41.6** | n/a | n/a |
| v5logit_og P(OG>25)>0.023 | n/a | n/a | 42.0 |
| ORNL mature > 50 (target) | 33.4 | n/a | n/a |
| ORNL OG > 50 (target) | n/a | n/a | 0.13 |

## Cohen's kappa (binary agreement with ORNL)

| Variant | kappa |
|---|---:|
| **v5logit_y any-LSOG vs ORNL mature** | **0.200** |
| v5logit any-LSOG vs ORNL mature | 0.198 |
| **v5b any-LSOG vs ORNL mature** | **0.127** |
| v5 any-LSOG vs ORNL mature | 0.098 |
| v4 any-LSOG vs ORNL mature | 0.091 |
| v5logit_og OG-flag vs ORNL OG > 50 | 0.002 |
| v5 OG vs ORNL OG > 50 | -0.001 |
| v5b OG vs ORNL OG > 50 | -0.002 |

## The two key findings

### 1. v5logit_y is the best any-LSOG classifier

Logistic-fit predicted probability of ORNL mature > 50, with the Youden-
optimal threshold (0.352), achieves kappa 0.20 against ORNL — twice the
agreement of v4 default. AUC = 0.644 on the mature target. The Youden-
optimal classifier flags 41.6 percent of plots, slightly more than ORNL's
33.4 percent target, but with TPR 0.57 and TNR 0.65 — modest but
meaningful discrimination. v5b (rule-based 4/6/8 in /12) is the best
non-logit classifier (kappa 0.127), a clear improvement on v4 (0.091).

### 2. Old-growth class agreement is essentially zero

**This is the sobering finding.** The Phase 5 v5 OG share (0.128 percent)
matched ORNL OG share (0.130 percent) exactly — same 4 plots out of
3,125. But the kappa is -0.001. Those 4 plots are NOT the same 4 plots.
v5 OG and ORNL OG flag different plots; their overlap is no better than
random. v5b OG (0.35 percent) is similarly uncorrelated.

The Youden-optimal logit-OG classifier flags 42 percent of plots as
OG-prone (using the OG > 25 percent target to get more positives) —
which is wildly overinclusive — and still achieves only kappa 0.002.
The OG class is too rare and too dissimilar to FIA-plot-aggregate
predictors to be reliably proxied at this scale.

This does not mean OG class is unimportant. It means:
- The 4-plot ORNL-OG sample is not a usable training target.
- The handful of v5 OG plots are flagged on different criteria than
  what ORNL's QDA flags.
- Hagan et al. 2024 LiDAR is the more credible OG-class reference;
  proxy validation against Hagan should be the next OG calibration test.

## Recommendation

For operational deployment, the choice is between:

- **v5b (rule-based, 4/6/8 in /12)** — interpretable thresholds, clean
  acres-and-percent reporting matching the v3/v4 framework. Kappa 0.127
  against ORNL mature. Slightly more inclusive than v5 default; less
  inclusive than the logit fit.

- **v5logit_y (data-driven binary)** — best agreement (kappa 0.200) but
  loses the LS / OG / TLS stratification. Useful as a cross-check on
  v5b assignments rather than a replacement.

Sensible workflow: report v5b as the primary classification, with the
v5logit predicted probability included as an auxiliary score per plot.
Plots where v5b says any-LSOG and v5logit_y agrees are the most
defensible "high confidence" assignments.

## Files

In `output_phase5/v5b/`:

- `phase5b_share_table.csv`       8-row variant share table
- `phase5b_kappa.csv`             8-row kappa table
- `phase5b_logit_mature_coefs.csv` 7-row mature target fit
- `phase5b_logit_og25_coefs.csv`   7-row OG > 25 target fit
- `phase5b_anylsog_bar.png`        bar chart of any-LSOG share

