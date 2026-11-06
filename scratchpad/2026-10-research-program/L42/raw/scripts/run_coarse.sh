#!/bin/bash
# L42: coarse-instrumented phase split runs (rdtsc per key-level phase; no per-survivor timer).
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw
B=/tmp/l42/l42_prof.coarse
B60=1157209632114824200908
B62W=4473156762334864396992
B62F=4473066762334864396992
run() { echo "### $(date -u +%H:%M:%S) $*"; nice -n 19 $B "$@"; echo; }
{
run 60 $B60 1e14 1 400
run 60 $B60 1e14 4 0
run 62 $B62W 1e14 1 400
run 62 $B62W 1e14 4 0
run 60 $B60 1e16 1 6
run 60 $B60 1e16 4 16
run 62 $B62W 1e16 1 6
run 62 $B62W 1e16 4 16
run 62 $B62F 1e17 1 4 6
run 62 $B62F 1e17 4 16 6
run 62 $B62F 1e17 1 4 0
echo "### done $(date -u +%H:%M:%S)"
} > $R/coarse-runs.txt 2>&1
