#!/bin/bash
# cudadump.sh: CUDA source of the join kernel via CUBECL_DEBUG_LOG (b62 1e14, one field), tail off and on; then ptxas resource usage.
L=/root/pad
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
cd /root/padsrc
for t in off tail; do
  E=""; [ $t = tail ] && E="NICE_EXP_JOIN_TAIL=1"
  rm -f $L/cuda_$t.log
  env $E CUBECL_DEBUG_LOG=$L/cuda_$t.log NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=62 \
    $L/pad --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L/cudadump_$t.out 2>&1
done
echo CUDADUMP_DONE $(date -u +%T) > $L/cudadump.done
