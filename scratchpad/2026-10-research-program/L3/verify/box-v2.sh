#!/bin/bash
# Phase 2 on the box at 297a969: CUDA tests, lavapipe tests, the Metal reproducer. Full logs in /root/v/*-full.log.
set -u
source /root/.cargo/env
cd /root/nice
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
log() { echo "=== $(date -u +%T) $*"; }
T="cargo test --release -p nice_common --features gpu --lib"
{
log head; git log --oneline -1
log cuda-fd
RUST_LOG=debug $T -- --ignored --nocapture --test-threads=1 --exact cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed > /root/v/cuda-fd-full.log 2>&1; echo "CUDAFD rc $?"
grep -vE "^b[0-9]+ (random|dS|dC|ddC)" /root/v/cuda-fd-full.log | grep -vE "^\[|^\s*$" | tail -40
log cuda-prod-path
RUST_LOG=debug $T -- --ignored --nocapture --test-threads=1 --exact cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss > /root/v/cuda-prod-full.log 2>&1; echo "CUDAPROD rc $?"
grep -vE "^\[|^\s*$" /root/v/cuda-prod-full.log | tail -20
log cuda-hand-detailed
RUST_LOG=debug $T -- --ignored --nocapture --test-threads=1 --exact client_process_cuda::tests::gpu_matches_cpu_detailed_small > /root/v/cuda-hand-full.log 2>&1; echo "CUDAHAND rc $?"
grep -E "^test |test result|panicked|skipping|not available" /root/v/cuda-hand-full.log | tail -10
} > /root/v/tests-cuda.log 2>&1
{
log vulkaninfo
VK_ICD_FILENAMES="$LVP" vulkaninfo --summary 2>&1 | grep -E "deviceName|driverName|apiVersion"; echo "ICD $LVP"
log lavapipe
VK_ICD_FILENAMES="$LVP" RUST_LOG=debug $T -- --ignored --nocapture cubecl_fd_matches_cpu_detailed cubecl_fd_seed_matches_cpu cubecl_reads_back_every_near_miss cubecl_matches_cpu_detailed cubecl_finds_69_in_base_10 web_kernel_near_miss_matches_cpu_at_base_49 > /root/v/lvp-full.log 2>&1; echo "LVP rc $?"
grep -vE "^b[0-9]+ (random|dS|dC|ddC)" /root/v/lvp-full.log | grep -vE "^\[|^\s*$" | tail -200
log repro-lavapipe
VK_ICD_FILENAMES="$LVP" NICE_METAL_DIV_REPRO=1 $T -- --ignored --nocapture --exact cubecl_detailed_fd::tests::metal_half_shift_div_repro > /root/v/repro-lvp-full.log 2>&1; echo "REPRO_LVP rc $?"
grep -vE "^\s*$" /root/v/repro-lvp-full.log | tail -45
log repro-default-device
NICE_METAL_DIV_REPRO=1 $T -- --ignored --nocapture --exact cubecl_detailed_fd::tests::metal_half_shift_div_repro > /root/v/repro-default-full.log 2>&1; echo "REPRO_DEFAULT rc $?"
grep -E "test result|panicked|variant 0 k=3:" /root/v/repro-default-full.log
log done-v2
} > /root/v/tests-lvp.log 2>&1
