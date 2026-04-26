# =============================================================================
# Phase 5b: classifier variant comparison
#   v5         /12 score, thresholds 5/7/9   (current Phase 5 default)
#   v5b        /12 score, thresholds 4/6/8   (loosened TLS threshold)
#   v5logit    logistic P(ORNL mature > 50) > 0.5
#   v5logit_y  logistic P(ORNL mature > 50) > Youden-optimal threshold
#   v5logit_og logistic P(ORNL OG > 25) for OG-specific (small-n target)
# =============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(broom)
})

in_csv  <- "~/LSOG/output_phase5/phase5_plot_classified_ME.csv"
out_dir <- "~/LSOG/output_phase5/v5b"
if (!dir.exists(path.expand(out_dir))) dir.create(path.expand(out_dir), recursive = TRUE)

dat <- read_csv(path.expand(in_csv), show_col_types = FALSE)
cat(sprintf("Loaded %d plots\n", nrow(dat)))

# ---- v5b: 4/6/8 in /12 -------------------------------------------------------

dat <- dat %>% mutate(
  v5b_class = factor(case_when(
    v5_total >= 8 ~ "OG",
    v5_total >= 6 ~ "LS",
    v5_total >= 4 ~ "Transitioning LS",
    TRUE          ~ "Not LSOG"),
    levels = c("Not LSOG", "Transitioning LS", "LS", "OG"))
)

# ---- Logistic models ---------------------------------------------------------

set.seed(42)
n <- nrow(dat); ti <- sample.int(n, floor(0.8 * n))
fit <- function(target_col) {
  d <- dat %>% filter(!is.na(.data[[target_col]]))
  glm(reformulate(c("score_ba_large","score_maturity","score_structure",
                    "score_canopy","score_deadwood","score_canopy_height"),
                  response = target_col),
      data = d, family = binomial)
}

m_mat <- fit("ornl_mat_50")
dat$p_mat <- predict(m_mat, dat, type = "response")

# OG target uses larger threshold to get more positives. Use OG > 25 bin.
dat <- dat %>% mutate(ornl_og_25 = if_else(ornl_p_oldgrowth > 25, 1L, 0L))
m_og  <- fit("ornl_og_25")
dat$p_og <- predict(m_og, dat, type = "response")

# ---- Helper metrics ----------------------------------------------------------

auc_fn <- function(y, p) {
  ok <- !is.na(y) & !is.na(p)
  y <- as.integer(y[ok]); p <- p[ok]
  pos <- p[y == 1]; neg <- p[y == 0]
  if (length(pos) == 0 || length(neg) == 0) return(NA_real_)
  (sum(outer(pos, neg, ">")) + 0.5 * sum(outer(pos, neg, "=="))) /
    (length(pos) * length(neg))
}

# Youden-optimal threshold maximizes TPR + TNR - 1
youden <- function(y, p) {
  ok <- !is.na(y) & !is.na(p)
  y <- as.integer(y[ok]); p <- p[ok]
  if (length(y) == 0) return(list(threshold = 0.5, J = NA_real_, tpr = NA_real_, tnr = NA_real_))
  ord <- order(-p); y <- y[ord]; p <- p[ord]
  pos <- sum(y == 1); neg <- sum(y == 0)
  if (pos == 0 || neg == 0) return(list(threshold = 0.5, J = NA_real_, tpr = NA_real_, tnr = NA_real_))
  tp <- cumsum(y); fp <- seq_along(y) - tp
  tpr <- tp / pos; tnr <- (neg - fp) / neg
  J <- tpr + tnr - 1
  i <- which.max(J)
  list(threshold = p[i], J = J[i], tpr = tpr[i], tnr = tnr[i])
}

ya_mat <- youden(dat$ornl_mat_50, dat$p_mat)
ya_og  <- youden(dat$ornl_og_25,  dat$p_og)

cat(sprintf("\n  Youden threshold (mature target): %.3f  J=%.3f  TPR=%.2f  TNR=%.2f\n",
            ya_mat$threshold, ya_mat$J, ya_mat$tpr, ya_mat$tnr))
cat(sprintf("  Youden threshold (OG>25 target):   %.3f  J=%.3f  TPR=%.2f  TNR=%.2f\n",
            ya_og$threshold, ya_og$J, ya_og$tpr, ya_og$tnr))
cat(sprintf("  AUC mature: %.3f, AUC OG>25: %.3f\n",
            auc_fn(dat$ornl_mat_50, dat$p_mat), auc_fn(dat$ornl_og_25, dat$p_og)))

# Cohen's kappa for two binary classifications
kappa <- function(y_true, y_pred) {
  ct <- table(y_true, y_pred)
  if (any(dim(ct) < 2)) return(NA_real_)
  n <- sum(ct); po <- sum(diag(ct)) / n
  pe <- sum(rowSums(ct) * colSums(ct)) / n^2
  (po - pe) / (1 - pe)
}

# ---- Apply logit-based binary classifications -------------------------------

dat <- dat %>% mutate(
  v5logit_any   = if_else(!is.na(p_mat) & p_mat > 0.5,             "any-LSOG", "Not LSOG"),
  v5logit_y_any = if_else(!is.na(p_mat) & p_mat > ya_mat$threshold,"any-LSOG", "Not LSOG"),
  v5logit_og    = if_else(!is.na(p_og)  & p_og  > ya_og$threshold, "OG-flag", "Not")
)

