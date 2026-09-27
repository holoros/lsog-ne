# At cells where the 10 m frame says forest but s3 wrote no prediction, what does the 30 m frame say?
# And does an independent rasterio nearest warp of a small window reproduce gdalwarp's 10 m frame?
import os, numpy as np, rasterio, subprocess, tempfile
from rasterio.enums import Resampling
from rasterio.warp import reproject
from rasterio.windows import from_bounds
E = os.environ; B = E["BUILD"]; k = 10
f30 = rasterio.open(E["FRAME_M3"])
for J in ("ME", "NB"):
    a = np.load(f"{B}/logs/diag_{J}_frame_dec.npy"); q = np.load(f"{B}/logs/diag_{J}_prob_dec.npy")
    with rasterio.open(f"{B}/_frame_{J}.tif") as m:
        T = m.transform; full = m
        rng = np.random.default_rng(0)
        for lab, sel in [("frame1_nopred", (a == 1) & (q == 65535)), ("frame1_pred", (a == 1) & (q != 65535)), ("frame0", a == 0)]:
            rr, cc = np.nonzero(sel); i = rng.choice(len(rr), min(3000, len(rr)), replace=False)
            xs, ys = rasterio.transform.xy(T, rr[i] * k, cc[i] * k)
            v30 = np.array([s[0] for s in f30.sample(zip(xs, ys))])
            v10 = np.array([s[0] for s in m.sample(zip(xs, ys))])
            u, n = np.unique(v30, return_counts=True)
            print(J, lab, "30m values:", dict(zip(u.tolist(), n.tolist())), "10m agrees with decimated:", float((v10 == a[rr[i], cc[i]]).mean()))
    # independent warp of a 6 km box at the ME/NB center
    with rasterio.open(f"{B}/_frame_{J}.tif") as m:
        cx = (m.bounds.left + m.bounds.right) / 2; cy = (m.bounds.bottom + m.bounds.top) / 2
        cx -= cx % 10; cy -= cy % 10
        w = from_bounds(cx, cy, cx + 6000, cy + 6000, m.transform).round_offsets().round_lengths()
        g = m.read(1, window=w); wt = m.window_transform(w)
    dst = np.zeros(g.shape, "uint8")
    reproject(rasterio.band(f30, 1), dst, dst_transform=wt, dst_crs="EPSG:3979", src_nodata=255, dst_nodata=0, resampling=Resampling.nearest)
    print(J, "window forest share gdalwarp", round(float((g == 1).mean()), 4), "rasterio", round(float((dst == 1).mean()), 4),
          "cell agreement", round(float((g == dst).mean()), 4))
    r30 = f30.read(1, window=from_bounds(cx, cy, cx + 6000, cy + 6000, f30.transform).round_offsets().round_lengths())
    print(J, "window forest share at 30 m", round(float((r30 == 1).mean()), 4), "values", np.unique(r30).tolist())
print(subprocess.run(["bash", "-c", f"gdalinfo {E['FRAME_M3']} | head -40"], capture_output=True, text=True).stdout)
