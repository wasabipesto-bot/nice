#!/bin/bash
# fmt, clippy (-D warnings) on nice_common with and without the device features, production's lib tests
cd /root/midout; source ~/.cargo/env
L=/root/b3/final/lint; mkdir -p $L
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt
export CARGO_TARGET_DIR=/root/t/lint
{ cargo fmt --all --check && echo FMT-CLEAN; } > $L/fmt.log 2>&1
cargo clippy --offline -p nice_common --all-targets -- -D warnings > $L/clippy_default.log 2>&1; echo "rc=$?" >> $L/clippy_default.log
cargo clippy --offline -p nice_common --all-targets --features cubecl-cuda,cubecl-spirv -- -D warnings > $L/clippy_gpu.log 2>&1; echo "rc=$?" >> $L/clippy_gpu.log
cargo test --offline --release -p nice_common --lib > $L/suite.log 2>&1; echo "rc=$?" >> $L/suite.log
echo done > $L/done
