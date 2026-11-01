#!/bin/bash
# Exactness on both (CUDA): the CPU-reference test, then 1e14 at b57/60/62/64 with NICE_TEST_JOIN_COMPARE=1 on both and main.
L=/root/sc
until [ -e $L/testbin_both.done ]; do sleep 10; done
/root/test.sh x_ref both cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference
until [ -x $L/main ]; do sleep 10; done
/root/run.sh both_cmp_e14 both 57,60,62,64 1 1e14 1
/root/run.sh main_cmp_e14 main 57,60,62,64 1 1e14 1
echo CHAIN_X_DONE $(date -u +%T) > $L/chainX.done
