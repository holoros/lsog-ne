# =============================================================================
# Phase 5c: Potapov RH95 threshold sensitivity
# Grid-search the score_canopy_height breakpoints; logistic on continuous RH95
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
})

dat <- read_csv("~/LSOG/output_phase5/phase5_plot_classified_ME.csv",
                show_col_types = FALSE)
out_dir <- "~/LSOG/output_phase5/v5c"
if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

cat(sprintf("Plots: %d   with Potapov RH95: %d\n", nrow(dat),
            sum(!is.na(dat$potapov_rh95))))

# AUC helper (NA-safe)
auc_fn <- function(y, p) {
  ok <- !is.na(y) & !is.na(p); y <- as.integer(y[ok]); p <- p[ok]
  pos <- p[y == 1]; neg <- p[y == 0]
  if (length(pos) == 0 || length(neg) == 0) return(NA_real_)
  (sum(outer(pos, neg, ">")) + 0.5 * sum(outer(pos, neg, "=="))) /
    (length(pos) * length(neg))
}

# ---- Grid search over (1pt, 2pt) thresholds, fixed at v3R relaxed dims -------

cat("\n--- Grid search over RH95 breakpoints ---\n")

grid <- expand_grid(t_1pt = seq(10, 22, by = 2),
                    t_2pt = seq(20, 32, by = 2)) %>%
  filter(t_1pt < t_2pt)

shrunk <- map_dfr(seq_len(nrow(grid)), function(i) {
  t1 <- grid$t_1pt[i]; t2 <- grid$t_2pt[i]
  d <- dat %>% mutate(
    sch = case_when(potapov_rh95 >= t2 ~ 2L,
                    potapov_rh95 >= t1 ~ 1L,
                    !is.na(potapov_rh95) ~ 0L,
                    TRUE ~ 0L),
    v5_t = score_ba_large + score_maturity + score_structure +
           score_canopy + score_deadwood + sch,
    cls = case_when(v5_t >= 8 ~ "OG", v5_t >= 6 ~ "LS",
                    v5_t >= 4 ~ "Trans LS", TRUE ~ "Not LSOG")
  )

  tibble(
    t_1pt = t1, t_2pt = t2,
    pct_any_lsog = 100 * mean(d$cls != "Not LSOG"),
    pct_ls_og    = 100 * mean(d$cls %in% c("LS","OG")),
    pct_og       = 100 * mean(d$cls == "OG"),
    auc_mat      = {
      m <- glm(d$ornl_mat_50 ~ d$score_ba_large + d$score_maturity +
                                d$score_structure + d$score_canopy +
                                d$score_deadwood + d$sch,
                family = binomial,
                data = d %>% select(ornl_mat_50, score_ba_large, score_maturity,
                                     score_structure, score_canopy,
                                     score_deadwood, sch) %>%
                  filter(!is.na(ornl_mat_50)))
      auc_fn(d$ornl_mat_50, predict(m, d, type = "response"))
    }
  )
})

write_csv(shrunk, file.path(path.expand(out_dir), "phase5c_threshold_grid.csv"))

cat("\nTop 8 by AUC (mature target):\n")
print(shrunk %>% arrange(desc(auc_mat)) %>% head(8))

cat("\nDefault (18, 25) row:\n")
print(shrunk %>% filter(t_1pt == 18, t_2pt == 25))

# ---- Logistic on continuous RH95 (vs binned) ----------------------------------

cat("\n--- Logistic with continuous RH95 vs binned score ---\n")

dfit <- dat %>% filter(!is.na(ornl_mat_50), !is.na(potapov_rh95))

m_cont <- glm(ornl_mat_50 ~ score_ba_large + score_maturity + score_structure +
                            score_canopy + score_deadwood + potapov_rh95,
              data = dfit, family = binomial)
m_bin  <- glm(ornl_mat_50 ~ score_ba_large + score_maturity + score_structure +
                            score_canopy + score_deadwood + score_canopy_height,
              data = dfit, family = binomial)

cat(sprintf("\nAUC continuous RH95: %.3f\n",
            auc_fn(dfit$ornl_mat_50, predict(m_cont, dfit, type = "response"))))
cat(sprintf("AUC binned score_canopy_height: %.3f\n",
            auc_fn(dfit$ornl_mat_50, predict(m_bin, dfit, type = "response"))))

cont_coefs <- broom::tidy(m_cont) %>% mutate(odds_ratio = exp(estimate))
write_csv(cont_coefs, file.path(path.expand(out_dir), "phase5c_continuous_logit_coefs.csv"))
cat("\nContinuous-RH95 logit coefficients:\n"); print(cont_coefs)

cat("\nDone.\n")
