#!/bin/bash
# start_ab3.sh: start the final A/B (chain_ab3.sh H2) once the H2 screen is done and no test binary runs.
L=/root/l40/logs
until grep -q SCR_H2_DONE $L/chain_h2.out; do sleep 3; done
while pgrep -f "l40/bin/[MH]" > /dev/null; do sleep 2; done
echo "GO $(date -u +%T) load=$(cut -d' ' -f1 /proc/loadavg)" > $L/ab3_start.txt
touch $L/ab3_go
/root/l40/chain_ab3.sh H2 > $L/chain_ab3.out 2>&1
