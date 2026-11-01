#!/bin/bash
# After the builds: CUDA exactness (GPU) | lavapipe builds + tests (CPU) | fmt/clippy (CPU, niced); then the A/B on a quiet box.
L=/root/l31b/logs
w() { until [ -e "$1" ]; do sleep 10; done; }
w $L/builds.done
echo "X+LVP+LINT start $(date -u +%T)"
nohup /root/l31b/chain_x.sh > $L/chain_x.out 2>&1 < /dev/null &
nohup /root/l31b/chain_lvp.sh > $L/chain_lvp.out 2>&1 < /dev/null &
w $L/lvpbuilds.done
nohup /root/l31b/chain_lint.sh > $L/chain_lint.out 2>&1 < /dev/null &
w $L/chainX.done; w $L/lvp.done; w $L/lint.done
echo "AB start $(date -u +%T)"
/root/l31b/chain_ab.sh > $L/chain_ab.out 2>&1 < /dev/null
echo "ALL DONE $(date -u +%T)"
