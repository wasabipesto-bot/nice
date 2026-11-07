#!/bin/bash
# chain_lvp.sh W SRC "LEVELS" FULL: lavapipe (llvmpipe) for tree SRC: builds W_naga (cubecl) and W_spv (cubecl-spirv),
# own target dir, niced (skipped if present); waits for lvp_go; per level: CI's WGSL dump + lint (naga, the workflow's 13
# requires), #240's FD-vs-top-kernel test on naga and SPIR-V, TopFdKernel's SPIR-V basic blocks (blocks.py); then every
# wgpu test of cubecl_join on naga and SPIR-V at level FULL.
L=/root/l48/logs; BIN=/root/l48/bin; W=$1; SRC=$2; LEVELS=$3; FULL=$4
[ -e $BIN/${W}_naga ] || NICEN=15 J=12 /root/l48/build.sh $SRC ${W}_naga cubecl /root/tgt_lvp
[ -e $BIN/${W}_spv ] || NICEN=15 J=12 /root/l48/build.sh $SRC ${W}_spv cubecl-spirv /root/tgt_lvp
touch $L/lvp_${W}.built
until [ -e $L/${GO:-lvp_go} ]; do sleep 10; done
echo LVP_START $W $(date -u +%T)
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json NICE_BUILD_SHA=test RUST_BACKTRACE=1
vulkaninfo --summary 2>/dev/null | grep -A3 deviceName > $L/lvp_device.txt
vulkaninfo 2>/dev/null | grep -i "subgroupSize\|minSubgroupSize\|maxSubgroupSize\|maxStorageBufferRange" | head -8 >> $L/lvp_device.txt
cd /root/l48/src/$SRC
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
P=cubecl_join::tests::top_fd_matches_the_top_kernel
for lv in $LEVELS; do
  export NICE_EXP_TOPFD=$lv
  rm -f $L/wgsl_${W}_l$lv.log
  ( date -u; CUBECL_DEBUG_LOG=$L/wgsl_${W}_l$lv.log timeout 900 $BIN/${W}_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/lint_dump_${W}_l$lv.log 2>&1
  ( python3 scripts/wgsl-lint.py $L/wgsl_${W}_l$lv.log $REQ --verbose; echo "lint rc=$?" ) > $L/wgsl_lint_${W}_l$lv.log 2>&1
  gzip -f $L/wgsl_${W}_l$lv.log
  ( date -u; timeout 2400 $BIN/${W}_naga --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvpfd_naga_${W}_l$lv.log 2>&1
  rm -f $L/spvdump_${W}_l$lv.log
  ( date -u; CUBECL_DEBUG_LOG=$L/spvdump_${W}_l$lv.log timeout 2400 $BIN/${W}_spv --ignored --exact $P --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvpfd_spv_${W}_l$lv.log 2>&1
  python3 /root/l48/blocks.py $L/spvdump_${W}_l$lv.log --top 30 > $L/blocks_spv_${W}_l$lv.txt 2>&1
  gzip -f $L/spvdump_${W}_l$lv.log
  echo "LVP l$lv: lint $(tail -1 $L/wgsl_lint_${W}_l$lv.log) naga $(grep -h 'test result' $L/lvpfd_naga_${W}_l$lv.log) spv $(grep -h 'test result' $L/lvpfd_spv_${W}_l$lv.log) blocks $(grep -m1 TopFd $L/blocks_spv_${W}_l$lv.txt) $(date -u +%T)"
done
if [ -n "$FULL" ]; then
  export NICE_EXP_TOPFD=$FULL
  for c in naga spv; do
    ( date -u; timeout 3600 $BIN/${W}_$c --ignored cubecl_join:: --nocapture --test-threads 1; echo "exit $?"; date -u ) > $L/lvp_${c}_${W}_l$FULL.log 2>&1
    echo "LVP FULL l$FULL $c: $(grep -h 'test result' $L/lvp_${c}_${W}_l$FULL.log) $(date -u +%T)"
  done
fi
echo LVP_DONE $W $(date -u +%T) > $L/lvp_${W}.done
