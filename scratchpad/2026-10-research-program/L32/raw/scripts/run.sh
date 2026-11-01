#!/bin/bash
# run.sh NAME BIN BASES FIELDS SIZE CMP [VAR=VAL ...]: throughput harness (one untimed 1e14 warm-up field per base), logs /root/pad/NAME.{log,smi}
set -u
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5; CMP=$6; shift 6
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
STARTS=${STARTS:-57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568}
OUT=/root/pad
cd /root/padsrc
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
unset NICE_EXP_GPU_PROFILE NICE_EXP_JOIN_TAIL NICE_EXP_JOIN_EPT
if [ "$CMP" = 1 ]; then export NICE_TEST_JOIN_COMPARE=1; else unset NICE_TEST_JOIN_COMPARE; fi
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE cmp=$CMP bin=$BIN md5=$(md5sum /root/pad/$BIN | cut -c1-8) env=$*" > $OUT/$NAME.log
env "$@" NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  /root/pad/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
