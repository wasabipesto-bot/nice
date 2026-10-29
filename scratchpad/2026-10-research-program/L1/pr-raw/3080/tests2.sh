#!/bin/bash
# The GPU and slow exactness checks on the PR tree's final head (host tests ran earlier, hosttests.log).
source ~/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
BIN=/root/bins/pr/nice_common_test
cd /root/pr
echo "== $(date -u +%T) PR $(git log --oneline -1)"
echo "== $(date -u +%T) CUDA join vs the CPU reference; dense b58 1e15 on 32 partitions"
NICE_TEST_JOIN_DENSE=32 $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --test-threads 1 --nocapture 2>&1 | grep -E "test result|panicked|differ" 
NICE_TEST_JOIN_DENSE=32 $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --test-threads 1 --nocapture 2>&1 | grep -E "^b|overran|test result|panicked|differ"
echo "== $(date -u +%T) dense-field test at b64 1e16 (the A/B field), 8 partitions"
NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=64:41242006262957161709568:1e16 $BIN --ignored --exact \
  cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture --test-threads 1 2>&1 | grep -E "^b|overran|panicked|test result|differ"
echo "== $(date -u +%T) CPU join vs reference on production fields (2 partitions each)"
NICE_TEST_CPU_JOIN_REF=2 $BIN --ignored --exact cpu_join::tests::cpu_join_matches_the_reference_on_production_fields --nocapture 2>&1 | grep -E "^b|test result|panicked"
echo "== $(date -u +%T) throughput harness with NICE_TEST_JOIN_COMPARE=1 (2 fields of 1e14 per base, A/B starts)"
NICE_TEST_JOIN_COMPARE=1 NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_BASES=58,60,62,64 NICE_TEST_JOIN_STARTS=$STARTS \
  $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields --nocapture --test-threads 1 2>&1 | grep -E "JOIN THROUGHPUT|STRIDE|test result|panicked|differs"
echo TESTS2_DONE $(date -u +%T)
