#!/bin/bash
# CUDA exactness chain for binary $1 (default pr2). Sequential.
B=${1:-pr2}
T=/root/test.sh
$T ${B}_ref $B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T ${B}_dense58 $B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T ${B}_dense62 $B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T ${B}_full42 $B cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
/root/run.sh ${B}_cmp_e14 $B 57,60,62,64 1 1e14 1
echo CHAIN_A_DONE $(date -u +%T) > /root/l30pr/chainA_$B.done
