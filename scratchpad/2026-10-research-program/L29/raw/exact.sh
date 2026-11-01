#!/bin/bash
# exact.sh TREE: the CUDA exactness tests on /root/bin/TREE.
T=${1:-pr}
B=/root/bin/$T/nice_common_test
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
cd /root/src/$T
run() { # NAME TEST [VAR=VAL...]
  local name=$1 test=$2; shift 2
  echo "== $(date -u +%T) $name"
  env "$@" $B --ignored --exact $test --nocapture --test-threads 1 > /root/logs/x_${T}_$name.log 2>&1
  echo "exit $? $(date -u +%T)"
}
run cert_cuda cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu
run parity_cuda cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference
run whole_cuda cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field
run dense58 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=64
run dense64 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=8 NICE_TEST_JOIN_DENSE_FIELD=64:41242006262957161709568:1e16
run compare cubecl_join::tests::cubecl_cuda_join_throughput_fixed_fields NICE_TEST_JOIN_COMPARE=1 NICE_TEST_JOIN_FIELDS=2 NICE_TEST_JOIN_BASES=58,60,62,64 \
  NICE_TEST_JOIN_STARTS=58:104400216587923470200,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568
echo EXACT_DONE $(date -u +%T)
