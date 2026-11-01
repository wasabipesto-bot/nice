#!/bin/bash
# b62 1e16 A/B on CUDA (RTX 3060): main, pr, fix interleaved, 2 rounds, as L29's run.sh.
mkdir -p /root/logs/ab
for T in main pr fix; do cp /root/src/$T/target/release/deps/nice_common-cbd4e892b0124d04 /root/bin_${T}_gpu; done
md5sum /root/bin_*_gpu > /root/logs/ab/md5_gpu.txt
nvidia-smi -q -d POWER,CLOCK > /root/logs/ab/smi_info.txt 2>&1
run() {
  T=$1; TAG=$2
  L=/root/logs/ab/$TAG
  nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $L.smi 2>&1 &
  SMI=$!
  NICE_BUILD_SHA=test NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=62 \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    /root/bin_${T}_gpu --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L.log 2>&1
  echo "exit $?" >> $L.log
  kill $SMI
}
for R in 1 2; do
  for T in main pr fix; do run $T e16_${T}_r$R; done
done
touch /root/logs/ab.done