# ---- Build expanded share table ---------------------------------------------

share_row <- function(label, pct_any, pct_lsog, pct_og) {
  tibble(variant = label, pct_any_lsog = pct_any,
         pct_ls_og = pct_lsog, pct_og = pct_og)
}

shares <- bind_rows(
  share_row("v4 default (4/6/8 /10)",
            100*mean(dat$v4_class != "Not LSOG"),
            100*mean(dat$v4_class %in% c("LS","OG")),
            100*mean(dat$v4_class == "OG")),
  share_row("v5 (5/7/9 /12)",
            100*mean(dat$v5_class != "Not LSOG"),
            100*mean(dat$v5_class %in% c("LS","OG")),
            100*mean(dat$v5_class == "OG")),
  share_row("v5b (4/6/8 /12)",
            100*mean(dat$v5b_class != "Not LSOG"),
            100*mean(dat$v5b_class %in% c("LS","OG")),
            100*mean(dat$v5b_class == "OG")),
  share_row("v5logit P(mature)>0.5",
            100*mean(dat$v5logit_any == "any-LSOG"),
            NA_real_, NA_real_),
  share_row(sprintf("v5logit_y P(mature)>%.2f", ya_mat$threshold),
            100*mean(dat$v5logit_y_any == "any-LSOG"),
            NA_real_, NA_real_),
  share_row("v5logit_og (Youden-optimal P(OG>25))",
            NA_real_, NA_real_,
            100*mean(dat$v5logit_og == "OG-flag")),
  share_row("ORNL mature > 50 (target)",
            100*mean(dat$ornl_mat_50, na.rm=TRUE), NA_real_, NA_real_),
  share_row("ORNL OG > 50 (target)", NA_real_, NA_real_,
            100*mean(dat$ornl_og_50, na.rm=TRUE))
)

write_csv(shares, file.path(path.expand(out_dir), "phase5b_share_table.csv"))
print(shares, n = Inf)

# ---- Cohen's kappa: each binary classification vs ORNL mature > 50 ----------

kapps <- tibble(
  variant = c("v4 any-LSOG vs ORNL mature",
              "v5 any-LSOG vs ORNL mature",
              "v5b any-LSOG vs ORNL mature",
              "v5logit any-LSOG vs ORNL mature",
              "v5logit_y any-LSOG vs ORNL mature",
              "v5 OG vs ORNL OG > 50",
              "v5b OG vs ORNL OG > 50",
              "v5logit_og OG-flag vs ORNL OG > 50"),
  kappa = c(
    kappa(dat$ornl_mat_50, as.integer(dat$v4_class != "Not LSOG")),
    kappa(dat$ornl_mat_50, as.integer(dat$v5_class != "Not LSOG")),
    kappa(dat$ornl_mat_50, as.integer(dat$v5b_class != "Not LSOG")),
    kappa(dat$ornl_mat_50, as.integer(dat$v5logit_any == "any-LSOG")),
    kappa(dat$ornl_mat_50, as.integer(dat$v5logit_y_any == "any-LSOG")),
    kappa(dat$ornl_og_50,  as.integer(dat$v5_class == "OG")),
    kappa(dat$ornl_og_50,  as.integer(dat$v5b_class == "OG")),
    kappa(dat$ornl_og_50,  as.integer(dat$v5logit_og == "OG-flag"))
  )
) %>% arrange(desc(kappa))

write_csv(kapps, file.path(path.expand(out_dir), "phase5b_kappa.csv"))
cat("\nCohen's kappa (binary agreement with ORNL):\n"); print(kapps, n = Inf)

# ---- Bar chart of any-LSOG share ---------------------------------------------

bar_data <- shares %>% filter(!is.na(pct_any_lsog)) %>%
  mutate(variant = fct_inorder(variant))

p <- ggplot(bar_data, aes(x = variant, y = pct_any_lsog, fill = variant)) +
  geom_col(alpha = 0.85, color = "white", width = 0.65) +
  geom_text(aes(label = sprintf("%.1f%%", pct_any_lsog)),
            vjust = -0.3, size = 4, fontface = "bold") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, NA), expand = expansion(mult = c(0, 0.12))) +
  scale_fill_brewer(type = "qual", palette = "Set2", guide = "none") +
  labs(
    title = "Phase 5b: any-LSOG share across classifier variants",
    subtitle = sprintf("ME 2019-2023 panel, n=%d. ORNL mature target = 33.4 percent.", nrow(dat)),
    x = NULL, y = "Percent of plots flagged any-LSOG / mature",
    caption = "v5 default thresholds 5/7/9 in /12; v5b loosens to 4/6/8 in /12; v5logit thresholds at 0.5 or Youden-optimal."
  ) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1, size = 9))

ggsave(file.path(path.expand(out_dir), "phase5b_anylsog_bar.png"),
       p, width = 12, height = 5.5, dpi = 200, bg = "white")

# ---- Save logit fits ---------------------------------------------------------

write_csv(broom::tidy(m_mat) %>% mutate(odds_ratio = exp(estimate)),
          file.path(path.expand(out_dir), "phase5b_logit_mature_coefs.csv"))
write_csv(broom::tidy(m_og) %>% mutate(odds_ratio = exp(estimate)),
          file.path(path.expand(out_dir), "phase5b_logit_og25_coefs.csv"))

cat("\nDone.\n")
