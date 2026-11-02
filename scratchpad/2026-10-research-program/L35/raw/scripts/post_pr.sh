#!/bin/bash
# post_pr.sh: after the PR A/B: the timing test on P (kernel alone), registers of P per base.
L=/root/l35/logs; BIN=/root/l35/bin
until [ -e $L/prab.done ]; do sleep 10; done
cd /root/l35/src/P
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16 58:130525216587923470200:1e16 64:41242006262957161709568:1e16; do
  NICE_TEST_TOPFD_TIMING=$F $BIN/P --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 2>&1 | grep TOPFD >> $L/p_timing.log
done
sed -e 's/^for FD in 0 1 2; do/for FD in 0; do/' /root/l35/regs.sh > /root/l35/regs_p.sh; chmod +x /root/l35/regs_p.sh
for B in 62 60 58 64; do SRCD=P BASES=$B /root/l35/regs_p.sh P P_b$B > $L/p_regs_b$B.log 2>&1; done
echo PPOST_DONE $(date -u +%T) > $L/ppost.done
