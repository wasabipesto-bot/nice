#!/bin/sh
# Sweep on the fix test binary, then interleaved 60 s benchmarks main/pr/fix x3.
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
cd "$D/src/common" || exit 10
s=$(date +%s)
RUST_LOG=warn "$D/bin/nice_common-test-c5" cubecl_detailed_fd::tests::zz_metal_sweep2 --ignored --exact --test-threads=1 --nocapture > "$D/logs/sweep.log" 2>&1
echo "SWEEP rc=$? secs=$(( $(date +%s)-s ))"
grep -E "SWEEP [0-9]|test result" "$D/logs/sweep.log"
cd "$D" || exit 11
for r in 1 2 3; do
  for t in main pr fix; do
    s=$(date +%s)
    NICE_API_BASE=http://127.0.0.1:9 RUST_LOG=info "$D/bin/nice_client-$t" detailed --gpu --benchmark --benchmark-secs 60 > "$D/logs/bench-r$r-$t.log" 2>&1 < /dev/null
    echo "BENCH r$r $t rc=$? secs=$(( $(date +%s)-s ))"
    grep -E "^b[0-9]+_detailed|NiceMark" "$D/logs/bench-r$r-$t.log"
  done
done
echo SWEEPBENCH_DONE
