#!/bin/bash
# suite.sh BIN: every ignored cubecl_backend test, each in its own process: CUDA ones on the 3080 (cuda in the name),
# the wgpu ones on lavapipe (LVP=1). Logs $W/logs/BIN_suite_<test>.log; summary to stdout.
W=/root/t26b; BIN=$1; ONLY=${ONLY:-all}
for t in $($W/bin/$BIN --list --ignored 2>/dev/null | grep -o 'cubecl_backend::tests::[a-z0-9_]*' | sed 's/cubecl_backend::tests:://'); do
  case $t in *throughput*) continue;; esac
  if [[ $t == *cuda* ]]; then [ "$ONLY" = lvp ] && continue; TMO=2400 bash $W/scripts/tb.sh ${BIN}_suite_$t $BIN $t
  else [ "$ONLY" = cuda ] && continue; LVP=1 TMO=3600 bash $W/scripts/tb.sh ${BIN}_suite_$t $BIN $t; fi
done
echo "SUITE_DONE $BIN $(date -u +%T)"
