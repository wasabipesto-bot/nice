#!/bin/bash
# builds_reads.sh: the batched-reads change (dev/mo-wide-reads) and its branch point, test binaries then benches.
#   base = 4fff25e7 (dev/mo-mode, the branch point) in tree mo-mode; reads = the branch head in tree wide-reads.
. "$HOME/research/scripts/env.sh"
S=$R/b65/scripts; L=$R/logs/reads; mkdir -p $L
cd "$SRC" || exit 1
git fetch -q fork dev/mo-mode dev/mo-wide-reads > $L/fetch.log 2>&1 || { echo "fetch failed" >> $L/rc.txt; exit 1; }
BASE=4fff25e7; RD=$(git rev-parse --short=8 fork/dev/mo-wide-reads 2>/dev/null || git rev-parse --short=8 FETCH_HEAD)
echo "base=$BASE reads=$RD" >> $L/rc.txt
# warm the new tree's target dirs from the existing ones (registry crates are path-independent)
[ -d $R/t/wide-reads ] || cp -a $R/t/mo-mode $R/t/wide-reads
[ -d $R/t/wide-reads-rel ] || cp -a $R/t/mo-mode-rel $R/t/wide-reads-rel
bash $S/build_t.sh wide-reads $RD cubecl-cuda,midout-box-tests reads-cuda
bash $S/build_t.sh mo-mode $BASE cubecl-cuda,midout-box-tests base-cuda
echo tests-cuda > $L/stage1.done
bash $S/build_t.sh wide-reads $RD cubecl-spirv,midout-box-tests reads-spv
bash $S/build_t.sh mo-mode $BASE cubecl-spirv,midout-box-tests base-spv
echo tests-spv > $L/stage2.done
bash $S/build_b65.sh wide-reads $RD cubecl-cuda,midout-bench midout_wide_bench rb-reads-cuda
bash $S/build_b65.sh mo-mode $BASE cubecl-cuda,midout-bench midout_wide_bench rb-base-cuda
bash $S/build_b65.sh wide-reads $RD cubecl-spirv,midout-bench midout_wide_bench rb-reads-spv
bash $S/build_b65.sh mo-mode $BASE cubecl-spirv,midout-bench midout_wide_bench rb-base-spv
echo done > $L/builds.done
