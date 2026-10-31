#!/bin/bash
# Build the fix tree (472c9a0 + fix-wip.diff) and the baseline tree with only
# the new test windows, each with its own target dir.
source /root/.cargo/env
L=/root/logs; mkdir -p $L
{ date -u
  cd /root/nice && git worktree add -q /root/fix 472c9a0 2>&1
  cd /root/fix && git apply /root/fix-wip.diff && git status --short
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning" 
  date -u; echo FIX_BUILD_DONE
  cd /root/nice && git worktree add -q /root/basew 472c9a0 2>&1
  cd /root/basew && git apply --include='common/src/overlap_join.rs' /root/fix-wip.diff && git status --short
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning"
  date -u; echo BASEW_BUILD_DONE
} > $L/fix_build.log 2>&1
