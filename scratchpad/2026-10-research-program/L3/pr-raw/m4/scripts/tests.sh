#!/bin/sh
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
T="$D/bin/nice_common-test-pr"
cd "$D/src-pr/common" || exit 10
export RUST_BACKTRACE=1
"$T" --list --include-ignored > "$D/logs/testlist.txt" 2>&1
one() {
  label=$1; shift
  s=$(date +%s)
  echo "=== $label: $T $*"
  "$T" "$@" --test-threads=1 --nocapture
  rc=$?
  e=$(date +%s)
  echo "=== RESULT $label rc=$rc secs=$((e-s))"
}
one fd_nonignored fd
one fd_wgpu cubecl_fd_matches_cpu_detailed --ignored
one matches_cpu cubecl_matches_cpu_detailed --ignored
one readback cubecl_reads_back_every_near_miss --ignored
echo TESTS_DONE
