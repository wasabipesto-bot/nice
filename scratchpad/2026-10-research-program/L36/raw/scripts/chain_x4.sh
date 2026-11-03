#!/bin/bash
# chain_x4.sh: build exp/top-fd-ablate 47c1b36 (X4: + bit 2048) niced once q3 is done (beside X3's device tests);
# after X3: FD device test with 2048 and 3584 (= 512 + 1024 + 2048), timing (2 rounds), then whole fields
# X4 off vs 3584 (b62 1e17 x2, b60 1e16 x2, interleaved), counts must be the exact ones.
L=/root/l36/logs; T=/root/l36/test.sh; R=/root/l36/run_abl.sh
until [ -e $L/q3.done ]; do sleep 10; done
cd /root/nice && git fetch -q origin exp/top-fd-ablate && git worktree add -q --detach /root/l36/src/X4 47c1b36
(cd /root/l36/src/X4 && git log --oneline -1 && md5sum common/src/cubecl_join.rs) >> $L/trees.txt
J=4 nice -n 19 /root/l36/build.sh X4 X4 gpu || exit 1
touch $L/X4.built
until [ -e $L/x3.done ]; do sleep 10; done
for c in 2048 3584; do
  SRCD=X4 $T x4_fd_a$c X4 cubecl_join::tests::cubecl_cuda_top_fd_matches_the_top_kernel NICE_EXP_TOP_FD_ABL=$c
done
touch $L/x4x.done
for r in 1 2; do
  for F in 62:7997740455941656911841:1e17 60:1366406074057412100454:1e16; do
    b=${F%%:*}
    for c in 0 1536 2048 3584; do
      SRCD=X4 $T l4_b${b}_a${c}_r$r X4 cubecl_join::tests::cubecl_cuda_top_fd_timing NICE_TEST_TOPFD_TIMING=$F NICE_EXP_TOP_FD_ABL=$c
    done
  done
done
touch $L/x4t.done
for r in 1 2; do
  SRCD=X4 NICE_EXP_TOP_FD_ABL=0 $R fx_off_e17_b62_r$r X4 62 1 1e17
  SRCD=X4 NICE_EXP_TOP_FD_ABL=3584 $R fx_on_e17_b62_r$r X4 62 1 1e17
done
for r in 1 2; do
  SRCD=X4 NICE_EXP_TOP_FD_ABL=0 $R fx_off_e16_b60_r$r X4 60 2 1e16
  SRCD=X4 NICE_EXP_TOP_FD_ABL=3584 $R fx_on_e16_b60_r$r X4 60 2 1e16
done
echo X4_DONE $(date -u +%T) > $L/x4.done
