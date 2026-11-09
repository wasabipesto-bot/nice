#!/bin/bash
# After the chain: (1) debug-build tests of the new code (overflow checks and
# debug assertions on); (2) the variants in place: base, PR, PR without the
# top's digits (notop), PR with L50's V3 form (v3), 3 rounds alternating, 1
# thread, b60 1e16 and b62 1e17 slice 0; (3) the check alone on recorded
# survivors (scratch bench); (4) the opt-in exhaustive quotient test.
# Scratch edits are reverted after each step (git checkout of cpu_join.rs).
set -u
WT=/home/claude/projects/nice/.worktrees/l56-seeded-check
R=/home/claude/projects/nice/scratchpad/2026-10-research-program/L56/raw
S=$R/scripts
cd $WT
export CARGO_TARGET_DIR=$WT/target
h() { echo "### $(date -u +%H:%M:%S) $* (head $(git rev-parse --short HEAD); dirty: $(git status --short | tr '\n' ' '); load $(cut -d' ' -f1-3 /proc/loadavg))"; }
{ h "debug build: cargo test -p nice_common --lib (cpu_check, windows, production survivors, stepped tops)"
  nice -n 19 cargo test -p nice_common --lib -- cpu_check cpu_join_matches_the_reference_on_the_test_windows the_full_check_is_exact_on_production_survivors stepped_tops_equal_divided_tops cpu_join_finds_69 --nocapture 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"; } > $R/unit-tests-debug.txt 2>&1
# Variants
for v in notop v3; do
  { h "variant $v: build"
    python3 $S/variants.py $v && git diff --stat
    nice -n 19 cargo build --release -p nice_common --example l52_ab 2>&1 | tail -2
    mkdir -p bin/$v && cp target/release/examples/l52_ab bin/$v/l52_ab && md5sum bin/$v/l52_ab
    git checkout common/src/cpu_join.rs; } >> $R/build-variants.log 2>&1
done
O=$R/ab-variants.txt
load1() { cut -d' ' -f1 /proc/loadavg; }
for r in 1 2 3; do
  for i in $(seq 1 72); do awk -v l="$(load1)" 'BEGIN{exit !(l <= 2.0)}' && break; sleep 5; done
  echo "#### round $r start $(date -u +%H:%M:%S) load $(cat /proc/loadavg)" >> $O
  if (( r % 2 == 1 )); then ORDER="base pr notop v3"; else ORDER="v3 notop pr base"; fi
  for c in "b60e16_1t|60 1157209632114824200908 1e16 1 4" "b62e17s0_1t|62 4473066762334864396992 1e17 1 4 0"; do
    name=${c%%|*}; args=${c#*|}
    for bin in $ORDER; do
      echo "### r$r $name $bin $(date -u +%H:%M:%S) load $(load1)" >> $O
      nice -n 19 bin/$bin/l52_ab $args >> $O 2>&1
    done
  done
done
echo "#### done $(date -u +%H:%M:%S)" >> $O
# The check alone on recorded survivors
{ h "scratch bench (raw/scripts/l56_scratch_bench.rs appended to cpu_join.rs, reverted after)"
  cat $S/l56_scratch_bench.rs >> common/src/cpu_join.rs
  nice -n 19 cargo test --release -p nice_common --lib l56_check_bench -- --ignored --nocapture 2>&1 | grep -v "^   Compiling"
  echo "exit ${PIPESTATUS[0]}"
  git checkout common/src/cpu_join.rs; } > $R/check-bench.txt 2>&1
# Exhaustive quotients (opt-in)
{ h "NICE_TEST_CPU_CHECK_EXHAUSTIVE=1 magic_quotients_are_exact_everywhere"
  NICE_TEST_CPU_CHECK_EXHAUSTIVE=1 nice -n 19 cargo test --release -p nice_common --lib magic_quotients_are_exact_everywhere -- --ignored --nocapture 2>&1 | grep -E "test |divisors|result"
  echo "exit ${PIPESTATUS[0]}"; h "exhaustive done"; } > $R/unit-tests-exhaustive.txt 2>&1
echo "### $(date -u +%H:%M:%S) post done" >> $R/unit-tests-exhaustive.txt
