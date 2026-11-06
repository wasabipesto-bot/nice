#!/bin/bash
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L42/raw
B=/tmp/l42/l42_prof.plain3
run() { # label env... -- args
  local lab=$1; shift
  echo "### $(date -u +%H:%M:%S) $lab"
  env "$@" | grep wall | sed 's/slice on.*survivors/survivors/; s/; tsc.*//'
}
{
for r in 1 2; do
 for f in "60 1157209632114824200908 1e16 1 4" "60 1157209632114824200908 1e16 4 16" "62 4473066762334864396992 1e17 1 4 0" "62 4473066762334864396992 1e17 4 16 0" "60 1157209632114824200908 1e14 1 400" "62 4473156762334864396992 1e14 1 400"; do
  run "r$r base   $f" L42_FD=0 L42_LEAN=0 nice -n 19 $B $f
  run "r$r FD     $f" L42_FD=1 L42_LEAN=0 nice -n 19 $B $f
  run "r$r FD+FXMT $f" L42_FD=1 L42_LEAN=2 nice -n 19 $B $f
 done
done
echo "### done $(date -u +%H:%M:%S)"
} > $R/fd-field-runs.txt 2>&1
