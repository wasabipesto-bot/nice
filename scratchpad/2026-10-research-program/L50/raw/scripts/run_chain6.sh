#!/bin/bash
# L50 chain 6: RC (no residue load before the prefilter for unclipped tops)
# on top of the two-pass scan + seeded check + inlined survivor.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
cd $WT
L=$R/build2.log
echo "### $(date -u +%H:%M:%S) build scan2checkinlrc [l50-scan2,l50-check,l50-inl,l50-rc] l50_prof" >> $L
CARGO_TARGET_DIR=$WT/target nice -n 19 cargo build --profile profiling -p nice_common --example l50_prof --features l50-scan2,l50-check,l50-inl,l50-rc >> $L 2>&1 || { echo "BUILD FAILED rc" >> $L; exit 1; }
cp $WT/target/profiling/examples/l50_prof $B/scan2checkinlrc
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
A60="60 1157209632114824200908 1e16"
A62="62 4473066762334864396992 1e17"
X=$R/ab-runs4.txt
for round in 1 2 3; do
  if [ $((round % 2)) = 0 ]; then order=(scan2checkinlrc scan2checkinl); else order=(scan2checkinl scan2checkinlrc); fi
  for sh in "b60e16 1t|$A60 1 4" "b62e17s0 1t|$A62 1 4 0" "b60e16 4t|$A60 4 16" "b62e17s0 4t|$A62 4 16 0"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in "${order[@]}"; do
      gate
      echo "### $(date -u +%H:%M:%S) r$round $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
      nice -n 19 $B/$bin $args >> $X 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $X
