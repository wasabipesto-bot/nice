#!/bin/bash
# chain_after.sh: after the screen: the combination screen (scr2: WB 0 against WB ${S2:-19}, 2 interleaved rounds, b62
# 1e17 and b60 1e16), then the A/B against B with the WB written to logs/ab_wb (waits for it), then the lavapipe
# tests (WB 31, every path; TT falls back) and the lint.
R=/root/l43/run.sh; L=/root/l43/logs
until [ -e $L/screen.done ]; do sleep 10; done
S2=${S2:-19}
echo SCREEN2_START $(date -u +%T)
for r in 1 2; do
  if [ $r = 2 ]; then O="$S2 0"; else O="0 $S2"; fi
  for v in $O; do NICE_EXP_JOIN_WB=$v SRCD=W3 $R scr2_wb${v}_e17_b62_r$r W3 62 1 1e17; done
  for v in $O; do NICE_EXP_JOIN_WB=$v SRCD=W3 $R scr2_wb${v}_e16_b60_r$r W3 60 2 1e16; done
done
echo SCREEN2_DONE $(date -u +%T) > $L/screen2.done
until [ -e $L/ab_wb ]; do sleep 10; done
touch $L/ab_go
/root/l43/chain_ab.sh W3 $(cat $L/ab_wb) > $L/chain_ab.out 2>&1
touch $L/lvp_go
/root/l43/chain_lvp.sh W3 31 > $L/chain_lvp.out 2>&1
/root/l43/chain_lint.sh W3 > $L/chain_lint.out 2>&1
echo AFTER_DONE $(date -u +%T) > $L/after.done
