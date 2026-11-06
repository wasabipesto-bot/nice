#!/bin/bash
# chain_p3.sh: the clip-word copy variant P3 (exp/join-lean-pf-cwcopy = the PR + s_cwr): tree and test binary (niced,
# after P2's), registers; once the box is quiet (P's and P2's chains done), a screen of P against P3: b62 1e17 and b60
# 1e16, 2 rounds, order P P3 then P3 P.
L=/root/l41/logs; R=/root/l41/run.sh
until [ -e $L/use_P2 ]; do sleep 10; done
/root/l41/tree.sh P3 exp/join-lean-pf-cwcopy
NICEN=15 J=10 /root/l41/build.sh P3 P3 > $L/build_P3.out 2>&1; cat $L/build_P3.out
/root/l41/regs.sh P3 P3 P3 > $L/regs_P3.out 2>&1
touch $L/p3_built.done
until [ -e $L/post.done ] && [ -e $L/p2.done ]; do sleep 10; done
echo P3SCR_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="P3 P"; else O="P P3"; fi
  for t in $O; do SRCD=$t $R s3_${t}_e17_b62_r$r $t 62 1 1e17; done
  for t in $O; do SRCD=$t $R s3_${t}_e16_b60_r$r $t 60 2 1e16; done
done
echo P3SCR_DONE $(date -u +%T)
touch $L/p3.done
