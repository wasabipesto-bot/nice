#!/bin/bash
# Partitions per launch: SLOTS 64 / 32 (profiled) at 1e14, and the survivor bound at 1e16 (b58/60/62),
# on the knob commit 31d95af (binary _y). Built after chain3 so no compile overlaps a timed run.
source ~/.cargo/env
cd /root/nice
git fetch -q origin rp/gpu-profile-2 && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
t0=$(date +%s)
cargo test --release -j 10 -p nice_common --features gpu --no-run > /root/p2/testbuild_y.log 2>&1 || { echo "y build FAILED"; tail -40 /root/p2/testbuild_y.log; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p2/testbuild_y.log | head -1)
cp /root/nice/$bin /root/nice_common_test_y; md5sum /root/nice_common_test_y
echo "y built in $(( $(date +%s) - t0 )) s commit=$(git rev-parse --short HEAD)"
export BIN=/root/nice_common_test_y
R=/root/run3.sh
NICE_EXP_SLOTS=64 $R x14_slots64_r1 20 1e14 0
$R x14_ctl_r3 20 1e14 0
NICE_EXP_SLOTS=32 $R x14_slots32_r3 20 1e14 0
NICE_EXP_SLOTS=64 $R x14_slots64_r2 20 1e14 0
NICE_EXP_SLOTS=32 $R x14_slots32_prof_r1 20 1e14 1
export BASES=58,60,62
NICE_EXP_SURV_PER_PREFIX=1 $R y16_spp1_r1 2 1e16 0
$R y16_ctl_r1 2 1e16 0
NICE_EXP_SURV_PER_PREFIX=1 $R y16_spp1_r2 2 1e16 0
unset BASES
# Upstream main itself (no instrumentation, no knobs) against the knob binary at 1e14.
git fetch -q https://github.com/wasabipesto/nice.git main && git checkout -q --detach FETCH_HEAD && echo "tree: $(git log --oneline -1)"
cargo test --release -j 10 -p nice_common --features gpu --no-run > /root/p2/testbuild_main.log 2>&1 || { echo "main build FAILED"; exit 1; }
bin=$(grep -o "target/release/deps/nice_common-[0-9a-f]*" /root/p2/testbuild_main.log | head -1)
cp /root/nice/$bin /root/nice_common_test_main; md5sum /root/nice_common_test_main
BIN=/root/nice_common_test_main $R x14_main_r1 20 1e14 0
$R x14_ctl_r4 20 1e14 0
BIN=/root/nice_common_test_main $R x14_main_r2 20 1e14 0
echo CHAIN4_DONE $(date -u +%T)
