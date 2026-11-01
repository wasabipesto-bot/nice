#!/bin/bash
# CUDA source of TopKernel per variant (CUBECL_DEBUG_LOG), compiled with nvcc to SASS (sm_86): static counts.
L=/root/logs/sass; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
B=/root/bin/exp/nice_common_gpu
for V in base diff bar both; do
  case $V in base) F="";; diff) F="NICE_EXP_TOP_DIFF=1";; bar) F="NICE_EXP_TOP_BARRETT=1";; both) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; esac
  rm -f $L/$V.dump
  env $F CUBECL_DEBUG_LOG=$L/$V.dump NICE_TEST_JOIN_FIELDS=0 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62 \
    $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/$V.log 2>&1
done
touch /root/logs/sass.done
