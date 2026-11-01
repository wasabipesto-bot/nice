#!/bin/bash
# Orchestration: exactness (GPU) + clippy once the test binaries exist; WGSL lint once the wgpu binary exists;
# A/B, then each PR alone, then the profile, once every build and check is finished (quiet box).
L=/root/cmb
w() { until [ -e "$1" ]; do sleep 10; done; }
w $L/testbins.done
echo "X+LINT start $(date -u +%T)"
nohup /root/chain_x.sh > $L/chain_x.out 2>&1 < /dev/null &
nohup /root/lint.sh > $L/lint.out 2>&1 < /dev/null &
w $L/wgpu.done
w $L/chainX.done
echo "WGSL start $(date -u +%T)"
/root/wgsl.sh > $L/wgsl.out 2>&1 < /dev/null
w $L/builds.done; w $L/lint.done
echo "AB start $(date -u +%T)"
/root/chain_ab.sh > $L/chain_ab.out 2>&1 < /dev/null
echo "SINGLE start $(date -u +%T)"
/root/chain_single.sh > $L/chain_single.out 2>&1 < /dev/null
echo "PROF start $(date -u +%T)"
/root/chain_prof.sh > $L/chain_prof.out 2>&1 < /dev/null
echo "ALL DONE $(date -u +%T)"
