#!/bin/bash
# chain_scr2.sh: build G2 (tree-select word pick), its registers; screen M, G, G2: b62 1e16 and b60 1e16 (2 fields),
# 2 rounds, order alternating (M G G2; G2 G M); nothing else on the GPU.
L=/root/l40/logs; R=/root/l40/run.sh
/root/l40/build.sh G2 G2 || exit 1
/root/l40/regs.sh G2 G2 G2 > $L/regs_G2.out 2>&1
grep join_kernel /root/l40/sass/G2/registers.txt; head -1 $L/regs_G2.out
for r in 1 2; do
  if [ $r = 2 ]; then O="G2 G M"; else O="M G G2"; fi
  for f in "62 e16_b62" "60 e16_b60"; do
    set -- $f
    for t in $O; do SRCD=$t $R scr2_${t}_$2_r$r $t $1 2 1e16; echo "$(grep -o 'device=[0-9.]*s\|survivors=[0-9]*\|checked=[0-9]*' $L/scr2_${t}_$2_r$r.log | tr '\n' ' ') $t $2 r$r"; done
  done
done
echo CHAIN_SCR2_DONE $(date -u +%T)
