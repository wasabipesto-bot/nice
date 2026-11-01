#!/bin/bash
# spv.sh TAG [VAR=VAL]: SPIR-V dump (cubecl-spirv on lavapipe) of the lint test's kernels, then OpLabel blocks per kernel.
TAG=$1; shift
L=/root/pad
export VK_ICD_FILENAMES="$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)"
cd /root/padsrc
rm -f $L/spv_$TAG.log
env "$@" CUBECL_DEBUG_LOG=$L/spv_$TAG.log $L/pad_spirv --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > $L/spv_dump_$TAG.log 2>&1
echo "dump rc=$?" >> $L/spv_dump_$TAG.log
python3 /root/blocks.py $L/spv_$TAG.log > $L/spv_blocks_$TAG.txt 2>&1
gzip -f $L/spv_$TAG.log
