#!/bin/sh
# usage: build.sh <main|pr>
. "$HOME/claude-exp-2026-10-30-fd/env.sh"
t=$1
cd "$D/src-$t" || exit 10
git log --oneline -1
rustc --version; cargo --version
cargo clean --release --offline -p nice_common -p nice_client
s=$(date +%s)
cargo build --release --offline -p nice_client --features cubecl || exit 11
e=$(date +%s); echo "CLIENT_BUILD_SECS $((e-s))"
cp "$CARGO_TARGET_DIR/release/nice_client" "$D/bin/nice_client-$t" || exit 13
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run 2> "$D/logs/testbuild-$t.err"; rc=$?
cat "$D/logs/testbuild-$t.err"
e=$(date +%s); echo "TEST_BUILD_SECS $((e-s)) rc $rc"
[ $rc -eq 0 ] || exit 12
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild-$t.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src-$t/$exe";; esac
cp "$exe" "$D/bin/nice_common-test-$t" || exit 14
echo "MARKER_COUNT client $(strings "$D/bin/nice_client-$t" | grep -c 'detailed run length')"
echo "MARKER_COUNT test $(strings "$D/bin/nice_common-test-$t" | grep -c 'detailed run length')"
echo BUILD_DONE
