#!/bin/bash
# lint.sh <fix sha>: fmt, clippy and the host suite on the committed tree (no local module).
source /root/.cargo/env
L=/root/logs; cd /root/nice
{ git checkout -q -f $1 && git log --oneline -1 && git status --short; date -u
  echo "== cargo fmt --all --check"; cargo fmt --all --check; echo "rc=$?"
  echo "== cargo clippy -p nice_common --all-targets --features gpu -- -D warnings"
  s=$(date +%s); cargo clippy -p nice_common --all-targets --features gpu -- -D warnings 2>&1 | tail -n 5; echo "rc=${PIPESTATUS[0]} secs=$(( $(date +%s) - s ))"
  date -u; echo LINT_DONE; } > $L/lint.log 2>&1
{ git log --oneline -1; date -u; s=$(date +%s)
  cargo test --release -p nice_common --features gpu -- --test-threads 8 2>&1 | grep -E "^test result|FAILED|panicked|failures:|Running"
  echo "rc=${PIPESTATUS[0]} secs=$(( $(date +%s) - s ))"; date -u; echo HOST_DONE; } > $L/host.log 2>&1
