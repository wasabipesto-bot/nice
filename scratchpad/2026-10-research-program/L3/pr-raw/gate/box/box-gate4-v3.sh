#!/bin/bash
# Phase 4: speed A/B on CUDA, 18cba8b (base) vs d8038d6 (gate), interleaved B A B.
set -u
source /root/.cargo/env
cd /root/nice
: # phase 3 finished
{
echo "=== $(date -u +%T) build base"
cp target/release/nice_client /root/nice_client_gate
git checkout -q -B base 18cba8b && cargo build --release -p nice_client --features gpu 2>&1 | tail -1
cp target/release/nice_client /root/nice_client_base
git checkout -q gate
for b in gate base; do echo "$b: $(/root/nice_client_$b --version 2>&1 | head -1) sha256 $(sha256sum /root/nice_client_$b | cut -c1-12)"; done
i=0
for r in base gate base gate; do
  i=$((i+1))
  echo "=== $(date -u +%T) bench $r (round $i)"
  RUST_LOG=info NICE_API_BASE=http://127.0.0.1:9 timeout 300 /root/nice_client_$r detailed --gpu --benchmark --benchmark-secs 60 < /dev/null > /root/gate/ab-$i-$r.log 2>&1
  echo "rc $?"
  grep -E "b40_detailed|b50_detailed|NiceMark|GPU initialized" /root/gate/ab-$i-$r.log
done
echo "=== $(date -u +%T) done4"
} > /root/gate/ab.log 2>&1
