#!/bin/bash
# chain_x3.sh: build exp/top-fd-ablate 1036a4c (X3: lean prototype bits 512, 1024) niced, then after q3: the FD device
# test with each prototype bit (exactness against top_kernel), then the timing test (2 rounds) and registers.
L=/root/l36/logs; T=/root/l36/test.sh
cd /root/nice && git fetch -q origin exp/top-fd-ablate && git worktree add -q --detach /root/l36/src/X3 1036a4c
(cd /root/l36/src/X3 && git log --oneline -1 && md5sum common/src/cubecl_join.rs) >> $L/trees.txt
J=4 nice -n 19 /root/l36/build.sh X3 X3 gpu || exit 1
touch $L/X3.built
until [ -e $L/q3.done ]; do sleep 10; done
for c in 512 1024 1536; do
  SRCD=X3 $T x3_fd_a$c X3 cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel NICE_EXP_TOP_FD_ABL=$c
done
touch $L/x3x.done
for r in 1 2; do
  for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
    b=${F%%:*}
    for c in 0 512 1024 1536; do
      SRCD=X3 $T l_b${b}_a${c}_r$r X3 cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F NICE_EXP_TOP_FD_ABL=$c
    done
  done
done
SRCD=X3 /root/l36/regs_abl.sh X3 abl3 0 512 1024 1536 > $L/regs_abl3.log 2>&1
echo X3_DONE $(date -u +%T) > $L/x3.done
