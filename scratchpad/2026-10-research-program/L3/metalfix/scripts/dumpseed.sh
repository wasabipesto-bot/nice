#!/bin/sh
# usage: dumpseed.sh <tag>: shader dump of the seed test
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
tag=$1
cd "$D/src/common" || exit 10
CUBECL_DEBUG_LOG="$D/logs/shader-seed-$tag.log" RUST_LOG=warn "$D/bin/nice_common-test-$tag" cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu --ignored --exact --test-threads=1 > /dev/null 2>&1
CUBECL_DEBUG_LOG="$D/logs/shader-repro-$tag.log" NICE_HI_DIV_REPRO=1 NICE_HI_DIV_VARIANTS=7 RUST_LOG=warn "$D/bin/nice_common-test-$tag" cubecl_detailed_fd::tests::metal_hi_div_constant_repro --ignored --exact --test-threads=1 --nocapture
echo "=== RESULT rc=$?"
ls -la "$D/logs/" | grep shader
