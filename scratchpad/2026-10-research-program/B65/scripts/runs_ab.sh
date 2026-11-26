#!/bin/bash
# runs_ab.sh: step 2 of B65/BRIEF.md: base 65, wide path, warm-up field 13731 then 77777, sampled check off (the wide
# bench's default), trunk 66259bb0 against head f61cf79e alternating, CUDA then Vulkan/SPIR-V, then head Vulkan/WGSL.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; A="--base 65 --fields 13731,77777 --group 16"
stop() { [ -e $R/b65/stop ] && { echo "stopped" >> $R/runs/b65-ab/rc.txt; exit 0; }; }
for i in 1 2; do
  stop; bash $S/run_b65.sh b65-ab cu_trunk$i trunk-cuda/midout_wide_bench cuda -- $A
  stop; bash $S/run_b65.sh b65-ab cu_head$i  mo-mode/midout_wide_bench    cuda -- $A
done
for i in 1 2; do
  stop; bash $S/run_b65.sh b65-ab spv_trunk$i trunk-spv/midout_wide_bench vk -- $A
  stop; bash $S/run_b65.sh b65-ab spv_head$i  head-spv/midout_wide_bench  vk -- $A
done
stop; bash $S/run_b65.sh b65-ab wgsl_head1 mo-mode/midout_wide_bench vk -- $A
echo done > $R/runs/b65-ab/done
