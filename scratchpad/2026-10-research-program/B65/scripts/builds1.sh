#!/bin/bash
# builds1.sh: the session's first builds (step 1 of B65/BRIEF.md), one after another.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; L=$R/logs/b65; mkdir -p $L
cd "$SRC" || exit 1
git fetch -q fork dev/mo-mode dev/mo-clean dev/middle-out-join > "$L/fetch.log" 2>&1 || { echo "fetch failed" >> $L/rc.txt; exit 1; }
for c in f61cf79e 66305ada 66259bb0 a82ad9db 1d4d6920 64cf6c24 85185fef 10ddbf17; do git cat-file -e $c^{commit} 2>/dev/null && echo "have $c" || echo "MISSING $c"; done >> "$L/fetch.log"
bash $S/build_b65.sh mo-mode f61cf79e cubecl-spirv,midout-bench midout_wide_bench,midout_bench head-spv
bash $S/build_b65.sh trunk 66259bb0 cubecl-cuda midout_wide_bench trunk-cuda
bash $S/build_b65.sh trunk 66259bb0 cubecl-spirv midout_wide_bench trunk-spv
echo done > $L/builds1.done
