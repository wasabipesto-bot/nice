#!/bin/bash
# clippy.sh: fmt check and the three clippy configurations on /root/src/pr.
source /root/.cargo/env
rustup component add clippy rustfmt > /root/logs/rustup_comp.log 2>&1
cd /root/src/pr
echo "== $(date -u +%T) fmt"; cargo fmt --all --check > /root/logs/fmt.log 2>&1; echo "fmt exit $?"
echo "== $(date -u +%T) clippy default"
nice -n 10 cargo clippy -p "*" --all-targets -- -D warnings > /root/logs/clippy_default.log 2>&1; echo "exit $?"
echo "== $(date -u +%T) clippy gpu"
nice -n 10 cargo clippy -p "*" --all-targets --features nice_client/gpu -- -D warnings > /root/logs/clippy_gpu.log 2>&1; echo "exit $?"
echo "== $(date -u +%T) clippy gpu,cubecl-spirv"
nice -n 10 cargo clippy -p "*" --all-targets --features nice_client/gpu,nice_client/cubecl-spirv -- -D warnings > /root/logs/clippy_spirv.log 2>&1; echo "exit $?"
echo CLIPPY_DONE $(date -u +%T)
