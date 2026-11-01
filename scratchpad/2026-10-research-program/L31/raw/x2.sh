#!/bin/bash
# CUDA exactness of the exp2 binary's new switches (after the 1e17 A/B, beside the lavapipe builds).
while [ ! -f /root/logs/ab17.done ]; do sleep 10; done
B=/root/bin/exp2/nice_common_gpu
L=/root/logs/x2; mkdir -p $L
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH NICE_BUILD_SHA=test
md5sum $B > $L/md5.txt
T=cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu
for V in all ndig dn; do
  case $V in ndig) F="NICE_EXP_TOP_NDIG=1";; dn) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";; all) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac
  ( date -u; env $F $B --ignored --exact $T --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/cert_$V.log 2>&1
done
for V in all dn; do
  case $V in dn) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_NDIG=1";; all) F="NICE_EXP_TOP_DIFF=1 NICE_EXP_TOP_BARRETT=1 NICE_EXP_TOP_NDIG=1";; esac
  ( date -u; env $F $B --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/parity_$V.log 2>&1
done
touch /root/logs/x2.done
