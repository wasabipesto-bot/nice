#!/bin/bash
# one experiment (from G2/build2e/raw/alloc/arun.sh): a client binary against the local stub, optional memory hog.
# usage: srun.sh TAG BIN QUEUE.json NFIELDS HOGMODE LEAVE_MIB ROUTE
#   BIN: path of the client binary; HOGMODE: none | before; ROUTE: auto | stride (NICE_JOIN_ROUTE=stride)
set -u
TAG=$1; BIN=$2; Q=$3; N=$4; MODE=$5; LEAVE=$6; ROUTE=$7
A=/root/mo/alloc; R=/root/sra/runs/$TAG; mkdir -p $R; PORT=8411
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
  getent hosts $h | grep -qvE '^(127\.0\.0\.1|::1) ' && { echo "ABORT: $h resolves off loopback"; exit 1; }
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
OUT=$R/out.jsonl; rm -f $OUT; touch $OUT
python3 /root/mo/stub_api.py $PORT $Q $OUT 2> $R/stub.log & SP=$!
sleep 1
nvidia-smi --query-gpu=timestamp,memory.used,utilization.gpu --format=csv,noheader -lms 200 > $R/mem.csv & MP=$!
HP=
if [ $MODE = before ]; then $A/hog $LEAVE > $R/hog.log 2>&1 & HP=$!; sleep 3; fi
echo "$(date -u +%FT%T.%3NZ) start $TAG bin=$BIN $(md5sum < $BIN | cut -c1-8) q=$Q mode=$MODE leave=$LEAVE route=$ROUTE" >> $R/run.log
if [ $ROUTE = stride ]; then export NICE_JOIN_ROUTE=stride; fi
RUST_LOG=info $BIN niceonly --api-base http://127.0.0.1:$PORT --username alloc-test-local \
  --telemetry --gpu --repeat --no-progress > $R/client.log 2>&1 & CP=$!
T0=$(date +%s)
while [ $(grep -vc '"claim_id": 1,' $OUT) -lt $N ] && kill -0 $CP 2>/dev/null && [ $(( $(date +%s) - T0 )) -lt 240 ]; do sleep 1; done
sleep 2
kill -0 $CP 2>/dev/null && echo "client alive at end" >> $R/run.log || { wait $CP; echo "client exited rc=$?" >> $R/run.log; }
kill $CP $SP $MP $HP 2>/dev/null; sleep 1
echo "$(date -u +%FT%T.%3NZ) end $TAG got $(grep -vc '"claim_id": 1,' $OUT)/$N" >> $R/run.log
echo "task_failed $(grep -c 'Task failed' $R/client.log) errors: $(grep -E 'ERROR|did not run' $R/client.log | head -3)" >> $R/run.log
python3 - $OUT >> $R/run.log <<'PY'
import json,sys
for l in open(sys.argv[1]):
    d=json.loads(l)
    if d.get("claim_id",1)==1: continue
    p=(d.get("telemetry") or {}).get("pipeline") or {}; s=d.get("_stub") or {}
    print("SUBMIT", d["claim_id"], "nice", d.get("nice_numbers"), "route", p.get("route"), "launches", p.get("launches"),
          "num_ranges", p.get("num_ranges"), "valid", p.get("valid_numbers"),
          "processing_s", (d.get("telemetry") or {}).get("processing_secs"), "pipe_total_s", p.get("total_secs"),
          "dev_wait_s", p.get("device_wait_secs"), "msd_s", p.get("msd_secs"),
          "claim_to_submit_s", round(s["recv"]-s["claim"],3) if s.get("claim") else None)
PY
cat $R/run.log
