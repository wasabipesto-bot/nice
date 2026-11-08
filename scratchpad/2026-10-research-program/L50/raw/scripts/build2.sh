#!/bin/bash
# L50 builds after chain 1: the instrumented build with the gap histogram,
# the two-pass scan, the seeded check, both, and the check bench.
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
L=$R/build2.log
b() { # name features example
  echo "### $(date -u +%H:%M:%S) build $1 [$2] $3" >> $L
  nice -n 19 cargo build --profile profiling -p nice_common --example $3 ${2:+--features $2} >> $L 2>&1 || { echo "BUILD FAILED $1" >> $L; exit 1; }
  cp target/profiling/examples/$3 bin/$1
}
cp bin/plain bin/plain0; cp bin/prof bin/prof0
b prof l50-prof l50_prof
b scan2 l50-scan2 l50_prof
b check l50-check l50_prof
b scan2check l50-scan2,l50-check l50_prof
b plain "" l50_prof
b checkbench "" l50_check
md5sum bin/* >> $L
echo "#### done $(date -u +%H:%M:%S)" >> $L
