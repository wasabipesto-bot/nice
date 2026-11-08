#!/bin/bash
# chain_x.sh W [SKIP_TOPFD]: CUDA exactness of tree/binary W (tree ${SRCD:-S}): 1e14 compare at b57/60/62/64 first,
# the new count/probe-mode check test, CPU-reference join parity (incl. b10's 69, b50/b54), #240/#249's FD-vs-top-kernel
# device test with the sentinel (unless skipped), #235's certificate test, both dense fields, the whole b42 field, the
# host-side unit tests of join_plan, cubecl_join and join_check, and join_check's exhaustive magic test.
T=/root/l47/scripts/test.sh; R=/root/l47/scripts/run.sh; L=/root/l47/logs
W=$1; export SRCD=${SRCD:-S}
echo X_START $W $(date -u +%T)
NICE_TEST_JOIN_COMPARE=1 $R cmp_${W}_e14 $W 57,60,62,64 1 1e14
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${W}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|test result' $L/cmp_${W}_e14.log
$T x_${W}_counts $W cubecl_join::tests::cubecl_cuda_check_counts_match_the_cpu X=1
$T x_${W}_ref $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
[ -z "$2" ] && $T x_${W}_topfd $W cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_${W}_cert $W cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_${W}_dense58 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${W}_dense62 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${W}_whole $W cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
( cd /root/l47/src/$SRCD && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l47/bin/$W join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l47/bin/$W cubecl_join:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l47/bin/$W join_check:: ; \
  NICE_TEST_CHECK_EXHAUSTIVE=1 /root/l47/bin/$W --ignored --exact join_check::tests::magic_quotients_are_exact_everywhere --nocapture ) > $L/x_${W}_unit.log 2>&1
for f in counts ref topfd cert dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${W}_$f.log 2>/dev/null | head -1) $(grep -h '^END' $L/x_${W}_$f.log 2>/dev/null)"; done
grep -h 'test result' $L/x_${W}_unit.log
echo X_DONE $W $(date -u +%T)
touch $L/x_${W}.done
