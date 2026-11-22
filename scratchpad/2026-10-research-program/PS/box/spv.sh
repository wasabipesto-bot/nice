#!/bin/bash
# box: mo_width_bench with the direct SPIR-V compiler (cubecl-spirv, own target dir); every listed variant once on
# lavapipe compiled for W = 64 (--force-w 64: compile only, lavapipe's planes are 8 wide so counts are INVALID; only
# the SPIR-V modules are wanted); CUBECL_DEBUG_SPIRV dumps them to /root/spv; spirv-val each.
source ~/.cargo/env; export CARGO_TARGET_DIR=/root/tgt_spv; cd /root/nice
date -u; git log --oneline -1
cargo build --release -p nice_common --features cubecl-spirv,cubecl/spirv-dump --example mo_width_bench 2>&1 | grep -E '^error|Finished'; echo build rc=${PIPESTATUS[0]}
S=${SPV:-/root/spv}; rm -rf $S; mkdir -p $S
CUBECL_DEBUG_SPIRV=$S VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json LP_NUM_THREADS=4 \
  timeout 1500 /root/tgt_spv/release/examples/mo_width_bench --dump /root/dump --pips 4977728 --once --max-inst 2 --force-w 64 \
  --variants ${SPVV:-w64,ps_q4n,ps_q4,ps_q2,ps_q1,ps_u1,ps16_q4} > $S/run.txt 2>&1
echo "run rc=$? (count mismatches are expected: W 64 compiled, 8-lane planes)"; grep -c EXACT $S/run.txt
ls $S | head -30
for s in $S/*.spv; do spirv-val --target-env vulkan1.3 --uniform-buffer-standard-layout --allow-vulkan-32-bit-bitwise $s > ${s%.spv}.val 2>&1 || echo "spirv-val FAIL $(basename $s)"; done
date -u
