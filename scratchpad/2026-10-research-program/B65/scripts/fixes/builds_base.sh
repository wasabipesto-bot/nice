#!/bin/bash
# builds_base.sh REV: benches (CUDA, SPIR-V) of the merge head REV, tree b65b; tags fx-base-bench-{cuda,spv}.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; REV=$1
bash $S/build_b65.sh b65b $REV cubecl-cuda,midout-bench midout_wide_bench,midout_bench fx-base-bench-cuda
bash $S/build_b65.sh b65b $REV cubecl-spirv,midout-bench midout_wide_bench,midout_bench fx-base-bench-spv
echo done > $R/b65b/builds_base.done
