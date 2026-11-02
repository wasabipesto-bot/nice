#!/bin/bash
# post.sh: after the A/B and NiceMark: kernel timings (plan slots; 20 slots = what persistence approaches), b64, registers per base.
L=/root/l35/logs; BIN=/root/l35/bin
until [ -e $L/chainNM.done ]; do sleep 10; done
cd /root/l35/src/B
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
tm() { # tm NAME FIELD [SLOTS]
  if [ -n "${3:-}" ]; then export NICE_TEST_TOPFD_SLOTS=$3; else unset NICE_TEST_TOPFD_SLOTS; fi
  NICE_TEST_TOPFD_TIMING=$2 $BIN/F --ignored --exact cubecl_join::tests::cubecl_cuda_top_fd_timing --nocapture --test-threads 1 > $L/tm_$1.log 2>&1
}
tm e17_b62 62:7997740455941656911841:1e17
tm e17_b62_s20 62:7997740455941656911841:1e17 20
tm e16_b60 60:1366406074057412100454:1e16
tm e16_b60_s20 60:1366406074057412100454:1e16 20
tm e16_b64 64:41242006262957161709568:1e16
tm e16_b64_s20 64:41242006262957161709568:1e16 20
for A in 1; do NICE_EXP_TOP_FD_ABL=$A tm e17_b62_abl$A 62:7997740455941656911841:1e17; done
unset NICE_TEST_TOPFD_SLOTS
for B in 62 60 64 57; do BASES=$B /root/l35/regs.sh F F_b$B > $L/regs_F_b$B.log 2>&1; done
echo POST_DONE $(date -u +%T) > $L/post.done
