#!/bin/bash
. /root/.cargo/env
export NICE_BUILD_SHA=test
while [ ! -f /root/logs/build_main_spirv.done ]; do sleep 5; done
for T in pr main; do
  cd /root/src/$T
  { date -u; cargo test --release --features gpu -p nice_common --no-run 2>&1 | grep -v "^ *Compiling\|^ *Downloaded" | tail -30; date -u; } > /root/logs/build_${T}_gpu.log 2>&1
  touch /root/logs/build_${T}_gpu.done
done
