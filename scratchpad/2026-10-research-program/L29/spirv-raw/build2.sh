#!/bin/bash
. /root/.cargo/env
export NICE_BUILD_SHA=test
while [ ! -f /root/logs/build1.done ]; do sleep 5; done
for T in fix main; do
  cd /root/src/$T
  [ -d target ] || cp -a /root/src/pr/target ./target
  { date -u; cargo test --release --features cubecl-spirv -p nice_common --no-run 2>&1 | grep -v "^ *Compiling\|^ *Downloaded" | tail -30; date -u; } > /root/logs/build_${T}_spirv.log 2>&1
  touch /root/logs/build_${T}_spirv.done
done
