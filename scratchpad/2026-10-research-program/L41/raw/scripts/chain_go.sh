#!/bin/bash
# chain_go.sh W: CUDA exactness of binary W at levels 3 and 4 (MT form 2, mul_hi, RC ranges in shared), then the
# one-binary screen of levels 0-4 and the walk counters (chain_screen.sh). Nothing else on the box.
L=/root/l41/logs; W=$1
export NICE_EXP_JOIN_MT=2 NICE_EXP_JOIN_FXM=0 NICE_EXP_JOIN_RCV=1
NICE_EXP_JOIN_PF=3 /root/l41/chain_x.sh $W ${W}L3 > $L/chain_x_${W}L3.out 2>&1
NICE_EXP_JOIN_PF=4 /root/l41/chain_x.sh $W ${W}L4 > $L/chain_x_${W}L4.out 2>&1
/root/l41/chain_screen.sh $W > $L/chain_screen_$W.out 2>&1
touch $L/go_$W.done
