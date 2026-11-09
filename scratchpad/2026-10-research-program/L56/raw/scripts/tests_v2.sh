#!/bin/bash
# Tests after the review fixes (release, nice -n 19): the whole suite, the
# new verdict test's output, the opt-in references, fmt and clippy.
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
h() { echo "### $(date -u +%H:%M:%S) $* (head $(git rev-parse --short HEAD); dirty: $(git status --short | tr '\n' ' '); load $(cut -d' ' -f1-3 /proc/loadavg))"; }
{ h "cargo test --release -p nice_common -p nice_client"
  nice -n 19 cargo test --release -p nice_common -p nice_client 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"; } > $R/unit-tests-v2.txt 2>&1
{ h "the new verdict test and the other cpu_check tests with output"
  nice -n 19 cargo test --release -p nice_common --lib -- --nocapture cpu_check 2>&1
  echo "exit $?"; } > $R/unit-tests-v2-verdict.txt 2>&1
{ h "NICE_TEST_CPU_JOIN_REF=3 cpu_join_matches_the_reference_on_production_fields"
  NICE_TEST_CPU_JOIN_REF=3 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-v2-prodref.txt 2>&1
{ h "NICE_TEST_JOIN_FULL_FIELD=1 cpu_join_matches_the_reference_on_a_whole_field"
  NICE_TEST_JOIN_FULL_FIELD=1 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-v2-fullfield.txt 2>&1
{ h "cargo fmt --all --check"
  cargo fmt --all --check 2>&1; echo "exit $?"
  h "cargo clippy -p '*' --all-targets -- -D warnings"
  nice -n 19 cargo clippy -p "*" --all-targets -- -D warnings 2>&1 | grep -v "^    Checking\|^   Compiling"; echo "exit ${PIPESTATUS[0]}"; } > $R/clippy-default-v2.txt 2>&1
echo "### $(date -u +%H:%M:%S) tests v2 done" >> $R/clippy-default-v2.txt
