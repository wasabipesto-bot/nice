#!/bin/bash
# After the NiceMark rounds: (1) perf profiles of both binaries at the two
# production shapes (1 thread, 4 partitions, recording from 3.5 s, past the
# slice setup); (2) rebuild the branch head's binaries and compare them with
# the measured ones; (3) the head's tests (full suites, clippy, fmt) and the
# opt-in exhaustive FX test.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
WT=/home/claude/projects/nice/.worktrees/pr-cpu-join-lean
AB=$WT/target-ab
until grep -q "^### done" $R/nicemark-runs.txt 2>/dev/null; do sleep 20; done
P=$R/perf-runs.txt
for shape in "b60e16|60 1157209632114824200908 1e16 1 4" "b62e17s0|62 4473066762334864396992 1e17 1 4 0"; do
  name=${shape%%|*}; args=${shape#*|}
  for bin in base pr; do
    echo "### $(date -u +%H:%M:%S) perf $name 1t $bin load $(cut -d' ' -f1 /proc/loadavg)" >> $P
    nice -n 19 perf record -q -F 1999 -D 3500 -o /tmp/l49perf.data -- $AB/$bin/l49_ab $args >> $P 2>&1
    perf report -i /tmp/l49perf.data --stdio --no-children --sort symbol 2>/dev/null | grep -v '^#' | grep -v '^$' | head -14 >> $P
    rm -f /tmp/l49perf.data
  done
done
cd $WT
echo "### $(date -u +%H:%M:%S) rebuild head $(git rev-parse HEAD)" >> $R/build-head.log
CARGO_TARGET_DIR=$WT/target nice -n 19 cargo build --release -p nice_common --example l49_ab >> $R/build-head.log 2>&1
CARGO_TARGET_DIR=$WT/target nice -n 19 cargo build --release -p nice_client >> $R/build-head.log 2>&1
md5sum $WT/target/release/examples/l49_ab $WT/target/release/nice_client $AB/*/* >> $R/build-head.log
mv $WT/common/examples /tmp/l49-examples-hold
(CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common -p nice_client > $R/unit-tests-head.txt 2>&1; echo "exit $?" >> $R/unit-tests-head.txt)
(CARGO_TARGET_DIR=$WT/target nice -n 19 cargo clippy -p "*" --all-targets -- -D warnings > $R/clippy-head.txt 2>&1; echo "exit $?" >> $R/clippy-head.txt; cargo fmt --all --check >> $R/clippy-head.txt 2>&1; echo "fmt exit $?" >> $R/clippy-head.txt)
(NICE_TEST_FX_EXHAUSTIVE=1 CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common --lib fx_digits_are_exact_everywhere -- --ignored --nocapture > $R/unit-tests-fx-exhaustive.txt 2>&1; echo "exit $?" >> $R/unit-tests-fx-exhaustive.txt)
mv /tmp/l49-examples-hold $WT/common/examples
echo "### post done $(date -u +%H:%M:%S)" >> $R/build-head.log
