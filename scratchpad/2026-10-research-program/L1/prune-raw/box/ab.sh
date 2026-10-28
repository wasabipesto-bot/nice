#!/bin/bash
# Fixed-field throughput A/B, interleaved A B A B A B (run under nohup).
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
for r in 1 2 3; do
  for t in main prune; do
    BIN=$(cat /root/ab/bin_$t)
    cd /root/$t
    echo "== $(date -u +%T) round=$r tree=$t commit=$(git rev-parse --short HEAD)"
    NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e16 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
      $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/thr_r${r}_$t.log 2>&1
    grep -E "JOIN THROUGHPUT|panicked|test result" /root/ab/thr_r${r}_$t.log
  done
done
echo "AB_DONE $(date -u +%T)"
