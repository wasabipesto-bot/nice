#!/bin/bash
# CUDA exactness: the certificate test under each switch, then join parity with both.
B=/root/bin/exp/nice_common_gpu
L=/root/logs/x; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
md5sum $B > $L/md5.txt
T=cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu
for V in diff bar both; do
  case $V in none) F="";; diff) F="NICE_EXP_TOP_DIFF=1";; bar) F="NICE_EXP_TOP_BARRETT=1";; both) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1";; esac
  ( date -u; env $F $B --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/cert_$V.log 2>&1
done
( date -u; env NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/parity_both.log 2>&1
touch /root/logs/exact.done
