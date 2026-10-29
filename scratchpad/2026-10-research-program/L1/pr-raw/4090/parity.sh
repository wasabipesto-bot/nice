#!/bin/bash
# Extra exactness on the prune tree 26a8b15: the CUDA join parity tests (CPU reference, dense b58 1e15 on 64
# partitions, whole b42 field), then the dense test on a b64 1e16 A/B field (the 3080's overrun-limit flag).
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
BIN=$(cat /root/ab/bin_prune); cd /root/prune
echo "== $(date -u +%T) parity tests, $(git rev-parse --short HEAD)"
NICE_TEST_JOIN_DENSE=64 NICE_TEST_JOIN_FULL_FIELD=1 timeout 420 $BIN --ignored cubecl_cuda_join --skip throughput --test-threads 1 --nocapture 2>&1 | grep -vE "^\s*$" | tail -40
echo "== $(date -u +%T) dense test on b64 [41242006262957161709568, +1e16), 64 partitions"
NICE_TEST_JOIN_DENSE=64 NICE_TEST_JOIN_DENSE_FIELD=64:41242006262957161709568:1e16 timeout 300 $BIN --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture 2>&1 | grep -vE "^\s*$" | tail -12
echo "PARITY_DONE $(date -u +%T)"
