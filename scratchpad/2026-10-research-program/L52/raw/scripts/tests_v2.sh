#!/bin/bash
# Tests on the amended head (release, nice -n 19), then once with the piece
# constant temporarily lowered to 9 (uncommitted; reverted at the end): the
# non-ignored cpu_join suite (without the pass-1 test, whose fixed lengths
# assume a piece of >= 1024) and the opt-in production reference.
WT=/home/claude/projects/nice/.worktrees/l52-two-pass-scan
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L52/raw
cd $WT
export CARGO_TARGET_DIR=$WT/target
h() { echo "### $(date -u +%H:%M:%S) $* (head $(git rev-parse --short HEAD); dirty: $(git status --short | tr '\n' ' '); load $(cut -d' ' -f1-3 /proc/loadavg))"; }
{ h "cargo test --release -p nice_common -p nice_client"
  nice -n 19 cargo test --release -p nice_common -p nice_client 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"; } > $R/unit-tests-v2.txt 2>&1
{ h "cargo test --release -p nice_common --lib cpu_join -- --nocapture (pass-1 and table tests' output)"
  nice -n 19 cargo test --release -p nice_common --lib -- --nocapture the_first_pass the_bit_tables every_scan 2>&1
  echo "exit $?"; } > $R/unit-tests-pass1-v2.txt 2>&1
{ h "NICE_TEST_CPU_JOIN_REF=3 cpu_join_matches_the_reference_on_production_fields"
  NICE_TEST_CPU_JOIN_REF=3 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-prodref-v2.txt 2>&1
{ h "NICE_TEST_JOIN_FULL_FIELD=1 cpu_join_matches_the_reference_on_a_whole_field"
  NICE_TEST_JOIN_FULL_FIELD=1 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_a_whole_field -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-fullfield-v2.txt 2>&1
# PIECE = 9, temporarily
sed -i 's/^const PIECE: usize = 1024;$/const PIECE: usize = 9;/' common/src/cpu_join.rs
{ h "PIECE = 9 (temporary): cargo test --release -p nice_common --lib cpu_join -- --skip the_first_pass"
  grep -n "^const PIECE" common/src/cpu_join.rs
  nice -n 19 cargo test --release -p nice_common --lib cpu_join -- --skip the_first_pass 2>&1
  echo "exit $?"
  h "PIECE = 9 (temporary): NICE_TEST_CPU_JOIN_REF=3 production reference"
  NICE_TEST_CPU_JOIN_REF=3 nice -n 19 cargo test --release -p nice_common --lib cpu_join_matches_the_reference_on_production_fields -- --ignored --nocapture 2>&1
  echo "exit $?"; } > $R/unit-tests-piece9.txt 2>&1
git checkout common/src/cpu_join.rs
h "reverted" >> $R/unit-tests-piece9.txt
echo "### $(date -u +%H:%M:%S) tests v2 done" >> $R/unit-tests-piece9.txt
