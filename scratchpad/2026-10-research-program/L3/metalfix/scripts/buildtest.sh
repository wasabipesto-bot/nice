#!/bin/sh
# usage: buildtest.sh <tag>: build the nice_common test binary from src, copy to bin/nice_common-test-<tag>
. "$HOME/claude-exp-2026-10-31-fd-metal/scripts/env.sh"
tag=$1
cd "$D/src" || exit 10
git log --oneline -1; git status --short
rustc --version
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-$tag.err"; rc=$?
tail -8 "$D/logs/testbuild-$tag.err"
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"
[ $rc -eq 0 ] || { cat "$D/logs/testbuild-$tag.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-$tag.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src/$exe";; esac
mkdir -p "$D/bin"
cp "$exe" "$D/bin/nice_common-test-$tag" || exit 14
echo BUILD_DONE
