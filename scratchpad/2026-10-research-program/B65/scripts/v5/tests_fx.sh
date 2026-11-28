#!/bin/bash
# tests_fx.sh OUT TAG RT: the device tests of bin/TAG/t_box on the RTX 3060, RT cuda (MIDOUT_CUDA=1) or vk
# (Vulkan, env_vulkan.sh, DiscreteGpu(1)): the card tier (cubecl_midout: wide and narrow), the wide slice test
# (unshared, shared, and compile-only at forced width 64), wide faults, wide parent sharing (brute force: brute.sh),
# narrow slice test (unshared, shared), narrow faults, narrow parent sharing. Output $R/runs/OUT/<RT>_<TAG>_<n>.txt.
. "$HOME/research/scripts/env.sh"
OUT=$1; TAG=$2; RT=$3
O=$R/runs/$OUT; mkdir -p $O
export NICE_BUILD_SHA=test RUST_LOG=${RUST_LOG:-warn} CUDA_VISIBLE_DEVICES=${GPU:-1}
T="--nocapture --test-threads 1"
g() { n=$1; shift; X=$R/bin/$TAG/t_box; s0=$(date +%s)
  [ -e $R/b65b/stop ] && { echo "stopped before $n" >> $O/rc.txt; exit 0; }
  if [ $RT = cuda ]; then env MIDOUT_CUDA=1 "$@" $T > $O/${RT}_${TAG}_$n.txt 2>&1
  else ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(1)'; env "$@" $T ) > $O/${RT}_${TAG}_$n.txt 2>&1; fi
  rc=$?; echo "$(date -u +%T) ${RT}_${TAG}_$n rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/${RT}_${TAG}_$n.txt | tail -1)" >> $O/rc.txt; }
X=$R/bin/$TAG/t_box; W=midout::gpu_wide::tests; N=midout::gpu::tests
g tier $X --ignored cubecl_midout
g wslices $X --ignored --exact $W::wide_slices_equal_cpu
g wslices_sh MIDOUT_WIDE_SHARE=1 $X --ignored --exact $W::wide_slices_equal_cpu
g wforce64 MIDOUT_FORCE_W=64 $X --ignored --exact $W::wide_slices_equal_cpu
g wfaults $X --ignored --exact $W::wide_faults_are_loud
g wshare $X --ignored --exact $W::wide_field_parent_sharing_is_exact_and_loud
g nslices $X --ignored --exact $N::gpu_slices_equal_cpu
g nslices_sh MIDOUT_SHARE8=1 $X --ignored --exact $N::gpu_slices_equal_cpu
g nfaults $X --ignored --exact midout::gpu::audit::accounts_faults_are_loud
g nshare $X --ignored --exact $N::field_parent_sharing_is_exact_and_loud
echo "done $TAG $RT" >> $O/done
