#!/bin/bash
# Exactness on this card: the throughput harness with NICE_TEST_JOIN_COMPARE=1 (2 fields of 1e14 per base at the
# A/B starts; the join against the stride pipeline). Usage: compare.sh <tree>
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
T=${1:-prune}
BIN=$(cat /root/ab/bin_$T)
cd /root/$T
echo "== $(date -u +%T) compare, tree $T $(git rev-parse --short HEAD)"
NICE_TEST_JOIN_COMPARE=1 NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_SIZE=1e14 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 > /root/ab/compare_$T.log 2>&1
echo "exit $?"
grep -E "JOIN THROUGHPUT|STRIDE|test result|panicked|differs" /root/ab/compare_$T.log
echo "COMPARE_DONE $(date -u +%T)"
