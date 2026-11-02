#!/bin/bash
# run2.sh NAME BIN BASES FIELDS SIZE [COMPARE]: run.sh, with NICE_EXP_TOP_FD recorded in the START line.
set -u
NAME=$1; BIN=$2; BASES=$3; N=$4; SIZE=$5; CMP=${6:-0}
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-} NICE_BUILD_SHA=test
STARTS=${STARTS:-57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568}
OUT=/root/l35/logs
cd /root/l35/src/${SRCD:-B}
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,clocks.mem,power.draw,power.limit,temperature.gpu,utilization.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 5; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
unset NICE_EXP_GPU_PROFILE NICE_EXP_TOP_FD_ABL
if [ "$CMP" = 1 ]; then export NICE_TEST_JOIN_COMPARE=1; else unset NICE_TEST_JOIN_COMPARE; fi
echo "START $NAME $(date -u +%T) bases=$BASES n=$N size=$SIZE cmp=$CMP bin=$BIN md5=$(md5sum /root/l35/bin/$BIN | cut -c1-8) NICE_EXP_TOP_FD=${NICE_EXP_TOP_FD:-unset}" > $OUT/$NAME.log
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES NICE_TEST_JOIN_STARTS=$STARTS \
  /root/l35/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
