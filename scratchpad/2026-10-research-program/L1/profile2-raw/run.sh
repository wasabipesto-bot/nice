#!/bin/bash
# One pass: run.sh NAME FIELDS SIZE PROF(0/1). Logs in /root/p2/NAME.{log,smi}.
set -u
NAME=$1; N=$2; SIZE=$3; PROF=$4; BIN=${BIN:-/root/nice_common_test}
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
OUT=/root/p2
cd /root/nice
( while true; do nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,power.limit,temperature.gpu,clocks_throttle_reasons.active --format=csv,noheader; sleep 15; done ) > $OUT/$NAME.smi 2>&1 &
SMI=$!
echo "START $NAME $(date -u +%T) prof=$PROF bin=$BIN bin_md5=$(md5sum $BIN | cut -c1-8) exp_env=$(env | grep ^NICE_EXP | tr "\n" " ") commit=$(git rev-parse --short HEAD)" > $OUT/$NAME.log
if [ "$PROF" = 1 ]; then export NICE_EXP_GPU_PROFILE=1; else unset NICE_EXP_GPU_PROFILE; fi
NICE_TEST_JOIN_FIELDS=$N NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 >> $OUT/$NAME.log 2>&1
echo "END $NAME $(date -u +%T) rc=$?" >> $OUT/$NAME.log
kill $SMI
