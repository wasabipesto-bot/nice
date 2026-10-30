#!/bin/sh
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
T="$D/bin/nice_common-test-pr"
cd "$D/src-pr/common" || exit 10
for t in cubecl_fd_matches_cpu_detailed cubecl_reads_back_every_near_miss; do
  s=$(date +%s)
  echo "=== DUMP $t"
  CUBECL_DEBUG_LOG="$D/logs/shader-$t.log" "$T" $t --ignored --test-threads=1 --nocapture
  echo "=== RESULT $t rc=$? secs=$(( $(date +%s)-s ))"
done
echo DUMP_DONE
