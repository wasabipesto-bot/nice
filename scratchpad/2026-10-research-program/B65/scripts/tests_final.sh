#!/bin/bash
# tests_final.sh: the branch's final commit (the clippy let-else on top of the measured one): its test binaries
# (CUDA and SPIR-V builds), then the wide tests through CUDA, Vulkan/WGSL and Vulkan/SPIR-V, output compared with the
# branch point's runs in reads-tests. Waits for runs_reads.sh.
. "$HOME/research/scripts/env.sh"
until [ -f $R/runs/reads-bench/done ]; do sleep 10; done
S=$R/b65/scripts; cd $SRC && git fetch -q fork dev/mo-wide-reads; F=$(git rev-parse --short=8 FETCH_HEAD)
bash $S/build_t.sh wide-reads $F cubecl-cuda,midout-box-tests final-cuda
bash $S/build_t.sh wide-reads $F cubecl-spirv,midout-box-tests final-spv
O=$R/runs/reads-tests; export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=1
T="--nocapture --test-threads 1"
g() { rt=$1; tag=$2; n=$3; shift 3; X=$R/bin/$tag/t_box; s0=$(date +%s)
  if [ $rt = cuda ]; then env MIDOUT_CUDA=1 $X --ignored "$@" $T > $O/${rt}_${tag}_$n.txt 2>&1
  else ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'; $X --ignored "$@" $T ) > $O/${rt}_${tag}_$n.txt 2>&1; fi
  rc=$?; echo "$(date -u +%T) ${rt}_${tag}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/${rt}_${tag}_$n.txt | tail -1)" >> $O/rc.txt; }
wide() { g $1 $2 ${3}_tier cubecl_midout_wide; g $1 $2 ${3}_slices --exact midout::gpu_wide::tests::wide_slices_equal_cpu; g $1 $2 ${3}_faults --exact midout::gpu_wide::tests::wide_faults_are_loud; }
wide cuda final-cuda cu; wide vk final-cuda wgsl; wide vk final-spv spv
echo done > $O/final.done
