#!/bin/bash
# chain_xs.sh: CUDA exactness of W3 with WB=31 (all four, TT in the TT2 form), then the CPU-reference parity and the
# 1e14 compare with WB=15 (TT in its first form); then (once the lavapipe builds are done) the screen.
L=/root/l43/logs; T=/root/l43/test.sh; R=/root/l43/run.sh
/root/l43/chain_x.sh W3 31 > $L/chain_x_W3_31.out 2>&1
( export SRCD=W3 NICE_EXP_JOIN_WB=15
  $T x_W3_wb15_ref W3 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
  $R cmp_W3_wb15_e14 W3 57,60,62,64 1 1e14 1 ) > $L/chain_x_W3_15.out 2>&1
echo XS_DONE $(date -u +%T) > $L/xs.done
until [ -e $L/lvp_W3.built ]; do sleep 10; done
touch $L/screen_go
O1="0 1 17 2 4 8 15 31" O2="31 15 8 4 2 17 1 0" /root/l43/chain_screen.sh W3 > $L/chain_screen.out 2>&1
