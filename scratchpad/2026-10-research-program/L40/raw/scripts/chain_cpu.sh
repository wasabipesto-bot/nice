#!/bin/bash
# chain_cpu.sh: after P's test binary: lavapipe builds and tests (chain_lvp.sh) and the lint chain, CPU only.
L=/root/l40/logs
until [ -e $L/P.built ]; do sleep 10; done
touch $L/lvp_go
/root/l40/chain_lint.sh P
/root/l40/chain_lvp.sh P
echo CHAIN_CPU_DONE $(date -u +%T) > $L/cpu.done
