#!/bin/bash
# chain_x.sh W [TAG]: CUDA exactness of binary W (tree W) under the caller's env (NICE_EXP_JOIN_PF): CPU-reference join
# parity (incl. b50/b54, the b57 frontier/clipped partitions), #240's FD-vs-top-kernel device test, #235's certificate
# test, both dense fields, the whole b42 field, the 1e14 compare at b57/60/62/64. Logs x_TAG_*, cmp_TAG_e14.
T=/root/l41/test.sh; R=/root/l41/run.sh; L=/root/l41/logs
W=$1; TAG=${2:-$W}; export SRCD=$W
echo X_START $TAG $(date -u +%T) pf=${NICE_EXP_JOIN_PF:-unset}
$T x_${TAG}_ref $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_${TAG}_topfd $W cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_${TAG}_cert $W cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_${TAG}_dense58 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${TAG}_dense62 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${TAG}_whole $W cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$R cmp_${TAG}_e14 $W 57,60,62,64 1 1e14 1
for f in ref topfd cert dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${TAG}_$f.log | head -1) $(grep -h '^END' $L/x_${TAG}_$f.log)"; done
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${TAG}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|test result' $L/cmp_${TAG}_e14.log
echo X_DONE $TAG $(date -u +%T)
touch $L/x_${TAG}.done
