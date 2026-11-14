#!/bin/bash
# Release tests on the box: the branch's full nice_common suite, the new L2
# test alone, then the L2 test (and the ascending skip-walk tests) on each mutant.
source /root/.cargo/env
O=/root/out
(cd /root/rev && CARGO_TARGET_DIR=/root/t-rev cargo build --release -p nice_client > $O/build-rev.log 2>&1 && mkdir -p /root/bin/rev && cp /root/t-rev/release/nice_client /root/bin/rev/)
cd /root/brtest
CARGO_TARGET_DIR=/root/t-test cargo test --release -p nice_common -- --test-threads=40 > $O/tests-branch-full.txt 2>&1
echo "exit $?" >> $O/tests-branch-full.txt
CARGO_TARGET_DIR=/root/t-test cargo test --release -p nice_common --lib -- cpu_join::tests::the_carried_state --nocapture > $O/tests-branch-l2.txt 2>&1
echo "exit $?" >> $O/tests-branch-l2.txt
for m in reset back id; do
  rm -rf /root/mut-$m; cp -r /root/brtest /root/mut-$m
  python3 /root/mutants.py /root/mut-$m $m
  (cd /root/mut-$m && git diff > $O/mutant-$m.diff
   CARGO_TARGET_DIR=/root/t-test cargo test --release -p nice_common --lib -- cpu_join::tests::the_carried_state cpu_join::tests::the_skip_walk_finds_every_top_on_small_bases --nocapture --test-threads=2 > $O/tests-mutant-$m.txt 2>&1
   echo "exit $?" >> $O/tests-mutant-$m.txt)
done
echo done > $O/tests.done
