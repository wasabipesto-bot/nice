#!/bin/bash
# Review follow-up: the amended head's tests, lints and opt-in checks.
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L49/raw
WT=/home/claude/projects/nice/.worktrees/pr-cpu-join-lean
cd $WT
echo "### head $(git rev-parse HEAD) $(date -u +%H:%M:%S)" > $R/tests-v2.log
(CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common -p nice_client > $R/unit-tests-v2.txt 2>&1; echo "exit $?" >> $R/unit-tests-v2.txt)
(CARGO_TARGET_DIR=$WT/target nice -n 19 cargo clippy -p "*" --all-targets -- -D warnings > $R/clippy-v2.txt 2>&1; echo "exit $?" >> $R/clippy-v2.txt; cargo fmt --all --check >> $R/clippy-v2.txt 2>&1; echo "fmt exit $?" >> $R/clippy-v2.txt)
(NICE_TEST_CPU_JOIN_REF=3 CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture > $R/unit-tests-prodref-v2.txt 2>&1; echo "exit $?" >> $R/unit-tests-prodref-v2.txt)
(NICE_TEST_JOIN_FULL_FIELD=1 CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture > $R/unit-tests-fullfield-v2.txt 2>&1; echo "exit $?" >> $R/unit-tests-fullfield-v2.txt)
(NICE_TEST_FX_EXHAUSTIVE=1 CARGO_TARGET_DIR=$WT/target nice -n 19 cargo test --release -p nice_common --lib fx_digits_are_exact_everywhere -- --ignored --nocapture > $R/unit-tests-fx-exhaustive-v2.txt 2>&1; echo "exit $?" >> $R/unit-tests-fx-exhaustive-v2.txt)
echo "### done $(date -u +%H:%M:%S)" >> $R/tests-v2.log
