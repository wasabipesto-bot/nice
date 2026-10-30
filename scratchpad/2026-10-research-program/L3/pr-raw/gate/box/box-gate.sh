#!/bin/bash
# Gate check on the box: build, lint, tests. Logs to /root/gate/.
set -u
source /root/.cargo/env
mkdir -p /root/gate && cd /root/nice
log() { echo "=== $(date -u +%T) $*"; }
{
log fetch
git fetch -q origin pr/gpu-detailed-fd-gate && git checkout -q -B gate FETCH_HEAD && git log --oneline -2
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libpq-dev > /dev/null 2>&1; echo "libpq rc $?"
log build
time cargo build --release -p nice_client --features gpu 2>&1 | tail -3; echo "BUILD rc ${PIPESTATUS[0]}"
log fmt
cargo fmt --all --check; echo "FMT rc $?"
log clippy-default
cargo clippy -p "*" --all-targets -- -D warnings 2>&1 | tail -5; echo "CLIPPY1 rc ${PIPESTATUS[0]}"
log clippy-gpu
cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings 2>&1 | tail -5; echo "CLIPPY2 rc ${PIPESTATUS[0]}"
log clippy-gpu-only
cargo clippy --all-targets --features gpu -- -D warnings 2>&1 | tail -5; echo "CLIPPY3 rc ${PIPESTATUS[0]}"
log done-build-lint
} > /root/gate/build.log 2>&1
