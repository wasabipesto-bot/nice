#!/bin/sh
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
T="$D/bin/nice_common-test-main"
cd "$D/src-main/common" || exit 10
export RUST_BACKTRACE=1
for t in cubecl_matches_cpu_detailed cubecl_reads_back_every_near_miss; do
  s=$(date +%s)
  echo "=== $t"
  "$T" $t --ignored --test-threads=1 --nocapture
  echo "=== RESULT main $t rc=$? secs=$(( $(date +%s)-s ))"
done
echo MAINTESTS_DONE
