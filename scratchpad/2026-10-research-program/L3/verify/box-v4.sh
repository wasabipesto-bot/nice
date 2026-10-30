#!/bin/bash
# Phase 4: same-box speed reference. PR #225 before the fix (18cba8b) vs 297a969, CUDA, interleaved ref head ref head.
set -u
source /root/.cargo/env
cd /root/nice
log() { echo "=== $(date -u +%T) $*"; }
{
log build-ref
git status --short | head -3
git checkout -q 18cba8b && git log --oneline -1 && cargo build --release -p nice_client --features gpu 2>&1 | tail -1
cp target/release/nice_client /root/nice_client_18cba8b
git checkout -q 297a969 && git log --oneline -1
for b in 18cba8b 297a969; do echo "$b: $(/root/nice_client_$b --version 2>&1 | head -1) sha256 $(sha256sum /root/nice_client_$b | cut -c1-12)"; done
i=0
for r in 18cba8b 297a969 18cba8b 297a969; do
  i=$((i+1))
  log "bench $r (round $i)"
  nvidia-smi dmon -s pc -d 1 > /root/v/ab-dmon-$i-$r.log 2>&1 &
  DMON=$!
  RUST_LOG=info NICE_API_BASE=http://127.0.0.1:9 timeout 300 /root/nice_client_$r detailed --gpu --benchmark --benchmark-secs 60 < /dev/null > /root/v/ab-$i-$r.log 2>&1
  echo "rc $?"
  kill $DMON
  grep -E "b40_detailed|b50_detailed|NiceMark|GPU initialized" /root/v/ab-$i-$r.log
  awk '!/^#/ && $2>100 {print $2, $6}' /root/v/ab-dmon-$i-$r.log | sort -n | awk '{p[NR]=$1} END {print "loaded samples", NR, "pwr median", p[int((NR+1)/2)]}'
  awk '!/^#/ && $2>100 {print $6}' /root/v/ab-dmon-$i-$r.log | sort -n | awk '{c[NR]=$1} END {print "pclk median", c[int((NR+1)/2)]}'
done
log default-wgpu-device
NICE_API_BASE=http://127.0.0.1:9 timeout 120 /root/nice_client_297a969 detailed --gpu --gpu-backend cubecl --benchmark --benchmark-secs 1 < /dev/null 2>&1 | grep -E "GPU initialized"
log done-v4
} > /root/v/ab.log 2>&1
