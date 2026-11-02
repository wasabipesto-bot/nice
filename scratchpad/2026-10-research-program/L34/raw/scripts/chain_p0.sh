#!/bin/bash
# The PR tree with TRANSPOSE_MIN = 0 (every batch transposed; a one-line edit of 1298ce7), so the CUDA parity tests'
# small windows exercise the transposed path too. Built at nice 19 once the SPIR-V rebuild is done; tests run after
# the A/B.
L=/root/l34/logs; S=/root/l34; T=$S/test.sh
until [ -e $L/p192t.done ]; do sleep 10; done
rm -rf /root/l34/src/P0; mkdir -p /root/l34/src/P0; tar xzf /root/l34/PR0.tgz -C /root/l34/src/P0
grep -n "^pub const TRANSPOSE_MIN" /root/l34/src/P0/common/src/cubecl_join.rs
J=4 nice -n 19 $S/build.sh P0 P0 gpu || exit 1
until [ -e $L/prab.done ]; do sleep 10; done
$T p0_ref P0 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T p0_dense58 P0 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T p0_dense62 P0 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T p0_whole P0 cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
echo P0_DONE $(date -u +%T) > $L/p0.done
