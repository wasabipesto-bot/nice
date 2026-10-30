#!/bin/sh
# usage: ztest.sh <tag> <testname> [env assignments...]
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
tag=$1; name=$2; shift 2
cd "$D/src/common" || exit 10
s=$(date +%s)
env "$@" RUST_LOG=warn "$D/bin/nice_common-test-$tag" "$name" --ignored --exact --test-threads=1 --nocapture
echo "=== RESULT rc=$? secs=$(( $(date +%s)-s ))"
