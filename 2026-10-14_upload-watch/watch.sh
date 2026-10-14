#!/bin/bash
# Retry the two Zenodo DRAFT syncs from the login node until each result json is clean. Never publishes:
# both uploaders have no publish path. Zenodo answered 502/504 on every bucket PUT on 2026-10-13/14, even 1 MB.
LOG=~/LSOG/2026-10-14_upload-watch/watch.log
A=~/LSOG/products/me-transitioning-10m_2026-10-12r/zenodo_upload
B=~/zenodo_staging/menb-lsog-manuscript/v160_work_20261001
clean() { python3 -c "import json,sys;d=json.load(open('$1'));sys.exit(0 if d.get('n_files')==$2 and not d.get('missing_on_server') and not d.get('md5_mismatch') and not d.get('extra_on_server') and d.get('submitted') is False else 1)" 2>/dev/null; }
doneA=0; doneB=0
for i in $(seq 1 36); do
  echo "=== try $i $(date -Is)" >> $LOG
  if [ $doneA = 0 ]; then (cd $A && timeout 4h /usr/bin/python3 zenodo_fire.py >> $LOG 2>&1); [ -f $A/zenodo_draft_result_v110.json ] && [ $A/zenodo_draft_result_v110.json -nt $LOG.start ] && clean $A/zenodo_draft_result_v110.json 41 && doneA=1; fi
  if [ $doneB = 0 ]; then (cd $B && timeout 4h /usr/bin/python3 2026-10-12_upload_v160_draft.py >> $LOG 2>&1); [ $B/zenodo_draft_result_v160.json -nt $LOG.start ] && clean $B/zenodo_draft_result_v160.json 100 && doneB=1; fi
  echo "status A(1.1.0)=$doneA B(1.6.0)=$doneB" >> $LOG
  [ $doneA = 1 ] && [ $doneB = 1 ] && { echo "ALL CLEAN $(date -Is)" >> $LOG; exit 0; }
  sleep 1800
done
echo "GAVE UP $(date -Is)" >> $LOG
