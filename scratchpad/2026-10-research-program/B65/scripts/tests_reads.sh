#!/bin/bash
# tests_reads.sh: exactness and loudness of the wide path, branch point (base) against the batched reads (reads),
# on the RTX 3060 through CUDA, Vulkan/SPIR-V and Vulkan/WGSL (the CUDA build's wgpu runtime); the narrow tests once
# (reads, CUDA). Output: $R/runs/reads-tests/<rt>_<tag>_<test>.txt and rc.txt.
. "$HOME/research/scripts/env.sh"
O=$R/runs/reads-tests; mkdir -p $O; L=$R/logs/reads
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=1
T="--nocapture --test-threads 1"
g() {  # g RT TAG NAME ARGS...: RT cuda|vk
  rt=$1; tag=$2; n=$3; shift 3; X=$R/bin/$tag/t_box; s0=$(date +%s)
  if [ $rt = cuda ]; then env MIDOUT_CUDA=1 $X --ignored "$@" $T > $O/${rt}_${tag}_$n.txt 2>&1
  else ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'; $X --ignored "$@" $T ) > $O/${rt}_${tag}_$n.txt 2>&1; fi
  rc=$?; echo "$(date -u +%T) ${rt}_${tag}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/${rt}_${tag}_$n.txt | tail -1)" >> $O/rc.txt
}
wide() {  # wide RT TAG (the RT label for the file names: cuda, spv, wgsl)
  rt=$1; tag=$2; lab=$3
  g $rt $tag ${lab}_tier cubecl_midout_wide
  g $rt $tag ${lab}_slices --exact midout::gpu_wide::tests::wide_slices_equal_cpu
  g $rt $tag ${lab}_faults --exact midout::gpu_wide::tests::wide_faults_are_loud
}
until [ -f $L/stage1.done ]; do sleep 10; done
wide cuda reads-cuda cu; wide cuda base-cuda cu
g cuda reads-cuda narrow_slices --exact midout::gpu::tests::gpu_slices_equal_cpu
g cuda reads-cuda narrow_faults accounts_faults_are_loud
wide vk reads-cuda wgsl; wide vk base-cuda wgsl
until [ -f $L/stage2.done ]; do sleep 10; done
wide vk reads-spv spv; wide vk base-spv spv
echo done > $O/done
