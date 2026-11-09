#!/bin/bash
# chain_post.sh: after the A/B (waits for ab.done). Tree P = exp/join-and-codegen bee17b98 (the PR form of form 2).
# 1. builds P (gpu), P_naga (cubecl), P_spv (cubecl-spirv), niced, beside 2. the spill-variant frequency: 12 processes
#    each of B and of X1 at form 2, alternating (1e14, b62 then b60, own PTX cache each; not timed).
# 3. P's join kernel CUDA/SASS (dumpcu), CUDA exactness (chain_x.sh P), with lavapipe (chain_lvp.sh) and lint
#    (chain_lint.sh) beside it on the CPU.
L=/root/l54/logs; cd /root/l54
until [ -e $L/ab.done ]; do sleep 15; done
echo POST_START $(date -u +%T)
cd /root/nice && git fetch -q origin exp/join-and-codegen && git worktree add -q --detach /root/l54/src/P bee17b98 && cd /root/l54
(cd /root/l54/src/P && echo "P $(git log --oneline -1) $(md5sum common/src/cubecl_join.rs)") >> $L/trees.txt
( NICEN=10 J=8 bash build.sh P P gpu /root/tgt > build_P.out 2>&1
  NICEN=10 J=8 bash build.sh P P_naga cubecl /root/tgt_lvp > build_P_naga.out 2>&1
  NICEN=10 J=8 bash build.sh P P_spv cubecl-spirv /root/tgt_lvp > build_P_spv.out 2>&1
  touch $L/post_built ) &
source /root/l54/cfg.sh
for i in $(seq 1 12); do
  for t in B F2; do
    setside $t
    bash /root/l54/chain_bfreq.sh $BIN ${t}_$i 1 2>&1 | grep -v BFREQ_DONE
  done
done
unset NICE_EXP_AND_FORM
echo BFREQ_ALL_DONE $(date -u +%T)
until [ -e $L/post_built ]; do sleep 10; done
cat build_P.out build_P_naga.out build_P_spv.out | grep -E 'md5|built|FAILED|^[0-9a-f]{32}'
bash dumpcu.sh P P0 2>&1 | grep -v '^/ptx'; sed 's/key=.*//' cu/P0/jit.txt; for s in cu/P0/jit/*.sass; do echo "$s $(python3 andloops.py --and $s | grep -o '[0-9]* instr' | tr '\n' ' ')"; done
bash chain_lvp.sh P P > chain_lvp.out 2>&1 &
bash chain_lint.sh P > chain_lint.out 2>&1 &
bash chain_x.sh P P
wait
cat chain_lvp.out chain_lint.out
echo POST_DONE $(date -u +%T) | tee $L/post.done
