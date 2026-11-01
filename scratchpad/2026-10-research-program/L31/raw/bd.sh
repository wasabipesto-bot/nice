#!/bin/bash
# Breakdown: NICE_EXP_TOP_STAGE 1..7 and 0 (whole), plus the candidates at stage 0,
# with the per-phase profile (topk = top_kernel alone). 1e16, 1 field: b62 2 rounds, b60 1 round.
B=/root/bin/exp/nice_common_gpu
L=/root/logs/bd; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
for R in 1 2; do
 for V in s0 s1 s2 s3 s4 s5 s6 s7 diff bar both; do
  case $V in s*) F="NICE_EXP_TOP_STAGE=${V#s}";; diff) F="NICE_EXP_TOP_DIFF=1";; bar) F="NICE_EXP_TOP_BARRETT=1";; both) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; esac
  BASES="62 60"; [ $R = 2 ] && BASES=62
  for BASE in $BASES; do
   env $F NICE_EXP_GPU_PROFILE=1 NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=$BASE \
    NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/${V}_b${BASE}_r$R.log 2>&1
   echo "exit $?" >> $L/${V}_b${BASE}_r$R.log
  done
 done
done
touch /root/logs/bd.done
