#!/bin/bash
# brute.sh OUT CTAG VTAG: the wide brute-force test on the GTX 1060 (nvidia-smi 0, wgpu DiscreteGpu(0)): through
# CUDA (bin/CTAG/t_box), then through Vulkan (bin/VTAG/t_box).
. "$HOME/research/scripts/env.sh"
O=$R/runs/$1; mkdir -p $O; export NICE_BUILD_SHA=test RUST_LOG=warn
T="--ignored --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force --nocapture --test-threads 1"
s0=$(date +%s); CUDA_VISIBLE_DEVICES=0 MIDOUT_CUDA=1 $R/bin/$2/t_box $T > $O/cuda1060_$2_wbrute.txt 2>&1; rc=$?
echo "$(date -u +%T) cuda1060_$2_wbrute rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/cuda1060_$2_wbrute.txt)" >> $O/rc.txt
[ -e $R/b65b/stop ] && exit 0
s0=$(date +%s); ( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(0)'; $R/bin/$3/t_box $T ) > $O/vk1060_$3_wbrute.txt 2>&1; rc=$?
echo "$(date -u +%T) vk1060_$3_wbrute rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $O/vk1060_$3_wbrute.txt)" >> $O/rc.txt
echo done > $O/brute.done
