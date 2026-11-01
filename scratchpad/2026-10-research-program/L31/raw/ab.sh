#!/bin/bash
# Build exp2 (adds candidate (c), NICE_EXP_TOP_NDIG), then the A/B with one binary and env
# switches, rounds interleaved; then the profile of the new variants; then lavapipe; then 1e17.
mkdir -p /root/src/exp2 && tar xzf /root/exp2-src.tgz -C /root/src/exp2
/root/build.sh exp2 gpu > /root/logs/build_exp2.log 2>&1
B=/root/bin/exp2/nice_common_gpu
L=/root/logs/ab; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
md5sum $B > $L/md5.txt
flags() { case $1 in base) echo "";; diff) echo "NICE_EXP_TOP_DIFF=1";; bar) echo "NICE_EXP_TOP_BARRETT=1";; ndig) echo "NICE_EXP_TOP_NDIG=1";;
  both) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; all) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac; }
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
run() { # V SIZE FIELDS BASE TAG [extra env]
  O=$L/$5
  nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $O.smi 2>&1 &
  SMI=$!
  env $(flags $1) $6 NICE_TEST_JOIN_FIELDS=$3 NICE_TEST_JOIN_SIZE=$2 NICE_TEST_JOIN_BASES=$4 NICE_TEST_JOIN_STARTS=$STARTS \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $O.log 2>&1
  echo "exit $?" >> $O.log
  kill $SMI
}
VS="base diff bar ndig both all"
for R in 1 2 3; do for V in $VS; do run $V 1e16 2 62 e16b62_${V}_r$R; done; done
for R in 1 2; do for V in $VS; do run $V 1e16 2 60 e16b60_${V}_r$R; done; done
touch /root/logs/ab16.done
for R in 1 2; do for V in base ndig all; do run $V 1e16 1 62 prof_${V}_b62_r$R NICE_EXP_GPU_PROFILE=1; done; done
touch /root/logs/prof2.done
nice -n 5 bash -c '/root/build.sh exp2 cubecl; /root/build.sh exp2 cubecl-spirv' > /root/logs/build_lvp2.log 2>&1
/root/lvp.sh
for R in 1 2; do for V in base all; do run $V 1e17 1 62 e17b62_${V}_r$R; done; done
touch /root/logs/ab.done
