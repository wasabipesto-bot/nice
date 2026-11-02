#!/bin/bash
# chain_x.sh G: CUDA exactness of F (the final tree) with the transposed AND on (group G), then 1e14 compare on vs off at b57/60/62/64.
G=${1:-8}
T=/root/l34/test.sh; R=/root/l34/run.sh; L=/root/l34/logs
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
ON="NICE_EXP_JOIN_TRANSPOSE=1 NICE_EXP_JOIN_TRANSPOSE_G=$G"
$T x_ref_g$G F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference $ON
$T x_dense58_g$G F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field $ON NICE_TEST_JOIN_DENSE=32
$T x_dense62_g$G F cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field $ON NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_whole_g$G F cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field $ON NICE_TEST_JOIN_FULL_FIELD=1
env $ON $R cmp_on_g${G}_e14 F 57,60,62,64 1 1e14 1
$R cmp_off_e14 F 57,60,62,64 1 1e14 1
echo CHAIN_X_DONE $(date -u +%T) > $L/x_g$G.done
