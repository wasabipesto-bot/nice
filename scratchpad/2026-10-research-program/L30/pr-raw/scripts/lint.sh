#!/bin/bash
# fmt + clippy as `just lint`, plus clippy with gpu only; separate target dir.
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt-clippy
L=/root/l30pr
cd /root/src-pr
dpkg -s libpq-dev > /dev/null 2>&1 || apt-get install -y -qq libpq-dev > $L/apt_libpq.log 2>&1
rustup component list --installed 2>/dev/null | grep -E "clippy|rustfmt" > $L/lint_toolchain.txt; rustc --version >> $L/lint_toolchain.txt
( cargo fmt --all --check && echo FMT_OK ) > $L/lint_fmt.log 2>&1; tail -1 $L/lint_fmt.log
( nice -n 10 cargo clippy -j 6 -p "*" --all-targets -- -D warnings && echo CLIPPY_DEFAULT_OK ) > $L/lint_clippy_default.log 2>&1; tail -1 $L/lint_clippy_default.log
( nice -n 10 cargo clippy -j 6 -p "*" --all-targets --features nice_client/gpu -- -D warnings && echo CLIPPY_GPU_OK ) > $L/lint_clippy_gpu.log 2>&1; tail -1 $L/lint_clippy_gpu.log
( nice -n 10 cargo clippy -j 6 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings && echo CLIPPY_GPU_SPIRV_OK ) > $L/lint_clippy_gpu_spirv.log 2>&1; tail -1 $L/lint_clippy_gpu_spirv.log
echo LINT_DONE $(date -u +%T)
