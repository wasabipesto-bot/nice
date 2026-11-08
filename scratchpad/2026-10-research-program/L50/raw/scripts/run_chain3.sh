#!/bin/bash
# L50 chain 3: build the inlined-survivor variants; perf stat (counting, no
# sampling) per partition for plain and the prototypes; A/B of the inlined
# survivor on top of the two-pass scan (+ seeded check).
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
cd $WT
export CARGO_TARGET_DIR=$WT/target
L=$R/build2.log
for v in "scan2inl|l50-scan2,l50-inl" "scan2checkinl|l50-scan2,l50-check,l50-inl"; do
  name=${v%%|*}; feat=${v#*|}
  echo "### $(date -u +%H:%M:%S) build $name [$feat] l50_prof" >> $L
  nice -n 19 cargo build --profile profiling -p nice_common --example l50_prof --features $feat >> $L 2>&1 || { echo "BUILD FAILED $name" >> $L; exit 1; }
  cp target/profiling/examples/l50_prof bin/$name
done
md5sum bin/* >> $L
gate() { for i in $(seq 1 30); do l=$(cut -d' ' -f1 /proc/loadavg); awk "BEGIN{exit !($l <= 1.5)}" && return; sleep 10; done; }
A60="60 1157209632114824200908 1e16"
A62="62 4473066762334864396992 1e17"
A58="58 104400216587923470200 1e15"
X=$R/ab-runs2.txt
for round in 1 2 3; do
  if [ $((round % 2)) = 0 ]; then order=(scan2checkinl scan2inl scan2check plain); else order=(plain scan2check scan2inl scan2checkinl); fi
  for sh in "b60e16 1t|$A60 1 4" "b62e17s0 1t|$A62 1 4 0" "b60e16 4t|$A60 4 16" "b62e17s0 4t|$A62 4 16 0" "b58e15 1t|$A58 1 32"; do
    name=${sh%%|*}; args=${sh#*|}
    for bin in "${order[@]}"; do
      gate
      echo "### $(date -u +%H:%M:%S) r$round $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $X
      nice -n 19 $B/$bin $args >> $X 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $X
O=$R/perfstat-runs.txt
for sh in "b60e16|$A60 1 4" "b62e17s0|$A62 1 4 0"; do
  name=${sh%%|*}; args=${sh#*|}
  for bin in plain scan2check scan2checkinl; do
    gate
    echo "### $(date -u +%H:%M:%S) perfstat $bin $name [$args] load $(cut -d' ' -f1-3 /proc/loadavg)" >> $O
    nice -n 19 perf stat -D 3500 -e cycles,instructions,branches,branch-misses,task-clock -x, -o $O.tmp -- $B/$bin $args >> $O 2>&1
    cat $O.tmp >> $O; rm -f $O.tmp
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
