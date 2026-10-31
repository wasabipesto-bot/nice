#!/bin/bash
# Phase 2 on the box: branch tests on CUDA (wide and forced split16) and lavapipe; kernel dumps of
# main and branch (WGSL via lavapipe, CUDA C++ wide and split16); benchmarks interleaved main/branch.
set -u
source /root/.cargo/env
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export NICE_API_BASE=http://127.0.0.1:9
until grep -q done-p1 /root/v/p1.log; do sleep 10; done
LVP=/usr/share/vulkan/icd.d/lvp_icd.json
log() { echo "=== $(date -u +%T) $*"; }
# run <logname> <test path> [env...]: one ignored test of the branch binary
run() {
  local name=$1 t=$2; shift 2
  local s=$(date +%s)
  (cd /root/pr/common && env RUST_LOG=warn "$@" /root/bin/test_pr $t --ignored --exact --nocapture --test-threads=1 > /root/v/$name.log 2>&1)
  echo "$name: $t rc=$? secs=$(( $(date +%s)-s )) $(grep -E '^test result' /root/v/$name.log)"
}
{
log head; (cd /root/pr && git log --oneline -1); sha256sum /root/bin/*
nvidia-smi --query-gpu=name,driver_version,power.limit,clocks.max.sm --format=csv
log tests-cuda
run cuda-fd cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed
run cuda-detailed cubecl_backend::tests::cubecl_cuda_matches_cpu_detailed
run cuda-nearmiss cubecl_backend::tests::cubecl_cuda_reads_back_every_near_miss
log tests-cuda-split16
run cuda16-fd cubecl_detailed_fd::tests::cubecl_cuda_fd_matches_cpu_detailed NICE_CUBECL_WIDE=0
log tests-lavapipe
VK_ICD_FILENAMES=$LVP vulkaninfo --summary 2>&1 | grep -E "deviceName|driverName|apiVersion"
run lvp-seed cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu VK_ICD_FILENAMES=$LVP
echo "seed windows exact: $(grep -cE '^b[0-9]+ \[.*\): exact$' /root/v/lvp-seed.log) of $(grep -cE '^b[0-9]+ \[' /root/v/lvp-seed.log)"
run lvp-fd cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed VK_ICD_FILENAMES=$LVP
run lvp-nearmiss cubecl_backend::tests::cubecl_reads_back_every_near_miss VK_ICD_FILENAMES=$LVP
run lvp-detailed cubecl_backend::tests::cubecl_matches_cpu_detailed VK_ICD_FILENAMES=$LVP
log dumps
for t in main pr; do
  d=/root/nice; [ $t = pr ] && d=/root/pr
  cd $d/common
  VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=/root/v/dump-wgsl-fd-$t.log RUST_LOG=warn /root/bin/test_$t cubecl_detailed_fd::tests::cubecl_fd_matches_cpu_detailed --ignored --exact --test-threads=1 > /root/v/dump-wgsl-fd-$t.run 2>&1; echo "dump wgsl fd $t rc $? $(grep -E '^test result' /root/v/dump-wgsl-fd-$t.run)"
  VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_LOG=/root/v/dump-wgsl-seed-$t.log RUST_LOG=warn /root/bin/test_$t cubecl_detailed_fd::tests::cubecl_fd_seed_matches_cpu --ignored --exact --test-threads=1 > /root/v/dump-wgsl-seed-$t.run 2>&1; echo "dump wgsl seed $t rc $? $(grep -E '^test result' /root/v/dump-wgsl-seed-$t.run)"
  CUBECL_DEBUG_LOG=/root/v/dump-cuda-wide-$t.log RUST_LOG=warn timeout 300 /root/bin/nice_client_$t detailed --gpu --benchmark --benchmark-secs 4 < /dev/null > /root/v/dump-cuda-wide-$t.run 2>&1; echo "dump cuda wide $t rc $?"
  NICE_CUBECL_WIDE=0 CUBECL_DEBUG_LOG=/root/v/dump-cuda-split16-$t.log RUST_LOG=warn timeout 300 /root/bin/nice_client_$t detailed --gpu --benchmark --benchmark-secs 4 < /dev/null > /root/v/dump-cuda-split16-$t.run 2>&1; echo "dump cuda split16 $t rc $?"
done
ls -la /root/v/dump-*.log
log bench
i=0
for mode in wide split16; do
  for t in main pr main pr; do
    i=$((i+1))
    E=""; [ $mode = split16 ] && E="NICE_CUBECL_WIDE=0"
    log "bench $i $mode $t"
    nvidia-smi dmon -s pc -d 1 > /root/v/bench-dmon-$i-$mode-$t.log 2>&1 &
    DMON=$!
    env $E RUST_LOG=info timeout 300 /root/bin/nice_client_$t detailed --gpu --benchmark --benchmark-secs 60 < /dev/null > /root/v/bench-$i-$mode-$t.log 2>&1
    echo "rc $?"
    kill $DMON
    grep -E "GPU initialized|b40_detailed|b50_detailed|NiceMark" /root/v/bench-$i-$mode-$t.log
    awk '!/^#/ && $2>100 {print $2}' /root/v/bench-dmon-$i-$mode-$t.log | sort -n | awk '{p[NR]=$1} END {print "loaded samples", NR, "pwr median", p[int((NR+1)/2)]}'
    awk '!/^#/ && $2>100 {print $6}' /root/v/bench-dmon-$i-$mode-$t.log | sort -n | awk '{c[NR]=$1} END {print "pclk median", c[int((NR+1)/2)]}'
  done
done
log done-p2
} > /root/v/p2.log 2>&1
