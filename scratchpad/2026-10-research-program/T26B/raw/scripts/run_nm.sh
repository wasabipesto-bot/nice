#!/bin/bash
# run_nm.sh NAME BIN SECS [ROUTE]: NiceMark (nice_client --benchmark, nice-only, CubeCL CUDA, 20 threads), API base
# pointed at a closed local port (no network), NICE_JOIN_ROUTE=ROUTE (default stride); nvidia-smi every 1 s.
W=/root/t26b; NAME=$1; BIN=$2; SECS=$3; ROUTE=${4:-stride}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_JOIN_ROUTE=$ROUTE
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 1; done ) > $W/logs/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) bin=$BIN md5=$(md5sum $W/bin/$BIN | cut -c1-8) secs=$SECS route=$ROUTE temp=$(nvidia-smi --query-gpu=temperature.gpu,power.limit --format=csv,noheader)" > $W/logs/$NAME.log
timeout 3600 $W/bin/$BIN --benchmark --benchmark-json --benchmark-secs $SECS niceonly --gpu --gpu-backend cubecl-cuda --threads 20 --api-base http://127.0.0.1:9 --no-progress > $W/logs/$NAME.json 2>> $W/logs/$NAME.log < /dev/null
echo "END $NAME $(date -u +%T) rc=$?" >> $W/logs/$NAME.log
kill $SMI
python3 - $W/logs/$NAME.json <<'PY'
import json,sys
try: r=json.load(open(sys.argv[1]))
except Exception as e: print("no json", e); sys.exit()
print(sys.argv[1].split('/')[-1], 'nicemark', r.get('nicemark') or r.get('score'), [(s.get('key'), s.get('rate'), (s.get('route') if 'route' in s else '')) for s in r.get('scenarios',[])])
PY
