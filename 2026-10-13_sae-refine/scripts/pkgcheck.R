for (p in c("data.table","lme4","glmmTMB","sae","saeSim","SAEval","emdi","ggplot2","spdep","Matrix","patchwork","ragg","statmod")) cat(p, requireNamespace(p, quietly=TRUE), "\n")
