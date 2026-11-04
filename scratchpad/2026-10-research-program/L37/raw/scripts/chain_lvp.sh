#!/bin/bash
# chain_lvp.sh SRC TAG VAR VALUES: lavapipe (llvmpipe) on tree SRC: builds (cubecl = naga, cubecl-spirv = direct SPIR-V) if
# missing, CI's WGSL dump + lint (naga, the workflow's 13 requires) per VAR value, join parity on naga and SPIR-V per value.
L=/root/l37/logs; BIN=/root/l37/bin; SRC=$1; TAG=$2; VAR=$3; shift 3
[ -e $BIN/${TAG}_naga ] || NICEN=15 J=12 CARGO_TARGET_DIR=/root/tgt_lvp /root/l37/build.sh $SRC ${TAG}_naga cubecl /root/tgt_lvp
[ -e $BIN/${TAG}_spv ] || NICEN=15 J=12 CARGO_TARGET_DIR=/root/tgt_lvp /root/l37/build.sh $SRC ${TAG}_spv cubecl-spirv /root/tgt_lvp
touch $L/lvp_${TAG}.built
until [ -e $L/lvp_go ]; do sleep 10; done
echo LVP_START $TAG $(date -u +%T)
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
vulkaninfo 2>/dev/null | grep -i "subgroupSize\|subgroupSupportedOperations\|minSubgroupSize\|maxSubgroupSize" | head -8 >> $L/lvp_device.txt
cd /root/l37/src/$SRC
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
P=cubecl_join::tests::cubecl_join_matches_the_cpu_reference
for v in "$@"; do
  export $VAR=$v
  rm -f $L/wgsl_${TAG}_$v.log
  ( date -u; CUBECL_DEBUG_LOG=$L/wgsl_${TAG}_$v.log timeout 900 $BIN/${TAG}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_${TAG}_$v.log 2>&1
  ( python3 scripts/wgsl-lint.py $L/wgsl_${TAG}_$v.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_${TAG}_$v.log 2>&1
  gzip -f $L/wgsl_${TAG}_$v.log
  ( date -u; echo "$VAR=$v"; timeout 2400 $BIN/${TAG}_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_naga_${TAG}_$v.log 2>&1
  ( date -u; echo "$VAR=$v"; timeout 2400 $BIN/${TAG}_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_par_spv_${TAG}_$v.log 2>&1
done
echo LVP_DONE $TAG $(date -u +%T) > $L/lvp_${TAG}.done
