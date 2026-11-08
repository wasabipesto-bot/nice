#!/bin/bash
# L50 chain 4: the profile after the prototypes (scan2checkinl), 1 thread.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
PD=$WT/perf
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
P=$R/perf-runs.txt
cd $WT
echo "### $(date -u +%H:%M:%S) build after [l50-scan2,l50-check,l50-inl,l50-split]" >> $R/build2.log
CARGO_TARGET_DIR=$WT/target nice -n 19 cargo build --profile profiling -p nice_common --example l50_prof --features l50-scan2,l50-check,l50-inl,l50-split >> $R/build2.log 2>&1 && cp $WT/target/profiling/examples/l50_prof $B/aftersplit
for sh in "b60e16|60 1157209632114824200908 1e16 1 4" "b62e17s0|62 4473066762334864396992 1e17 1 4 0"; do
  name=${sh%%|*}; args=${sh#*|}
  for bin in scan2checkinl aftersplit; do
    gate
    echo "### $(date -u +%H:%M:%S) perf $bin $name 1t [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $P
    nice -n 19 perf record -q -F 1999 -D 3500 -e cycles -e instructions -e branch-misses -o $PD/$bin-$name-1t.data -- $B/$bin $args >> $P 2>&1
  done
done
echo "#### done4 $(date -u +%H:%M:%S)" >> $P
