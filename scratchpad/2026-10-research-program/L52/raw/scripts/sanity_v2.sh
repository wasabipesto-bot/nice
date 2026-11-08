#!/bin/bash
# After the review fixes: the amended head (1cce00d) against #248's head on
# ivory, production shapes, 1 and 4 threads, 2 rounds alternating (a sanity
# check that the runtime piece length costs nothing; nice -n 19, load-gated).
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
L=$R/build-v2.log
mkdir -p bin/pr2 bin/base common/examples
cp $R/scripts/l52_ab.rs common/examples/
echo "### $(date -u +%H:%M:%S) build pr2 at $(git rev-parse --short HEAD) dirty: $(git status --short | tr '\n' ' ')" >> $L
nice -n 19 cargo build --release -p nice_common --example l52_ab >> $L 2>&1 && cp target/release/examples/l52_ab bin/pr2/
git checkout -q --detach 7f5260ba8b3f27788ab5faec8c4f8bdd489f73ce
echo "### $(date -u +%H:%M:%S) build base at $(git rev-parse --short HEAD) dirty: $(git status --short | tr '\n' ' ')" >> $L
nice -n 19 cargo build --release -p nice_common --example l52_ab >> $L 2>&1 && cp target/release/examples/l52_ab bin/base/
git checkout -q pr/cpu-join-two-pass-scan
md5sum bin/*/l52_ab >> $L
OUT=$R/ab-runs-v2.txt
load1() { cut -d' ' -f1 /proc/loadavg; }
others() { top -b -n1 -w 200 | awk 'NR>7 && $9+0 >= 20 && $12 != "l52_ab" && $12 != "top" {printf "%s(%s %s%%) ", $12, $2, $9}'; }
for r in 1 2; do
  for i in $(seq 1 72); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break; sleep 5; done
  l=$(load1); flag=OK; awk -v l="$l" 'BEGIN{exit !(l > 2.0)}' && flag=DISCARD
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg) $flag others: $(others)" >> $OUT
  if (( r % 2 == 1 )); then ORDER="base pr2"; else ORDER="pr2 base"; fi
  for c in "b60e16_1t|60 1157209632114824200908 1e16 1 4" "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0" "b60e16_4t|60 1157209632114824200908 1e16 4 16" "b62e17s0_4t|62 4473066762334864396992 1e17 4 16 0"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      b=$bin; [ $bin = pr2 ] && b=pr
      echo "### r$r $name $b $(date -u +%H:%M:%S) load $(load1) others: $(others)" >> $OUT
      nice -n 19 $WT/bin/$bin/l52_ab $args >> $OUT 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $OUT
