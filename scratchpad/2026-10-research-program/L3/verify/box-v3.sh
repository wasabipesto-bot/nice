#!/bin/bash
# Phase 3 on the box: CUDA benchmark x2 at 297a969 (with power sampling), lavapipe production-path benchmark,
# then a diagnostic-only build that adds the kernel name to the per-window debug line (not part of the verified tree).
set -u
source /root/.cargo/env
cd /root/nice
until grep -q "done-v2" /root/v/tests-lvp.log 2>/dev/null; do sleep 5; done
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
log() { echo "=== $(date -u +%T) $*"; }
{
log head; git log --oneline -1; git status --short | head -3
log power
nvidia-smi -q -d POWER | grep -E "Limit|Draw"
nvidia-smi --query-gpu=name,memory.total,power.limit,power.default_limit,power.max_limit,clocks.max.sm,temperature.gpu,driver_version --format=csv
sha256sum target/release/nice_client
for r in 1 2; do
  log bench-cuda round $r
  nvidia-smi dmon -s pc -d 1 > /root/v/dmon-$r.log 2>&1 &
  DMON=$!
  RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 ./target/release/nice_client detailed --gpu --benchmark --benchmark-secs 60 < /dev/null > /root/v/bench-$r-full.log 2>&1; echo "BENCH$r rc $?"
  kill $DMON
  grep -E "GPU initialized|_detailed |NiceMark|WARN|ERROR" /root/v/bench-$r-full.log
  echo "per-window debug lines: b40 $(grep -c 'CubeCL detailed b40' /root/v/bench-$r-full.log), b50 $(grep -c 'CubeCL detailed b50' /root/v/bench-$r-full.log)"
done
log bench-lavapipe-prod-path
VK_ICD_FILENAMES="$LVP" RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 ./target/release/nice_client detailed --gpu --gpu-backend cubecl --benchmark --benchmark-secs 10 < /dev/null > /root/v/bench-lvp-full.log 2>&1; echo "BENCHLVP rc $?"
grep -E "GPU initialized|_detailed |NiceMark|WARN|ERROR" /root/v/bench-lvp-full.log
grep -E "CubeCL detailed b" /root/v/bench-lvp-full.log | cut -c1-200 | head -14
cp target/release/nice_client /root/nice_client_297a969
log diag-build
sed -i 's|"CubeCL detailed b{base}: {:.2e} numbers|"CubeCL detailed b{base} ({kernel:?}): {:.2e} numbers|' common/src/cubecl_backend.rs
git diff --stat
cargo build --release -p nice_client --features gpu 2>&1 | tail -1
cp target/release/nice_client /root/nice_client_diag
git checkout -- common/src/cubecl_backend.rs; git status --short | head -3
log diag-cuda
RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 /root/nice_client_diag detailed --gpu --benchmark --benchmark-secs 10 < /dev/null > /root/v/diag-cuda-full.log 2>&1; echo "DIAGCUDA rc $?"
grep -E "GPU initialized|NiceMark" /root/v/diag-cuda-full.log
grep -oE "CubeCL detailed b[0-9]+ \([^)]*\)" /root/v/diag-cuda-full.log | sort | uniq -c
log diag-lavapipe
VK_ICD_FILENAMES="$LVP" RUST_LOG=info,nice_common::cubecl_backend=debug NICE_API_BASE=http://127.0.0.1:9 timeout 300 /root/nice_client_diag detailed --gpu --gpu-backend cubecl --benchmark --benchmark-secs 10 < /dev/null > /root/v/diag-lvp-full.log 2>&1; echo "DIAGLVP rc $?"
grep -E "GPU initialized|NiceMark" /root/v/diag-lvp-full.log
grep -oE "CubeCL detailed b[0-9]+ \([^)]*\)" /root/v/diag-lvp-full.log | sort | uniq -c
log power-after
nvidia-smi -q -d POWER | grep -E "Current Power Limit|Default Power Limit"
log done-v3
} > /root/v/bench.log 2>&1
