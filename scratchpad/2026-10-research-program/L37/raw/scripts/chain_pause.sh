#!/bin/bash
# chain_pause.sh: after ablation round 1, stop chain_abl.sh (discarding round 2's first, partial run), check H1's kernels
# compile and count right (regs.sh), then run ablation rounds 2-3 and the lane-round counts (chain_abl2.sh).
L=/root/l37/logs
until [ -e $L/abl_r1.done ]; do sleep 1; done
pkill -f chain_abl.sh; sleep 0.5; pkill -f "bin/A --ignored"; sleep 2
mkdir -p $L/discarded; mv $L/abl_c_e17_b62_r2.* $L/discarded/ 2>/dev/null
echo PAUSED $(date -u +%T)
until [ -e $L/C.built ]; do sleep 5; done
/root/l37/regs.sh C C C NICE_EXP_JOIN_COMPACT 0 1 2 > $L/regs_C.out 2>&1
/root/l37/regs.sh A A A NICE_EXP_JOIN_ABL 0 > $L/regs_A.out 2>&1
echo REGS $(date -u +%T)
/root/l37/chain_abl2.sh
