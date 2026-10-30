#!/bin/sh
D="$HOME/claude-exp-2026-10-31-fd-metal"
mkdir -p "$D/swift/mc" "$D/swift/tmp"
export TMPDIR="$D/swift/tmp/"
export CLANG_MODULE_CACHE_PATH="$D/swift/mc"
cd "$D/swift2" || exit 10
swiftc -O -module-cache-path "$D/swift/mc" -o h2_repro h2_repro.swift || exit 11
./h2_repro
echo "=== RESULT rc=$?"
