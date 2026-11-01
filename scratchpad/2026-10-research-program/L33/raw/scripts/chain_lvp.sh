#!/bin/bash
# After master: lavapipe. B naga + spirv test binaries; CI's lint dump with each ER (naga: lint; spirv: TopKernel blocks).
L=/root/l33/logs/lvp; BIN=/root/l33/bin; mkdir -p $L
while ! grep -q "MASTER done" /root/l33/logs/master.log 2>/dev/null; do sleep 10; done
dpkg -s mesa-vulkan-drivers > /dev/null 2>&1 || apt-get install -y -qq mesa-vulkan-drivers libvulkan1 vulkan-tools > $L/apt_lvp.log 2>&1
J=9 /root/l33/scripts/build.sh B B_spv cubecl-spirv > $L/build_spv.out 2>&1 || exit 1
J=9 /root/l33/scripts/build.sh B B_naga cubecl > $L/build_naga.out 2>&1 || exit 1
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) NICE_BUILD_SHA=test RUST_BACKTRACE=1
cd /root/l33/src/B
REQ="--require DetailedKernelU32@80 --require DetailedFdKernelU32@40 --require DetailedFdKernelU32@50 --require DetailedFdKernel@23 --require DetailedFdKernel@40 --require DetailedFdKernel@50 --require DetailedFdKernel@62 --require DetailedKernel@80 --require NiceonlyKernel@40 --require BucketKernel@57 --require JoinKernel@57 --require TopKernel@57 --require CheckKernel@57"
for ER in 0 2 4 6; do
  rm -f $L/spv_er$ER.log
  ( date -u; NICE_EXP_TOP_ER=$ER CUBECL_DEBUG_LOG=$L/spv_er$ER.log timeout 900 $BIN/B_spv --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/run_spv_er$ER.log 2>&1
  python3 /root/l33/scripts/blocks.py $L/spv_er$ER.log --name TopKernel --top 10 > $L/blocks_er$ER.txt 2>&1
  gzip -f $L/spv_er$ER.log
  rm -f $L/naga_er$ER.log
  ( date -u; NICE_EXP_TOP_ER=$ER CUBECL_DEBUG_LOG=$L/naga_er$ER.log timeout 900 $BIN/B_naga --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture; echo "exit $?"; date -u ) > $L/run_naga_er$ER.log 2>&1
  ( python3 /root/l33/src/B/scripts/wgsl-lint.py $L/naga_er$ER.log $REQ; echo "lint rc=$?" ) > $L/lint_er$ER.txt 2>&1
  gzip -f $L/naga_er$ER.log
done
echo LVP_DONE $(date -u +%T) > $L/lvp.done
