#!/bin/bash
# chain_lint.sh W: `just lint` as CI runs it on tree W (fmt; clippy default; clippy with nice_client/gpu and
# nice_client/cubecl-spirv), and clippy with nice_client/gpu alone; own target dir, niced.
source ~/.cargo/env
L=/root/l43/logs; W=$1
cd /root/l43/src/$W
export CARGO_TARGET_DIR=/root/tgt_clippy NICE_BUILD_SHA=test
( cargo fmt --all --check; echo "fmt rc=$?" ) > $L/fmt_${W}.log 2>&1
( nice -n 15 cargo clippy -j 10 -p "*" --all-targets -- -D warnings; echo "clippy default rc=$?" ) > $L/clippy_default_${W}.log 2>&1
( nice -n 15 cargo clippy -j 10 -p "*" --all-targets --features nice_client/gpu -- -D warnings; echo "clippy gpu rc=$?" ) > $L/clippy_gpu_${W}.log 2>&1
( nice -n 15 cargo clippy -j 10 -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings; echo "clippy gpu+spirv rc=$?" ) > $L/clippy_gpuspv_${W}.log 2>&1
tail -1 $L/fmt_${W}.log $L/clippy_*_${W}.log
echo LINT_DONE $W $(date -u +%T) > $L/lint_${W}.done
