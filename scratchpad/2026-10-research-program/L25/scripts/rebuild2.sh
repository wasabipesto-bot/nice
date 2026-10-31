#!/bin/bash
# Re-apply the fix with the survivor-bearing windows to both trees and rebuild.
source /root/.cargo/env
L=/root/logs
{ cd /root/fix && git checkout -q -- . && git apply /root/fix-wip2.diff && git status --short
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning"
  echo FIX2_BUILT
  cd /root/basew && git checkout -q -- . && git apply --include='common/src/overlap_join.rs' /root/fix-wip2.diff && git status --short
  cargo test --release -p nice_common --features gpu --no-run 2>&1 | grep -E "Executable unittests|^error|^warning"
  echo BASEW2_BUILT
  mkdir -p $L/round1 && mv $L/cuda_*.log $L/lvp_*.log $L/tput_*.log $L/wgsl_lvp_*.log $L/round1/ 2>/dev/null
  /root/tests.sh /root/fix fix cuda
  /root/tests.sh /root/basew basew cuda
  for r in 1 2 3; do /root/tests.sh /root/basew basew tput; mv $L/tput_basew.log $L/tput_basew_r$r.log; /root/tests.sh /root/fix fix tput; mv $L/tput_fix.log $L/tput_fix_r$r.log; done
  /root/tests.sh /root/fix fix lvp
  /root/tests.sh /root/basew basew lvp
  /root/tests.sh /root/fix fix host
  echo ROUND2_DONE
} > $L/round2.log 2>&1
