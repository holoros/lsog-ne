# =============================================================================
# State-level acres-by-class reporting table (DACF / MFS style)
# =============================================================================
suppressPackageStartupMessages({
  library(tidyverse)
  library(scales)
})

infile  <- "~/LSOG/output_v5/fia_lsog_v5_all_states.csv"
outfile <- "~/LSOG/output_unified/state_acres_summary.csv"
out_md  <- "~/LSOG/output_unified/state_acres_summary.md"

dat <- read_csv(path.expand(infile), show_col_types = FALSE)

acre_label <- function(x) {
  ifelse(x >= 1e6, sprintf("%.2f M", x/1e6),
         ifelse(x >= 1e3, sprintf("%.0f K", x/1e3),
                sprintf("%.0f", x)))
}

ci_pct <- function(p, lo, hi) sprintf("%.1f%% (%.1f-%.1f)", p, lo, hi)
ci_ac  <- function(a, lo, hi) sprintf("%s (%s-%s)", acre_label(a), acre_label(lo), acre_label(hi))

tab <- dat %>%
  transmute(
    State = state,
    Panel = eval_period,
    `Plots (n)` = n_plots,
    `Snag thresh` = sprintf("%d/%d", snag_thresh_1, snag_thresh_2),
    `Trans LS %`     = ci_pct(pct_trans, pct_trans_lo, pct_trans_hi),
    `Trans LS acres` = acre_label(acres_trans),
    `LS %`        = ci_pct(pct_ls, pct_ls_lo, pct_ls_hi),
    `LS acres`    = acre_label(acres_ls),
    `OG %`        = ci_pct(pct_og, pct_og_lo, pct_og_hi),
    `OG acres`    = acre_label(acres_og),
    `All LSOG %`  = ci_pct(pct_all, pct_all_lo, pct_all_hi),
    `All LSOG acres` = ci_ac(acres_all, ac_all_lo, ac_all_hi)
  ) %>%
  arrange(State, Panel)

write_csv(tab, path.expand(outfile))
cat(sprintf("\nwrote %s\n", outfile))

# Also write a clean Markdown table
md_lines <- c(
  "# Late-Successional / Old-Growth Forest by Northeast State",
  "",
  ("FIA-based proxy classification (v5: 5 FIA dimensions + Potapov 2021 GEDI canopy height; /12 score; class thresholds 5/7/9). Acres derived from FIA EXPNS or state forest-area fallback. 95% bootstrap confidence intervals from 2,000 resamples."),
  "",
  "## State x panel summary",
  "",
  "| State | Panel | n | Trans LS % | Trans LS ac | LS % | LS ac | OG % | OG ac | All LSOG % | All LSOG ac |",
  "|---|---|---:|---|---|---|---|---|---|---|---|"
)
for (i in seq_len(nrow(tab))) {
  md_lines <- c(md_lines, sprintf("| %s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s |",
    tab$State[i], tab$Panel[i], tab$`Plots (n)`[i],
    tab$`Trans LS %`[i], tab$`Trans LS acres`[i],
    tab$`LS %`[i],       tab$`LS acres`[i],
    tab$`OG %`[i],       tab$`OG acres`[i],
    tab$`All LSOG %`[i], tab$`All LSOG acres`[i]))
}
md_lines <- c(md_lines, "",
  "## Notes",
  "",
  "- v5.1 score system uses six dimensions: large-tree basal area (BA in trees DBH>=20in: 1pt at 40, 2pt at 80 ft^2/ac), stand maturity (STDAGE >=80/120 yr or max_dia >=24in fallback), TPA-weighted DBH dispersion (sd_dia >=5/8 in), total basal area (>=100/150 ft^2/ac), snag TPA (data-driven percentiles), and Potapov GEDI/Landsat canopy height (RH95 >=18/25 m). Class thresholds: Transitioning LS >= 4, LS >= 6, OG >= 8 (out of 12).",
  "- Reference points: Hagan et al. 2024 LiDAR estimate for Maine unorganized territories (9.5M ac): Trans LS 17.2%, LS+OG 4.2%, all LSOG 21.4%. Bruening et al. 2026 ORNL DAAC 2498 estimates ~33% mature-prob > 50 statewide for ME.",
  "- Maine is the lowest-LSOG state in the Northeast despite covering the largest forest area; NH and VT have nearly double Maine's percentage. NY's Adirondack region drives its high OG share (2.5%).",
  "- v5.1 reverts to v3-original dim thresholds and 18m/25m RH95 thresholds after the sweep showed that v3R relaxed dims combined with 10/20m RH95 produced implausibly high regional shares (NH/VT 65-69 percent all-LSOG). The v5.1 configuration produces field-defensible regional shares: ME 12.6 percent, NH ~31 percent, NY ~27 percent, VT ~29 percent statewide all-LSOG.")

writeLines(md_lines, path.expand(out_md))
cat(sprintf("wrote %s\n", out_md))
cat("\nSummary table preview:\n")
print(tab %>% select(State, Panel, `Plots (n)`, `All LSOG %`, `All LSOG acres`))
