#!/bin/bash
. /root/.cargo/env
export NICE_BUILD_SHA=test
while [ ! -f /root/logs/build_main_gpu.done ]; do sleep 5; done
cd /root/src/fix
{ date -u; cargo test --release --features gpu -p nice_common --no-run 2>&1 | grep -v "^ *Compiling\|^ *Downloaded" | tail -30; date -u; } > /root/logs/build_fix_gpu.log 2>&1
touch /root/logs/build_fix_gpu.done
{ date -u; cargo test --release --features cubecl -p nice_common --no-run 2>&1 | grep -v "^ *Compiling\|^ *Downloaded" | tail -30; date -u; } > /root/logs/build_fix_naga.log 2>&1
touch /root/logs/build_fix_naga.done
