#!/bin/bash
# Stack high-water mark of the CubeCL device-server thread (DSD-*), which
# compiles every kernel, measured with a 256 MiB stack via gdb at exit.
# $1 = tree, $2 = which (cert|parity|segv)
T=$1; W=$2
cd /root/src/$T
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_BUILD_SHA=test
BIN=$(cat /root/logs/${T}_spirv_bin.path)
L=/root/logs
case $W in
  cert) TEST=cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu ;;
  parity) TEST=cubecl_join::tests::cubecl_join_matches_the_cpu_reference ;;
  segv) TEST=cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu ;;
esac
if [ $W = segv ]; then
  ( date -u; CUBECL_DEBUG_LOG=$L/${T}_${W}_spv.log NICE_TEST_CERT_SAMPLES=200 timeout 1800 gdb -batch -x /root/gdb_segv.cmd --args $BIN --ignored --nocapture --exact $TEST --test-threads 1 2>&1 | grep -v "^\[New Thread\|^\[Thread .* exited\|libthread_db"; date -u ) > $L/${T}_${W}_gdb.log 2>&1
else
  ( date -u; RUST_MIN_STACK=268435456 CUBECL_DEBUG_LOG=$L/${T}_${W}_spv.log NICE_TEST_CERT_SAMPLES=200 timeout 2400 gdb -batch -x /root/gdb_exit.cmd --args $BIN --ignored --nocapture --exact $TEST --test-threads 1 2>&1 | grep -v "^\[New Thread\|^\[Thread .* exited\|libthread_db"; date -u ) > $L/${T}_${W}_gdb.log 2>&1
fi
gzip -f $L/${T}_${W}_spv.log 2>/dev/null
touch $L/${T}_${W}.done
