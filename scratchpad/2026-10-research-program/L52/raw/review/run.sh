#!/bin/bash
# usage: run.sh NAME   (NAME = a mutation name, or I1 for instrumentation)
set -u
W=/home/claude/projects/nice/.worktrees/review-l52
export CARGO_TARGET_DIR=$W/target
cd $W
git checkout -q -- common/src/cpu_join.rs
name=$1
if [ "$name" = I1 ]; then python3 /tmp/l52rev/mut/instrument.py common/src/cpu_join.rs; else python3 /tmp/l52rev/mut/mutate.py common/src/cpu_join.rs $name; fi || exit 1
git diff --stat | tail -1
out=/tmp/l52rev/mut/$name
nice -n 19 cargo test --release -p nice_common --no-run -j 3 > $out.build 2>&1
rc=$?
bin=$(grep -o 'unittests src/lib.rs ([^)]*)' $out.build | sed 's/.*(\(.*\))/\1/')
if [ $rc -ne 0 ] || [ -z "$bin" ]; then echo "$name BUILD FAILED"; tail -20 $out.build; git checkout -q -- common/src/cpu_join.rs; exit 1; fi
cd common
if [ "$name" = I1 ]; then
  nice -n 19 $W/$bin --exact cpu_join::tests::the_first_pass_lists_the_same_bottoms_on_every_path --nocapture --test-threads 1 > $out.test 2>&1
  nice -n 19 $W/$bin --exact cpu_join::tests::cpu_join_matches_the_reference_on_the_test_windows --nocapture --test-threads 1 >> $out.test 2>&1
  nice -n 19 $W/$bin --exact cpu_join::tests::every_scan_finds_the_same_pairs --nocapture --test-threads 1 >> $out.test 2>&1
  grep INSTR $out.test
elif [ "$name" = P9 ]; then
  nice -n 19 $W/$bin cpu_join:: --skip the_first_pass --test-threads 2 > $out.test 2>&1
  grep -E "^test .*(ok|FAILED)$|test result" $out.test
else
  nice -n 19 $W/$bin cpu_join:: --test-threads 2 > $out.test 2>&1
  echo "$name:"; grep -E "^test .*FAILED$|test result" $out.test
fi
cd $W && git checkout -q -- common/src/cpu_join.rs
