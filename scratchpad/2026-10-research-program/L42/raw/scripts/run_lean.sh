#!/bin/bash
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw
B=/tmp/l42/l42_prof.plain2
{
for m in 0 1 2 3; do echo "### lean=$m b60 1e14 1t 400"; L42_LEAN=$m nice -n 19 $B 60 1157209632114824200908 1e14 1 400 | grep wall; done
for r in 1 2; do
for m in 0 3 1 2; do echo "### round $r lean=$m b60 1e16 1t 4"; L42_LEAN=$m nice -n 19 $B 60 1157209632114824200908 1e16 1 4 | grep wall; done
for m in 0 3 1 2; do echo "### round $r lean=$m b62 1e17 s0 1t 4"; L42_LEAN=$m nice -n 19 $B 62 4473066762334864396992 1e17 1 4 0 | grep wall; done
done
echo "### done $(date -u +%H:%M:%S)"
} > $R/lean-runs.txt 2>&1
