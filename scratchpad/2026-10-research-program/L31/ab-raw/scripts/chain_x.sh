#!/bin/bash
# CUDA exactness on B, then the 1e14 compare runs of B and A. Sequential on the GPU.
T=/root/l31b/test.sh; R=/root/l31b/run.sh; L=/root/l31b/logs
$T x_cert B cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_ref B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_dense58 B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_dense62 B cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$R B_cmp_e14 B 57,60,62,64 1 1e14 1
$R A_cmp_e14 A 57,60,62,64 1 1e14 1
echo CHAIN_X_DONE $(date -u +%T) > $L/chainX.done
