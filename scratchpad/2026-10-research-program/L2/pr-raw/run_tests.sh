#!/bin/bash
# Whole nice_common suite on the PR tree, then the ignored timing test pinned to one core, twice.
set -u
. ~/.cargo/env
OUT=/root/out
cd /root/pr
git log --oneline -1 > $OUT/test-tree.txt
( time cargo test --release -p nice_common --no-fail-fast ) > $OUT/test-pr-common.log 2>&1
echo "suite exit $?" >> $OUT/test-progress.log
for pass in 1 2; do
  taskset -c 2 cargo test --release -p nice_common --lib detailed_fd::tests::fd_timing -- --ignored --nocapture --test-threads 1 \
    > $OUT/fd-timing-$pass.log 2>&1
  echo "timing $pass exit $?" >> $OUT/test-progress.log
done
echo TESTSDONE >> $OUT/test-progress.log
