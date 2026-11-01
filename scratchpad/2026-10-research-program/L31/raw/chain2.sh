#!/bin/bash
# After the 1e16 A/B and the new-variant profile: stop chain.sh's group (before its lavapipe
# build), then: dn (diff + ndig, no Barrett) A/B at b62 1e16 against base and all; dn's
# profile; 1e17 base/dn/all; then the lavapipe builds and lvp.sh.
while [ ! -f /root/logs/prof2.done ]; do sleep 5; done
PG=$(ps -eo pid,pgid,args | awk '$3=="/bin/bash" && $4=="/root/chain.sh" {print $2}' | head -1)
echo "chain.sh pgid=$PG"; [ -n "$PG" ] && kill -- -$PG
sleep 3; ps -eo pid,pgid,args | grep -E "[c]argo|[r]ustc|[n]ice_common" > /root/logs/chain2_after_kill.txt
B=/root/bin/exp2/nice_common_gpu
L=/root/logs/ab
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
flags() { case $1 in base) echo "";; dn) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";;
  all) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac; }
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
for R in 1 2 3; do for V in base dn all; do run $V 1e16 2 62 x16b62_${V}_r$R; done; done
for R in 1 2; do run dn 1e16 1 62 prof_dn_b62_r$R NICE_EXP_GPU_PROFILE=1; done
for R in 1 2; do for V in base dn all; do run $V 1e17 1 62 e17b62_${V}_r$R; done; done
touch /root/logs/ab17.done
/root/sass.sh2 2>/dev/null
nice -n 5 bash -c '/root/build.sh exp2 cubecl; /root/build.sh exp2 cubecl-spirv' > /root/logs/build_lvp2.log 2>&1
/root/lvp.sh
touch /root/logs/chain2.done
