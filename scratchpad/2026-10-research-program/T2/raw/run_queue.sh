#!/bin/bash
# On the box: run one queue through the real client of one build, against the local stub only.
# usage: run_queue.sh BUILD8 QUEUE.json PORT TAG [extra client args...]
set -u
B=$1; Q=$2; PORT=$3; TAG=$4; shift 4
cd /root/t2
OUT=/root/t2/out_${TAG}.jsonl; LOG=/root/t2/client_${TAG}.log
N=$(python3 -c "import json,sys;print(len(json.load(open('$Q'))))")
# refuse to start unless production is unreachable from here
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
touch $OUT
python3 /root/t2/stub_api.py $PORT $Q $OUT 2> /root/t2/stub_${TAG}.log &
SP=$!; sleep 1
echo "$(date -u +%FT%TZ) start $TAG build $B n=$N" >> /root/t2/runs.log
NICE_API_BASE=http://127.0.0.1:$PORT /root/bin/nice-$B niceonly --api-base http://127.0.0.1:$PORT \
  --username t2-audit-local --telemetry --gpu --repeat --no-progress "$@" > $LOG 2>&1 &
CP=$!
while [ $(grep -vc "\"claim_id\":1," $OUT) -lt $N ] && kill -0 $CP 2>/dev/null; do sleep 2; done
kill $CP 2>/dev/null; sleep 1; kill $SP 2>/dev/null
echo "$(date -u +%FT%TZ) end $TAG got $(grep -vc "\"claim_id\":1," $OUT)/$N" >> /root/t2/runs.log
