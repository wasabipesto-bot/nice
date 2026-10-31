#!/bin/bash
# lint2.sh: clippy again with full output, nice_common forced to be re-checked.
while ! grep -q DUMP40_DONE /root/logs/tests.status 2>/dev/null; do sleep 10; done
source /root/.cargo/env
cd /root/nice
{ git log --oneline -1; git status --short; date -u
  touch common/src/lib.rs
  cargo clippy -p nice_common --all-targets --features gpu -- -D warnings 2>&1
  echo "rc=$?"; date -u; } > /root/logs/lint2.log 2>&1
echo "LINT2_DONE $(date -u +%T)" >> /root/logs/tests.status
