#!/bin/bash
# chain_x.sh: CUDA exactness of all5 (S), then the 1e14 compare on S and main (M).
T=/root/l36/test.sh; R=/root/l36/run.sh; L=/root/l36/logs
until [ -e $L/S.built ]; do sleep 10; done
echo X_START $(date -u +%T)
$T x_ref S cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_fd S cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_cert S cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_dense58 S cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_dense62 S cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_whole S cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$R cmp_S_e14 S 57,60,62,64 1 1e14 1
until [ -e $L/M.built ]; do sleep 10; done
SRCD=M $R cmp_M_e14 M 57,60,62,64 1 1e14 1
echo CUDA_X_DONE $(date -u +%T) > $L/cudax.done
