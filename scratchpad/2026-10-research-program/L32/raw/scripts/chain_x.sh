#!/bin/bash
# Exactness with the tail on (CUDA), then 1e14 COMPARE counts tail / off / base.
T=/root/test.sh; L=/root/pad
until [ -e $L/pad.done ]; do sleep 10; done
$T x_ref_tail pad cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_JOIN_TAIL=1
$T x_dense58_tail pad cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_EXP_JOIN_TAIL=1 NICE_TEST_JOIN_DENSE=32
$T x_dense62_tail pad cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_EXP_JOIN_TAIL=1 NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
/root/run.sh cmp_e14_tail pad 57,60,62,64 1 1e14 1 NICE_EXP_JOIN_TAIL=1
/root/run.sh cmp_e14_base base 57,60,62,64 1 1e14 1
$T x_ref_ept1tail pad cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_JOIN_TAIL=1 NICE_EXP_JOIN_EPT=1
$T x_ref_ept1 pad cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference NICE_EXP_JOIN_EPT=1
echo CHAIN_X_DONE $(date -u +%T) > $L/chainX.done
