#!/bin/bash
# chain_go.sh: start the A/B (ab_go) once P's exactness chain and the CPU chain are done and nothing else runs.
L=/root/l40/logs
until [ -e $L/main.done ] && [ -e $L/cpu.done ]; do sleep 10; done
while pgrep -f "cargo|rustc|nice_common-|lvp" > /dev/null; do sleep 10; done
echo "AB_GO $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg)"; touch $L/ab_go
