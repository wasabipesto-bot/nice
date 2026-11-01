#!/bin/bash
. /root/.cargo/env
cd /root/src/pr
export NICE_BUILD_SHA=test
{ date -u; rustc --version; cargo test --release --features cubecl-spirv -p nice_common --no-run 2>&1 | tail -5; date -u; } > /root/logs/build_pr_spirv.log 2>&1
{ date -u; cargo test --release --features cubecl -p nice_common --no-run 2>&1 | tail -5; date -u; } > /root/logs/build_pr_naga.log 2>&1
touch /root/logs/build1.done
