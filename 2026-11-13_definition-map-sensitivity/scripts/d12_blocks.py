#!/usr/bin/env python3
"""d12_blocks.py (November 13, 2026). Writes the 20 km block tables of d5 and d9 as aggregate CSVs for the figure:
block index (EPSG:3979, 20 km), forest-frame cells, cells by number of definitions flagged (c0 to c6), cells flagged
per definition, and summed probability per definition. Map cells only; no plot record is read."""
import os, pandas as pd, numpy as np
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); SCR = "/fs/scratch/PUOM0008/crsfaaron/defsens_2026-11-13"
for j in ("me", "nb"):
    B = pd.read_pickle(f"{SCR}/{j}_block_table.pkl"); bx = np.round(B.block / 100000).astype(int); by = (B.block - bx * 100000).astype(int)
    assert (np.abs(by) < 50000).all(); B.insert(1, "bx", bx); B.insert(2, "by", by)
    B[[c for c in B.columns if not c.startswith("i_")]].to_csv(f"{W}/out/d12_{j}_blocks_DATA.csv", index=False); print(j, len(B), int(B.n.sum()), by.min(), by.max(), bx.min(), bx.max())
