#!/bin/bash
# Tests on the branch head (release, nice -n 19): the workspace tests of
# nice_common and nice_client, the new pass-1 test with its output, the
# opt-in production reference (3 partitions a plan field) and the whole b42
# field (join = reference = stride).
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
h() { echo "### $(date -u +%H:%M:%S) $* (head $(git rev-parse --short HEAD); load $(cut -d' ' -f1-3 /proc/loadavg))"; }
{ h "cargo test --release -p nice_common -p nice_client"
  nice -n 19 cargo test --release -p nice_common -p nice_client 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"; } > $R/unit-tests.txt 2>&1
{ h "cargo test --release -p nice_common --lib the_first_pass -- --nocapture"
  nice -n 19 cargo test --release -p nice_common --lib the_first_pass -- --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-pass1.txt 2>&1
{ h "NICE_TEST_CPU_JOIN_REF=3 cpu_join_matches_the_reference_on_production_fields"
  NICE_TEST_CPU_JOIN_REF=3 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-prodref.txt 2>&1
{ h "NICE_TEST_JOIN_FULL_FIELD=1 cpu_join_matches_the_reference_on_a_whole_field"
  NICE_TEST_JOIN_FULL_FIELD=1 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-fullfield.txt 2>&1
echo "### $(date -u +%H:%M:%S) tests done" >> $R/unit-tests-fullfield.txt
