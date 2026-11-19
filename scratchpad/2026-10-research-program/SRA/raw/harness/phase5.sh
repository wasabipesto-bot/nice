#!/bin/bash
# CI's GPU-feature unit tests (rust-build-test.yml "Run tests"): the cubecl module's non-device tests, incl. ran_complete's
source ~/.cargo/env
cd /root/sra/nice
export CARGO_TARGET_DIR=/root/sra/target
L=/root/sra/logs/phase5; mkdir -p $L
while [ ! -f /root/sra/logs/phase4/done ]; do sleep 10; done
echo "$(date -u +%FT%TZ) start gpu_lib" >> $L/steps.log
NICE_REQUIRE_NVRTC=1 cargo test --locked --release -p nice_common --features gpu --lib -- --format pretty > $L/gpu_lib.log 2>&1
echo "$(date -u +%FT%TZ) end gpu_lib rc=$?" >> $L/steps.log
echo done > $L/done
