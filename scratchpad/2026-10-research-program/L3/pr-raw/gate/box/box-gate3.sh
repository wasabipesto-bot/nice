#!/bin/bash
# Phase 3: the seed-dump diagnostic (patch on top of the gate), CUDA and lavapipe.
set -u
source /root/.cargo/env
cd /root/nice
until grep -q "=== .* done$" /root/gate/bench.log 2>/dev/null; do sleep 5; done
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
{
echo "=== $(date -u +%T) apply"
git checkout -q -B seed-diag gate && git apply /root/seed-dump-diag.patch && git diff --stat
echo "=== $(date -u +%T) build"
cargo test --release -p nice_common --features gpu --lib --no-run 2>&1 | grep -E "^(error|warning: unused)|Finished|error\[" | head -30
echo "=== $(date -u +%T) cuda"
cargo test --release -p nice_common --features gpu --lib -- --ignored --nocapture zz_seed_dump_cuda 2>&1 | grep -E "SEED|test result|panicked" | head -150
echo "=== $(date -u +%T) lavapipe"
VK_ICD_FILENAMES="$LVP" cargo test --release -p nice_common --features gpu --lib -- --ignored --nocapture zz_seed_dump_wgpu 2>&1 | grep -E "SEED|test result|panicked" | head -80
echo "=== $(date -u +%T) done3"
git checkout -q gate
} > /root/gate/seed-diag.log 2>&1
