#!/bin/bash
# EPT sweep on the prune (b62, b64 first field, 1e16), 2 interleaved rounds.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
BIN=$(cat /root/ab/bin_ept)
cd /root/ept
for r in 1 2; do
  for ept in 2 3 4 5; do
    for bs in 62:7997740455941656911841 64:41242006262957161709568; do
      b=${bs%%:*}
      echo "== $(date -u +%T) round=$r ept=$ept base=$b"
      NICE_EXP_JOIN_EPT=$ept NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=$b NICE_TEST_JOIN_STARTS=$bs \
        $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/ept_r${r}_e${ept}_b$b.log 2>&1
      grep -E "JOIN THROUGHPUT|panicked" /root/ab/ept_r${r}_e${ept}_b$b.log
    done
  done
done
echo "EPT_DONE $(date -u +%T)"
