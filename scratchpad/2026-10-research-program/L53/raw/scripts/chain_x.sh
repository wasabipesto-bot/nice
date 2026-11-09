#!/bin/bash
# chain_x.sh W: CUDA exactness of binary W (tree ${SRCD:-C}), L46's list: 1e14 compare at b57/60/62/64, CPU-reference
# join parity, the FD-vs-top-kernel device test (with #249's sentinel), the certificate test, both dense fields, the
# whole b42 field, and the host-side unit tests of join_plan and cubecl_join (incl. sorted_layer_and_segments_...).
T=/root/l53/test.sh; R=/root/l53/run.sh; L=/root/l53/logs
W=$1; export SRCD=${SRCD:-C}
echo X_START $W $(date -u +%T)
NICE_TEST_JOIN_COMPARE=1 $R cmp_${W}_e14 $W 57,60,62,64 1 1e14
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${W}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|test result' $L/cmp_${W}_e14.log
$T x_${W}_ref $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_${W}_topfd $W cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_${W}_cert $W cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_${W}_dense58 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${W}_dense62 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${W}_whole $W cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
( cd /root/l53/src/$SRCD && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l53/bin/$W join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l53/bin/$W cubecl_join:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l53/bin/$W --exact cubecl_join::tests::sorted_layer_and_segments_match_the_cpu_buckets --nocapture ) > $L/x_${W}_unit.log 2>&1
for f in ref topfd cert dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${W}_$f.log 2>/dev/null | head -1) $(grep -h '^END' $L/x_${W}_$f.log 2>/dev/null)"; done
grep -h 'test result\|buckets agree' $L/x_${W}_unit.log
echo X_DONE $W $(date -u +%T)
touch $L/x_${W}.done
