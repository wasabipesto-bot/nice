#!/bin/bash
# CUDA exactness on B (and the host digit-count test), then the 1e14 compare runs of B and A. Sequential on the GPU.
T=/root/l33p/test.sh; R=/root/l33p/run.sh; L=/root/l33p/logs
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
( cd /root/l33p/src/B; /root/l33p/bin/B --exact cubecl_join::tests::ndig_fast_constants_give_the_digit_count --nocapture; echo "exit $?" ) > $L/host_ndig.log 2>&1
$T x_cert B cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_ref B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_dense58 B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_dense62 B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
until [ -e $L/a.done ]; do sleep 10; done
$R B_cmp_e14 B 57,60,62,64 1 1e14 1
$R A_cmp_e14 A 57,60,62,64 1 1e14 1
( cd /root/l33p/src/B; /root/l33p/bin/B cubecl_join:: --test-threads 4; echo "exit $?" ) > $L/host_cubecl_join.log 2>&1
$T x_whole B cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
echo CHAIN_X_DONE $(date -u +%T) > $L/x.done
