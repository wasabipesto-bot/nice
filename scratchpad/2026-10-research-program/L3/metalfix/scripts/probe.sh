#!/bin/sh
# usage: probe.sh <tag> [env assignments...]: run zz_fd_seed_probe from bin/nice_common-test-<tag>
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
tag=$1; shift
cd "$D/src/common" || exit 10
s=$(date +%s)
env "$@" RUST_LOG=warn "$D/bin/nice_common-test-$tag" zz_fd_seed_probe --ignored --test-threads=1 --nocapture
echo "=== RESULT rc=$? secs=$(( $(date +%s)-s ))"
