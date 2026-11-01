#!/bin/bash
# fmt + clippy -D warnings (default and nice_client/gpu) on /root/padsrc, separate target dir.
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt-clippy
L=/root/pad
cd /root/padsrc
dpkg -s libpq-dev > /dev/null 2>&1 || apt-get install -y -qq libpq-dev > $L/apt_libpq.log 2>&1
rustc --version > $L/lint_toolchain.txt
( cargo fmt --all --check && echo FMT_OK ) > $L/lint_fmt.log 2>&1; tail -1 $L/lint_fmt.log
( cargo clippy -j 9 -p "*" --all-targets --features nice_client/gpu -- -D warnings && echo CLIPPY_GPU_OK ) > $L/lint_clippy_gpu.log 2>&1; tail -1 $L/lint_clippy_gpu.log
( cargo clippy -j 9 -p "*" --all-targets -- -D warnings && echo CLIPPY_DEFAULT_OK ) > $L/lint_clippy_default.log 2>&1; tail -1 $L/lint_clippy_default.log
