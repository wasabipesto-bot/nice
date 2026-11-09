#!/bin/bash
# The review's mutants M4 / M4b (an early exit on the verdict path only,
# after n²'s column 3 / column 5) against the new verdict test and the
# module's other tests; the source is restored from a copy after each.
# usage: mutants.sh   (in the worktree; log to raw/mutants.txt)
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
F=common/src/cpu_check.rs
cp $F /tmp/l56-cpu_check.rs.orig
O=$R/mutants.txt
for m in "M4 3" "M4b 5"; do
  set -- $m
  sed -i "s/if !COUNT \&\& \$j % 2 == 1 \&\& sc.repeat {/if !COUNT \&\& \$j % 2 == 1 \&\& (sc.repeat || \$j == $2) {/" $F
  { echo "### $(date -u +%H:%M:%S) mutant $1: exit after n² column $2 (verdict path only)"
    diff /tmp/l56-cpu_check.rs.orig $F
    nice -n 19 cargo test --release -p nice_common --lib -- cpu_check the_full_check_is_exact_on_production_survivors cpu_join_matches_the_reference_on_the_test_windows cpu_join_finds_69 2>&1 | grep -E "^test |panicked|left|right|test result|b[0-9]+ n ="
  } >> $O 2>&1
  cp /tmp/l56-cpu_check.rs.orig $F
done
echo "### $(date -u +%H:%M:%S) restored: $(git diff --stat | tail -1)" >> $O
rm -f /tmp/l56-cpu_check.rs.orig
