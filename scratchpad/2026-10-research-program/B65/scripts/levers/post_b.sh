#!/bin/bash
# post_b.sh: after the timing, on the GTX 1060 3GB: card memory at base 65 (stop 2: tops and parents, one field,
# baseline and head; nvidia-smi -i 0 every 0.5 s), then the head's brute-force small bases through Vulkan/SPIR-V.
. "$HOME/research/scripts/env.sh"
O=$R/runs/levers-1060; mkdir -p $O; export NICE_BUILD_SHA=test RUST_LOG=warn
for b in l-base-cuda fin-bench-cuda; do
  nvidia-smi -i 0 --query-gpu=timestamp,utilization.gpu,power.draw,memory.used,memory.total --format=csv,noheader,nounits -lms 500 > $O/$b.gpu 2>&1 & M=$!
  CUDA_VISIBLE_DEVICES=0 MIDOUT_STOP=2 $R/bin/$b/midout_wide_bench --cuda --base 65 --fields 77777 --group 16 > $O/$b.log 2>&1; echo "rc=$?" >> $O/$b.log
  kill $M; wait $M 2>/dev/null
  echo "$b peak MiB $(cut -d, -f4 $O/$b.gpu | sort -n | tail -1) of $(cut -d, -f5 $O/$b.gpu | head -1)" >> $O/rc.txt
done
T=$R/runs/levers-final-tests; s0=$(date +%s)
( . $R/scripts/env_vulkan.sh; export CUBECL_WGPU_DEFAULT_DEVICE='DiscreteGpu(0)'; $R/bin/fin-t-spv/t_box --ignored --exact midout::gpu_wide::tests::wide_whole_small_bases_vs_brute_force --nocapture --test-threads 1 ) > $T/vk1060_fin-t-spv_brute.txt 2>&1; rc=$?
echo "$(date -u +%T) vk1060_fin-t-spv_brute rc=$rc $(( $(date +%s) - s0 )) s $(grep -h -o 'test result: [a-zA-Z]*\. [0-9]* passed; [0-9]* failed' $T/vk1060_fin-t-spv_brute.txt | tail -1)" >> $T/rc.txt
echo done > $O/post_b.done
