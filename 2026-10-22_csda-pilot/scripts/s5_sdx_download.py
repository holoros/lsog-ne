#!/usr/bin/env python3
"""CSDA pilot: clipped download of the approved order (out/sdx_all102_ORDER_DATA.csv) from SDX.
Authorized by Aaron on October 22, 2026 (full autopilot, "including the download script and SDX token").

Token: SDX issues its own JWT after an Earthdata login in the browser; the Earthdata token in ~/.edl_token is
refused (401) and the token endpoint only takes a browser authorization code or an M2M client. Aaron saves the
access_token value shown at https://csdap.earthdata.nasa.gov/api/v1/auth/verify (while logged in) to
~/.sdx_token on Cardinal, mode 600. This script reads it and never prints it.

For each item it calls GET /api/v2/download/{collection}/{item}/{asset} (307 to a signed URL), reads only
the 1 km cell windows plus a 150 m buffer through GDAL range requests, and writes clips to RESTRICTED/clips.
Usage: python3 s5_sdx_download.py --check   (token validity and expiry, one tiny readme request)
       python3 s5_sdx_download.py           (full run; resumable; ledger in out/sdx_download_LEDGER.json)"""
import base64, csv, json, os, re, sys, time, urllib.request, urllib.error
from pathlib import Path
os.environ.setdefault("CPL_VSIL_CURL_USE_HEAD", "NO")      # signed URLs: ranged GET instead of HEAD
os.environ.setdefault("GDAL_HTTP_MAX_RETRY", "4"); os.environ.setdefault("GDAL_DISABLE_READDIR_ON_OPEN", "EMPTY_DIR")

def redact(msg):
    """Strip query strings (signatures) from any URL in an error message before it is stored."""
    return re.sub(r"\?\S*", "?<redacted>", str(msg))

D = Path.home() / "LSOG/2026-10-22_csda-pilot"; API = "https://csdap.earthdata.nasa.gov/api/v2/download"
TOKF = Path.home() / ".sdx_token"
if not TOKF.exists():
    sys.exit("No ~/.sdx_token. Log in at https://csdap.earthdata.nasa.gov, open /api/v1/auth/verify, save access_token to ~/.sdx_token (chmod 600).")
if oct(TOKF.stat().st_mode)[-3:] != "600": os.chmod(TOKF, 0o600)
TOK = TOKF.read_text().strip().strip('"')
try:
    pay = json.loads(base64.urlsafe_b64decode(TOK.split(".")[1] + "==="))
    left = pay.get("exp", 0) - time.time()
    print(f"token expires in {left / 3600:.1f} h" if pay.get("exp") else "token has no exp claim")
    if pay.get("exp") and left < 300: sys.exit("token expired or about to; fetch a fresh one")
except Exception:
    print("token is not a readable JWT; continuing")

ORDER = list(csv.DictReader(open(D / "out/sdx_all102_ORDER_DATA.csv")))
CELLS = json.load(open(D / "RESTRICTED/item_cells_RESTRICTED.json"))
LEDGER = D / "out/sdx_download_LEDGER.json"
led = json.load(open(LEDGER)) if LEDGER.exists() else {}
BUF = 150 / 111320.0
ASSETS = {"pgc-earthdem": ["dem", "mask", "matchtag"], "desis": ["SPECTRAL_IMAGE.tif", "QL_QUALITY.tif"]}

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *a, **k): return None
opener = urllib.request.build_opener(NoRedirect)

def resolve(coll, item, asset):
    name = asset if coll == "pgc-earthdem" else f"{item}-{asset}"   # DESIS asset keys are the item id plus suffix
    req = urllib.request.Request(f"{API}/{coll}/{item}/{name}", headers={"Authorization": f"Bearer {TOK}"})
    for k in range(4):
        try:
            r = opener.open(req, timeout=120); return ("body", r)
        except urllib.error.HTTPError as e:
            if e.code in (301, 302, 303, 307, 308): return ("url", e.headers["Location"])
            if e.code in (401, 403): raise SystemExit(f"auth refused ({e.code}); refresh ~/.sdx_token")
            if e.code in (429, 500, 502, 503, 504): time.sleep(10 * (k + 1)); continue
            raise
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            time.sleep(10 * (k + 1)); continue
    raise RuntimeError("retries exhausted")

import rasterio
from rasterio.windows import from_bounds, Window
from rasterio.warp import transform_bounds

def save_ledger():
    tmp = LEDGER.with_suffix(".tmp"); json.dump(led, open(tmp, "w"), indent=1); os.replace(tmp, LEDGER)

if "--check" in sys.argv:   # token, signed redirect, and one 64 x 64 range read through /vsicurl
    first = next(o for o in ORDER if o["collection"] == "pgc-earthdem")
    kind, val = resolve("pgc-earthdem", first["item_id"], "dem")
    if kind != "url": sys.exit("expected a signed redirect for the dem asset; --check will not pull a whole file")
    try:
        with rasterio.open("/vsicurl/" + val) as src: a = src.read(1, window=Window(0, 0, 64, 64))
    except Exception as e:
        sys.exit("range read failed: " + redact(e)[:300])
    print("token OK; signed redirect and range read OK", a.shape); sys.exit(0)

for o in ORDER:
    coll, item = o["collection"], o["item_id"]
    for asset in ASSETS[coll]:
        key = f"{item}|{asset}"
        if led.get(key, {}).get("state") == "done": continue
        try:
            kind, val = resolve(coll, item, asset)
            out = D / "RESTRICTED/clips" / item; out.mkdir(parents=True, exist_ok=True)
            if kind == "body":
                tmp = out / f"{asset.split('.')[0]}.full.tif"
                with open(tmp, "wb") as fh:
                    while (b := val.read(1 << 20)): fh.write(b)
                src_path = str(tmp)
            else:
                src_path = "/vsicurl/" + val
            n = 0
            with rasterio.open(src_path) as src:
                for k, g, role, bb in CELLS[item]:
                    b = transform_bounds("EPSG:4326", src.crs, bb[0] - BUF, bb[1] - BUF, bb[2] + BUF, bb[3] + BUF)
                    w = from_bounds(*b, transform=src.transform).round_offsets().round_lengths()
                    fv = src.nodata if src.nodata is not None else (255 if asset == "mask" else 0)   # outside the strip reads as masked
                    arr = src.read(window=w, boundless=True, fill_value=fv)
                    prof = dict(src.profile); prof.update(driver="GTiff", width=arr.shape[2], height=arr.shape[1],
                                                          transform=src.window_transform(w), compress="deflate", tiled=False)
                    for x in ("blockxsize", "blockysize", "interleave"): prof.pop(x, None)
                    with rasterio.open(out / f"{asset.split('.')[0]}_c{k:03d}_{g}_{role}.tif", "w", **prof) as dst: dst.write(arr)
                    n += 1
            if kind == "body": os.remove(src_path)
            led[key] = {"state": "done", "clips": n, "t": time.strftime("%Y-%m-%dT%H:%M:%S")}
        except SystemExit: raise
        except Exception as e:
            led[key] = {"state": "error", "err": redact(e)[:300], "t": time.strftime("%Y-%m-%dT%H:%M:%S")}
        save_ledger()
        print(key, led[key]["state"], flush=True)
print("done:", sum(v["state"] == "done" for v in led.values()), "errors:", sum(v["state"] == "error" for v in led.values()))
