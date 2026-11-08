#!/bin/bash
# L50 chain 7: NiceMark CPU nice-only (4 threads, 150 s), #248's head vs the
# three prototypes (two-pass scan, seeded check, inlined survivor), 2 rounds,
# order alternating. Nothing is uploaded.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L50/raw
WT=/home/claude/projects/nice/.worktrees/l50-cpu-roadmap
B=$WT/bin
cd $WT
L=$R/build2.log
export CARGO_TARGET_DIR=$WT/target
echo "### $(date -u +%H:%M:%S) build nice_client base" >> $L
nice -n 19 cargo build --release -p nice_client >> $L 2>&1 || { echo "BUILD FAILED client base" >> $L; exit 1; }
cp target/release/nice_client $B/client-base
echo "### $(date -u +%H:%M:%S) build nice_client proto [scan2,check,inl]" >> $L
nice -n 19 cargo build --release -p nice_client --features nice_common/l50-scan2,nice_common/l50-check,nice_common/l50-inl >> $L 2>&1 || { echo "BUILD FAILED client proto" >> $L; exit 1; }
cp target/release/nice_client $B/client-proto
md5sum $B/client-* >> $L
OUT=$R/nicemark-runs.txt
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in 1 2; do
  if (( r % 2 == 1 )); then ORDER="base proto"; else ORDER="proto base"; fi
  for bin in $ORDER; do
    for i in $(seq 1 72); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 1.5)}' && break; sleep 5; done
    echo "### r$r $bin start $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" >> $OUT
    nice -n 19 $B/client-$bin niceonly --benchmark --threads 4 --benchmark-secs 150 --benchmark-json \
      > $R/nicemark-r$r-$bin.json 2> $R/nicemark-r$r-$bin.stderr
    echo "### r$r $bin end $(date -u +%H:%M:%S) exit $?" >> $OUT
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
