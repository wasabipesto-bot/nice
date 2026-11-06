#!/bin/bash
# chain_post.sh W: after the screen: the A/B of B against W (chain_ab.sh), then W's CUDA exactness (chain_x.sh), the RC
# mutant (X4 at NICE_EXP_JOIN_PF=4 NICE_EXP_JOIN_RCV=2 against the CPU reference and the 1e14 compare: must fail),
# B's registers, then lavapipe (chain_lvp.sh) and the lint (chain_lint.sh) on W.
L=/root/l41/logs; W=$1
until [ -e $L/screen.done ]; do sleep 10; done
[ -e $L/stop ] && exit 0
/root/l41/chain_ab.sh $W > $L/chain_ab_$W.out 2>&1
/root/l41/chain_x.sh $W > $L/chain_x_$W.out 2>&1
ln -sf /root/l41/src/X /root/l41/src/X4
NICE_EXP_JOIN_PF=4 NICE_EXP_JOIN_MT=2 NICE_EXP_JOIN_RCV=2 SRCD=X4 /root/l41/test.sh mut_X4_ref X4 cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_reference X=1
NICE_EXP_JOIN_PF=4 NICE_EXP_JOIN_MT=2 NICE_EXP_JOIN_RCV=2 SRCD=X4 /root/l41/run.sh mut_X4_e14 X4 57,60,62,64 1 1e14 1
/root/l41/regs.sh B B B > $L/regs_B.out 2>&1
touch $L/post_gpu.done
/root/l41/chain_lvp.sh $W > $L/chain_lvp_$W.out 2>&1
/root/l41/chain_lint.sh $W > $L/chain_lint_$W.out 2>&1
touch $L/post.done
