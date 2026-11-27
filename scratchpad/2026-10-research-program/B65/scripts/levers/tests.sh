#!/bin/bash
# tests.sh OUT TAG RT [EXTRA_TESTS...]: the wide exactness tests of a test binary bin/TAG/t_box on the RTX 3060:
# the tier (cubecl_midout_wide*), wide_slices_equal_cpu, wide_faults_are_loud, then EXTRA (exact names).
# RT cuda (MIDOUT_CUDA=1) | vk (Vulkan, env_vulkan.sh, DiscreteGpu(1)). Output $R/runs/OUT/<RT>_<TAG>_<test>.txt.
. "$HOME/research/scripts/env.sh"
OUT=$1; TAG=$2; RT=$3; shift 3
O=$R/runs/$OUT; mkdir -p $O
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=${GPU:-1}
T="--nocapture --test-threads 1"
g() { n=$1; shift; X=$R/bin/$TAG/t_box; s0=$(date +%s)
  if [ $RT = cuda ]; then env MIDOUT_CUDA=1 $X --ignored "$@" $T > $O/${RT}_${TAG}_$n.txt 2>&1
  else ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'; $X --ignored "$@" $T ) > $O/${RT}_${TAG}_$n.txt 2>&1; fi
  rc=$?; echo "$(date -u +%T) ${RT}_${TAG}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/${RT}_${TAG}_$n.txt | tail -1)" >> $O/rc.txt; }
g tier cubecl_midout_wide
g slices --exact midout::gpu_wide::tests::wide_slices_equal_cpu
g faults --exact midout::gpu_wide::tests::wide_faults_are_loud
for t in "$@"; do g ${t##*::} --exact $t; done
echo "done $TAG $RT" >> $O/done
