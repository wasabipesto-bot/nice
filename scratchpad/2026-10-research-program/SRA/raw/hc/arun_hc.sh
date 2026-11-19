#!/bin/bash
# one hand-CUDA allocation-failure experiment against the local stub, optional memory hog.
# usage: arun_hc.sh TAG BIN QUEUE.json NFIELDS HOGMODE LEAVE_MIB DELAY_S [BACKEND] [ENV=VAL ...]
#   BIN: nice-v345 | nice-main ; BACKEND: auto (default) | cuda
#   HOGMODE: none | before (hog holds all but LEAVE before start) | after (hog starts DELAY_S after the client)
#            | between (hog starts as soon as the first queued field has been submitted)
set -u
TAG=$1; BIN=$2; Q=$3; N=$4; MODE=$5; LEAVE=$6; DELAY=$7; BACKEND=${8:-auto}; shift 8 2>/dev/null || shift $#
A=/root/mo/alloc; R=$A/runs/$TAG; rm -rf $R; mkdir -p $R; PORT=8410
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable"; exit 1; fi
done
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing"; exit 1; }
OUT=$R/out.jsonl; rm -f $OUT; touch $OUT; TRIG=$R/trigger; rm -f $TRIG
python3 /root/mo/stub_api.py $PORT $Q $OUT 2> $R/stub.log & SP=$!
sleep 1
nvidia-smi --query-gpu=timestamp,memory.used,utilization.gpu --format=csv,noheader -lms 200 > $R/mem.csv & MP=$!
HP=
if [ $MODE = before ]; then $A/${HOG:-hog} $LEAVE > $R/hog.log 2>&1 & HP=$!; sleep 3; fi
if [ $MODE = between ]; then $A/${HOG:-hog} $LEAVE $TRIG > $R/hog.log 2>&1 & HP=$!; fi
echo "$(date -u +%FT%T.%3NZ) start $TAG hog=${HOG:-hog} bin=$BIN backend=$BACKEND mode=$MODE leave=$LEAVE delay=$DELAY env=$*" >> $R/run.log
env "$@" RUST_LOG=info,nice_common=debug NICE_API_BASE=http://127.0.0.1:$PORT $A/$BIN niceonly --api-base http://127.0.0.1:$PORT \
  --username hc-test-local --telemetry --gpu --gpu-backend $BACKEND --repeat --no-progress > $R/client.log 2>&1 & CP=$!
if [ $MODE = after ]; then sleep $DELAY; $A/${HOG:-hog} $LEAVE > $R/hog.log 2>&1 & HP=$!; echo "$(date -u +%FT%T.%3NZ) hog started" >> $R/run.log; fi
T0=$(date +%s)
while [ $(grep -vc '"claim_id": 1,' $OUT) -lt $N ] && kill -0 $CP 2>/dev/null && [ $(( $(date +%s) - T0 )) -lt 150 ]; do
  if [ $MODE = between ] && [ ! -e $TRIG ] && [ $(grep -vc '"claim_id": 1,' $OUT) -ge 1 ]; then touch $TRIG; echo "$(date -u +%FT%T.%3NZ) hog triggered after first submit" >> $R/run.log; fi
  sleep 0.2
done
sleep ${TAIL:-5}
kill -0 $CP 2>/dev/null && echo "client alive at end" >> $R/run.log || { wait $CP; echo "client exited rc=$?" >> $R/run.log; }
kill $CP $SP $MP $HP 2>/dev/null; sleep 1
echo "$(date -u +%FT%T.%3NZ) end $TAG got $(grep -vc '"claim_id": 1,' $OUT)/$N (+$(grep -c '"claim_id": 1,' $OUT) b10 sentinel)" >> $R/run.log
python3 /root/mo/alloc/summ.py $OUT >> $R/run.log
grep -h "hog" $R/hog.log | tail -3 >> $R/run.log 2>/dev/null
cat $R/run.log
