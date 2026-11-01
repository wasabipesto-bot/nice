#!/bin/bash
# run.sh TREE TAG SIZE FIELDS BASES: the join throughput harness at the A/B
# starts, with nvidia-smi sampled every 5 s.
T=$1; TAG=$2; SIZE=$3; FIELDS=$4; BASES=$5
L=/root/logs/$TAG
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $L.smi 2>&1 &
SMI=$!
NICE_TEST_JOIN_FIELDS=$FIELDS NICE_TEST_JOIN_SIZE=$SIZE NICE_TEST_JOIN_BASES=$BASES \
  NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
  /root/bin/$T/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L.log 2>&1
echo "exit $?" >> $L.log
kill $SMI
