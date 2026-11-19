#!/bin/bash
# box: dump.sh TAG — every narrow kernel's generated code from /root/bin/TAG/t_sc (compile-only path of
# gpu_slices_equal_cpu, MIDOUT_FORCE_W; results invalid by design, only the code is wanted):
#   spv8/, spv64/: SPIR-V modules (CubeCL's direct compiler) on lavapipe for W 8 and W 64 (CUBECL_DEBUG_SPIRV);
#   cuda32.log: CubeCL's CUDA source for W 32 on the RTX 3080 (CUBECL_DEBUG_LOG).
# Then one md5 per module in sums.txt, and the CUDA kernels normalised (cudanorm.py) in cu/, cu_sums.txt.
# (t_dp: the SPIR-V test binary with cubecl/spirv-dump; $2: the output name, default TAG.)
T=$1; O=/root/dump/${2:-$T}; rm -rf $O; mkdir -p $O/spv8 $O/spv64; X=/root/bin/$T/t_sc; XD=/root/bin/$T/t_dp
LVP=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -1)
TEST=midout::gpu::tests::gpu_slices_equal_cpu
E="MIDOUT_GPU_SLICES=712012851 MIDOUT_CLASSES=1 MIDOUT_BATCHES=1"
for w in 8 64; do
  env $E MIDOUT_FORCE_W=$w VK_ICD_FILENAMES=$LVP CUBECL_DEBUG_SPIRV=$O/spv$w $XD --ignored --exact $TEST --nocapture --test-threads 1 > $O/run_spv$w.txt 2>&1
  echo "spv$w rc=$?" >> $O/rc.txt
done
env $E MIDOUT_FORCE_W=32 MIDOUT_CUDA=1 CUBECL_DEBUG_LOG=$O/cuda32.log $X --ignored --exact $TEST --nocapture --test-threads 1 > $O/run_cuda32.txt 2>&1
echo "cuda32 rc=$?" >> $O/rc.txt
(cd $O; for d in spv8 spv64; do for f in $d/*; do echo "$(md5sum < $f | cut -c1-32) $f"; done; done) > $O/sums.txt
python3 /root/cudanorm.py $O/cuda32.log $O/cu > $O/cu_sums.txt
echo done > $O/done
