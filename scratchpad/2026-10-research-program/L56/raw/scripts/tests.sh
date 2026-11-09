#!/bin/bash
# Tests on the committed head (release, nice -n 19): the whole suite, the
# new tests' output, the opt-in references, fmt and clippy.
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
h() { echo "### $(date -u +%H:%M:%S) $* (head $(git rev-parse --short HEAD); dirty: $(git status --short | tr '\n' ' '); load $(cut -d' ' -f1-3 /proc/loadavg))"; }
{ h "cargo test --release -p nice_common -p nice_client"
  nice -n 19 cargo test --release -p nice_common -p nice_client 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"; } > $R/unit-tests.txt 2>&1
{ h "new and touched tests with output (cpu_check, cpu_join survivors, certificates)"
  nice -n 19 cargo test --release -p nice_common --lib -- --nocapture cpu_check the_full_check_is_exact_on_production_survivors stepped_ the_fast_certificate cpu_join_finds_69 cpu_join_matches_the_reference_on_the_test_windows 2>&1
  echo "exit $?"; } > $R/unit-tests-new.txt 2>&1
{ h "NICE_TEST_CPU_CHECK_REF=4 the_full_check_is_exact_on_production_shapes"
  NICE_TEST_CPU_CHECK_REF=4 nice -n 19 cargo test --release -p nice_common --lib the_full_check_is_exact_on_production_shapes -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-checkref.txt 2>&1
{ h "NICE_TEST_CPU_JOIN_REF=3 cpu_join_matches_the_reference_on_production_fields"
  NICE_TEST_CPU_JOIN_REF=3 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-prodref.txt 2>&1
{ h "NICE_TEST_JOIN_FULL_FIELD=1 cpu_join_matches_the_reference_on_a_whole_field"
  NICE_TEST_JOIN_FULL_FIELD=1 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-fullfield.txt 2>&1
{ h "cargo fmt --all --check"
  cargo fmt --all --check 2>&1; echo "exit $?"
  h "cargo clippy -p '*' --all-targets -- -D warnings (examples/l52_ab.rs moved out)"
  mv common/examples /tmp/l56-wip/examples-moved
  nice -n 19 cargo clippy -p "*" --all-targets -- -D warnings 2>&1 | grep -v "^    Checking\|^   Compiling"; echo "exit ${PIPESTATUS[0]}"
  mv /tmp/l56-wip/examples-moved common/examples; } > $R/clippy-default.txt 2>&1
echo "### $(date -u +%H:%M:%S) tests done" >> $R/unit-tests-fullfield.txt
