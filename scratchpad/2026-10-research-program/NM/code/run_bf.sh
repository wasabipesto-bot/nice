#!/bin/bash
# NM exactness: the join's reported set (tolerance m) against brute force of the definition;
# small bases over their whole range (W) with every n's distinct count (ALL).
# columns: JP(t,k,p or -) ALL(0/1) base start|W|fFRAC size tol v0 count
B=/home/claude/projects/nice/.worktrees/nm-near-miss/target-nm/release/examples/nm_join
O=/home/claude/projects/nice/scratchpad/2026-10-research-program/NM/raw/bf2.txt
: > $O
while read -r jp all args; do
  [ -z "$args" ] && continue
  echo "### $jp $all $args $(date -u +%H:%M:%S)" >> $O
  ( [ "$jp" != - ] && export NM_JP=$jp; [ "$all" = 1 ] && export NM_ALL=1
    timeout 1800 nice -n 19 $B bf $args 2>&1 | sed -E 's/join-reps \[([0-9, ]*)\]/join-reps [...]/' >> $O )
done <<'LIST'
3,2,0 1 20 W 0 64 0 1
3,2,0 0 20 W 0 3 0 1
4,3,1 1 22 W 0 64 0 22
4,3,1 1 24 W 0 64 0 24
4,3,1 1 25 W 0 64 0 25
4,3,1 0 25 W 0 2 0 25
5,4,2 1 28 W 0 64 0 784
5,4,2 1 29 W 0 64 0 841
5,4,2 0 29 W 0 2 0 841
5,4,2 1 30 W 0 64 0 900
5,4,2 0 30 W 0 3 0 900
- 0 40 f0.1 1e10 1 0 1600
- 0 44 f0.5 1e11 64 0 200
- 0 45 f0.9 1e11 64 0 200
- 0 50 f0.5 1e12 64 0 4
- 0 60 1157209632114824200908 1e12 64 0 8
- 0 62 4473066762334864396992 1e12 64 0 8
- 0 64 71779931862957161709568 1e12 64 0 8
- 0 62 f0.5 1e12 2 100 8
- 0 64 f0.5 1e12 2 3000 8
LIST
echo "#### done $(date -u +%H:%M:%S)" >> $O
