#!/bin/bash
# CUDA exactness on the combined tree (binary both), then main's 1e14 counts. Sequential on the GPU.
T=/root/test.sh; L=/root/cmb
$T x_cert both cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_ref both cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_dense58 both cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_dense62 both cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
/root/run.sh both_cmp_e14 both 57,60,62,64 1 1e14 1
/root/run.sh main_cmp_e14 main 57,60,62,64 1 1e14 1
echo CHAIN_X_DONE $(date -u +%T) > $L/chainX.done
