#!/bin/bash
# chain_p2.sh: the final head P2 (= P with comments moved): after the A/B, tree and test binary (niced, beside P's
# untimed exactness); after P's GPU checks, P2's CUDA exactness, registers, the exhaustive host test, and a repeat of
# the level-0 walk counters (run-to-run order noise). lavapipe and the lint take P2 instead of P (use_P2).
L=/root/l41/logs
until [ -e $L/ab.done ]; do sleep 10; done
/root/l41/tree.sh P2 pr/join-lean-prefilter
NICEN=15 J=10 /root/l41/build.sh P2 P2 > $L/build_P2.out 2>&1; cat $L/build_P2.out
touch $L/use_P2
until [ -e $L/post_gpu.done ]; do sleep 10; done
/root/l41/chain_x.sh P2 > $L/chain_x_P2.out 2>&1
/root/l41/regs.sh P2 P2 P2 > $L/regs_P2.out 2>&1
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu NICE_BUILD_SHA=test
( cd /root/l41/src/P2 && /root/l41/bin/P2 fx_ lean_ --nocapture; /root/l41/bin/P2 fx_digits_are_exact_everywhere --ignored --nocapture; /root/l41/bin/P2 join_plan:: ; /root/l41/bin/P2 cubecl_join:: ) > $L/host_P2.log 2>&1
NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=0 SRCD=X3 /root/l41/run.sh ctr_L0b_e17_b62 X3 62 1 1e17
NICE_EXP_JOIN_ROUNDS=1 NICE_EXP_JOIN_PF=0 SRCD=X3 /root/l41/run.sh ctr_L0b_e16_b60 X3 60 2 1e16
touch $L/p2.done
