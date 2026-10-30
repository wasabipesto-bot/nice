#!/bin/sh
D="$HOME/claude-exp-2026-10-31-fd-metal"
mkdir -p "$D/swift/mc" "$D/swift/tmp"
export TMPDIR="$D/swift/tmp/"
export CLANG_MODULE_CACHE_PATH="$D/swift/mc"
cd "$D/swift" || exit 10
swiftc -O -module-cache-path "$D/swift/mc" -o shr_div_repro shr_div_repro.swift || exit 11
./shr_div_repro
echo "=== RESULT rc=$?"
