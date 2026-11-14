#!/bin/bash
# One run of the real nice_client (CPU, nice-only) on a field served by the
# local mock API. Usage: run_one.sh <bin: main|br> <tag> <base> <start> <size> <threads> [slices] [parts]
# Writes /root/out/<tag>-<bin>.{err,submit}. Never contacts anything but 127.0.0.1.
BIN=$1; TAG=$2; B=$3; S=$4; SZ=$5; T=$6; SL=$7; PA=$8
OUT=/root/out; mkdir -p $OUT
PORT=$((18000 + RANDOM % 1000))
END=$(python3 -c "print($S+$SZ)")
echo "{\"claim_id\": 1, \"base\": $B, \"range_start\": $S, \"range_end\": $END, \"range_size\": $SZ}" > $OUT/$TAG-$BIN.claim
rm -f $OUT/$TAG-$BIN.submit
CLAIM_JSON=$OUT/$TAG-$BIN.claim SUBMIT_LOG=$OUT/$TAG-$BIN.submit python3 /root/mock_api.py $PORT &
MOCK=$!
sleep 1
export NICE_API_BASE=http://127.0.0.1:$PORT
unset NICE_MEASURE_SLICES NICE_MEASURE_PARTS
[ -n "$SL" ] && export NICE_MEASURE_SLICES=$SL
[ -n "$PA" ] && export NICE_MEASURE_PARTS=$PA
echo "### $TAG $BIN b$B $S +$SZ threads $T slices ${SL:-all} parts ${PA:-all} start $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" > $OUT/$TAG-$BIN.err
/usr/bin/time -v /root/bin/$BIN/nice_client niceonly --api-base $NICE_API_BASE --threads $T --no-progress --telemetry \
  --prefetch-seconds 0 --log-level info >> $OUT/$TAG-$BIN.err 2>&1
echo "### exit $? end $(date -u +%H:%M:%S)" >> $OUT/$TAG-$BIN.err
kill $MOCK 2>/dev/null; wait $MOCK 2>/dev/null
