#!/usr/bin/env python3
"""d6_nb_labels.py (November 13, 2026). New Brunswick labels for the six definitions of the PREREG, taken from the
producer's own sweep code so the reproduction gate is the producer's estimator, not a copy of it.
nb_instrument_sweep_20260902 (W variants) and nb_instrument_sweep_core4_20260902 (X variants) are run unchanged
with 2,000 holder-cluster replicates; run_variant is wrapped only to keep the per-plot indicator each variant passes
to the bootstrap. Every CSV the two scripts would write outside this run's work folder is redirected into it, so no
existing file is touched. The producer deletes its OUTDIR on a failed guard, so OUTDIR is a throwaway subfolder.
Per-plot labels stay in RESTRICTED (licensed records); only provincial aggregates are printed or saved to out/."""
import os, sys, json, shutil
W = os.path.expanduser("~/LSOG/2026-11-13_definition-map-sensitivity"); NBM = os.path.expanduser("~/LSOG/nb_magplot")
WORK = f"{W}/nb_sweep_work"; os.makedirs(WORK, exist_ok=True); sys.path.insert(0, NBM); os.chdir(NBM)
import pandas as pd
_to_csv = pd.DataFrame.to_csv
def to_csv(self, path_or_buf=None, *a, **k):
    if isinstance(path_or_buf, str) and not os.path.abspath(path_or_buf).startswith(WORK):
        path_or_buf = os.path.join(WORK, "redirected_" + os.path.basename(path_or_buf))
    return _to_csv(self, path_or_buf, *a, **k)
pd.DataFrame.to_csv = to_csv
import nb_cli_lsog_fullscope as P, nb_instrument_sweep_20260902 as S, nb_instrument_sweep_core4_20260902 as C
shutil.copy(C.MAIN_CSV, f"{WORK}/prior_main.csv"); C.MAIN_CSV = f"{WORK}/prior_main.csv"
cap, res = {}, {}; _rv = S.run_variant
def rv(est_df, strat, Wt, W150, nboot, vid):
    out = _rv(est_df, strat, Wt, W150, nboot, vid)
    if vid not in cap:
        f = est_df[[P.KEY, "any_lsog"]].copy(); f["strat"] = strat; cap[vid] = f.reset_index(drop=True); res[vid] = out["any-LSOG"]
    return out
S.run_variant = rv
for mod, sub in ((S, "w"), (C, "x")):
    sys.argv = [mod.__name__, "--outdir", f"{WORK}/{sub}", "--nboot", "2000"]
    try: mod.main()
    except SystemExit as e: print(mod.__name__, "exit", e.code, flush=True)
WANT = {"W2": 39.39, "W1": 31.47, "W4": 9.75, "X9_c3": 9.37, "X9": 6.12, "W6": 4.49}
CI = {"W2": (36.89, 41.82), "W1": (29.17, 33.31), "W4": (8.51, 10.88), "X9_c3": (7.71, 11.03), "X9": (4.87, 7.48), "W6": (3.57, 5.55)}
miss = [v for v in WANT if v not in cap]; out = {"captured": sorted(cap), "missing": miss, "defs": {}}
if not miss:
    base = cap["W1"][[P.KEY]]; L = base.copy(); same = True
    for v in WANT:
        f = cap[v]; same &= bool(len(f) == len(base) and (f[P.KEY].values == base[P.KEY].values).all()); L[v] = f.any_lsog.values if same else None
        r = res[v]; out["defs"][v] = {"pct": r["poststrat_pct"], "lo": r["ci_lo"], "hi": r["ci_hi"], "n_plots": int(len(f)), "n_pos": int(f.any_lsog.sum()),
                                       "target": WANT[v], "pass_point": bool(abs(r["poststrat_pct"] - WANT[v]) < 0.005),
                                       "pass_interval": bool(abs(r["ci_lo"] - CI[v][0]) < 0.005 and abs(r["ci_hi"] - CI[v][1]) < 0.005)}
    out["same_plot_basis_all_variants"] = same
    if same: L.to_csv(f"{WORK}/nb_def_labels_RESTRICTED.csv", index=False); shutil.move(f"{WORK}/nb_def_labels_RESTRICTED.csv", f"{W}/RESTRICTED/nb_def_labels_RESTRICTED.csv")
out["gate"] = bool(not miss and out.get("same_plot_basis_all_variants") and all(d["pass_point"] for d in out["defs"].values()))
json.dump(out, open(f"{W}/out/d6_nb_labels_DATA.json", "w"), indent=1); print(json.dumps(out)); print("GATE PASS" if out["gate"] else "GATE FAIL")
sys.exit(0 if out["gate"] else 3)
