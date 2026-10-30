#!/bin/sh
# Final confirmation on the committed source: build the test binary, run the detailed/FD tests.
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
cd "$D/src" || exit 10
cp "$D/patch/cubecl_detailed_fd_final.rs" common/src/cubecl_detailed_fd.rs || exit 11
md5 -q common/src/cubecl_detailed_fd.rs
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-final.err"; rc=$?
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"; [ $rc -eq 0 ] || { tail -30 "$D/logs/testbuild-final.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-final.err" | head -1)
cp "$exe" "$D/bin/nice_common-test-final" || exit 13
T="$D/bin/nice_common-test-final"
cd "$D/src/common" || exit 14
export RUST_BACKTRACE=1 RUST_LOG=warn
"$T" --list --ignored 2>/dev/null | grep -E "detailed|fd_|half_shift" 
one() {
  s=$(date +%s)
  echo "=== $*"
  "$T" "$@" --test-threads=1 --nocapture
  echo "=== RESULT $1 rc=$? secs=$(( $(date +%s)-s ))"
}
one fd
one cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu --ignored --exact
one cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed --ignored --exact
one cubecl_detailed_fd::tests::metal_half_shift_div_repro --ignored --exact
export NICE_METAL_DIV_REPRO=1
one cubecl_detailed_fd::tests::metal_half_shift_div_repro --ignored --exact
unset NICE_METAL_DIV_REPRO
one cubecl_backend::tests::cubecl_reads_back_every_near_miss --ignored --exact
one cubecl_backend::tests::cubecl_matches_cpu_detailed --ignored --exact
one cubecl_backend::tests::cubecl_detailed_survives_more_batches_than_the_task_cap --ignored --exact
echo FINAL_DONE
