#!/bin/sh
# Seed test again with wgpu's adapter logging, to record which device ran it.
. "$HOME/claude-exp-2026-10-31-seed/scripts/env.sh"
cd "$D/src/common" || exit 10
s=$(date +%s)
RUST_LOG=wgpu_core=info,wgpu_hal=info "$D/bin/nice_common-test" cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu --ignored --exact --test-threads=1 --nocapture > "$D/logs/test-seed-adapter.log" 2>&1
echo "rc=$? secs=$(( $(date +%s)-s ))"
grep -iE 'adapter|Apple|Metal' "$D/logs/test-seed-adapter.log" | head -8
echo "seed windows exact: $(grep -cE ': exact$' "$D/logs/test-seed-adapter.log") of 132"
grep -E 'test result' "$D/logs/test-seed-adapter.log"
