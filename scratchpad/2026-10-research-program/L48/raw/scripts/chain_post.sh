#!/bin/bash
# chain_post.sh: after chain_l6: build P (the PR form, one commit on f3fb390: level 6 without knobs) and client_P;
# registers of P and of X7's levels 5-7; P's CUDA exactness list (chain_x.sh) beside the lavapipe chain of X (levels
# 1, 2, 3, 103) and P's lavapipe builds; then the A/B of B against P (chain_ab.sh, nothing else on the box); then the
# CUDA exactness list of X at levels 1-4 beside P's lavapipe tests and lint.
L=/root/l48/logs; cd /root/l48
until [ -e $L/l6.done ]; do sleep 10; done
echo POST_START $(date -u +%T)
J=19 ./build.sh P P || exit 1
J=19 ./buildclient.sh P client_P /root/tgt_cl || exit 1
./regs48.sh P P 0 > regs_P.out 2>&1
./regs48.sh X7 X7 5 6 7 > regs_X7.out 2>&1
echo REGS_DONE $(date -u +%T)
touch $L/lvp_go
( GO=lvp_P_go ./chain_lvp.sh P P "" 6 > chain_lvp_P.out 2>&1 ) &
SRCD=P ./chain_x.sh P 0 P > chain_x_P.out 2>&1
echo X_P_DONE $(date -u +%T)
# the A/B needs a quiet box: wait for the lavapipe X chain to finish (P's builds wait for lvp_go and run after)
while pgrep -f "bin/X_naga|bin/X_spv|bin/P_naga|bin/P_spv|cargo test|rustc" > /dev/null; do sleep 15; done
echo AB_GO $(date -u +%T)
touch $L/ab_go
./chain_ab.sh P 0 P > chain_ab.out 2>&1
echo AB_DONE $(date -u +%T)
touch $L/lvp_P_go
for lv in 1 2 3 4; do SRCD=X ./chain_x.sh X $lv > chain_x_X_l$lv.out 2>&1; echo "X_X_l$lv done $(date -u +%T)"; done
echo POST_DONE $(date -u +%T) | tee $L/post.done
