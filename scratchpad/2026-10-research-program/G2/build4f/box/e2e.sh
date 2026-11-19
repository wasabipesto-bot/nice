#!/bin/bash
# the end-to-end run: coordinator (24 b64 fields spread over the base, 2 b65 fields) + the route client; $1 = run tag
set -u
B=/root/mo/bin; R=/root/mo/runs/$1; mkdir -p $R; source /root/mo/guard.sh $R
PORT=8471
$B/midout_fields --base 64 --spread ${N64:-24} > $R/w64.json && $B/midout_fields --base 65 --t ${T65:-13731,77777} > $R/w65.json || exit 1
python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1]))+json.load(open(sys.argv[2])), indent=0))' $R/w64.json $R/w65.json > $R/work.json
md5sum $B/nice_mo > $R/bin.txt
python3 /root/mc/scripts/midout_coordinator.py --worklist $R/work.json --state $R/state --port $PORT 2> $R/coord.log & CP=$!
nvidia-smi --query-gpu=timestamp,power.draw,clocks.sm,temperature.gpu,utilization.gpu,memory.used --format=csv,noheader -lms 1000 > $R/smi.csv & MP=$!
sleep 1
echo "$(date -u +%FT%T.%3NZ) client start" >> $R/run.log
$B/nice_mo niceonly --midout-coordinator http://127.0.0.1:$PORT --repeat --username mo-e2e-local > $R/client.log 2>&1
echo "$(date -u +%FT%T.%3NZ) client rc=$?" >> $R/run.log
curl -s http://127.0.0.1:$PORT/status >> $R/run.log; echo >> $R/run.log
kill $CP $MP; echo done > $R/done
