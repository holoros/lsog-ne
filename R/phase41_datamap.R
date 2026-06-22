# =============================================================================
# Phase 41: shapefiles for all validation plots + a study-area data map showing
# the key datasets used (FIA true-coordinate plots, MNAP/TNC ecological reserves
# incl. Big Reed, Baxter SFMA CFI) over Maine. Shapefiles kept in the restricted
# dir (they carry coordinates); the rendered map aggregates and is shareable.
# Output: shapefiles -> data/validation_restricted/shp/ ; figure -> output_phase41/
# =============================================================================
suppressPackageStartupMessages({ library(sf); library(data.table); library(ggplot2) })
RES<-"/users/PUOM0008/crsfaaron/LSOG/data/validation_restricted"
SHP<-file.path(RES,"shp"); dir.create(SHP,showWarnings=FALSE,recursive=TRUE)
OUT<-"/users/PUOM0008/crsfaaron/LSOG/output_phase41"; dir.create(OUT,showWarnings=FALSE,recursive=TRUE)
log<-function(...) cat(sprintf(...),"\n")

## ---- FIA true-coordinate plots (ME) ----
xy<-unique(fread(file.path(RES,"FIA.xy.csv"), colClasses=list(character="PLT_CN"))[
  STATE=="ME" & !is.na(TRUE.LAT), .(PLT_CN, lat=TRUE.LAT, lon=TRUE.LON)], by="PLT_CN")
fia<-st_as_sf(xy, coords=c("lon","lat"), crs=4269)
st_write(fia, file.path(SHP,"FIA_ME_true.shp"), append=FALSE, quiet=TRUE)
log("FIA ME true-coord plots: %d", nrow(fia))

## ---- MNAP/TNC ecological reserve plots ----
erm<-fread(file.path(RES,"ERM_ME_Plots.csv"), encoding="Latin-1")
erm<-erm[!is.na(as.numeric(Latitude))]
ermsf<-st_as_sf(erm[, .(EcoRName, lat=as.numeric(Latitude), lon=as.numeric(Longitude))],
                coords=c("lon","lat"), crs=4269)
st_write(ermsf, file.path(SHP,"MNAP_TNC_reserves.shp"), append=FALSE, quiet=TRUE)
log("MNAP/TNC reserve plots: %d in %d reserves", nrow(ermsf), length(unique(erm$EcoRName)))

## ---- Baxter SFMA CFI plots ----
bx<-fread(file.path(RES,"baxter_coords_clean.csv"))
bxsf<-st_as_sf(bx, coords=c("lon","lat"), crs=4269)
st_write(bxsf, file.path(SHP,"Baxter_SFMA.shp"), append=FALSE, quiet=TRUE)
log("Baxter SFMA plots: %d", nrow(bxsf))

## ---- Maine boundary ----
me_bound<-tryCatch({ st_as_sf(maps::map("state","maine", plot=FALSE, fill=TRUE)) },
  error=function(e) NULL)

## ---- map ----
br<-ermsf[ermsf$EcoRName=="Big Reed Forest Reserve",]
p<-ggplot()+
  { if(!is.null(me_bound)) geom_sf(data=me_bound, fill="grey97", color="grey55", linewidth=0.4) } +
  geom_sf(data=fia, color="grey70", size=0.25, alpha=0.5)+
  geom_sf(data=ermsf, color="#1B9E9E", size=0.9, alpha=0.85)+
  geom_sf(data=bxsf, color="#E18727", size=1.1, alpha=0.9, shape=17)+
  geom_sf(data=br, color="#B2182B", size=2.2, shape=18)+
  annotate("text", x=st_coordinates(st_centroid(br))[1]+0.15, y=st_coordinates(st_centroid(br))[1,2],
           label="Big Reed", hjust=0, size=3, color="#B2182B")+
  labs(title="Datasets used in the LSOG analysis",
       subtitle="FIA plots (grey), MNAP/TNC ecological reserves (teal), Baxter SFMA CFI (orange), Big Reed (red)")+
  theme_minimal(base_size=11)+
  theme(panel.grid=element_line(color="grey92"), plot.background=element_rect(fill="white",color=NA),
        axis.title=element_blank())
ggsave(file.path(OUT,"Fig_datamap.png"), p, width=7.0, height=7.6, dpi=300)
ggsave(file.path(OUT,"Fig_datamap_thumb.jpg"), p, width=7.0, height=7.6, dpi=70)
log("counts: FIA %d | reserve %d | Baxter %d | BigReed %d", nrow(fia), nrow(ermsf), nrow(bxsf), nrow(br))
cat("PHASE 41 DONE\n")
