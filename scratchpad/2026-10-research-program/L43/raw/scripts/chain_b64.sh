#!/bin/bash
# chain_b64.sh: after everything else: b64 1e16 (2 fields) split by trim, WB 0 / 17 (TT2) / 2 (WH) / 19 (both),
# 2 interleaved rounds (second reversed), nothing else on the box.
R=/root/l43/run.sh; L=/root/l43/logs
until [ -e $L/after.done ]; do sleep 10; done
for r in 1 2; do
  if [ $r = 2 ]; then O="19 2 17 0"; else O="0 17 2 19"; fi
  for v in $O; do NICE_EXP_JOIN_WB=$v SRCD=W3 $R scr3_wb${v}_e16_b64_r$r W3 64 2 1e16; done
done
echo B64_DONE $(date -u +%T) > $L/b64.done
