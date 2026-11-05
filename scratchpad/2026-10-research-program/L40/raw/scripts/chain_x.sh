#!/bin/bash
# chain_x.sh W: CUDA exactness of tree/binary W: CPU-reference join parity (incl. b50/b54), #240's FD-vs-top-kernel
# device test (on the record), #235's certificate test, both dense fields, the whole b42 field, the 1e14 compare at
# b57/60/62/64, and the host-side unit tests of join_plan and cubecl_join.
T=/root/l40/test.sh; R=/root/l40/run.sh; L=/root/l40/logs
W=$1; export SRCD=$W
echo X_START $W $(date -u +%T)
$T x_${W}_ref $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_${W}_topfd $W cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_${W}_cert $W cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_${W}_dense58 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${W}_dense62 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${W}_whole $W cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
$R cmp_${W}_e14 $W 57,60,62,64 1 1e14 1
( cd /root/l40/src/$W && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l40/bin/$W join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l40/bin/$W cubecl_join:: ) > $L/x_${W}_unit.log 2>&1
for f in ref topfd cert dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${W}_$f.log | head -1) $(grep -h '^END' $L/x_${W}_$f.log)"; done
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${W}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|test result' $L/cmp_${W}_e14.log
grep -h 'test result' $L/x_${W}_unit.log
echo X_DONE $W $(date -u +%T)
touch $L/x_${W}.done
