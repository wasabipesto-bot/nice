#!/bin/bash
# After the 1e17 A/B: stop chain2's group (before its SASS/lavapipe steps), then b60 1e16
# base vs dn (2 rounds, GPU and host otherwise idle), then the CUDA exactness of the new
# switches beside the SASS counts and the lavapipe builds, then lvp.sh.
while [ ! -f /root/logs/ab17.done ]; do sleep 5; done
PG=$(ps -eo pid,pgid,args | awk '$3=="/bin/bash" && $4=="/root/chain2.sh" {print $2}' | head -1)
echo "chain2.sh pgid=$PG"; [ -n "$PG" ] && kill -- -$PG
sleep 3; ps -eo pid,pgid,args | grep -E "[c]argo|[r]ustc|[n]ice_common|[n]vcc" > /root/logs/chain3_after_kill.txt
B=/root/bin/exp2/nice_common_gpu
L=/root/logs/ab
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
flags() { case $1 in base) echo "";; dn) echo "NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";; esac; }
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
run() {
  O=$L/$5
  nvidia-smi --query-gpu=timestamp,clocks.sm,power.draw,temperature.gpu,clocks_throttle_reasons.active,memory.used --format=csv -l 5 > $O.smi 2>&1 &
  SMI=$!
  env $(flags $1) NICE_TEST_JOIN_FIELDS=$3 NICE_TEST_JOIN_SIZE=$2 NICE_TEST_JOIN_BASES=$4 NICE_TEST_JOIN_STARTS=$STARTS \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $O.log 2>&1
  echo "exit $?" >> $O.log
  kill $SMI
}
for R in 1 2; do for V in base dn; do run $V 1e16 2 60 x16b60_${V}_r$R; done; done
touch /root/logs/x16b60.done
/root/x2.sh > /root/logs/x2.log 2>&1 &
/root/sass.sh2 > /root/logs/sass2.log 2>&1
nice -n 5 bash -c '/root/build.sh exp2 cubecl; /root/build.sh exp2 cubecl-spirv' > /root/logs/build_lvp2.log 2>&1
wait
/root/lvp.sh
touch /root/logs/chain3.done
