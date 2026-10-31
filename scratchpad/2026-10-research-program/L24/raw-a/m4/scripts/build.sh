#!/bin/sh
# Build the nice_common test binary (cubecl = wgpu/Metal), -j 4, offline.
. "$HOME/claude-exp-2026-10-31-seed/scripts/env.sh"
cd "$D/src" || exit 10
cat "$D/src/COMMIT" 2>/dev/null
rustc --version; cargo --version
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run -j 4 2> "$D/logs/testbuild.err"; rc=$?
tail -6 "$D/logs/testbuild.err"
echo "TEST_BUILD_SECS $(( $(date +%s)-s )) rc $rc"
[ $rc -eq 0 ] || { tail -40 "$D/logs/testbuild.err"; exit 12; }
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src/$exe";; esac
mkdir -p "$D/bin"
cp "$exe" "$D/bin/nice_common-test" || exit 14
shasum -a 256 "$D/bin/nice_common-test"
echo BUILD_DONE
