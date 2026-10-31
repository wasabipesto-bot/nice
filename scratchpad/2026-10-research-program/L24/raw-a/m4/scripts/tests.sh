#!/bin/sh
# The three Metal tests on the branch's test binary.
. "$HOME/claude-exp-2026-10-31-seed/scripts/env.sh"
T="$D/bin/nice_common-test"
cd "$D/src/common" || exit 10
export RUST_BACKTRACE=1 RUST_LOG=warn
for t in cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed \
         cubecl_backend::tests::cubecl_reads_back_every_near_miss; do
  n=$(echo $t | sed 's/.*:://')
  s=$(date +%s)
  "$T" $t --ignored --exact --test-threads=1 --nocapture > "$D/logs/test-$n.log" 2>&1
  echo "=== $t rc=$? secs=$(( $(date +%s)-s )) $(grep -E 'test result' "$D/logs/test-$n.log")"
done
echo "seed windows exact: $(grep -cE '^b[0-9]+ \[.*\): exact$' "$D/logs/test-cubecl_fd_seed_matches_cpu.log") of $(grep -cE '^b[0-9]+ \[' "$D/logs/test-cubecl_fd_seed_matches_cpu.log")"
grep -m1 -iE 'adapter|Apple M' "$D/logs/test-cubecl_fd_seed_matches_cpu.log"
echo TESTS_DONE
