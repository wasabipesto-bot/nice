#!/bin/bash
# bisect.sh C1 C2 ...: for each commit of gpu_wide.rs's history (66259bb0..66305ada), build midout_wide_bench with
# cubecl-spirv,midout-bench in worktree "bisect" and run base 65 (warm-up 13731, field 77777) through Vulkan/SPIR-V.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts
for c in "$@"; do
  [ -e $R/b65/stop ] && { echo "stopped" >> $R/runs/b65-bisect/rc.txt; exit 0; }
  bash $S/build_b65.sh bisect $c cubecl-spirv,midout-bench midout_wide_bench bis-$c || { mkdir -p $R/runs/b65-bisect; echo "build $c failed" >> $R/runs/b65-bisect/rc.txt; continue; }
  bash $S/run_b65.sh b65-bisect spv_$c bis-$c/midout_wide_bench vk -- --base 65 --fields 13731,77777 --group 16
done
echo done > $R/runs/b65-bisect/done
