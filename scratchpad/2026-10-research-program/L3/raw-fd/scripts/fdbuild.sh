#!/bin/bash
# fast-iteration build of the fd worktree (no LTO, many CGUs, incremental)
source ~/.cargo/env
cd /root/fd
export CARGO_TARGET_DIR=/root/tfast CARGO_PROFILE_RELEASE_LTO=false CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16 CARGO_PROFILE_RELEASE_INCREMENTAL=true
cargo test --release -p nice_common --features gpu --no-run 2>&1
echo "== test build exit $?"
cargo build --release -p nice_client --features gpu 2>&1
echo "== client build exit $?"
