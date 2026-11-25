#!/bin/bash
# Every smallest reproduction against one coordinator script, then a short randomized run and the byte sweep.
# usage: run_all.sh [SCRIPT] [AUDIT]   (state under $COORD_SCRATCH, default the session scratch directory)
set -u
H=$(cd "$(dirname "$0")" && pwd)
W=$HOME/projects/nice/.worktrees/mo-mode
SCRIPT=${1:-$W/scripts/midout_coordinator.py}
AUDIT=${2:-$W/scripts/midout_audit.py}
export COORD_SCRATCH=${COORD_SCRATCH:-$HOME/projects/nice/scratchpad/2026-10-research-program/G2/mode/run_all}
mkdir -p "$COORD_SCRATCH"
rc=0
for f in "$H"/repro/repro_*.py; do
  printf '%-28s ' "$(basename "$f")"; nice -n 19 python3 "$f" "$SCRIPT" || rc=1
done
nice -n 19 python3 "$H/chaos.py" --script "$SCRIPT" --audit "$AUDIT" --runs 60 --seed 1 --jobs 3 --out "$COORD_SCRATCH/chaos" | head -1 || rc=1
nice -n 19 python3 "$H/torn_sweep.py" "$SCRIPT" --audit "$AUDIT" || rc=1
rm -rf "$COORD_SCRATCH"
exit $rc
