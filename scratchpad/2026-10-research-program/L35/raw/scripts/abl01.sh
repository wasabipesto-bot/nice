#!/bin/bash
# abl.sh BIN: top-kernel timing (b62 1e17 first slice) per ablation bitmask.
BIN=$1; L=/root/l35/logs
cd /root/l35/src/B
for A in 0 1; do
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_EXP_TOP_FD_ABL=$A NICE_TEST_TOPFD_TIMING=${F:-62:7997740455941656911841:1e17} /root/l35/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 2>&1 | grep -E "TOPFD" | sed "s/^/ABL=$A /" | tee -a $L/abl_$BIN.log | grep "round=2" | sed -E 's/prefixes=.*consecutive/consecutive/'
done
