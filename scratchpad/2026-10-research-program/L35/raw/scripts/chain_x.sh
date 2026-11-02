#!/bin/bash
# chain_x.sh BIN: build done; FD exactness test, regs, top timing at b62 1e17 and 1e16.
BIN=$1; T=/root/l35/test.sh; L=/root/l35/logs
$T x_fd_$BIN $BIN cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel X=1
grep -E "top_fd = top_kernel|test result|panicked" $L/x_fd_$BIN.log
/root/l35/regs.sh $BIN $BIN 2>&1 | grep -E "registers"
cd /root/l35/src/B
for F in 62:7997740455941656911841:1e17 62:7997740455941656911841:1e16 60:1366406074057412100454:1e16; do
LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_TEST_TOPFD_TIMING=$F /root/l35/bin/$BIN --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 2>&1 | grep -E "TOPFD" | tee -a $L/timing_$BIN.log | grep "round=2"
done
