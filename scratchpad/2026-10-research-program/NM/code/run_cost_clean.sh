#!/bin/bash
# NM cost: the unmodified join (base) against variant A at m = 2 and m = 3 (and the modified
# binary at m = 0), one thread, rounds interleaved with a rotating order, CPU2's shapes.
# Before each round wait (up to 6 min) for the 1-min load <= 1.5.
BASE=/home/claude/projects/nice/.worktrees/nm-near-miss-base/target-nmb/release/examples/nm_base
NM=/home/claude/projects/nice/.worktrees/nm-near-miss/target-nm-clean/release/examples/nm_join
OUT=${OUT:-/home/claude/projects/nice/scratchpad/2026-10-research-program/NM/raw/cost-clean.txt}
ROUNDS=${ROUNDS:-5}
CASES=(
 "b60e16|60 1157209632114824200908 1e16 0 1000 16"
 "b62e17|62 4473066762334864396992 1e17 0 1000 16"
 "b64e17|64 71779931862957161709568 1e17 0 1000 8"
)
ARMS=(base nm0 nm2)
load1() { cut -d' ' -f1 /proc/loadavg; }
run_arm() { # arm, args
  local arm=$1; shift
  case $arm in
    base) nice -n 19 $BASE "$@" ;;
    nm0) nice -n 19 $NM run $1 $2 $3 $4 $5 $6 0 ;;
    nm2) nice -n 19 $NM run $1 $2 $3 $4 $5 $6 2 ;;
    nm3) nice -n 19 $NM run $1 $2 $3 $4 $5 $6 3 ;;
  esac
}
for r in $(seq 1 $ROUNDS); do
  for i in $(seq 1 72); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 1.5)}' && break; sleep 5; done
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" >> $OUT
  n=${#ARMS[@]}
  for c in "${CASES[@]}"; do
    name=${c%%|*}; args=${c#*|}
    for k in $(seq 0 $((n-1))); do
      arm=${ARMS[$(( (k + r) % n ))]}
      echo "### r$r $name $arm $(date -u +%H:%M:%S) load $(load1)" >> $OUT
      run_arm $arm $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
