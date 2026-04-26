suppressPackageStartupMessages({ library(tidyverse) })
dat <- read_csv("~/LSOG/output_phase5/phase5_plot_classified_ME.csv", show_col_types = FALSE)

variants <- list(
  list(name = "18/25m (legacy)", t1 = 18, t2 = 25),
  list(name = "14/22m (mid)",    t1 = 14, t2 = 22),
  list(name = "10/20m (new)",    t1 = 10, t2 = 20)
)

out <- map_dfr(variants, function(v) {
  d <- dat %>% mutate(
    sch = case_when(
      potapov_rh95 >= v$t2 ~ 2L,
      potapov_rh95 >= v$t1 ~ 1L,
      !is.na(potapov_rh95) ~ 0L,
      TRUE ~ 0L),
    v5_t = score_ba_large + score_maturity + score_structure +
           score_canopy + score_deadwood + sch,
    cls = case_when(v5_t >= 9 ~ "OG", v5_t >= 7 ~ "LS",
                    v5_t >= 5 ~ "Trans", TRUE ~ "Not"))
  tibble(variant = v$name,
         pct_any_lsog = 100*mean(d$cls != "Not"),
         pct_ls_og    = 100*mean(d$cls %in% c("LS","OG")),
         pct_og       = 100*mean(d$cls == "OG"))
})

print(out)
write_csv(out, "~/LSOG/output_unified/v5_threshold_variants_ME.csv")
