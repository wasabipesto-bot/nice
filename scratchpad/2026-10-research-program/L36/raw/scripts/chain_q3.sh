#!/bin/bash
# chain_q3.sh: after chain_x2, a third quiet ablation round (named _r1), plus the production binary's timing test.
L=/root/l36/logs; T=/root/l36/test.sh
until [ -e $L/x2.done ]; do sleep 10; done
TAG=q /root/l36/chain_abl.sh 1 0 1 2 4 8 16 32 3 6 36 38 54 9 10 12 24 40 63
TAG=lad /root/l36/chain_abl.sh 3 0 8 9 45 47 63
for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
  b=${F%%:*}
  SRCD=S $T qS_b${b}_r1 S cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F
done
echo Q3_DONE $(date -u +%T) > $L/q3.done
