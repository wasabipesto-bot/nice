#!/bin/bash
# builds_final.sh C2 C3: the final series' binaries (trees b65l at C3, b65l2 at C2) and the baseline's SPIR-V bench.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; L=$R/b65l/scripts; C2=$1; C3=$2
bash $S/build_t.sh b65l $C3 cubecl-cuda,midout-box-tests fin-t-cuda
bash $S/build_t.sh b65l $C3 cubecl-spirv,midout-box-tests fin-t-spv
echo tests > $R/b65l/builds_final.tests
bash $S/build_b65.sh b65l $C3 cubecl-spirv,midout-bench midout_wide_bench fin-bench-spv
bash $S/build_b65.sh b65l $C3 cubecl-cuda,midout-bench midout_wide_bench fin-bench-cuda
bash $S/build_b65.sh wide-reads 0b6e22e1 cubecl-spirv,midout-bench midout_wide_bench l-base-spv
bash $S/build_b65.sh b65l $C2 cubecl-cuda,midout-bench midout_wide_bench c2-bench-cuda
echo done > $R/b65l/builds_final.done
