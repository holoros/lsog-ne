# Render a 4-panel Northeast regional 10 m LSOG probability figure (NH, VT, NY, NB).
suppressMessages(library(terra))
H <- path.expand("~/LSOG")
files <- c(
  "New Hampshire"      = file.path(H,"output_phase66/NH_v6_prob_10m.tif"),
  "Vermont"            = file.path(H,"output_region/VT/VT_prob_10m.tif"),
  "New York"           = file.path(H,"output_region/NY/NY_prob_10m.tif"),
  "New Brunswick (CA)" = file.path(H,"output_region/NB/NB_prob_10m.tif")
)
files <- files[file.exists(files)]
out  <- file.path(H,"regional_10m_4panel.png")
png(out, width=2600, height=2200, res=200)
par(mfrow=c(2,2), mar=c(1.5,1.5,2.6,1.0), oma=c(0,0,0,2))
pal <- hcl.colors(100, "viridis")
for(nm in names(files)){
  r <- rast(files[[nm]]); if(nlyr(r)>1) r <- r[[1]]
  fac <- max(1, round(max(dim(r)[1:2])/1100))
  ra <- aggregate(r, fac, fun="mean", na.rm=TRUE)
  plot(ra, col=pal, range=c(0,1), main=nm, axes=FALSE, legend=(nm==names(files)[2]),
       plg=list(title="P(LSOG)"), mar=c(1.5,1.5,2.6,1.0))
}
dev.off()
# small preview for review
prev <- file.path(H,"regional_10m_4panel_thumb.png")
png(prev, width=900, height=760, res=72)
par(mfrow=c(2,2), mar=c(1,1,2,1))
for(nm in names(files)){
  r <- rast(files[[nm]]); if(nlyr(r)>1) r <- r[[1]]
  fac <- max(1, round(max(dim(r)[1:2])/500))
  plot(aggregate(r,fac,fun="mean",na.rm=TRUE), col=pal, range=c(0,1), main=nm, axes=FALSE, legend=FALSE)
}
dev.off()
cat("WROTE", out, "and", prev, "\n")
# quick stats per state (mean probability and % above 0.5, for the results paragraph)
for(nm in names(files)){
  r <- rast(files[[nm]]); if(nlyr(r)>1) r <- r[[1]]
  v <- values(aggregate(r, max(1,round(max(dim(r)[1:2])/1500)), fun="mean", na.rm=TRUE)); v <- v[!is.na(v)]
  cat(sprintf("STAT %s: nvalid=%d meanP=%.3f pctGt0.5=%.1f\n", nm, length(v), mean(v), 100*mean(v>0.5)))
}
