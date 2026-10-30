#!/bin/sh
# usage: suite.sh <tag>: the exactness tests on bin/nice_common-test-<tag>
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
tag=$1
T="$D/bin/nice_common-test-$tag"
cd "$D/src/common" || exit 10
export RUST_BACKTRACE=1 RUST_LOG=warn
one() {
  s=$(date +%s)
  echo "=== $*"
  "$T" "$@" --test-threads=1 --nocapture
  echo "=== RESULT $1 rc=$? secs=$(( $(date +%s)-s ))"
}
one cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu --ignored --exact
NICE_METAL_DIV_REPRO=1 one cubecl_detailed_fd::tests::metal_half_shift_div_repro --ignored --exact
one fd
one cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed --ignored --exact
one cubecl_backend::tests::cubecl_reads_back_every_near_miss --ignored --exact
one cubecl_backend::tests::cubecl_matches_cpu_detailed --ignored --exact
echo SUITE_DONE
