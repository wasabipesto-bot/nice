#!/bin/bash
# A third 1e17 round (base, dn, all), after the lavapipe work, with the box otherwise idle.
while [ ! -f /root/logs/chain3.done ]; do sleep 10; done
B=/root/bin/exp2/nice_common_gpu
L=/root/logs/ab
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
flags() { case $1 in base) echo "";; dn) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";;
  all) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac; }
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for V in base dn all; do
  O=$L/e17b62_${V}_r3
  nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $O.smi 2>&1 &
  SMI=$!
  env $(flags $V) NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e17 NICE_TEST_JOIN_BASES=62 NICE_TEST_JOIN_STARTS=$STARTS \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $O.log 2>&1
  echo "exit $?" >> $O.log
  kill $SMI
done
touch /root/logs/x17.done
