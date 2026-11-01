#!/bin/bash
# A/B, one binary, env switches; rounds interleaved base, diff, bar, both. nvidia-smi every 5 s.
B=/root/bin/exp/nice_common_gpu
L=/root/logs/ab; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
run() { # V SIZE FIELDS BASE TAG
  V=$1; case $V in base) F="";; diff) F="NICE_EXP_TOP_DIFF=1";; bar) F="NICE_EXP_TOP_BARRETT=1";; both) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; esac
  O=$L/$5
  nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $O.smi 2>&1 &
  SMI=$!
  env $F NICE_TEST_JOIN_FIELDS=$3 NICE_TEST_JOIN_SIZE=$2 NICE_TEST_JOIN_BASES=$4 \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $O.log 2>&1
  echo "exit $?" >> $O.log
  kill $SMI
}
for R in 1 2 3; do for V in base diff bar both; do run $V 1e16 2 62 e16b62_${V}_r$R; done; done
for R in 1 2 3; do for V in base diff bar both; do run $V 1e16 2 60 e16b60_${V}_r$R; done; done
touch /root/logs/ab16.done
for R in 1 2; do for V in base diff bar both; do run $V 1e17 1 62 e17b62_${V}_r$R; done; done
touch /root/logs/ab.done
