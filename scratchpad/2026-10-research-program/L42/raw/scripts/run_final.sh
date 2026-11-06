#!/bin/bash
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw
C=/tmp/l42/l42_prof.coarse3
P=/tmp/l42/l42_prof.plain3
{
echo "### $(date -u +%H:%M:%S) coarse split, FD + FX/MT (L42_FD=1 L42_LEAN=2)"
for f in "60 1157209632114824200908 1e16 1 4" "60 1157209632114824200908 1e16 4 16" "62 4473066762334864396992 1e17 1 4 0" "62 4473066762334864396992 1e17 4 16 0" "60 1157209632114824200908 1e14 1 400" "62 4473156762334864396992 1e14 1 400"; do
  echo "## $f"; L42_FD=1 L42_LEAN=2 nice -n 19 $C $f | grep -E "^wall|%|^per"
done
echo "### $(date -u +%H:%M:%S) FD self-check (every unclipped slot against Base::cert) on production samples"
for f in "60 1157209632114824200908 1e16 4 16" "62 4473066762334864396992 1e17 4 16 0" "62 4473066762334864396992 1e17 4 16 6" "62 4473156762334864396992 1e16 4 16"; do
  echo "## $f"; L42_FD=1 L42_LEAN=3 L42_FD_CHECK=1 nice -n 19 $P $f | grep -E "^wall"
done
echo "### done $(date -u +%H:%M:%S)"
} > $R/final-runs.txt 2>&1
