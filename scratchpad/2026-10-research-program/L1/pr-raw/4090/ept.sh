#!/bin/bash
# EPT sweep with the prune (ept tree 6e4e895): EPT 2,3,4,6 at b58/60/62/64, first 1e16 field after a 1e14
# warm-up, 3 interleaved rounds (2 3 4 6, 2 3 4 6, 2 3 4 6). Pauses before a run while /root/ab/PAUSE exists;
# skips runs whose log already has a result (restartable).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
BIN=$(cat /root/ab/bin_ept)
cd /root/ept
for r in 1 2 3; do
  for ept in 2 3 4 6; do
    for bs in 58:104400216587923470200 60:1366406074057412100454 62:7997740455941656911841 64:41242006262957161709568; do
      b=${bs%%:*}; L=/root/ab/ept_r${r}_e${ept}_b$b.log
      grep -q "JOIN THROUGHPUT" $L 2>/dev/null && continue
      while [ -e /root/ab/PAUSE ]; do sleep 5; done
      echo "== $(date -u +%T) round=$r ept=$ept base=$b"
      NICE_EXP_JOIN_EPT=$ept NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=$b NICE_TEST_JOIN_STARTS=$bs \
        $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > $L 2>&1
      grep -E "JOIN THROUGHPUT|panicked" $L
    done
  done
done
echo "EPT_DONE $(date -u +%T)"
