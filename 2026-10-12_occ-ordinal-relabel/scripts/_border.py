# ---- distance to the shared Maine and New Brunswick border (EPSG:3979), restricted table only
import geopandas as gpd
from shapely.ops import unary_union
from shapely.geometry import Point
_ME = gpd.read_file("/users/PUOM0008/crsfaaron/LSOG/2026-09-16_menb-core4-10m-build/inputs/me_boundary_3979.geojson").to_crs(3979)
_NB = gpd.read_file("/fs/scratch/PUOM0008/crsfaaron/canada_landcover/nb_boundary_3979.geojson").to_crs(3979)
BORDER = unary_union(_ME.geometry).boundary.intersection(unary_union(_NB.geometry).buffer(1000))
def border_km(lon, lat):
    x, y = Transformer.from_crs(4326, 3979, always_xy=True).transform(np.asarray(lon), np.asarray(lat))
    return np.array([BORDER.distance(Point(a, b)) / 1000 for a, b in zip(x, y)])
