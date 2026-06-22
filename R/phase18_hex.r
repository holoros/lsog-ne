# =============================================================================
# Phase 18: Hex-scale spatial summary of cross-map LSOG disagreement.
# Aggregates each method's any-LSOG to ~8 km hexagons over the AOI, maps the
# per-method LSOG fraction and the cross-method disagreement (max - min).
# Outputs: ~/LSOG/output_phase18/
# =============================================================================
suppressPackageStartupMessages({ library(terra); library(sf); library(data.table) })
L <- "/users/PUOM0008/crsfaaron/LSOG"
tmpl <- rast(file.path(L,"output_phase10/C_hagan_class_100m.tif"))
pL   <- rast(file.path(L,"output_phase12/M2_v51gedi_pLSOG_100m.tif"))
m4   <- rast(file.path(L,"output_phase13/M4_treemap_class_100m.tif"))
OUT  <- file.path(L,"output_phase18"); dir.create(file.path(OUT,"fig"),showWarnings=FALSE,recursive=TRUE)
THR2 <- 0.2553
# any-LSOG binary rasters (0/1), masked to AOI
m1 <- (tmpl %in% c(2,3,4));               m1 <- mask(m1, tmpl)
m2 <- (pL >= THR2);                        m2 <- mask(m2, tmpl)
m4b<- (m4 %in% c(2,3,4));                  m4b<- mask(m4b, tmpl)
# hex grid over AOI
ext_sf <- st_as_sf(as.polygons(ext(tmpl), crs=crs(tmpl)))
hex <- st_make_grid(ext_sf, cellsize=8000, square=FALSE)
hex <- st_sf(hexid=seq_along(hex), geometry=hex)
hv <- vect(hex)
# zonal mean of each method per hex (fraction of hex flagged LSOG)
ex <- function(r) terra::extract(r, hv, fun=mean, na.rm=TRUE)[,2]
hex$hagan <- ex(m1); hex$gedi <- ex(m2); hex$treemap <- ex(m4b)
hex$nvalid <- terra::extract(!is.na(tmpl), hv, fun=sum, na.rm=TRUE)[,2]
hex <- hex[!is.na(hex$hagan) & hex$nvalid>200, ]   # keep hexes substantially within AOI
hex$disagree <- pmax(hex$hagan,hex$gedi,hex$treemap,na.rm=TRUE) - pmin(hex$hagan,hex$gedi,hex$treemap,na.rm=TRUE)
st_write(hex, file.path(OUT,"hex_lsog_by_method.gpkg"), delete_dsn=TRUE, quiet=TRUE)
fwrite(st_drop_geometry(hex), file.path(OUT,"hex_lsog_by_method.csv"))
cat(sprintf("Hexes: %d | mean disagreement (max-min any-LSOG fraction): %.3f | median: %.3f\n",
            nrow(hex), mean(hex$disagree,na.rm=TRUE), median(hex$disagree,na.rm=TRUE)))

png(file.path(OUT,"fig","hex_panels.png"), 1700, 560, res=130)
par(mfrow=c(1,4), mar=c(1,1,2.5,2))
br <- seq(0,1,0.1)
pal <- hcl.colors(10,"YlGnBu", rev=TRUE)
for(v in c("hagan","gedi","treemap")) plot(hex[v], pal=pal, breaks=br, key.pos=NULL, axes=FALSE,
   main=c(hagan="Hagan (LiDAR)",gedi="v5.1-GEDI",treemap="TreeMap")[v], border=NA)
plot(hex["disagree"], pal=hcl.colors(10,"Reds",rev=TRUE), key.pos=4, axes=FALSE, main="Disagreement (max - min)", border=NA)
dev.off()
png(file.path(OUT,"fig","hex_panels_thumb.png"), 1000, 330, res=80)
par(mfrow=c(1,4), mar=c(1,1,2,1))
for(v in c("hagan","gedi","treemap")) plot(hex[v], pal=pal, breaks=br, key.pos=NULL, axes=FALSE, main=v, border=NA)
plot(hex["disagree"], pal=hcl.colors(10,"Reds",rev=TRUE), key.pos=NULL, axes=FALSE, main="disagree", border=NA)
dev.off()
cat("DONE Phase 18.\n")
