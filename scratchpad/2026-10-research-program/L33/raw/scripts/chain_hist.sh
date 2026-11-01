#!/bin/bash
# Histogram runs on the instrumented binary H (NICE_EXP_TOP_HIST=1), after its build.
R=/root/l33/scripts/run.sh; L=/root/l33/logs
while [ ! -f /root/l33/bin/H ]; do sleep 5; done
export NICE_EXP_TOP_HIST=1
$R hist_b60_e16 H 60 1 1e16
$R hist_b62_e16 H 62 1 1e16
$R hist_b62_e17 H 62 1 1e17
echo CHAIN_HIST_DONE $(date -u +%T) > $L/chainHIST.done
