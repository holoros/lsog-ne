## H2 scoring, DESCRIPTIVE ONLY: H2 is not testable under the registered coverage rule (PREREG amendment A2).
## Inputs: per-site EarthDEM canopy metrics (s9, restricted), OCC veg and lidar metrics (no coordinates), WESM
## vintage (s6, restricted). Groups are the registered 10 km groups carried from the order (G01 to G18), not
## rebuilt from covered sites. Aggregates only leave the server. Seed 20261022.
suppressPackageStartupMessages(library(data.table))
set.seed(20261022)
H  <- path.expand("~/LSOG"); P <- Sys.getenv("CSDA_DIR", file.path(H, "2026-10-22_csda-pilot"))
sink_file <- file.path(P, "out/h2_score_SUMMARY.txt")
ch <- fread(file.path(P, "RESTRICTED/h2_site_chm_RESTRICTED.csv"))
m  <- fread(file.path(H, "2026-10-20_veg-dfa/out/occ466_metrics_nocoords.csv"))
v  <- fread(file.path(P, "RESTRICTED/occ_site_lidar_vintage_RESTRICTED.csv"))
out <- list(label = "DESCRIPTIVE: H2 not testable under the registered coverage rule (PREREG A2)")
## a site-strip pair without metrics (window outside the clip, under 625 valid cells, or no usable vertical offset)
## is excluded, and the strip selection rule below is applied to the site's remaining strips
out$drops <- c(pairs_in = nrow(ch), no_metrics = ch[is.na(cov15), .N], no_offset = ch[dz_source == "none", .N])
ch <- ch[!is.na(cov15) & dz_source != "none"]
if (!nrow(ch)) { writeLines(c(out$label, "no usable EarthDEM site metrics"), sink_file); quit(save = "no") }
ch[, yr := as.integer(substr(date, 1, 4))]
n0 <- uniqueN(ch$plotname)
ch <- merge(ch, v[, .(plotname, collect_year = as.integer(collect_year), wesm_project)], by = "plotname")
ch[, `:=`(inwin = yr >= 2015 & yr <= 2019, dyr = abs(yr - collect_year))]
## one strip per site: in-window first, then higher valid share, then the year closest to the site's lidar collection
s <- ch[order(plotname, -as.integer(inwin), -valid_share, dyr)][, .SD[1], by = plotname]
s <- merge(s, m[, .(plotname, cov15_lidar = D2_100X_COVFR_15, cvdbh = CV_LIVEDBH, campaign = project)], by = "plotname")
out$drops <- c(out$drops, sites_with_metrics = n0, sites_after_merges = nrow(s))
s[, og := as.integer(occ_class == "Old-growth")]
s[, grp := as.character(group)]                   # registered 10 km groups (no group mixes OG and LS)
s[, stratum := grp %in% s[og == 1, unique(grp)]]
auc <- function(y, sc) { r <- rank(sc); n1 <- sum(y); n0 <- sum(!y); if (!n1 || !n0) return(NA_real_); (sum(r[y == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0) }
bootg <- function(dd, f, B = 2000) {
  g1 <- unique(dd[stratum == TRUE, grp]); g0 <- unique(dd[stratum == FALSE, grp])
  z <- replicate(B, { gs <- c(sample(g1, length(g1), replace = TRUE), sample(g0, length(g0), replace = TRUE))
    f(rbindlist(lapply(seq_along(gs), function(k) dd[grp == gs[k]][, grp := as.character(k)]))) })
  c(lo = unname(quantile(z, .025, na.rm = TRUE)), hi = unname(quantile(z, .975, na.rm = TRUE)), na_draws = sum(is.na(z))) }
r_fun <- function(dd) suppressWarnings(cor(dd$cov15, dd$cov15_lidar, use = "complete.obs"))
a_fun <- function(dd) auc(dd$og, -dd$cov15)        # OG expected to have LOWER cover above 15 m
## H2(c): AUC within each OCC lidar acquisition, pooled with weights n_OG * n_LS (the weighting stated in A2)
sa <- function(dd) { q <- dd[, .(a = auc(og, -cov15), w = sum(og) * sum(!og)), by = wesm_project][!is.na(a) & w > 0]
  if (!nrow(q)) NA_real_ else sum(q$a * q$w) / sum(q$w) }
## within the EarthDEM strip (the nuisance specific to this score)
ss <- function(dd) { q <- dd[, .(a = auc(og, -cov15), w = sum(og) * sum(!og)), by = item_id][!is.na(a) & w > 0]
  if (!nrow(q)) NA_real_ else sum(q$a * q$w) / sum(q$w) }
br <- s[og == 1, .N, by = grp][which.max(N), grp]  # largest covered OG group; must be G01, Big Reed with Grant Mountain
out$big_reed_group_check <- br   # expected "G01"
variants <- list(all = s, without_big_reed = s[grp != br], campaign_2023 = s[campaign == "LSOG2023"], in_window_only = s[inwin == TRUE])
out$n <- s[, .(sites = .N, in_window = sum(inwin), groups = uniqueN(grp)), by = occ_class]
out$registration <- s[, .(median_p05_h = median(p05_h), share_p05_below_minus2 = mean(p05_h < -2), share_strip_offset = mean(dz_source == "strip"))]
## sensitivity of the class contrast to the vertical offset: per-clip dz against strip-level dz
out$offset_sensitivity <- s[, .(median_cov15_clipdz = median(cov15), median_cov15_stripdz = median(cov15_stripdz)), by = occ_class]
out$valid_share_by_class <- s[, .(median_valid_share = median(valid_share)), by = occ_class]
out$table <- rbindlist(lapply(names(variants), function(nm) { d <- variants[[nm]]
  if (nrow(d) < 5) return(data.table(variant = nm, n_OG = sum(d$og), n_LS = sum(!d$og)))
  ra <- if (d[, .N] > 3) bootg(d, r_fun) else c(lo = NA, hi = NA, na_draws = NA)
  ab <- if (length(unique(d$og)) == 2) bootg(d, a_fun) else c(lo = NA, hi = NA, na_draws = NA)
  ac <- if (length(unique(d$og)) == 2) bootg(d, sa) else c(lo = NA, hi = NA, na_draws = NA)
  data.table(variant = nm, n_OG = sum(d$og), n_LS = sum(!d$og), n_OG_groups = d[og == 1, uniqueN(grp)],
             H2c_projects = d[, .(k = sum(og) > 0 && sum(!og) > 0), by = wesm_project][, sum(k)],
             H2a_r = round(r_fun(d), 3), H2a_lo = round(ra["lo"], 3), H2a_hi = round(ra["hi"], 3),
             H2b_auc = round(a_fun(d), 3), H2b_lo = round(ab["lo"], 3), H2b_hi = round(ab["hi"], 3),
             H2c_auc = round(sa(d), 3), H2c_lo = round(ac["lo"], 3), H2c_hi = round(ac["hi"], 3),
             within_strip_auc = round(ss(d), 3),
             H2b_auc_stripdz = round(auc(d$og, -d$cov15_stripdz), 3)) }), fill = TRUE)
out$pass_rules_for_reference <- "H2a r >= 0.7; H2b and H2c interval lower bound > 0.5 (not applied: descriptive)"
out$cov15_vs_cvdbh_spearman <- round(s[, cor(cov15, cvdbh, method = "spearman", use = "complete.obs")], 3)
sink(sink_file); print(out); sink(); print(out)
