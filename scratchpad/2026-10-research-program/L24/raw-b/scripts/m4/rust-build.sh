#!/bin/sh
# Offline test build of nice_common (cubecl = wgpu -> naga -> Metal), -j 4.
. "$HOME/claude-exp-2026-11-01-webfd/scripts/rust-env.sh"
set -e
mkdir -p "$CARGO_HOME/registry"
cp -c -R "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/index" "$CARGO_HOME/registry/"
tar -xzf "$D/crates-ship.tgz" -C "$CARGO_HOME/registry"
cd "$D/src"
rustc --version; cargo --version
s=$(date +%s)
cargo test --release --offline -p nice_common --features cubecl --no-run -j 4 2> "$D/logs/testbuild.err"
echo "TEST_BUILD_SECS $(( $(date +%s)-s ))"
exe=$(sed -n 's/.*Executable unittests src\/lib.rs (\(.*\))$/\1/p' "$D/logs/testbuild.err" | head -1)
case "$exe" in /*) ;; *) exe="$D/src/$exe";; esac
mkdir -p "$D/bin"; cp "$exe" "$D/bin/nice_common-test"; shasum -a 256 "$D/bin/nice_common-test"
echo BUILD_DONE
