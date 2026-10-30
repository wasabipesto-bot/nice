#!/bin/bash
# run.sh BIN TAG SIZE FIELDS [VAR=VAL ...]: the join throughput harness on
# bases 58/60/62/64 at the A/B starts, with nvidia-smi sampled every 15 s.
# BIN is a directory holding nice_common_test (see stage.sh).
BIN=$1; TAG=$2; SIZE=$3; FIELDS=$4; shift 4
L=/root/logs/$TAG
nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 15 > $L.smi 2>&1 &
SMI=$!
env "$@" NICE_TEST_JOIN_FIELDS=$FIELDS NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=58,60,62,64 \
  NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
  $BIN/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L.log 2>&1
echo "exit $?" >> $L.log
kill $SMI
