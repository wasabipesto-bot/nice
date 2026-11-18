#!/bin/bash
# one allocation-failure experiment: v3.4.8 client against the local stub, optional memory hog.
# usage: arun.sh TAG QUEUE.json NFIELDS HOGMODE LEAVE_MIB DELAY_S
#   HOGMODE: none | before (hog holds all but LEAVE before the client starts) | after (hog starts DELAY_S after the client)
set -u
TAG=$1; Q=$2; N=$3; MODE=$4; LEAVE=$5; DELAY=$6
A=/root/mo/alloc; R=$A/runs/$TAG; mkdir -p $R; PORT=8410
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
OUT=$R/out.jsonl; rm -f $OUT; touch $OUT
python3 /root/mo/stub_api.py $PORT $Q $OUT 2> $R/stub.log & SP=$!
sleep 1
nvidia-smi --query-gpu=timestamp,memory.used,utilization.gpu --format=csv,noheader -lms 200 > $R/mem.csv & MP=$!
HP=
if [ $MODE = before ]; then $A/hog $LEAVE > $R/hog.log 2>&1 & HP=$!; sleep 3; fi
echo "$(date -u +%FT%T.%3NZ) start $TAG mode=$MODE leave=$LEAVE delay=$DELAY" >> $R/run.log
RUST_LOG=info $A/nice-v348 niceonly --api-base http://127.0.0.1:$PORT --username alloc-test-local \
  --telemetry --gpu --repeat --no-progress > $R/client.log 2>&1 & CP=$!
if [ $MODE = after ]; then sleep $DELAY; $A/hog $LEAVE > $R/hog.log 2>&1 & HP=$!; echo "$(date -u +%FT%T.%3NZ) hog started" >> $R/run.log; fi
T0=$(date +%s)
while [ $(grep -vc '"claim_id": 1,' $OUT) -lt $N ] && kill -0 $CP 2>/dev/null && [ $(( $(date +%s) - T0 )) -lt 240 ]; do sleep 1; done
sleep 2
kill -0 $CP 2>/dev/null && echo "client alive at end" >> $R/run.log || { wait $CP; echo "client exited rc=$?" >> $R/run.log; }
kill $CP $SP $MP $HP 2>/dev/null; sleep 1
echo "$(date -u +%FT%T.%3NZ) end $TAG got $(grep -vc '"claim_id": 1,' $OUT)/$N" >> $R/run.log
python3 - $OUT >> $R/run.log <<'PY'
import json,sys
for l in open(sys.argv[1]):
    d=json.loads(l)
    if d.get("claim_id")==1: continue
    p=(d.get("telemetry") or {}).get("pipeline") or {}; j=p.get("join") or {}
    print("SUBMIT", d["claim_id"], "nice", d.get("nice_numbers"), "route", p.get("route"), "launches", p.get("launches"),
          "valid", p.get("valid_numbers"), "join_surv", j.get("survivors"), "join_checked", j.get("checked"), "refused", j.get("refused_layouts"))
PY
cat $R/run.log
