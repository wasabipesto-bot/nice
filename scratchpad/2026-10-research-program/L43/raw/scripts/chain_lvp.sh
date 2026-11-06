#!/bin/bash
# chain_lvp.sh W WB: lavapipe (llvmpipe, 8-lane subgroups) on binaries W_naga / W_spv with NICE_EXP_JOIN_WB=WB (TT must
# fall back to the shared-memory copy there): CI's WGSL dump + lint (naga, the workflow's 13 requires), every wgpu
# test of cubecl_join on naga and on direct SPIR-V, and the direct-SPIR-V block count of the join kernel (parity
# test dumped with CUBECL_DEBUG_LOG, WB=0 and WB).
L=/root/l43/logs; BIN=/root/l43/bin; W=$1; WB=$2
until [ -e $L/lvp_go ]; do sleep 10; done
echo LVP_START $W $(date -u +%T)
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
vulkaninfo 2>/dev/null | grep -i "subgroupSize\|minSubgroupSize\|maxSubgroupSize\|maxStorageBufferRange" | head -8 >> $L/lvp_device.txt
cd /root/l43/src/$W
export NICE_EXP_JOIN_WB=$WB
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
rm -f $L/wgsl_${W}.log
( date -u; CUBECL_DEBUG_LOG=$L/wgsl_${W}.log timeout 900 $BIN/${W}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_${W}.log 2>&1
( python3 scripts/wgsl-lint.py $L/wgsl_${W}.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_${W}.log 2>&1
gzip -f $L/wgsl_${W}.log
for c in naga spv; do
  ( date -u; timeout 3600 $BIN/${W}_$c --ignored cubecl_join:: --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_${c}_${W}.log 2>&1
done
for v in 0 $WB; do
  ( date -u; NICE_EXP_JOIN_WB=$v CUBECL_DEBUG_LOG=$L/spvdump_wb$v.log timeout 1800 $BIN/${W}_spv --ignored --exact cubecl_join::tests::cubecl_join_matches_the_cpu_reference --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/spvdump_wb$v.out 2>&1
  python3 /root/l43/blocks.py $L/spvdump_wb$v.log --top 40 > $L/spv_blocks_wb$v.txt 2>&1
  gzip -f $L/spvdump_wb$v.log
done
echo LVP_DONE $W $(date -u +%T) > $L/lvp_${W}.done
