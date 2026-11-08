#!/bin/bash
# L50 chain 5: the bit-sliced pass 1 (l50-tr) against the two-pass scan, both
# with the seeded check and the inlined survivor.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
cd $WT
L=$R/build2.log
echo "### $(date -u +%H:%M:%S) build trcheckinl [l50-tr,l50-check,l50-inl] l50_prof" >> $L
CARGO_TARGET_DIR=$WT/target nice -n 19 cargo build --profile profiling -p nice_common --example l50_prof --features l50-tr,l50-check,l50-inl >> $L 2>&1 || { echo "BUILD FAILED trcheckinl" >> $L; exit 1; }
cp $WT/target/profiling/examples/l50_prof $B/trcheckinl
md5sum $B/trcheckinl >> $L
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
A60="60 1157209632114824200908 1e16"
A62="62 4473066762334864396992 1e17"
A58="58 104400216587923470200 1e15"
X=$R/ab-runs3.txt
for round in 1 2 3; do
  if [ $((round % 2)) = 0 ]; then order=(trcheckinl scan2checkinl plain); else order=(plain scan2checkinl trcheckinl); fi
  for sh in "b60e16 1t|$A60 1 4" "b62e17s0 1t|$A62 1 4 0" "b60e16 4t|$A60 4 16" "b62e17s0 4t|$A62 4 16 0" "b58e15 1t|$A58 1 32"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in "${order[@]}"; do
      gate
      echo "### $(date -u +%H:%M:%S) r$round $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
      nice -n 19 $B/$bin $args >> $X 2>&1
    done
  done
done
for sh in "b60e14 4t|60 1157209632114824200908 1e14 4 0" "b62e14 4t|62 4473156762334864396992 1e14 4 0"; do
  name=${sh%%|*}; args=${sh#*|}
  for bin in plain scan2checkinl trcheckinl; do
    gate
    echo "### $(date -u +%H:%M:%S) r1 $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
    nice -n 19 $B/$bin $args >> $X 2>&1
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $X
