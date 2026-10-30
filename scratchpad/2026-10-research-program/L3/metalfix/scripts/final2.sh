#!/bin/sh
# Final confirmation on the committed trees: src-gate (af41956, fix + gate), src-lift (297a969, gate lifted).
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
build() { # tree target tag
  cd "$1" || exit 20
  echo "=== BUILD $3: $(git log --oneline -1) $(git status --short | wc -l) dirty"
  s=$(date +%s)
  CARGO_TARGET_DIR="$2" cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-$3.err"; rc=$?
  echo "TEST_BUILD $3 secs $(( $(date +%s)-s )) rc $rc"; [ $rc -eq 0 ] || { tail -30 "$D/logs/testbuild-$3.err"; exit 21; }
  exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-$3.err" | head -1)
  cp "$exe" "$D/bin/nice_common-test-$3" || exit 22
  s=$(date +%s)
  CARGO_TARGET_DIR="$2" cargo build --release --offline -p nice_client --features cubecl > "$D/logs/clientbuild-$3.log" 2>&1; rc=$?
  echo "CLIENT_BUILD $3 secs $(( $(date +%s)-s )) rc $rc"; [ $rc -eq 0 ] || { tail -30 "$D/logs/clientbuild-$3.log"; exit 23; }
  cp "$2/release/nice_client" "$D/bin/nice_client-$3" || exit 24
}
suite() { # tree tag
  T="$D/bin/nice_common-test-$2"
  cd "$1/common" || exit 30
  export RUST_BACKTRACE=1 RUST_LOG=warn
  for t in fd detailed_kernel_by_device; do
    echo "=== $2 $t"; "$T" $t --test-threads=1 2>&1 | grep -E "^test |test result"
  done
  for t in cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed \
           cubecl_detailed_fd::tests::metal_half_shift_div_repro cubecl_backend::tests::cubecl_reads_back_every_near_miss \
           cubecl_backend::tests::cubecl_matches_cpu_detailed cubecl_backend::tests::cubecl_detailed_survives_more_batches_than_the_task_cap; do
    s=$(date +%s)
    "$T" $t --ignored --exact --test-threads=1 --nocapture > "$D/logs/final-$2-$(echo $t | sed 's/.*:://').log" 2>&1
    echo "=== $2 $t rc=$? secs=$(( $(date +%s)-s )) $(grep -E 'test result' "$D/logs/final-$2-$(echo $t | sed 's/.*:://').log")"
  done
}
build "$D/src-gate" "$D/target-pr" gate
build "$D/src-lift" "$D/target" lift
suite "$D/src-gate" gate
suite "$D/src-lift" lift
cd "$D" || exit 40
for t in gate lift; do
  s=$(date +%s)
  NICE_API_BASE=http://127.0.0.1:9 RUST_LOG=debug "$D/bin/nice_client-$t" detailed --gpu --benchmark --benchmark-secs 60 > "$D/logs/bench-final-$t.log" 2>&1 < /dev/null
  echo "BENCH $t rc=$? secs=$(( $(date +%s)-s ))"
  grep -E "^b[0-9]+_detailed|NiceMark" "$D/logs/bench-final-$t.log"
  grep -m2 -E "CubeCL detailed b(40|50)" "$D/logs/bench-final-$t.log" | cut -c1-160
done
echo FINAL2_DONE
