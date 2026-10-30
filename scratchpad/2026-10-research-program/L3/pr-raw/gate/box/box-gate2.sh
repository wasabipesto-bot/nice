#!/bin/bash
# Phase 2 on the box: tests (CUDA, lavapipe) and a CUDA benchmark. Logs to /root/gate/.
set -u
source /root/.cargo/env
cd /root/nice
until grep -q "done-build-lint" /root/gate/build.log; do sleep 5; done
log() { echo "=== $(date -u +%T) $*"; }
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
{
log lib-suite
cargo test --release -p nice_common --features gpu --lib 2>&1 | grep -E "test result|detailed_kernel_by_device|plan_covers|FAILED|panicked" ; echo "LIB rc ${PIPESTATUS[0]}"
log cuda-fd
cargo test --release -p nice_common --features gpu --lib -- --ignored --nocapture --test-threads=1 cubecl_cuda_fd_matches_cpu_detailed 2>&1 | tail -60; echo "CUDAFD rc ${PIPESTATUS[0]}"
log cuda-prod-path
cargo test --release -p nice_common --features gpu --lib -- --ignored --nocapture --test-threads=1 cubecl_cuda_matches_cpu_detailed cubecl_cuda_reads_back_every_near_miss 2>&1 | tail -20; echo "CUDAPROD rc ${PIPESTATUS[0]}"
} > /root/gate/tests-cuda.log 2>&1
{
log vulkaninfo
VK_ICD_FILENAMES="$LVP" vulkaninfo --summary 2>&1 | grep -E "deviceName|driverName|apiVersion" ; echo "ICD $LVP"
log lavapipe-gpu-binary
VK_ICD_FILENAMES="$LVP" cargo test --release -p nice_common --features gpu --lib -- --ignored --nocapture cubecl_fd_matches_cpu_detailed cubecl_reads_back_every_near_miss cubecl_matches_cpu_detailed cubecl_finds_69_in_base_10 web_kernel_near_miss_matches_cpu_at_base_49 2>&1 | grep -vE "^b[0-9]+ (random|dS|dC|ddC)" | tail -60; echo "LVP rc ${PIPESTATUS[0]}"
} > /root/gate/tests-lavapipe.log 2>&1
{
log bench-cuda
RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 ./target/release/nice_client detailed --gpu --benchmark --benchmark-secs 60 < /dev/null 2>&1 | grep -vE "^\s*$" | grep -E "CubeCL detailed b40|CubeCL detailed b50|GPU initialized|_detailed|NiceMark|score|backend|rate|error|warn|WARN|ERROR" | awk '!seen[$0]++' | head -60; echo "BENCH rc ${PIPESTATUS[0]}"
log bench-lavapipe-kernel
VK_ICD_FILENAMES="$LVP" RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 ./target/release/nice_client detailed --gpu --gpu-backend cubecl --benchmark --benchmark-secs 10 < /dev/null 2>&1 | grep -E "CubeCL detailed b|GPU initialized|_detailed|NiceMark|error|warn|WARN|ERROR" | awk '{k=$0; sub(/[0-9.]+e[0-9]+ numbers in [0-9.]+s \([0-9.e]+ n\/s\)/, "", k)} !seen[k]++' | head -30; echo "BENCHLVP rc ${PIPESTATUS[0]}"
log done
} > /root/gate/bench.log 2>&1
