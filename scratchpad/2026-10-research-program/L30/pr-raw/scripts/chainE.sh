#!/bin/bash
T=/root/test.sh
$T main_dense58 main cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T main_dense62 main cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
bash /root/regs.sh > /root/l30pr/regs.out 2>&1
echo CHAIN_E_DONE $(date -u +%T) > /root/l30pr/chainE.done
