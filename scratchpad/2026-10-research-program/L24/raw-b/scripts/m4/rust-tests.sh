#!/bin/sh
# The web kernel tests on the M4 through naga's MSL (Firefox's compiler path on a Mac).
. "$HOME/claude-exp-2026-11-01-webfd/scripts/rust-env.sh"
cd "$D/src/common" || exit 10
export RUST_BACKTRACE=1 RUST_LOG=warn
for t in cubecl_web::tests::web_fd_seed_matches_cpu cubecl_web::tests::web_fd_matches_cpu_detailed \
         cubecl_web::tests::web_kernel_matches_cpu_detailed cubecl_web::tests::web_kernel_near_miss_matches_cpu_at_base_49 \
         cubecl_web::tests::web_kernel_finds_69_in_base_10; do
  n=$(echo $t | sed 's/.*:://')
  s=$(date +%s)
  "$D/bin/nice_common-test" $t --ignored --exact --test-threads=1 --nocapture > "$D/logs/test-$n.log" 2>&1
  echo "$n rc=$? secs=$(( $(date +%s)-s ))"
done
s=$(date +%s)
NICE_METAL_DIV_REPRO=1 "$D/bin/nice_common-test" cubecl_detailed_fd::tests::metal_half_shift_div_repro --ignored --exact --test-threads=1 --nocapture > "$D/logs/test-repro.log" 2>&1
echo "repro rc=$? secs=$(( $(date +%s)-s )) (expected to fail on Apple silicon)"
grep -E '^variant' "$D/logs/test-repro.log" | head -36
echo TESTS_DONE
