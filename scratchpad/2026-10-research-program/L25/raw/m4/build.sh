#!/bin/sh
# usage: build.sh <A|B>
. "$HOME/claude-exp-2026-10-31-top/env.sh"
t=$1
cd "$D/src-$t" || exit 10
cat "$D/src-$t/TREE_COMMIT"
rustc --version; cargo --version
cargo clean --release --offline -p nice_common
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-$t.err"; rc=$?
tail -40 "$D/logs/testbuild-$t.err"
e=$(date +%s); echo "TEST_BUILD_SECS $((e-s)) rc $rc"
[ $rc -eq 0 ] || exit 12
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-$t.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src-$t/$exe";; esac
echo "EXE $exe"
cp "$exe" "$D/bin/nice_common-test-$t" || exit 14
echo "MARKER_A $(strings "$D/bin/nice_common-test-$t" | grep -c 'L25TREE-A')"
echo "MARKER_B $(strings "$D/bin/nice_common-test-$t" | grep -c 'L25TREE-B')"
shasum -a 256 "$D/bin/nice_common-test-$t"
echo BUILD_DONE
