#!/bin/bash
# chain_x.sh W [TAG]: CUDA exactness of binary W: CPU-reference join parity (incl. b50/b54), the FD-vs-top-kernel device
# test, the certificate test, both dense fields, the whole b42 field, the 1e14 compare at b57/60/62/64 (join = stride),
# and the host-side unit tests of join_plan and cubecl_join.
T=/root/l54/test.sh; R=/root/l54/run.sh; L=/root/l54/logs
W=$1; TAG=${2:-$W}; export SRCD=${SRCD:-P}
echo X_START $TAG $(date -u +%T)
$T x_${TAG}_ref $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
$T x_${TAG}_topfd $W cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
$T x_${TAG}_cert $W cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu X=1
$T x_${TAG}_dense58 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=32
$T x_${TAG}_dense62 $W cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field NICE_TEST_JOIN_DENSE=4 NICE_TEST_JOIN_DENSE_FIELD=62:7997740455941656911841:1e16
$T x_${TAG}_whole $W cubecl_join::tests::cubecl_cuda_join_matches_the_reference_on_a_whole_field NICE_TEST_JOIN_FULL_FIELD=1
NICE_TEST_JOIN_COMPARE=1 STARTS=57:28151599893042801193,60:1366406074057412100454,62:7997740455941656911841,64:41242006262957161709568 $R cmp_${TAG}_e14 $W 57,60,62,64 1 1e14
( cd /root/l54/src/$SRCD && LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l54/bin/$W join_plan:: ; \
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test /root/l54/bin/$W cubecl_join:: ) > $L/x_${TAG}_unit.log 2>&1
for f in ref topfd cert dense58 dense62 whole; do echo "$f: $(grep -h 'test result' $L/x_${TAG}_$f.log | head -1) $(grep -h '^END' $L/x_${TAG}_$f.log)"; done
grep -o 'base=[0-9]* fields.*found=[0-9]*' $L/cmp_${TAG}_e14.log | sed 's/rate.*survivors/survivors/'; grep -h 'STRIDE\|stride\|test result' $L/cmp_${TAG}_e14.log | head -12
grep -h 'test result' $L/x_${TAG}_unit.log
echo X_DONE $TAG $(date -u +%T)
touch $L/x_${TAG}.done
