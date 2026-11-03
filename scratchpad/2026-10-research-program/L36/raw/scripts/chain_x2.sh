#!/bin/bash
# chain_x2.sh: after the profiles: build exp/top-fd-ablate cd239e0 (X2: + bits 128, 256 inside the digit scan) and
# time the scan's sub-parts (2 interleaved rounds, both fields), then their registers.
L=/root/l36/logs; T=/root/l36/test.sh
until [ -e $L/prof.done ]; do sleep 10; done
cd /root/nice && git fetch -q origin exp/top-fd-ablate && git worktree add -q --detach /root/l36/src/X2 cd239e0
(cd /root/l36/src/X2 && git log --oneline -1 && md5sum common/src/cubecl_join.rs) >> $L/trees.txt
/root/l36/build.sh X2 X2 gpu; touch $L/X2.built
for r in 1 2; do
  for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
    b=${F%%:*}
    for c in 0 1 128 256 384 8 9 136 264 392; do
      SRCD=X2 $T s_b${b}_a${c}_r$r X2 cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F NICE_EXP_TOP_FD_ABL=$c
    done
  done
done
SRCD=X2 /root/l36/regs_abl.sh X2 abl2 0 1 128 256 384 > $L/regs_abl2.log 2>&1
echo X2_DONE $(date -u +%T) > $L/x2.done
