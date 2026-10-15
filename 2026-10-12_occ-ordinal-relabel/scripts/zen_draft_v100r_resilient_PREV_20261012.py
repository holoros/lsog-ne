#!/usr/bin/env python3
"""Bring UNPUBLISHED Zenodo draft 23209841 to version 1.0.0. Never publishes. Refuses to run unless the gate log says all
gates passed and is newer than every manifest file. Uploads only files whose md5 differs from the server copy, deletes
server files that are no longer in the manifest (each named in the log), sets the metadata, then re-reads the draft and
checks that the server listing equals the manifest and every md5 matches. Token from ~/.zenodo_token as a Bearer header."""
import os, sys, json, time, hashlib, requests
P = "/users/PUOM0008/crsfaaron/LSOG/products/me-ordinal-lsog-v4c_2026-10-07/zenodo_upload"; B = "https://zenodo.org/api"; DID = 23209841
tok = open(os.path.expanduser("~/.zenodo_token")).read().strip(); H = {"Authorization": f"Bearer {tok}"}
def mask(t): return str(t).replace(tok, "***")
man = [l.split("#")[0].strip() for l in open(f"{P}/files_to_upload.txt")]; man = [l for l in man if l]
if "ALL GATES PASS" not in open(f"{P}/check_deposit_log.txt").read(): sys.exit("gates not passed")
lt = os.path.getmtime(f"{P}/check_deposit_log.txt")
newer = [f for f in man if os.path.getmtime(os.path.join(P, f)) > lt]
if newer: sys.exit(f"files changed after the gate run: {newer}")
key = lambda f: f.replace("/", "__") if f.startswith("code/") else f
def md5(fp):
    h = hashlib.md5()
    with open(fp, "rb") as fh:
        for b in iter(lambda: fh.read(1 << 22), b""): h.update(b)
    return h.hexdigest()
def get():
    for i in range(6):
        try:
            r = requests.get(f"{B}/deposit/depositions/{DID}", headers=H, timeout=120)
            if r.status_code < 300: return r.json()
            print("GET", r.status_code, flush=True)
        except requests.exceptions.RequestException as e: print("GET", mask(e)[:200], flush=True)
        time.sleep(60)
    sys.exit("cannot read draft")
d = get()
if d.get("submitted"): sys.exit("draft is already published; refusing")
bucket = d["links"]["bucket"]; srv = {f["filename"]: f for f in d.get("files", [])}
want = {key(f): f for f in man}
for name, f in srv.items():
    if name not in want:
        r = requests.delete(f["links"]["self"], headers=H, timeout=120)
        print(("deleted " if r.status_code < 300 else f"DELETE FAILED {r.status_code} ") + name, flush=True)
order = sorted(want, key=lambda n: os.path.getsize(os.path.join(P, want[n])))
pending = list(order); hashes = {}
for rnd in range(4):
    failed = []
    for name in pending:
        f = want[name]; h = hashes.setdefault(name, md5(os.path.join(P, f)))
        if name in srv and srv[name]["checksum"].endswith(h): print("have", name, flush=True); continue
        u = None
        for attempt in range(3):
            try:
                with open(os.path.join(P, f), "rb") as fh:
                    u = requests.put(f"{bucket}/{name}", data=fh, headers=H, timeout=(60, 14400))
                if u.status_code < 300: break
                print(f"round {rnd + 1} attempt {attempt + 1} {name}: HTTP {u.status_code}", flush=True)
            except requests.exceptions.RequestException as e:
                u = None; print(f"round {rnd + 1} attempt {attempt + 1} {name}: {mask(e)[:160]}", flush=True)
            time.sleep(120)
        if u is None or u.status_code >= 300: failed.append(name); print("DEFER", name, flush=True); continue
        ok = u.json().get("checksum", "").endswith(h); print(("ok  " if ok else "MISMATCH ") + name, flush=True)
        if not ok: sys.exit("checksum mismatch")
    if not failed: break
    print(f"round {rnd + 1}: {len(failed)} deferred; sleeping 20 min", flush=True); pending = failed
    time.sleep(1200); srv = {x["filename"]: x for x in get().get("files", [])}
else:
    print("STILL FAILING:", failed, flush=True)
meta = json.load(open(f"{P}/zenodo_metadata.json"))
r = requests.put(f"{B}/deposit/depositions/{DID}", headers=H, json=meta, timeout=120)
if r.status_code >= 300: sys.exit(f"metadata: {mask(r.text)[:800]}")
print("metadata set; NOT published", flush=True)
d = get(); srv = {f["filename"]: f["checksum"] for f in d.get("files", [])}
extra = sorted(set(srv) - set(want)); miss = sorted(set(want) - set(srv))
bad = [n for n in want if n in srv and not srv[n].endswith(md5(os.path.join(P, want[n])))]
res = {"deposition_id": DID, "version": d["metadata"].get("version"), "access_right": d["metadata"].get("access_right"),
       "n_files": len(srv), "total_gb": round(sum(f["filesize"] for f in d["files"]) / 1e9, 3), "extra_on_server": extra,
       "missing_on_server": miss, "md5_mismatch": bad, "submitted": d.get("submitted"),
       "reserved_doi": d["metadata"].get("prereserve_doi", {}).get("doi"), "concept_recid": d.get("conceptrecid"),
       "checked": time.strftime("%Y-%m-%dT%H:%M:%S%z")}
json.dump(res, open(f"{P}/zenodo_draft_result_v100.json", "w"), indent=1); print(json.dumps(res, indent=1))
sys.exit(0 if not (extra or miss or bad) else 4)
