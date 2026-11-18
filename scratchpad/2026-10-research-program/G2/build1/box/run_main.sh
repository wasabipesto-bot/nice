#!/bin/bash
# on box: today's main, real client against the local stub only, b64 1e17 fields at 0.05..0.95 (+ 1e14 warm-up)
# usage: run_main.sh TAG
set -u
TAG=$1; cd /root/mo; Q=/root/mo/queue_b64.json; PORT=8400
OUT=/root/mo/out_${TAG}.jsonl; LOG=/root/mo/client_${TAG}.log
N=$(python3 -c "import json;print(len(json.load(open('$Q'))))")
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
rm -f $OUT; touch $OUT
python3 /root/mo/stub_api.py $PORT $Q $OUT 2> /root/mo/stub_${TAG}.log &
SP=$!; sleep 1
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,utilization.gpu,temperature.gpu --format=csv,noheader -l 5 > /root/mo/smi_${TAG}.csv &
MP=$!
echo "$(date -u +%FT%TZ) $(date +%s.%N) start $TAG n=$N" >> /root/mo/runs.log
NICE_API_BASE=http://127.0.0.1:$PORT /root/mo/nice-main niceonly --api-base http://127.0.0.1:$PORT \
  --username g2-bench-local --telemetry --gpu --repeat --no-progress > $LOG 2>&1 &
CP=$!
while [ $(grep -vc "\"claim_id\": 1," $OUT) -lt $N ] && kill -0 $CP 2>/dev/null; do sleep 1; done
kill $CP 2>/dev/null; sleep 1; kill $SP $MP 2>/dev/null
echo "$(date -u +%FT%TZ) $(date +%s.%N) end $TAG got $(grep -vc "\"claim_id\": 1," $OUT)/$N" >> /root/mo/runs.log
