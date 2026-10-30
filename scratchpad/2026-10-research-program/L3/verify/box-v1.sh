#!/bin/bash
# Phase 1 on the box at 297a969: fmt, build, clippy (lint recipe + gate's gpu-only line), test build. Logs to /root/v/.
set -u
source /root/.cargo/env
mkdir -p /root/v && cd /root/nice
log() { echo "=== $(date -u +%T) $*"; }
{
log head
git checkout -q 297a969 && git log --oneline -1 && git status --short | head -5
rustc --version; cargo --version
log fmt
cargo fmt --all --check; echo "FMT rc $?"
log build
time cargo build --release -p nice_client --features gpu 2>&1 | tail -3; echo "BUILD rc ${PIPESTATUS[0]}"
sha256sum target/release/nice_client; ./target/release/nice_client --version
log clippy-default
cargo clippy -p "*" --all-targets -- -D warnings 2>&1 | tail -5; echo "CLIPPY1 rc ${PIPESTATUS[0]}"
log clippy-gpu-spirv
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings 2>&1 | tail -5; echo "CLIPPY2 rc ${PIPESTATUS[0]}"
log clippy-gpu-only
cargo clippy --all-targets --features gpu -- -D warnings 2>&1 | tail -5; echo "CLIPPY3 rc ${PIPESTATUS[0]}"
log test-no-run
cargo test --release -p nice_common --features gpu --no-run 2>&1 | tail -6; echo "NORUN rc ${PIPESTATUS[0]}"
log done-v1
} > /root/v/v1.log 2>&1
