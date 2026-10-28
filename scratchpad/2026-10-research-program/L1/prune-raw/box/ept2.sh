#!/bin/bash
# Extension: EPT 1 at b62/b64, and EPT 4/2/1 at b58/b60 (first 1e16 field), one round, with the prune.
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
BIN=$(cat /root/ab/bin_ept)
cd /root/ept
run() { ept=$1; bs=$2; b=${bs%%:*}
  echo "== $(date -u +%T) round=3 ept=$ept base=$b"
  NICE_EXP_JOIN_EPT=$ept NICE_TEST_JOIN_FIELDS=1 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=$b NICE_TEST_JOIN_STARTS=$bs \
    $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/ept_r3_e${ept}_b$b.log 2>&1
  grep -E "JOIN THROUGHPUT|panicked" /root/ab/ept_r3_e${ept}_b$b.log; }
run 1 62:7997740455941656911841
run 1 64:41242006262957161709568
for e in 4 2 1; do run $e 58:104400216587923470200; run $e 60:1366406074057412100454; done
echo EPT2_DONE $(date -u +%T)
