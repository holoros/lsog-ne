## Does OG's lower lidar cover above 15 m survive within one lidar acquisition? (H2(c) feasibility check and the
## acquisition caution in the shared OCC notes, John's October 20 entry). Exploratory; aggregates only leave the server.
## Inputs: OCC veg and lidar metrics (no coordinates), WESM project per site (s6), OCC points (restricted, for 10 km groups).
suppressPackageStartupMessages({library(stats)})
set.seed(20261022)
H <- path.expand("~/LSOG")
m  <- read.csv(file.path(H, "2026-10-20_veg-dfa/out/occ466_metrics_nocoords.csv"))
v  <- read.csv(file.path(H, "2026-10-22_csda-pilot/RESTRICTED/occ_site_lidar_vintage_RESTRICTED.csv"))
p  <- read.csv(file.path(H, "data/validation_restricted/occ_2026-10-06/2026-10-07_occ-lsog-study-points-v2_DATA.csv"))
d  <- merge(merge(m, v[, c("plotname", "wesm_project", "collect_year", "n_workunits_all_years")], by = "plotname"),
            p[, c("plotname", "lat", "lon")], by = "plotname")
d  <- d[d$lsog_class %in% c("LS", "Old-growth") & !is.na(d$D2_100X_COVFR_15), ]
d$og <- as.integer(d$lsog_class == "Old-growth")
hav <- function(a, b) { R <- 6371; r <- pi / 180
  dl <- (b[, 1] - a[1]) * r; dp <- (b[, 2] - a[2]) * r
  2 * R * asin(sqrt(sin(dp / 2)^2 + cos(a[2] * r) * cos(b[, 2] * r) * sin(dl / 2)^2)) }
X <- cbind(d$lon, d$lat)   # hav() takes (lon, lat)
D <- sapply(seq_len(nrow(X)), function(i) hav(X[i, ], X))
d$grp <- cutree(hclust(as.dist(D), method = "single"), h = 10)
auc <- function(y, s) { r <- rank(s); n1 <- sum(y); n0 <- sum(!y); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
## score = lower cover is OG-like, so use -cover
strat_auc <- function(dd) {             # within-project AUC pooled with weights n_OG * n_LS
  s <- split(dd, dd$wesm_project); num <- 0; den <- 0
  for (q in s) { if (sum(q$og) > 0 && sum(!q$og) > 0) { w <- sum(q$og) * sum(!q$og); num <- num + w * auc(q$og, -q$D2_100X_COVFR_15); den <- den + w } }
  if (den == 0) NA else num / den }
boot <- function(dd, f, B = 2000) {
  g1 <- unique(dd$grp[dd$og == 1]); g0 <- unique(dd$grp[dd$og == 0])
  out <- replicate(B, { gs <- c(sample(g1, replace = TRUE), sample(g0, replace = TRUE))
    bb <- do.call(rbind, lapply(seq_along(gs), function(k) { z <- dd[dd$grp == gs[k], ]; z$grp <- k; z })); f(bb) })
  quantile(out, c(.025, .975), na.rm = TRUE) }
res <- list()
res$n <- c(OG = sum(d$og), LS = sum(!d$og), groups_OG = length(unique(d$grp[d$og == 1])), groups_LS = length(unique(d$grp[d$og == 0])))
res$sites_with_overlapping_workunits <- sum(d$n_workunits_all_years > 1)
res$pooled_auc <- auc(d$og, -d$D2_100X_COVFR_15); res$pooled_ci <- boot(d, function(z) auc(z$og, -z$D2_100X_COVFR_15))
res$within_project_auc <- strat_auc(d); res$within_project_ci <- boot(d, strat_auc)
res$by_project <- do.call(rbind, lapply(split(d, d$wesm_project), function(q) data.frame(project = q$wesm_project[1],
  n_OG = sum(q$og), n_LS = sum(!q$og), groups_OG = length(unique(q$grp[q$og == 1])),
  mean_cov15_OG = round(mean(q$D2_100X_COVFR_15[q$og == 1]), 3), mean_cov15_LS = round(mean(q$D2_100X_COVFR_15[q$og == 0]), 3),
  auc = if (sum(q$og) && sum(!q$og)) round(auc(q$og, -q$D2_100X_COVFR_15), 2) else NA)))
## Big Reed group split across two acquisitions: does OG cover differ by acquisition within the same tract?
br <- d[d$og == 1 & d$grp == names(which.max(table(d$grp[d$og == 1]))), ]
res$big_reed_by_project <- aggregate(D2_100X_COVFR_15 ~ wesm_project, br, function(x) c(n = length(x), mean = round(mean(x), 3), sd = round(sd(x), 3)))
## same check for CV of live dbh (ground metric, should not depend on lidar acquisition)
res$within_project_auc_cvdbh <- { dd <- d; dd$D2_100X_COVFR_15 <- -dd$CV_LIVEDBH; strat_auc(dd) }
## leave-one-acquisition-out stability (drop each project in turn)
res$drop_one_project <- sapply(unique(d$wesm_project), function(k) round(strat_auc(d[d$wesm_project != k, ]), 3))
sink(file.path(H, "2026-10-22_csda-pilot/out/lidar_acq_confound_SUMMARY.txt")); print(res); sink()
print(res)
## Stress test of analyst choices (added before any write-up)
st <- list()
st$drop_overlap_sites <- { dd <- d[d$n_workunits_all_years == 1, ]; c(n_OG = sum(dd$og), n_LS = sum(!dd$og), auc = round(strat_auc(dd), 3)) }
st$campaign_2023_only <- { dd <- d[d$project == "LSOG2023", ]; c(n_OG = sum(dd$og), n_LS = sum(!dd$og), auc = round(strat_auc(dd), 3)) }
st$without_big_reed <- { dd <- d[!(d$og == 1 & d$grp == names(which.max(table(d$grp[d$og == 1])))), ]; c(n_OG = sum(dd$og), auc = round(strat_auc(dd), 3)) }
st$within_project_ci_B5000 <- { set.seed(20261022); boot(d, strat_auc, 5000) }
st$cov6_within_project <- { dd <- d; dd$D2_100X_COVFR_15 <- dd$D2_100X_COVFR_6; round(strat_auc(dd), 3) }
sink(file.path(H, "2026-10-22_csda-pilot/out/lidar_acq_confound_STRESS.txt")); print(st); sink(); print(st)
## group partition check against the Python single-linkage groups (counts per class)
cat("groups OG/LS:", length(unique(d$grp[d$og == 1])), length(unique(d$grp[d$og == 0])), " sizes OG:", sort(table(d$grp[d$og == 1]), decreasing = TRUE), "\n")
cat("bootstrap NA draws dropped are counted in boot(); none expected when both classes are sampled\n")
