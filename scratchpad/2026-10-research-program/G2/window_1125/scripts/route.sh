#!/bin/sh
# route.sh: window 3, task 5 (spare): the client route against the local coordinator (127.0.0.1 only). A work list
# of 12 base-64 fields (midout_fields --spread 12), scripts/midout_coordinator.py --reissue-after 600, the client
# (dev/mo-clean, --features cubecl-spirv = $BIN/client) with the hidden --midout-coordinator flag and --repeat,
# --api-base pointed at a closed local port; the client is killed by its recorded PID with SIGTERM once /status
# says 12 done (or at END_AT); then scripts/midout_audit.py on the state directory (must exit 0).
. "$(dirname "$(readlink -f "$0")")/env.sh"
: "${END_AT:?set END_AT}"
R=$OUT/route; mkdir -p $R/state; PORT=8471
echo "ROUTE_START $(date -u +%T) client md5=$(md5sum $BIN/client | cut -c1-8) fields md5=$(md5sum $BIN/mo_fields | cut -c1-8)"
$BIN/mo_fields --base 64 --spread 12 > $R/w64.json || { echo "mo_fields failed"; exit 1; }
python3 -c "import json;print('fields in work list:', len(json.load(open('$R/w64.json'))))"
python3 $W/src/scripts/midout_coordinator.py --worklist $R/w64.json --state $R/state --port $PORT --reissue-after 600 > $R/coordinator.log 2>&1 &
CO=$!; echo $CO > $R/coordinator.pid; sleep 2
sh "$SCRIPTS/smp.sh" "$OUT/route_client.gpu" & MON=$!
$BIN/client --api-base http://127.0.0.1:9 --midout-coordinator http://127.0.0.1:$PORT --repeat --no-progress --threads $HTHREADS niceonly > $R/client.log 2>&1 &
CL=$!; echo $CL > $R/client.pid; echo "ROUTE_RUN_START $(date -u +%T) client pid $CL coordinator pid $CO"
while kill -0 $CL 2>/dev/null; do
  S=$(python3 -c "import urllib.request,json;print(json.load(urllib.request.urlopen('http://127.0.0.1:$PORT/status',timeout=5)).get('done',0))" 2>/dev/null)
  [ "${S:-0}" -ge 12 ] && break
  [ "$(date +%s)" -ge "$END_AT" ] && { echo "END_AT reached before the list was done"; break; }
  sleep 5
done
kill -TERM $CL 2>/dev/null; wait $CL; echo "client rc=$? (SIGTERM by pid) $(date -u +%T)"
kill $MON 2>/dev/null
python3 -c "import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:$PORT/status',timeout=5).read().decode())"
python3 $W/src/scripts/midout_audit.py --worklist $R/w64.json --state $R/state > $R/audit.txt 2>&1; echo "audit rc=$?"; tail -5 $R/audit.txt
kill -TERM $CO 2>/dev/null; wait $CO
wc -l $R/state/*.jsonl
echo "ROUTE_DONE $(date -u +%T)"
