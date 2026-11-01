#!/bin/bash
# fmt + clippy -D warnings (default, nice_client/gpu, nice_client/gpu + cubecl-spirv) on B; then B's host suite.
source ~/.cargo/env
export CARGO_TARGET_DIR=/root/tgt-clippy NICE_BUILD_SHA=test
L=/root/l31b/logs
cd /root/l31b/src/B
dpkg -s libpq-dev > /dev/null 2>&1 || apt-get install -y -qq libpq-dev > $L/apt_libpq.log 2>&1
rustc --version > $L/lint_toolchain.txt
( cargo fmt --all --check && echo FMT_OK ) > $L/lint_fmt.log 2>&1
( nice -n 10 cargo clippy -j 4 -p "*" --all-targets -- -D warnings && echo CLIPPY_DEFAULT_OK ) > $L/lint_clippy_default.log 2>&1
( nice -n 10 cargo clippy -j 4 -p "*" --all-targets --features nice_client/gpu -- -D warnings && echo CLIPPY_GPU_OK ) > $L/lint_clippy_gpu.log 2>&1
( nice -n 10 cargo clippy -j 4 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings && echo CLIPPY_GPU_SPIRV_OK ) > $L/lint_clippy_gpu_spirv.log 2>&1
for f in fmt clippy_default clippy_gpu clippy_gpu_spirv; do echo "$f: $(tail -1 $L/lint_$f.log)"; done > $L/lint_summary.txt
echo LINT_DONE $(date -u +%T) > $L/lint.done
