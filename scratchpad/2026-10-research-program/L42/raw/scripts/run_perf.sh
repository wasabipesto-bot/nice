#!/bin/bash
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw
B=/tmp/l42/l42_prof.plain
B60=1157209632114824200908
B62F=4473066762334864396992
rep() { perf report -i $1 --no-children --sort symbol --stdio 2>/dev/null | grep -v "^#" | grep -v "^$" | head -14 | sed -E 's/ +$//' | cut -c1-150; }
{
echo "### $(date -u +%H:%M:%S) perf b60 1e16 4t 16 partitions (delay 3.5 s past setup)"
nice -n 19 perf record -F 999 --delay 3500 -o /tmp/l42/p-b60-1e16-4t.data $B 60 $B60 1e16 4 16 2>&1 | grep -v "^\["
rep /tmp/l42/p-b60-1e16-4t.data
echo "### $(date -u +%H:%M:%S) perf b62 1e17 slice 0, 1t 4 partitions"
nice -n 19 perf record -F 1999 --delay 3500 -o /tmp/l42/p-b62-1e17s0-1t.data $B 62 $B62F 1e17 1 4 0 2>&1 | grep -v "^\["
rep /tmp/l42/p-b62-1e17s0-1t.data
echo "### $(date -u +%H:%M:%S) perf b62 1e17 slice 0, 4t 16 partitions"
nice -n 19 perf record -F 999 --delay 3500 -o /tmp/l42/p-b62-1e17s0-4t.data $B 62 $B62F 1e17 4 16 0 2>&1 | grep -v "^\["
rep /tmp/l42/p-b62-1e17s0-4t.data
echo "### $(date -u +%H:%M:%S) perf b60 1e14 1t 400 (delay 0.3 s)"
nice -n 19 perf record -F 1999 --delay 300 -o /tmp/l42/p-b60-1e14-1t.data $B 60 $B60 1e14 1 400 2>&1 | grep -v "^\["
rep /tmp/l42/p-b60-1e14-1t.data
echo "### $(date -u +%H:%M:%S) perf b62 1e14 1t 400"
nice -n 19 perf record -F 1999 --delay 300 -o /tmp/l42/p-b62-1e14-1t.data $B 62 4473156762334864396992 1e14 1 400 2>&1 | grep -v "^\["
rep /tmp/l42/p-b62-1e14-1t.data
echo "### $(date -u +%H:%M:%S) perf stat b60 1e16 1t 4 partitions"
nice -n 19 perf stat --delay 3500 -e cycles,instructions,branches,branch-misses,L1-dcache-load-misses $B 60 $B60 1e16 1 4 2>&1 | grep -v "^\[" 
echo "### done $(date -u +%H:%M:%S)"
} > $R/perf-runs.txt 2>&1
