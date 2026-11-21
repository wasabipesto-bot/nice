#!/bin/bash
# box: build mo_width_bench with the direct SPIR-V compiler (cubecl-spirv, own target dir), run every variant once on
# lavapipe compiled for W = 64 (--force-w 64; lavapipe's planes are 8 wide, so the counts are INVALID and only the
# SPIR-V modules are wanted), CUBECL_DEBUG_SPIRV dumps them to /root/spv; spirv-val each.
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt_spv; cd /root/nice
date -u; git log --oneline -1
cargo build --release -p nice_common --features cubecl-spirv,cubecl/spirv-dump --example mo_width_bench 2>&1 | grep -E '^error|Finished'; echo build rc=${PIPESTATUS[0]}
rm -rf /root/spv; mkdir -p /root/spv
CUBECL_DEBUG_SPIRV=/root/spv VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=4 \
  timeout 1200 /root/tgt_spv/release/examples/mo_width_bench --dump /root/dump --pips 4977728 --once --max-inst 2 --force-w 64 > /root/spv/run.txt 2>&1
echo "run rc=$? (count mismatches are expected: W 64 compiled, 8-lane planes)"; grep -c EXACT /root/spv/run.txt
ls /root/spv | head -30
for s in /root/spv/*.spv; do spirv-val --target-env vulkan1.3 --uniform-buffer-standard-layout --allow-vulkan-32-bit-bitwise $s > ${s%.spv}.val 2>&1 || echo "spirv-val FAIL $(basename $s)"; done
date -u
