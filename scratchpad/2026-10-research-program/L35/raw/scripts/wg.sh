#!/bin/bash
# wg.sh BIN: top-kernel timing per FD cube size.
BIN=$1; L=/root/l35/logs
cd /root/l35/src/B
for WG in 256 128 64; do
for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
  LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_EXP_TOP_FD_WG=$WG NICE_TEST_TOPFD_TIMING=$F /root/l35/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 2>&1 | grep -E "TOPFD" | sed "s/^/WG=$WG /" | tee -a $L/wg_$BIN.log | grep "round=2" | sed -E 's/prefixes=.*consecutive/consecutive/'
done; done
