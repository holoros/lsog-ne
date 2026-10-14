#!/usr/bin/env python3
"""check_record_2026-10-12.py (track fh-relabel). Checks the 2026-10-12 table of record before it is used:
66 rows; every h3 id a valid H3 index at resolution 4 and unique; columns identical (names and order) to the
October 5 table of record; no plot level column (plot id, PLT_CN, coordinates, per plot values); and no file in
out/ other than block aggregates. Writes out/record_check_2026-10-12.json. Exit 2 on any failure."""
import os, sys, json
import pandas as pd, h3
L = os.path.expanduser("~/LSOG"); R = f"{L}/2026-10-12_fh-relabel/out"
new = pd.read_csv(f"{R}/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-12.csv", dtype={"h3": str})
old = pd.read_csv(f"{L}/2026-10-05_fh-crossfit/out/sae-blocks_ME_TRANS_crossfit_DATA_2026-10-05.csv", dtype={"h3": str})
valid = h3.is_valid_cell if hasattr(h3, "is_valid_cell") else h3.h3_is_valid
res = h3.get_resolution if hasattr(h3, "get_resolution") else h3.h3_get_resolution
bad = {"plot_id", "plt_cn", "lat", "lon", "latitude", "longitude", "x", "y", "statecd", "countycd", "plot", "pltcn"}
ck = {"rows": int(len(new)), "rows_is_66": len(new) == 66,
      "h3_all_valid": bool(all(valid(c) for c in new.h3)),
      "h3_resolutions": sorted({int(res(c)) for c in new.h3 if valid(c)}),
      "h3_unique": bool(new.h3.is_unique),
      "same_h3_set_as_2026_10_05": set(new.h3) == set(old.h3),
      "columns_identical_to_2026_10_05": list(new.columns) == list(old.columns),
      "plot_level_columns_present": sorted(c for c in new.columns if c.lower() in bad),
      "min_n_plots_in_nonsynthetic_blocks": int(new.loc[new.synthetic == 0, "n_plots"].min())}
ck["h3_all_res4"] = ck["h3_resolutions"] == [4]
ok = ck["rows_is_66"] and ck["h3_all_valid"] and ck["h3_all_res4"] and ck["h3_unique"] and ck["columns_identical_to_2026_10_05"] and not ck["plot_level_columns_present"]
ck["pass"] = bool(ok)
json.dump(ck, open(f"{R}/record_check_2026-10-12.json", "w"), indent=1)
print(json.dumps(ck))
sys.exit(0 if ok else 2)
