#!/bin/bash
# Reviewer's own mutants of the carry rule (PR review). Run in the mutant worktree, one at a time.
W=/home/claude/projects/nice/.worktrees/review-cpu2-pr-mut
O=/home/claude/projects/nice/scratchpad/2026-10-research-program/CPU2/review-pr/mut
export CARGO_TARGET_DIR=/home/claude/projects/nice/.worktrees/rebase-1112/target
cd $W
OLD='            Some((last_id, last)) if last_id == id \&\& last < v => (true, v - last <= RUN_GAP),'
for m in $*; do
  git checkout -q common/src/cpu_join.rs
  case $m in
    stepback1) NEW='            Some((last_id, last)) if last_id == id \&\& last <= v + 1 => (true, v.saturating_sub(last) <= RUN_GAP),' ;;
    lenid) NEW='            Some((_, last)) if self.next.len() == len \&\& last < v => (true, v - last <= RUN_GAP),' ;;
    retry) NEW='            Some((last_id, last)) if last_id == id \&\& last <= v => (true, v - last <= RUN_GAP),' ;;
  esac
  sed -i "s/^$OLD\$/$NEW/" common/src/cpu_join.rs
  git diff > $O/mutant-$m.diff
  [ -s $O/mutant-$m.diff ] || { echo "no change for $m" > $O/tests-mutant-$m.txt; continue; }
  touch common/src/cpu_join.rs
  nice -n 19 cargo test --release -p nice_common --lib -j 1 -- the_carried_state the_skip_walk a_field_in_slices cpu_join_matches_the_reference_on_a_whole_field cpu_join_agrees_with_the_stride_path --test-threads=1 > $O/tests-mutant-$m.txt 2>&1
  echo "exit $?" >> $O/tests-mutant-$m.txt
done
git checkout -q common/src/cpu_join.rs
git status --short > $O/worktree-status-after.txt
echo done > $O/mut.done
