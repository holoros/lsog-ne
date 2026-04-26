# Reading ZSTD-compressed COGs on Cardinal

Cardinal's bundled GDAL (3.7.3, gcc/12.3.0) was built without ZSTD codec
support, so it cannot read the Bruening et al. 2026 ORNL probability TIFFs
directly. The work-around is a one-time re-encode using a conda-forge GDAL
that does ship with ZSTD support.

```bash
source /etc/profile.d/lmod.sh
module purge
module load miniconda3/24.1.2-py310
eval "$(conda shell.bash hook)"

# One-time setup: create a conda env with ZSTD-capable GDAL (~5 min)
# (already done; the env lives at ~/.conda/envs/gdalz)
conda create -y -n gdalz -c conda-forge gdal libgdal libgdal-core zstd

# Re-encode the probability file from ZSTD to LZW
conda activate gdalz
cd ~/LSOG/data/rasters/ornl_2498
gdal_translate \
  -of GTiff \
  -co COMPRESS=LZW -co PREDICTOR=2 -co TILED=YES -co BIGTIFF=YES \
  -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
  CONUS_mature_old_growth_probabilities_0100m.tif \
  CONUS_mature_old_growth_probabilities_0100m_lzw.tif
```

The LZW-encoded file is ~1.7 GB (vs 1.5 GB ZSTD) and takes about 80 seconds
on a Cardinal login node. The Phase 4 R script points at the _lzw variant.
The strata and proportions files are also ZSTD-compressed; re-encode them
the same way if you ever need them in R.
