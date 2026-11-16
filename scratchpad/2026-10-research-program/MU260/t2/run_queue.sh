#!/bin/bash
# On the box: run one queue through the real client of one build, against the local stub only (from T2/raw/run_queue.sh).
# usage: run_queue.sh BUILD8 QUEUE.json PORT TAG [extra client args...]
set -u
B=$1; Q=$2; PORT=$3; TAG=$4; shift 4
cd /root/mu/t2
OUT=/root/mu/t2/out_${TAG}.jsonl; LOG=/root/mu/t2/client_${TAG}.log
N=$(python3 -c "import json,sys;print(len(json.load(open('$Q'))))")
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
touch $OUT
python3 /root/mu/t2/stub_api.py $PORT $Q $OUT 2> /root/mu/t2/stub_${TAG}.log &
SP=$!; sleep 1
echo "$(date -u +%FT%TZ) $(date +%s.%N) start $TAG build $B n=$N" >> /root/mu/t2/runs.log
NICE_API_BASE=http://127.0.0.1:$PORT /root/mu/t2/bin/nice-$B niceonly --api-base http://127.0.0.1:$PORT \
  --username mu260-local --telemetry --gpu --repeat --no-progress "$@" > $LOG 2>&1 &
CP=$!
while [ $(grep -vc "\"claim_id\": 1," $OUT) -lt $N ] && kill -0 $CP 2>/dev/null; do sleep 1; done
kill $CP 2>/dev/null; sleep 1; kill $SP 2>/dev/null
echo "$(date -u +%FT%TZ) $(date +%s.%N) end $TAG got $(grep -vc "\"claim_id\": 1," $OUT)/$N" >> /root/mu/t2/runs.log
