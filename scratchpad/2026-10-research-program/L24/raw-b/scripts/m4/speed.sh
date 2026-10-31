#!/bin/sh
# Speed on the M4: bench.mjs (kernel-only + real-page suite) three rounds,
# old and new builds interleaved (old first in odd rounds, new first in even);
# then run length 64 vs 128 vs the per-number kernel in the new build.
. "$HOME/claude-exp-2026-11-01-webfd/scripts/env.sh"
cd "$D/harness"
O="$D/out"
for r in 1 2 3; do
  if [ $((r % 2)) -eq 1 ]; then order="old new"; else order="new old"; fi
  for b in $order; do
    pmset -g therm > "$O/therm-bench-r$r-$b.txt" 2>&1
    uptime >> "$O/therm-bench-r$r-$b.txt"
    NICE_E2E_ROOT="$D/site-$b" node hw/bench.mjs --rounds 1 --out "$O/bench-r$r-$b.json" > "$O/bench-r$r-$b.log" 2>&1
    echo "rc=$?" >> "$O/bench-r$r-$b.log"
  done
done
NICE_E2E_ROOT="$D/site-new" node kshape.mjs --shapes 0,64,128 --rounds 3 --out "$O/kshape-m4.json" > "$O/kshape-m4.log" 2>&1; echo "rc=$?" >> "$O/kshape-m4.log"
pmset -g therm > "$O/therm-speed-after.txt" 2>&1
echo SPEED_DONE
